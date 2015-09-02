function generateConeLearningProgressVideo(obj, datafile, varargin)

    default = struct(...
        'fixationsPerSceneRotations', 12, ...
        'adaptationModel',   'none', ...
        'photoCurrentNoise', 'noNoise', ...
        'precorrelationFilter', [], ...
        'disparityMetric', 'linear', ...
        'mdsWarningsOFF', false, ...
        'coneLearningUpdateIntervalInFixations', 1.0, ...
        'displayComputationTimes', false, ...
        'outputFormat', 'still' ...
        );
    
    % Parse optional analysis paramaters in varargin
    parser = inputParser;
    parser.addParamValue('fixationsPerSceneRotation', default.fixationsPerSceneRotations, @isnumeric);
    parser.addParamValue('adaptationModel', default.adaptationModel, @ischar);
    parser.addParamValue('photocurrentNoise', default.photoCurrentNoise, @ischar);
    parser.addParamValue('precorrelationFilter', default.precorrelationFilter);
    parser.addParamValue('disparityMetric', default.disparityMetric, @ischar);
    parser.addParamValue('mdsWarningsOFF', default.mdsWarningsOFF, @islogical);
    parser.addParamValue('coneLearningUpdateIntervalInFixations', default.coneLearningUpdateIntervalInFixations, @isfloat);
    parser.addParamValue('displayComputationTimes', default.displayComputationTimes, @islogical);
    parser.addParamValue('outputFormat', default.outputFormat, @ischar);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    parserResults = parser.Results;
    pNames = fieldnames(parserResults);
    for k = 1:length(pNames)
        eval(sprintf('obj.%s = parserResults.%s', pNames{k}, pNames{k}))
    end
   
    % Load data and conv
    obj.loadSpatioTemporalPhotonAbsorptionMatrix(datafile);
 
    % Go !
    if (strcmp(obj.outputFormat, 'video'))
        generateVideo(obj);
    elseif (strcmp(obj.outputFormat, 'still'))
        generateFigure(obj);
    else
        error('Unknown outputFormat (''%s'').\n', obj.outputFormat);
    end
end


