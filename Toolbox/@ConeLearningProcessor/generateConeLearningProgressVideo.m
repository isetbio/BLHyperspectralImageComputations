function generateConeLearningProgressVideo(obj, datafile, varargin)

    obj.loadSpatioTemporalPhotonAbsorptionMatrix(datafile);
 
    % parse optional arguments
    parser = inputParser;
    parser.addParamValue('fixationsPerSceneRotation', 12, @isnumeric);
    parser.addParamValue('adaptationModelToUse',  'none', @ischar);
    parser.addParamValue('noiseFlag', 'noNoise', @ischar);
    parser.addParamValue('precorrelationFilter', []);
    parser.addParamValue('disparityMetric', 'linear', @ischar);
    parser.addParamValue('mdsWarningsOFF', false, @islogical);
    parser.addParamValue('coneLearningUpdateInFixations', 1.0, @isfloat);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    parserResults = parser.Results;
    pNames = fieldnames(parserResults);
    for k = 1:length(pNames)
        eval(sprintf('obj.%s = parserResults.%s', pNames{k}, pNames{k}))
    end
    
    generateVideo(obj);
end


function generateVideo(obj)

    if (obj.mdsWarningsOFF)
        warning('off','stats:mdscale:IterOrEvalLimit');
    else
        warning('on','stats:mdscale:IterOrEvalLimit');
    end
    
    % find minimal number of eye movements across all scenes
    minEyeMovements = 1000*1000*1000;
    totalEyeMovementsNum = 0;
    
    % Set the rng for repeatable eye movements
    rng(obj.randomSeedForEyeMovementsOnDifferentScenes);
    
    % permute eyemovements and XT response indices 
    for sceneIndex = 1:numel(obj.core1Data.allSceneNames)
         
        fprintf('Permuting eye movements and photon absorptions sequences for scene %d (''%s'')\n', sceneIndex, obj.core1Data.allSceneNames{sceneIndex});
        
        responseLength = size(obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex},2);
        fixationsNum = responseLength / obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        % to photon rate
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = ...
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}/obj.core1Data.sensorConversionGain/obj.core1Data.sensorExposureTime;
        
        % Ensure that all scenes have same maximal photon absorption rates (and
        % equal to the max absorption rate during scene 1)
        maxPhotonAbsorptionForCurrentScene = max(max(abs(obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex})));
        if (sceneIndex == 1)
            maxPhotonAbsorptionForScene1 = maxPhotonAbsorptionForCurrentScene;
        else
            obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = ...
            obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} / maxPhotonAbsorptionForCurrentScene * maxPhotonAbsorptionForScene1;
        end
            
        % do the permutation of eyemovements/responses
        tmp1 = obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}*0;
        tmp2 = obj.core1Data.eyeMovements{sceneIndex}*0;
        
        kk = 1:obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*obj.core1Data.eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*obj.core1Data.eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = obj.core1Data.eyeMovements{sceneIndex}(sourceIndices,:);
        end
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = tmp1;
        obj.core1Data.eyeMovements{sceneIndex} = tmp2;
        
        % compute min number of eyemovements across all scenes
        eyeMovementsNum = size(obj.core1Data.eyeMovements{sceneIndex},1);
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end   
    end % sceneIndex
    
    % determine maximally - responsive LMS cones for sceneIndex = 1
    obj.determineMaximallyResponseLMSConeIndices(1);
    
    eyeMovementsPerSceneRotation = obj.fixationsPerSceneRotation * obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation);
    
    fullSceneRotations = input(sprintf('Enter desired scene rotations [max=%2.0f]: ', fullSceneRotations));
    totalFixationsNum  = numel(obj.core1Data.allSceneNames)*obj.fixationsPerSceneRotation*fullSceneRotations;
    fprintf('Video will contain a total of %d fixations (total of %d microfixations)\n', totalFixationsNum, eyeMovementsPerSceneRotation*fullSceneRotations);
    
    % Setup video stream
    writerObj = VideoWriter(sprintf('MosaicReconstruction_%s_%s.m4v',obj.adaptationModelToUse, obj.noiseFlag), 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    axesStruct = generateAxes(hFig);
   
    % Initialize counters
    eyeMovementIndex = 1;
    kSteps = 0;
    kStepsMin = 100;
    
    % Preallocate temp matrices to hold up various computation components
    obj.videoData.photonAsborptionTraces = zeros(3,obj.core1Data.eyeMovementParamsStruct.samplesPerFixation);
    obj.videoData.photoCurrentTraces = zeros(3,obj.core1Data.eyeMovementParamsStruct.samplesPerFixation);
    
    % XT response for a duration equal to 1 fixation
    obj.videoData.shortHistoryXTResponse = zeros(prod(obj.core1Data.sensorRowsCols), eyeMovementsPerSceneRotation)-Inf;
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
               
                fprintf('Scene:%d/%d Rotation:%d/%d\n', sceneIndex, numel(obj.core1Data.allSceneNames), rotationIndex, fullSceneRotations)
                
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
                % and post-adaptation filter according to analysis params
                % passed to generateConeLearningProgressVideo();
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
                    updateConeMosaicLearning = (mod(obj.fixationsNum,obj.coneLearningUpdateInFixations) == 0.0);
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
                        tic
                        % Compute MDSprojection
                        dimensionsNum = 3;
                        [obj.MDSprojection, obj.MDSstress] = mdscale(obj.disparityMatrix,dimensionsNum);

                        % unwarp MDSprojection
                        obj.unwrapMDSprojection();

                        % compute cone learning progression
                        obj.computeConeMosaicLearningProgression(obj.fixationsNum);
                        fprintf('MDS took %f\n', toc);

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
    
    drawnow;
    frame = getframe(gcf);
    writeVideo(writerObj, frame);
end


function axesStruct = generateAxes(hFig)
    % top row
    axesStruct.opticalImageAxes      = axes('parent',hFig,'unit','pixel','position',[-30 394 620 400], 'Color', [0 0 0]);
    axesStruct.photonAbsorptionTraces= axes('parent',hFig,'unit','pixel','position',[563 705 140 75], 'Color', [0 0 0]);
    axesStruct.photoCurrentTraces    = axes('parent',hFig,'unit','pixel','position',[563 590 140 75], 'Color', [0 0 0]);
    axesStruct.current2DResponseAxes = axes('parent',hFig,'unit','pixel','position',[563 395 140 140], 'Color', [0 0 0]);
    axesStruct.xtResponseAxes        = axes('parent',hFig,'unit','pixel','position',[720 395 144 400], 'Color', [0 0 0]);
    axesStruct.dispMatrixAxes        = axes('parent',hFig,'unit','pixel','position',[870 395 400 400], 'Color', [0 0 0]);
     
    % mid row
    axesStruct.xyMDSAxes         = axes('parent',hFig,'unit','pixel','position',[30   130  256 226], 'Color', [0 0 0]);
    axesStruct.xzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[370  130  256 226], 'Color', [0 0 0]);
    axesStruct.yzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[720  130  256 256], 'Color', [0 0 0]);
    axesStruct.mosaicAxes        = axes('parent',hFig,'unit','pixel','position',[1010 130  256 256], 'Color', [0 0 0]);
    
    % bottom row
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[25   10 600 110], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[670  10 600 110], 'Color', [0 0 0]);
end