function generateFigure(obj)

    if (obj.mdsWarningsOFF)
            warning('off','stats:mdscale:IterOrEvalLimit');
        else
            warning('on','stats:mdscale:IterOrEvalLimit');
    end
    
    % Permute eye movements and photon absorptions and compute max scene
    % rotations so that all scenes are scanned with the same number of eye movements
    maxAvailableSceneRotations = obj.permuteEyeMovementsAndPhotoAbsorptionResponses();
    
    % Ask user for the desired number of scene rotations
    fullSceneRotations = input(sprintf('Enter desired scene rotations [max=%2.0f]: ', maxAvailableSceneRotations));
    totalFixationsNum  = numel(obj.core1Data.allSceneNames)*obj.fixationsPerSceneRotation*fullSceneRotations;
    eyeMovementsPerSceneRotation = obj.fixationsPerSceneRotation * obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
    fprintf('Video will contain a total of %d fixations (total of %d microfixations).\n\n', totalFixationsNum, eyeMovementsPerSceneRotation*fullSceneRotations);
    
    % Initialize counters
    eyeMovementIndex = 1;
    
    % aggregated photon absorption XT response
    obj.photonAbsorptionXTresponse = [];
    obj.adaptedPhotoCurrentXTresponse = [];
    
    for rotationIndex = 1:fullSceneRotations

       % time bins for eyeMovement and XTresponse that this scene rotation will include
       timeBinsForPresentSceneRotation = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);

       for sceneIndex = 1:numel(obj.core1Data.allSceneNames)
           
           fprintf('<strong>Scene:%d/%d Rotation:%d/%d</strong>\n', sceneIndex, numel(obj.core1Data.allSceneNames), rotationIndex, fullSceneRotations)
                
           % Aggregate response
           aggegateXTResponseOffset = size(obj.photonAbsorptionXTresponse,2);
                obj.photonAbsorptionXTresponse  = [...
                    obj.photonAbsorptionXTresponse ...
                    obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}(:,timeBinsForPresentSceneRotation)...
                    ];
           
           % Compute rieke adapted photo-current response with noise
           % and post-adaptation filter according to the passed analysis params
           obj.computePostAbsorptionResponse();
           
           % Now generate image data ms-for-ms and compute mosaic during this scene rotation
           for timeBinIndex = 1:eyeMovementsPerSceneRotation
               
                % range of time bins to include
                timeBinRangeToThisPoint = 1:(aggegateXTResponseOffset+timeBinIndex);
                    
                % compute fixation time for current time bin
                obj.fixationsNum = timeBinRangeToThisPoint(end) / obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;     
                obj.fixationTimeInMilliseconds = timeBinRangeToThisPoint(end) * (1000.0*obj.core1Data.sensorTimeInterval);
                    
                % check to see if it is time to compute an updated learned cone mosaic
                updateConeMosaicLearning = (mod(obj.fixationsNum,obj.coneLearningUpdateIntervalInFixations) == 0.0);
                    
                if (~updateConeMosaicLearning)
                    % do not update learned cone mosaic
                    continue;
                end
                    
                % compute disparity matrix
                obj.computeDisparityMatrix(timeBinRangeToThisPoint);
                    
                % Attempt MDS of disparity matrix
                try
                    % Compute MDSprojection
                    dimensionsNum = 3;
                    [obj.MDSprojection, obj.MDSstress] = mdscale(obj.disparityMatrix,dimensionsNum);

                    % unwarp MDSprojection
                    obj.unwrapMDSprojection();

                    % compute cone learning progression
                    obj.computeConeMosaicLearningProgression(obj.fixationsNum);
                      
                catch err
                    fprintf(2,'Problem with mdscale (''%s''). Skipping this time bin (%d).\n', err.message, timeBinRangeToThisPoint(end));
                    rethrow(err)
                    continue;
                end
                    
           end % timeBinIndex
        end % sceneIndex
       
        % update eye movementIndex
        eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
           
    end % rotationIndex       
    
    hFig = figure(2); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    axesStruct = generateFigureAxes(hFig);
    obj.displayLearnedConeMosaic(axesStruct.xyMDSAxes, axesStruct.xzMDSAxes, axesStruct.yzMDSAxes,axesStruct.mosaicAxes);
    obj.displayConeMosaicProgress(axesStruct.performanceAxes1, axesStruct.performanceAxes2);
    drawnow;
    
    % Save figure as PDF
    pdfFileName = sprintf('MosaicReconstruction_%s_%s.pdf',obj.adaptationModel, obj.photocurrentNoise);
    NicePlot.exportFigToPDF(pdfFileName,hFig,300);
    
    % Save data as matfile
    dataFileName = sprintf('MosaicReconstruction_%s_%s.mat',obj.adaptationModel, obj.photocurrentNoise);
    coneMosaicLearningProgress = obj.coneMosaicLearningProgress;
    save(dataFileName, 'coneMosaicLearningProgress');
end


function generateVideo(obj)

    if (obj.mdsWarningsOFF)
        warning('off','stats:mdscale:IterOrEvalLimit');
    else
        warning('on','stats:mdscale:IterOrEvalLimit');
    end
    
    % Permute eye movements and photon absorptions and compute max scene
    % rotations so that all scenes are scanned with the same number of eye movements
    maxAvailableSceneRotations = obj.permuteEyeMovementsAndPhotoAbsorptionResponses();
    
    % Ask user for the desired number of scene rotations
    fullSceneRotations = input(sprintf('Enter desired scene rotations [max=%2.0f]: ', maxAvailableSceneRotations));
    totalFixationsNum  = numel(obj.core1Data.allSceneNames)*obj.fixationsPerSceneRotation*fullSceneRotations;
    eyeMovementsPerSceneRotation = obj.fixationsPerSceneRotation * obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
    fprintf('Video will contain a total of %d fixations (total of %d microfixations).\n\n', totalFixationsNum, eyeMovementsPerSceneRotation*fullSceneRotations);
    
    % determine maximally - responsive LMS cones for sceneIndex = 1
    obj.determineMaximallyResponseLMSConeIndices(1);
    
    % Setup video stream
    writerObj = VideoWriter(sprintf('MosaicReconstruction_%s_%s.m4v',obj.adaptationModel, obj.photocurrentNoise), 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    axesStruct = generateVideoAxes(hFig);
   
    % Initialize counters
    eyeMovementIndex = 1;
    kSteps = 0;
    kStepsMin = 100;
    
    % Preallocate temp matrices to hold up various computation components
    % Traces for a duration equal to 1 fixations
    obj.videoData.photonAsborptionTraces = zeros(3,obj.core1Data.eyeMovementParamsStruct.samplesPerFixation);
    obj.videoData.photoCurrentTraces = zeros(3,obj.core1Data.eyeMovementParamsStruct.samplesPerFixation);
    
    % XT response for a duration equal to 6 fixations
    obj.videoData.shortHistoryXTResponse = zeros(prod(obj.core1Data.sensorRowsCols), 6*obj.core1Data.eyeMovementParamsStruct.samplesPerFixation)-Inf;
    % current 2D response
    obj.videoData.current2DResponse = zeros(obj.core1Data.sensorRowsCols(1), obj.core1Data.sensorRowsCols(2));
    
    % aggregated photon absorption XT response
    obj.photonAbsorptionXTresponse = [];
    obj.adaptedPhotoCurrentXTresponse = [];
    
    % Open video stream
    open(writerObj);
    
    try
       for rotationIndex = 1:fullSceneRotations
           
           % time bins for eyeMovement and XTresponse that this scene rotation will include
           timeBinsForPresentSceneRotation = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);
           
           for sceneIndex = 1:numel(obj.core1Data.allSceneNames)
               
                fprintf('<strong>Scene:%d/%d Rotation:%d/%d</strong>\n', sceneIndex, numel(obj.core1Data.allSceneNames), rotationIndex, fullSceneRotations)
                
                % Get optical image and eye movement video data for this scene scan
                obj.computeOpticalImageVideoData(sceneIndex);
                obj.computeEyeMovementVideoData(sceneIndex, timeBinsForPresentSceneRotation);
            
                % Aggregate response
                aggegateXTResponseOffset = size(obj.photonAbsorptionXTresponse,2);
                obj.photonAbsorptionXTresponse  = [...
                    obj.photonAbsorptionXTresponse ...
                    obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}(:,timeBinsForPresentSceneRotation)...
                    ];
            
                % Compute rieke adapted photo-current response with noise
                % and post-adaptation filter according to the passed analysis params
                obj.computePostAbsorptionResponse();
               
                % Now generate image data ms-for-ms and compute mosaic during this scene rotation
                for timeBinIndex = 1:eyeMovementsPerSceneRotation
                   
                    % range of time bins to include
                    timeBinRangeToThisPoint = 1:(aggegateXTResponseOffset+timeBinIndex);
                    
                    % compute fixation time for current time bin
                    obj.fixationsNum = timeBinRangeToThisPoint(end) / obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;     
                    obj.fixationTimeInMilliseconds = timeBinRangeToThisPoint(end) * (1000.0*obj.core1Data.sensorTimeInterval);
                    
                    % update traces
                    obj.videoData.photonAsborptionTraces = circshift(obj.videoData.photonAsborptionTraces, -1, 2);
                    obj.videoData.photonAsborptionTraces(:,end) = obj.photonAbsorptionXTresponse(obj.maxResponsiveConeIndices, timeBinRangeToThisPoint(end));
                    obj.videoData.photoCurrentTraces = circshift(obj.videoData.photoCurrentTraces, -1, 2);
                    obj.videoData.photoCurrentTraces(:,end) = obj.prefilteredAdaptedPhotoCurrentXTresponse(obj.maxResponsiveConeIndices, timeBinRangeToThisPoint(end));
                    
                    % obtain current response at this time bin index
                    currentResponse = (obj.adaptedPhotoCurrentXTresponse(:, timeBinRangeToThisPoint(end)))';
                    obj.videoData.current2DResponse = reshape(currentResponse, [obj.core1Data.sensorRowsCols(1) obj.core1Data.sensorRowsCols(2)]);
                   
                    % update short history response
                    obj.videoData.shortHistoryXTResponse = circshift(obj.videoData.shortHistoryXTResponse, -1, 2);
                    obj.videoData.shortHistoryXTResponse(:,end) = currentResponse;
                    
                    % check to see if it is time to compute an updated learned cone mosaic
                    updateConeMosaicLearning = (mod(obj.fixationsNum,obj.coneLearningUpdateIntervalInFixations) == 0.0);
                    kSteps = kSteps + 1;
                    
                    if (kSteps < kStepsMin)
                        continue;
                    end
                    
                    if (~updateConeMosaicLearning)
                        % Render another video frame
                        renderVideoFrame(obj, timeBinIndex, axesStruct, writerObj);
                        % do not update learned cone mosaic
                        continue;
                    end
                    
                    % compute disparity matrix
                    obj.computeDisparityMatrix(timeBinRangeToThisPoint);
                    
                    % Attempt MDS of disparity matrix
                    try
                        if (obj.displayComputationTimes)
                            tic
                        end
                        % Compute MDSprojection
                        dimensionsNum = 3;
                        [obj.MDSprojection, obj.MDSstress] = mdscale(obj.disparityMatrix,dimensionsNum);

                        % unwarp MDSprojection
                        obj.unwrapMDSprojection();

                        % compute cone learning progression
                        obj.computeConeMosaicLearningProgression(obj.fixationsNum);
                        if (obj.displayComputationTimes)
                            fprintf('\tMDS computation took %f seconds.\n', toc);
                        end
                        
                    catch err
                        fprintf(2,'Problem with mdscale (''%s''). Skipping this time bin (%d).\n', err.message, timeBinRangeToThisPoint(end));
                        rethrow(err)
                        continue;
                    end
                    
                    % Render another video frame
                    renderVideoFrame(obj, timeBinIndex, axesStruct, writerObj);
                    
                end  % timeBinIndex
           end % sceneIndex
           
           % update eye movementIndex
           eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
       end % rotationIndex
       
    catch err
         fprintf(2, 'Encountered error. Will attempt to save movie now.\n');
         % close video stream and save movie
         close(writerObj);
         
         fprintf('Saved movie. Rethrowing the error now.\n');
         rethrow(err);
    end
    
    % close video stream and save movie
    close(writerObj);
end

function renderVideoFrame(obj, eyeMovementIndex, axesStruct, writerObj)

    obj.displayOpticalImageAndEyeMovements(axesStruct.opticalImageAxes, eyeMovementIndex);
    obj.displaySingleConeTraces(axesStruct.photonAbsorptionTraces,axesStruct.photoCurrentTraces);
    obj.displayCurrent2Dresponse(axesStruct.current2DResponseAxes);
    obj.displayShortHistoryXTresponse(axesStruct.xtResponseAxes);
    obj.displayDisparityMatrix(axesStruct.dispMatrixAxes);
    obj.displayLearnedConeMosaic(axesStruct.xyMDSAxes, axesStruct.xzMDSAxes, axesStruct.yzMDSAxes,axesStruct.mosaicAxes);
    obj.displayConeMosaicProgress(axesStruct.performanceAxes1, axesStruct.performanceAxes2);
    obj.displayTimeInfo(axesStruct.timeDisplayAxes);
    
    drawnow;
    frame = getframe(gcf);
    writeVideo(writerObj, frame);
end


function axesStruct = generateVideoAxes(hFig)
    % top row
    axesStruct.opticalImageAxes      = axes('parent',hFig,'unit','pixel','position',[-30 394 620 400], 'Color', [0 0 0]);
    axesStruct.photonAbsorptionTraces= axes('parent',hFig,'unit','pixel','position',[563 705 140 75], 'Color', [0 0 0]);
    axesStruct.photoCurrentTraces    = axes('parent',hFig,'unit','pixel','position',[563 590 140 75], 'Color', [0 0 0]);
    axesStruct.current2DResponseAxes = axes('parent',hFig,'unit','pixel','position',[563 395 140 140], 'Color', [0 0 0]);
    axesStruct.xtResponseAxes        = axes('parent',hFig,'unit','pixel','position',[720 395 144 400], 'Color', [0 0 0]);
    axesStruct.dispMatrixAxes        = axes('parent',hFig,'unit','pixel','position',[870 395 400 400], 'Color', [0 0 0]);
    axesStruct.timeDisplayAxes       = axes('parent',hFig,'unit','pixel','position',[1120 720 140 20], 'Color', [0 0 0]);
     
    % mid row
    axesStruct.xyMDSAxes         = axes('parent',hFig,'unit','pixel','position',[30   130  256 226], 'Color', [0 0 0]);
    axesStruct.xzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[370  130  256 226], 'Color', [0 0 0]);
    axesStruct.yzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[720  130  256 256], 'Color', [0 0 0]);
    axesStruct.mosaicAxes        = axes('parent',hFig,'unit','pixel','position',[1010 130  256 256], 'Color', [0 0 0]);
    
    % bottom row
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[25   10 600 110], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[670  10 600 110], 'Color', [0 0 0]);
end

function axesStruct = generateFigureAxes(hFig)
    % top row
    axesStruct.xyMDSAxes         = axes('parent',hFig,'unit','pixel','position',[30   130+400  256 226], 'Color', [0 0 0]);
    axesStruct.xzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[370  130+400  256 226], 'Color', [0 0 0]);
    axesStruct.yzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[720  130+400  256 256], 'Color', [0 0 0]);
    axesStruct.mosaicAxes        = axes('parent',hFig,'unit','pixel','position',[1010 130+400  256 256], 'Color', [0 0 0]);
    
    % bottom row
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[25   30 600 110+350], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[670  30 600 110+350], 'Color', [0 0 0]);
end
