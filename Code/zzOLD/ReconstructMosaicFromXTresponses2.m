function ReconstructMosaicFromXTresponses2

    warning('off','stats:mdscale:IterOrEvalLimit');
    
    generateVideo = true;

    conesAcross = 10;
    resultsFile = sprintf('results_%dx%d.mat', conesAcross,conesAcross);
            
    if (generateVideo)
        selectedDemo = input('Full reconstruction video (1), Demo1 short video (2), Demo2 short video (3) : ');

        if (selectedDemo == 1)
            resultsFile = sprintf('results_%dx%d.mat', conesAcross,conesAcross);
        elseif (selectedDemo == 2)
            conesAcross = 20;
            resultsFile1 = sprintf('results_%dx%d_ForDemoVideo1.mat', conesAcross,conesAcross);
        elseif (selectedDemo == 3)
            conesAcross = 20;
            resultsFile2 = sprintf('results_%dx%d_ForDemoVideo2.mat', conesAcross,conesAcross);
        end
    end
    fprintf('Using %s file.\n', resultsFile);
    
    normalizeResponsesForEachScene = false;
    
    adaptationModelToUse = 'linear';  % choose from 'none' or 'linear'
    noiseFlag = 'RiekeNoise';       % 'noNoise' or 'RiekeNoise'
    
    randomSeedForEyeMovementsOnDifferentScenes = 234823568;
    indicesOfScenesToExclude = [25];
     
    
    if (generateVideo)
        if (selectedDemo == 1)
            GenerateVideoFile(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude);
        end
        
        if (selectedDemo == 2)
            GeneratePartsVideoFile(resultsFile1, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, round(randomSeedForEyeMovementsOnDifferentScenes*17.4), indicesOfScenesToExclude);
        end
        
        if (selectedDemo == 3)
            GeneratePartsVideo2File(resultsFile2, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude);
        end
        
    else
        GenerateResultsFigure(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude);
    end
end


function GeneratePartsVideoFile(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    load(resultsFile, '-mat');
    
    fixationsPerSceneRotation = 12;
    
    % find minimal number of eye movements across all scenes
    minEyeMovements = 1000*1000*1000;
    totalEyeMovementsNum = 0;
    
    
    % Set the rng for repeatable eye movements
    rng(randomSeedForEyeMovementsOnDifferentScenes);
    
    % permute eyemovements and XT response indices 
    for sceneIndex = 1:numel(allSceneNames)
        
        if (ismember(sceneIndex, indicesOfScenesToExclude))
            continue;
        end
        
        if (normalizeResponsesForEachScene)
            if (sceneIndex == 1)
                maxXTresponseForScene1 = max(abs(XTresponses{sceneIndex}));
            else
                XTresponses{sceneIndex} = XTresponses{sceneIndex} / max(abs(XTresponses{sceneIndex})) * maxXTresponseForScene1*10;
            end
        end
        
        fprintf('Permuting eye movements and XT responses for scene %d\n', sceneIndex);
        fixationsNum = size(XTresponses{sceneIndex},2) / eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        tmp1 = XTresponses{sceneIndex}*0;
        tmp2 = eyeMovements{sceneIndex}*0;

        kk = 1:eyeMovementParamsStruct.samplesPerFixation;
        
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = eyeMovements{sceneIndex}(sourceIndices,:);
        end
        
        XTresponses{sceneIndex} = tmp1;
        eyeMovements{sceneIndex} = tmp2;
        
        eyeMovementsNum = size(eyeMovements{sceneIndex},1);
        
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end   
    end
    
    eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation)
    totalFixationsNum = (numel(allSceneNames)-numel(indicesOfScenesToExclude))*fullSceneRotations*fixationsPerSceneRotation
    
    fullSceneRotations = 1;
    
    % Setup video stream
    writerObj = VideoWriter(sprintf('OpticalImageEyeMovementMosaicActivationAdaptedResponse.m4v'), 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    % Open video stream
    open(writerObj); 
    
    kSteps = 0;
    performance = [];
    fixationNo = 0;
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    
    % top row
    axesStruct.opticalImageAxes      = axes('parent',hFig,'unit','pixel','position',[30 45 900 700], 'Color', [0 0 0]);
    axesStruct.current2DResponseAxes = axes('parent',hFig,'unit','pixel','position',[950 435 300 300], 'Color', [0 0 0]);
    axesStruct.current2DAdaptedResponseAxes     = axes('parent',hFig,'unit','pixel','position',[950 55 300 300], 'Color', [0 0 0]);
    % Initialize
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    minSteps = 10;  % 1 minute + 2 seconds + 500 milliseconds
    
    midgetIR = temporalImpulseResponse('V1monophasic');
    
    for rotationIndex = 1:fullSceneRotations
        
        timeBins = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);

        for sceneIndex = 1:numel(allSceneNames)

            % get optical/sensor params for this scene
            opticalImage = opticalImageRGBrendering{sceneIndex};
            opticalImageXposInMicrons = (0:size(opticalImage,2)-1) * opticalSampleSeparation{sceneIndex}(1);
            opticalImageYposInMicrons = (0:size(opticalImage,1)-1) * opticalSampleSeparation{sceneIndex}(2);
            opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
            opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);
            selectXPosIndices = 1:1:size(opticalImage,2);
            selectYPosIndices = 1:1:size(opticalImage,1);
            opticalImage = opticalImage(selectYPosIndices, selectXPosIndices,:);
            opticalImageXposInMicrons = opticalImageXposInMicrons(selectXPosIndices);
            opticalImageYposInMicrons = opticalImageYposInMicrons(selectYPosIndices);
            
            % Get eye movements for this scene scan
            currentEyeMovements = eyeMovements{sceneIndex}(timeBins,:);
            currentEyeMovementsInMicrons(:,1) = currentEyeMovements(:,1) * sensorSampleSeparation(1);
            currentEyeMovementsInMicrons(:,2) = currentEyeMovements(:,2) * sensorSampleSeparation(2);

            sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparation(1);
            sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparation(2);
   
            % aggregate response
            aggegateXTResponseOffset = size(aggregateXTresponse,2);
            aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];

            if (strcmp(adaptationModelToUse, 'linear'))
                fprintf('Computing aggregate adapted XT response - linear adaptation (scene:%d/%d, rotation:%d/%d)\n', sceneIndex,numel(allSceneNames), rotationIndex,fullSceneRotations);
                photonRate = reshape(aggregateXTresponse, [sensorRowsCols(1) sensorRowsCols(2) size(aggregateXTresponse,2)]) / ...
                     sensorConversionGain/sensorExposureTime;
                initialState = riekeInit;
                initialState.timeInterval  = sensorTimeInterval;
                initialState.Compress = false;
                adaptedXYTresponse = riekeLinearCone(photonRate, initialState);
                if (strcmp(noiseFlag, 'RiekeNoise'))
                    disp('Adding noise');
                    params.seed = 349573409;
                    params.sampTime = sensorTimeInterval;
                    [adaptedXYTresponse, ~] = riekeAddNoise(adaptedXYTresponse, params);
                end
                
                
                aggregateAdaptedXTresponse = reshape(adaptedXYTresponse, ...
                             [size(photonRate,1)*size(photonRate,2) size(photonRate,3)]);
                         
                % apply ganglion midget temporal filtering
                signalLength = size(aggregateAdaptedXTresponse,2);
                for coneIndex = 1:size(aggregateAdaptedXTresponse,1)
                    tmp = conv(squeeze(aggregateAdaptedXTresponse(coneIndex,:)), midgetIR);
                    aggregateAdaptedXTresponse(coneIndex,:) = tmp(1:signalLength);
                end
                
                % normalize
                aggregateAdaptedXTresponse = aggregateAdaptedXTresponse / max(abs(aggregateAdaptedXTresponse(:)));
            end
        
            for timeBinIndex = 1:eyeMovementsPerSceneRotation 

                tt = aggegateXTResponseOffset + timeBins(timeBinIndex);
                currentResponse        = aggregateXTresponse(:, tt); 
                currentAdaptedResponse = aggregateAdaptedXTresponse(:, tt);
                
                current2DResponse        = reshape(currentResponse,        [sensorRowsCols(1) sensorRowsCols(2)]);
                current2DAdaptedResponse = reshape(currentAdaptedResponse, [sensorRowsCols(1) sensorRowsCols(2)]);
                kSteps = kSteps + 1;
                
                binRange = 1:size(aggregateXTresponse,2)-eyeMovementsPerSceneRotation+timeBinIndex;
                fixationNo = (binRange(end))/eyeMovementParamsStruct.samplesPerFixation;
                
                RenderPartsFrame(axesStruct, fixationNo,  ...
                    opticalImage, opticalImageXposInMicrons, opticalImageYposInMicrons, ...
                    timeBinIndex, currentEyeMovementsInMicrons, sensorOutlineInMicrons, ...
                    current2DResponse, current2DAdaptedResponse);
                
                if (~isempty(writerObj))
                    frame = getframe(gcf);
                    writeVideo(writerObj, frame);
                end
        
            end % timeBin
        end % sceneIndex
        
        eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
    end% rotationIndex
    
    % close video stream and save movie
    close(writerObj);
end



function GeneratePartsVideo2File(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    load(resultsFile, '-mat');
     
    fixationsPerSceneRotation = 12;
     
    % find minimal number of eye movements across all scenes
    minEyeMovements = 1000*1000*1000;
    totalEyeMovementsNum = 0;
    
    
    % Set the rng for repeatable eye movements
    rng(randomSeedForEyeMovementsOnDifferentScenes);
    
    % permute eyemovements and XT response indices 
    for sceneIndex = 1:numel(allSceneNames)
        fprintf('Wha the ? Permuting eye movements and XT responses for scene %d\n', sceneIndex);
        fixationsNum = size(XTresponses{sceneIndex},2) / eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        if (normalizeResponsesForEachScene)
            if (sceneIndex == 1)
                maxXTresponseForScene1 = max(abs(XTresponses{sceneIndex}));
            else
                XTresponses{sceneIndex} = XTresponses{sceneIndex} / max(abs(XTresponses{sceneIndex})) * maxXTresponseForScene1;
            end
        end
        
        tmp1 = XTresponses{sceneIndex}*0;
        tmp2 = eyeMovements{sceneIndex}*0;

        kk = 1:eyeMovementParamsStruct.samplesPerFixation;
        
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = eyeMovements{sceneIndex}(sourceIndices,:);
        end
        
        XTresponses{sceneIndex} = tmp1;
        eyeMovements{sceneIndex} = tmp2;
        
        eyeMovementsNum = size(eyeMovements{sceneIndex},1);
        
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end   
        
    end % sceneIndex
    
    eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation)
    totalFixationsNum = (numel(allSceneNames)-numel(indicesOfScenesToExclude))*fullSceneRotations*fixationsPerSceneRotation
    
    fullSceneRotations = input('Enter desired scene rotations: ');
    
    % Setup video stream
    writerObj = VideoWriter(sprintf('DispatiryMatrixBuildUp.m4v'), 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    % Open video stream
    open(writerObj); 
    
    kSteps = 0;
    performance = [];
    fixationNo = 0;
    
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    
    axesStruct.current2DResponseAxes = axes('parent',hFig,'unit','pixel','position',[20 270 200 200], 'Color', [0 0 0]);
    axesStruct.xtResponseAxes        = axes('parent',hFig,'unit','pixel','position',[250 200 600 400], 'Color', [0 0 0]);
    axesStruct.dispMatrixAxes        = axes('parent',hFig,'unit','pixel','position',[860 200 400 400], 'Color', [0 0 0]);
    
    shortHistoryXTResponse = zeros(prod(sensorRowsCols), eyeMovementsPerSceneRotation);
    
    % Initialize
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    minSteps = 10;  % 1 minute + 2 seconds + 500 milliseconds
    
    midgetIR = temporalImpulseResponse('V1monophasic');
    
    for rotationIndex = 1:fullSceneRotations
        
        timeBins = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);

        for sceneIndex = 1:numel(allSceneNames)
            
            % aggregate response
            aggegateXTResponseOffset = size(aggregateXTresponse,2);
            aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];
            
            if (strcmp(adaptationModelToUse, 'linear'))
                disp('Computing aggregate adapted XT response - linear adaptation');
                photonRate = aggregateXTresponse / sensorConversionGain/sensorExposureTime;
                initialState = riekeInit;
                initialState.timeInterval  = sensorTimeInterval;
                initialState.Compress = false;
                aggregateAdaptedXTresponse = riekeLinearCone(photonRate, initialState);
                if (strcmp(noiseFlag, 'RiekeNoise'))
                    disp('Adding noise to adapted responses');
                    params.seed = 349573409;
                    params.sampTime = sensorTimeInterval;
                    [aggregateAdaptedXTresponse, ~] = riekeAddNoise(aggregateAdaptedXTresponse, params);
                end
               
                % apply ganglion midget temporal filtering
                signalLength = size(aggregateAdaptedXTresponse,2);
                for coneIndex = 1:size(aggregateAdaptedXTresponse,1)
                    tmp = conv(squeeze(aggregateAdaptedXTresponse(coneIndex,:)), midgetIR);
                    aggregateAdaptedXTresponse(coneIndex,:) = tmp(1:signalLength);
                end
                
                % normalize
                aggregateAdaptedXTresponse = aggregateAdaptedXTresponse / max(abs(aggregateAdaptedXTresponse(:)));
            end
            

            for timeBinIndex = 1:eyeMovementsPerSceneRotation 
                
                if (strcmp(adaptationModelToUse, 'none'))
                    %currentResponse = XTresponses{sceneIndex}(:,timeBins(timeBinIndex));
                    currentResponse = aggregateXTresponse(:, aggegateXTResponseOffset + timeBinIndex);
                    %currentMax = max(max(abs(aggregateXTresponse(:, aggegateXTResponseOffset + 1:timeBins(timeBinIndex)))));
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    currentResponse = aggregateAdaptedXTresponse(:, aggegateXTResponseOffset + timeBinIndex);
                    %currentMax = max(max(abs(aggregateAdaptedXTresponse(:, aggegateXTResponseOffset + 1:timeBins(timeBinIndex)))));
                end
                
                
                
                shortHistoryXTResponse = circshift(shortHistoryXTResponse, -1, 2);
                shortHistoryXTResponse(:,end) = currentResponse;
                current2DResponse = reshape(currentResponse, [sensorRowsCols(1) sensorRowsCols(2)]);
                
                kSteps = kSteps + 1;
                
                
                binRange = 1:size(aggregateXTresponse,2)-eyeMovementsPerSceneRotation+timeBinIndex;
                
                if (strcmp(adaptationModelToUse, 'none'))
                    correlationMatrix = corrcoef((aggregateXTresponse(:,binRange))');
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    correlationMatrix = corrcoef((aggregateAdaptedXTresponse(:,binRange))');
                end
                %D = -log((correlationMatrix+1.0)/2.0);
                %Linear dissim metric
                D = 1-(correlationMatrix+1.0)/2.0;
                if ~issymmetric(D)
                    D = 0.5*(D+D');
                end
                
                
                if (kSteps < minSteps)
                    fprintf('Skipping MDS for step %d (%d)\n', kSteps, minSteps);
                    continue;
                end
                
                fixationNo = (binRange(end)-1)/eyeMovementParamsStruct.samplesPerFixation;
                fixationTimeInMilliseconds = binRange(end)-1;
                
                RenderParts2Frame(axesStruct, fixationNo, fixationTimeInMilliseconds, timeBinIndex, ...
                    shortHistoryXTResponse, current2DResponse, D );
                
                if (~isempty(writerObj))
                    frame = getframe(gcf);
                    writeVideo(writerObj, frame);
                end
           end % timeBin
        end % sceneIndex
        
        eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
    end% rotationIndex
    
    % close video stream and save movie
    close(writerObj);
            
end

function  RenderParts2Frame(axesStruct, fixationNo, fixationTimeInMilliseconds, eyeMovementIndex, ...
                    shortHistoryXTResponse, current2DResponse, D )
                
    xtResponseAxes = axesStruct.xtResponseAxes;
    current2DResponseAxes = axesStruct.current2DResponseAxes;
    dispMatrixAxes   = axesStruct.dispMatrixAxes;
    
    % Current 2d respose
    hCurrRespPlot = pcolor(current2DResponseAxes, current2DResponse);
    set(hCurrRespPlot, 'EdgeColor', 'none');
    axis(current2DResponseAxes, 'square');
    axis(current2DResponseAxes, 'ij');
    axis(current2DResponseAxes, 'on');
    box(current2DResponseAxes, 'on');
    set(current2DResponseAxes, 'CLim', [0 1]);
    set(current2DResponseAxes, 'XLim', [1 size(current2DResponse,2)], 'YLim', [1 size(current2DResponse,1)]);
    set(current2DResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {});
    currentTimeHours   = floor(fixationTimeInMilliseconds/(1000*60*60));
    currentTimeMinutes = floor((fixationTimeInMilliseconds - currentTimeHours*(1000*60*60)) / (1000*60));
    currentTimeSeconds = floor((fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60))/1000);
    currentTimeMilliSeconds = fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60) - currentTimeSeconds*1000;
    if (fixationNo < 1000)
        title(current2DResponseAxes,  sprintf('fixation #%03.3f\n(%02.0f : %02.0f : %02.0f : %03.0f)', fixationNo, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 20, 'Color', [1 .8 .4]);
    else
        title(current2DResponseAxes,  sprintf('fixation #%03.0f\n(%02.0f : %02.0f : %02.0f : %03.0f)', fixationNo, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 20, 'Color', [1 .8 .4]);
    end
    %xlabel(current2DResponseAxes, sprintf('mosaic activation'), 'Color', [1 1 1], 'FontSize', 16);
    
    
    % Short history XT response
    hXTrespPlot = pcolor(xtResponseAxes, shortHistoryXTResponse);
    set(hXTrespPlot, 'EdgeColor', 'none');
    box(xtResponseAxes, 'on'); 
    axis(xtResponseAxes, 'ij')
    set(xtResponseAxes, 'CLim', [0 1]);
    set(xtResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', (0.0 : 200 : 1200), 'YTick', [0:100:400], 'XTickLabel', {}, 'YTickLabel', {}, 'FontSize', 16);
    grid(xtResponseAxes, 'on');
    title(xtResponseAxes, sprintf('spatiotemporal adapted response (%2.1f seconds)', size(shortHistoryXTResponse,2)/1000), 'FontSize', 20, 'Color', [1 .8 .4]);
    
    % Disparity matrix
    visD = D.*tril(ones(size(D)));
    hdensityPlot = pcolor(dispMatrixAxes, visD);
    set(hdensityPlot, 'EdgeColor', 'none');
    colormap(hot);
    box(dispMatrixAxes, 'off'); 
    axis(dispMatrixAxes, 'square');
    axis(dispMatrixAxes, 'ij')
    set(dispMatrixAxes, 'CLim', [0 max(D(:))]);
    set(dispMatrixAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [],'XTickLabel', {}, 'YTickLabel', {});
    title(dispMatrixAxes, sprintf('disparity matrix'), 'FontSize', 20, 'Color', [1 .8 .4]);
    
    colormap(hot);
    
    drawnow
end


function GenerateVideoFile(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    load(resultsFile, '-mat');
    
    
    scenesNumForThreshold1 = 0;     % after this many scenes num (here 1), a new frame is added only at the end of each fixation
    scenesNumForThreshold2 = 1;     % after this many scenes num (here 2), a new frame is added only at the end of 2 consecutive fixations
    scenesNumForThreshold3 = 2;     % after this many scenes num (here 3), a new frame is added only at the end of 3 consecutive fixations
    scenesNumForThreshold4 = 3;     % after this many scenes num (here 4), a new frame is added only at the end of 4 consecutive fixations
    
    fixationsPerSceneRotation = 22;
    fixationsThreshold1 = ceil((fixationsPerSceneRotation*scenesNumForThreshold1)/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    fixationsThreshold2 = ceil((fixationsPerSceneRotation*scenesNumForThreshold2)/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    fixationsThreshold3 = ceil((fixationsPerSceneRotation*scenesNumForThreshold3)/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    fixationsThreshold4 = ceil((fixationsPerSceneRotation*scenesNumForThreshold4)/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    
    % find minimal number of eye movements across all scenes
    minEyeMovements = 1000*1000*1000;
    totalEyeMovementsNum = 0;
    
    
    % Set the rng for repeatable eye movements
    rng(randomSeedForEyeMovementsOnDifferentScenes);
    
    % permute eyemovements and XT response indices 
    for sceneIndex = 1:numel(allSceneNames)
        
        if (ismember(sceneIndex, indicesOfScenesToExclude))
            continue;
        end
        
        fprintf('Permuting eye movements and XT responses for scene %d\n', sceneIndex);
        fixationsNum = size(XTresponses{sceneIndex},2) / eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        if (normalizeResponsesForEachScene)
            if (sceneIndex == 1)
                maxXTresponseForScene1 = max(abs(XTresponses{sceneIndex}));
            else
                XTresponses{sceneIndex} = XTresponses{sceneIndex} / max(abs(XTresponses{sceneIndex})) * maxXTresponseForScene1;
            end
        end
        
        tmp1 = XTresponses{sceneIndex}*0;
        tmp2 = eyeMovements{sceneIndex}*0;

        kk = 1:eyeMovementParamsStruct.samplesPerFixation;
        
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = eyeMovements{sceneIndex}(sourceIndices,:);
        end
        
        XTresponses{sceneIndex} = tmp1;
        eyeMovements{sceneIndex} = tmp2;
        
        eyeMovementsNum = size(eyeMovements{sceneIndex},1);
        
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end  
        
        % to photon rate
        XTresponses{sceneIndex} = XTresponses{sceneIndex}/sensorConversionGain/sensorExposureTime;
        
    end
        
    eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation)
    totalFixationsNum = (numel(allSceneNames)-numel(indicesOfScenesToExclude))*fullSceneRotations*fixationsPerSceneRotation
    
    fullSceneRotations = input('Enter desired scene rotations: ');
    
    % Setup video stream
    writerObj = VideoWriter(sprintf('MosaicReconstruction_%s_%s.m4v',adaptationModelToUse, noiseFlag), 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    % Open video stream
    open(writerObj); 
    
    
    kSteps = 0;
    performance = [];
    fixationNo = 0;
    
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    
    % top row
    axesStruct.opticalImageAxes      = axes('parent',hFig,'unit','pixel','position',[-30 395 620 400], 'Color', [0 0 0]);
    axesStruct.current2DResponseAxes = axes('parent',hFig,'unit','pixel','position',[563 525 140 140], 'Color', [0 0 0]);
    axesStruct.xtResponseAxes        = axes('parent',hFig,'unit','pixel','position',[720 395 144 400], 'Color', [0 0 0]);
    axesStruct.dispMatrixAxes        = axes('parent',hFig,'unit','pixel','position',[870 395 400 400], 'Color', [0 0 0]);
     
    % mid row
    axesStruct.xyMDSAxes         = axes('parent',hFig,'unit','pixel','position',[30   130  256 226], 'Color', [0 0 0]);
    axesStruct.xzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[290+80  130  256 226], 'Color', [0 0 0]);
    axesStruct.yzMDSAxes         = axes('parent',hFig,'unit','pixel','position',[720  130  256 256], 'Color', [0 0 0]);
    axesStruct.mosaicAxes        = axes('parent',hFig,'unit','pixel','position',[1010 130  256 256], 'Color', [0 0 0]);
    
    % bottom row
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[25   10 600 110], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[670  10 600 110], 'Color', [0 0 0]);
    
    
    shortHistoryXTResponse = zeros(prod(sensorRowsCols), eyeMovementsPerSceneRotation);
    
    % Initialize
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    minSteps = 10;  % 1 minute + 2 seconds + 500 milliseconds
    
    midgetIR = temporalImpulseResponse('RGCbiphasic'); % temporalImpulseResponse('V1monophasic');
     
    try
        
    for rotationIndex = 1:fullSceneRotations
        
        timeBins = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);

        for sceneIndex = 1:numel(allSceneNames)
            
            if (ismember(sceneIndex, indicesOfScenesToExclude))
               continue; 
            end
            % get optical/sensor params for this scene
            opticalImage = opticalImageRGBrendering{sceneIndex};
            opticalImageXposInMicrons = (0:size(opticalImage,2)-1) * opticalSampleSeparation{sceneIndex}(1);
            opticalImageYposInMicrons = (0:size(opticalImage,1)-1) * opticalSampleSeparation{sceneIndex}(2);
            opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
            opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);
            selectXPosIndices = 1:1:size(opticalImage,2);
            selectYPosIndices = 1:1:size(opticalImage,1);
            opticalImage = opticalImage(selectYPosIndices, selectXPosIndices,:);
            opticalImageXposInMicrons = opticalImageXposInMicrons(selectXPosIndices);
            opticalImageYposInMicrons = opticalImageYposInMicrons(selectYPosIndices);
            
            % Get eye movements for this scene scan
            currentEyeMovements = eyeMovements{sceneIndex}(timeBins,:);
            currentEyeMovementsInMicrons(:,1) = currentEyeMovements(:,1) * sensorSampleSeparation(1);
            currentEyeMovementsInMicrons(:,2) = currentEyeMovements(:,2) * sensorSampleSeparation(2);

            sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparation(1);
            sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparation(2);
    

            % aggregate response
            aggegateXTResponseOffset = size(aggregateXTresponse,2);
            aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];

            
            
            plotResponses = false;
            
            if plotResponses
                LconeIndices = find(trueConeTypes==2);
                MconeIndices = find(trueConeTypes==3);
                SconeIndices = find(trueConeTypes==4);

                m1 = 0;
                for k = 1:numel(LconeIndices)
                   m2 = max(squeeze(aggregateXTresponse(LconeIndices(k),:)));
                   if (m2 > m1)
                       m1 = m2;
                       LconeIndex = LconeIndices(k);
                   end
                end
            
                m1 = 0;
                for k = 1:numel(MconeIndices)
                   m2 = max(squeeze(aggregateXTresponse(MconeIndices(k),:)));
                   if (m2 > m1)
                       m1 = m2;
                       MconeIndex = MconeIndices(k);
                   end
                end
            
                m1 = 0;
                for k = 1:numel(SconeIndices)
                   m2 = max(squeeze(aggregateXTresponse(SconeIndices(k),:)));
                   if (m2 > m1)
                       m1 = m2;
                       SconeIndex = SconeIndices(k);
                   end
                end
    
                LconeAbsorptions = aggregateXTresponse(LconeIndex,:);
                MconeAbsorptions = aggregateXTresponse(MconeIndex,:);
                SconeAbsorptions = aggregateXTresponse(SconeIndex,:);
            end
            
            
            
            if (strcmp(adaptationModelToUse, 'linear'))
                fprintf('Computing aggregate adapted XT response - linear adaptation (scene:%d/%d, rotation:%d/%d)\n', sceneIndex,numel(allSceneNames), rotationIndex,fullSceneRotations);
                initialState = riekeInit;
                initialState.timeInterval  = sensorTimeInterval;
                initialState.Compress = false;
                aggregateAdaptedXTresponse = ...
                    riekeLinearCone(aggregateXTresponse, initialState);
                
                if plotResponses
                    LadaptedConeAbsorptions = aggregateAdaptedXTresponse(LconeIndex,:);
                    MadaptedConeAbsorptions = aggregateAdaptedXTresponse(MconeIndex,:);
                    SadaptedConeAbsorptions = aggregateAdaptedXTresponse(SconeIndex,:);
                end
                
                if (strcmp(noiseFlag, 'RiekeNoise'))
                    disp('Adding noise to adapted responses');
                    params.seed = 349573409;
                    params.sampTime = sensorTimeInterval;
                    [aggregateAdaptedXTresponse2, ~] = riekeAddNoise(aggregateAdaptedXTresponse, params);
                end
                noise = (aggregateAdaptedXTresponse2-aggregateAdaptedXTresponse);
                aggregateAdaptedXTresponse  = aggregateAdaptedXTresponse + 1.0*noise;
                
                if plotResponses
                    LphotoCurrent = aggregateAdaptedXTresponse(LconeIndex,:);
                    MphotoCurrent = aggregateAdaptedXTresponse(MconeIndex,:);
                    SphotoCurrent = aggregateAdaptedXTresponse(SconeIndex,:);
                end
                
                disp('Applying midget temporal filtering');
                % apply ganglion midget temporal filtering
                signalLength = size(aggregateAdaptedXTresponse,2);
                for coneIndex = 1:size(aggregateAdaptedXTresponse,1)
                    tmp = conv(squeeze(aggregateAdaptedXTresponse(coneIndex,:)), midgetIR);
                    aggregateAdaptedXTresponse(coneIndex,:) = tmp(1:signalLength);
                end
                
                if plotResponses
                    LfilteredPhotoCurrent = aggregateAdaptedXTresponse(LconeIndex,:);
                    MfilteredPhotoCurrent = aggregateAdaptedXTresponse(MconeIndex,:);
                    SfilteredPhotoCurrent = aggregateAdaptedXTresponse(SconeIndex,:);
                end
                
                if plotResponses
                    
                    subplotPosVector = NicePlot.getSubPlotPosVectors(...
                        'rowsNum',      2, ...
                        'colsNum',      2, ...
                        'widthMargin',  0.07, ...
                        'leftMargin',   0.06, ...
                        'bottomMargin', 0.06, ...
                        'heightMargin', 0.11, ...
                        'topMargin',    0.04);
    
                    hh  = figure(2);
                    clf;
                    set(hh, 'Position', [10 10 1200 720]);
                    subplot('Position', subplotPosVector(1,1).v);
                    timeInMsec = numel(midgetIR):numel(LconeAbsorptions)-numel(midgetIR);
                    plot(timeInMsec-numel(midgetIR), LconeAbsorptions(timeInMsec), 'r.-');
                    hold on;
                    plot(timeInMsec-numel(midgetIR), MconeAbsorptions(timeInMsec), 'g.-');
                    plot(timeInMsec-numel(midgetIR), SconeAbsorptions(timeInMsec), 'b.-');
                    xlabel('time (ms)')
                    set(gca, 'FontSize', 14);
                    title('1. cone absorptions', 'FontSize', 16);

                    subplot('Position', subplotPosVector(1,2).v);
                    plot(timeInMsec-numel(midgetIR), LadaptedConeAbsorptions(timeInMsec), 'r.-');
                    hold on;
                    plot(timeInMsec-numel(midgetIR), MadaptedConeAbsorptions(timeInMsec), 'g.-');
                    plot(timeInMsec-numel(midgetIR), SadaptedConeAbsorptions(timeInMsec), 'b.-');
                    xlabel('time (ms)')
                    set(gca, 'FontSize', 14);
                    title('2. adapted cone Vm', 'FontSize', 16);
                
                    subplot('Position', subplotPosVector(2,1).v);
                    plot(timeInMsec-numel(midgetIR), LphotoCurrent(timeInMsec), 'r.-');
                    hold on;
                    plot(timeInMsec-numel(midgetIR), MphotoCurrent(timeInMsec), 'g.-');
                    plot(timeInMsec-numel(midgetIR), SphotoCurrent(timeInMsec), 'b.-');
                    xlabel('time (ms)')
                    set(gca, 'FontSize', 14);
                    title('3. photo-current', 'FontSize', 16);


                    subplot('Position', subplotPosVector(2,2).v);
                    plot(timeInMsec-numel(midgetIR), LfilteredPhotoCurrent(timeInMsec), 'r.-');
                    hold on;
                    plot(timeInMsec-numel(midgetIR), MfilteredPhotoCurrent(timeInMsec), 'g.-');
                    plot(timeInMsec-numel(midgetIR), SfilteredPhotoCurrent(timeInMsec), 'b.-');
                    offset = mean(LfilteredPhotoCurrent);
                    delta = (max(LfilteredPhotoCurrent)-min(LfilteredPhotoCurrent))/2;
                    plot((1:length(midgetIR))+1200, midgetIR/max(abs(midgetIR))*delta/2, 'k.-', 'LineWidth', 2);

                    set(gca, 'FontSize', 14);
                    xlabel('time (ms)')
                    title('4. filtered photo-current', 'FontSize', 16);

                    drawnow;
                    NicePlot.exportFigToPNG('ConeSignals.png',hh,300);
                    pause
                    figure(1);
                end
                
                % normalize
                aggregateAdaptedXTresponse = aggregateAdaptedXTresponse / (0.5*max(abs(aggregateAdaptedXTresponse(:))));
            end
            
            for timeBinIndex = 1:eyeMovementsPerSceneRotation 
   
                relevantTimeBins = aggegateXTResponseOffset + timeBinIndex; % timeBins(timeBinIndex);
               
                if (strcmp(adaptationModelToUse, 'none'))
                    %currentResponse = XTresponses{sceneIndex}(:,timeBins(timeBinIndex));
                    if (max(relevantTimeBins) > size(aggregateXTresponse,2))
                        relevantTimeBins = size(aggregateXTresponse,2);
                    end
                    currentResponse = aggregateXTresponse(:, relevantTimeBins);
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    if (max(relevantTimeBins) > size(aggregateAdaptedXTresponse,2))
                        fprintf(2, 'requested up to bin %d, but only got up to %d (full length)\n', max(relevantTimeBins), size(aggregateAdaptedXTresponse,2));
                        error('stop here');
                        relevantTimeBins = size(aggregateAdaptedXTresponse,2);
                    end
                    currentResponse = aggregateAdaptedXTresponse(:, relevantTimeBins);
                end
                
                shortHistoryXTResponse = circshift(shortHistoryXTResponse, -1, 2);
                shortHistoryXTResponse(:,end) = currentResponse;
                current2DResponse = reshape(currentResponse', [sensorRowsCols(1) sensorRowsCols(2)]);
                
                kSteps = kSteps + 1;
                
                
                % check if we need to accelerate
                if (fixationNo >= fixationsThreshold4)
                    % add a frame at the end of every third fixation
                    if (mod(timeBinIndex,(4*eyeMovementParamsStruct.samplesPerFixation)) ~= 0)
                        continue;
                    end
                    
                elseif (fixationNo >= fixationsThreshold3)
                    % add a frame at the end of every third fixation
                    if (mod(timeBinIndex,(3*eyeMovementParamsStruct.samplesPerFixation)) ~= 0)
                        continue;
                    end
                    
                elseif (fixationNo >= fixationsThreshold2) 
                    % add a frame at the end of every other fixation
                    if (mod(timeBinIndex,(2*eyeMovementParamsStruct.samplesPerFixation)) ~= 0)
                        continue;
                    end
                   
                elseif (fixationNo >= fixationsThreshold1)
                    % add a frame at the end of all micro-movements associated with each fixation
                    if (mod(timeBinIndex,(1*eyeMovementParamsStruct.samplesPerFixation)) ~= 0)
                        continue;
                    end
                end
                    
                
                
                binRange = 1:size(aggregateXTresponse,2)-eyeMovementsPerSceneRotation+timeBinIndex;
                
                if (strcmp(adaptationModelToUse, 'none'))
                    correlationMatrix = corrcoef((aggregateXTresponse(:,binRange))');
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    correlationMatrix = corrcoef((aggregateAdaptedXTresponse(:,binRange))');
                end
                %D = -log((correlationMatrix+1.0)/2.0);
                D = 1-(correlationMatrix+1.0)/2.0;
                if ~issymmetric(D)
                    D = 0.5*(D+D');
                end
                
                
                if (kSteps < minSteps)
                    fprintf('Skipping MDS for step %d (%d)\n', kSteps, minSteps);
                    continue;
                end
                
                
                dimensionsNum = 3;
                try
                    [MDSprojection,stress] = mdscale(D,dimensionsNum);
                catch err
                    fprintf(2,'Problem with mdscale. Skipping this time bin (%d).\n', aggegateXTResponseOffset + timeBins(timeBinIndex));
                    continue;
                end
                
                swapMDSdimsYZ = true;
                if (swapMDSdimsYZ)
                    % swap MDS dimension Y with MDS dimension Z
                    MDSdimensionForXspatialDim = 3;
                    MDSdimensionForYspatialDim = 2;
                    tmp_MDSprojection = MDSprojection;
                    tmp_MDSprojection(:,2) = MDSprojection(:,MDSdimensionForXspatialDim);
                    tmp_MDSprojection(:,3) = MDSprojection(:,MDSdimensionForYspatialDim);
                    MDSprojection = tmp_MDSprojection;
                end

                [rotatedMDSprojection, LconeIndices, MconeIndices, SconeIndices, LMconeIndices,...
                    cLM, cS, pivot, cLMPrime, cSPrime, pivotPrime] = ...
                    mdsProcessor.estimateConeMosaicFromMDSprojection(MDSprojection);
    
                % For comparison to true spatial mosaic determine optimal scaling and
                % rotation (around the spectral (X) axis) of the MDS embedding
                coneIndices = LMconeIndices;
                %coneIndices = (1:size(trueConeXYLocations,1));
                [d,Z,transform] = procrustes(trueConeXYLocations(coneIndices,:), rotatedMDSprojection(coneIndices,2:3));

                % Form the rotation matrix around X-axis
                rotationMatrixAroundXaxis = ...
                    [1 0                0; ...
                     0 transform.T(1,1) transform.T(1,2); ...
                     0 transform.T(2,1) transform.T(2,2) ...
                     ];

                MDSspatialScalingFactor = transform.b;

                % apply rotation and scaling
                rotatedMDSprojection = rotatedMDSprojection * rotationMatrixAroundXaxis;
                rotatedMDSprojection = rotatedMDSprojection * MDSspatialScalingFactor;

                cSPrime = cSPrime * MDSspatialScalingFactor;
                cLMPrime = cLMPrime * MDSspatialScalingFactor;
                pivotPrime = pivotPrime * MDSspatialScalingFactor; 
    
               
                % Plot the result of stage-2: Rotation and Separation of L from M
                coneIndices = {LconeIndices, MconeIndices, SconeIndices};
                coneColors = [1 0 0; 0 1 0; 0 0.5 1.0];
                coneColors2 = [1 0.5 0.5; 0.5 1 0.5; 0.3 0.7 1.0];
                spatialExtent = max(trueConeXYLocations(:)) * 1.2;
                
                % Update cone mosaic estimation performance
                performance = mdsProcessor.ComputePerformance(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, performance, kSteps-(minSteps-1), eyeMovementParamsStruct.samplesPerFixation);
                
                fixationNo = (binRange(end))/eyeMovementParamsStruct.samplesPerFixation;
                fixationTimeInMilliseconds = binRange(end)-1;
                
                RenderFrame(axesStruct, fixationNo, fixationTimeInMilliseconds, ...
                    opticalImage, opticalImageXposInMicrons, opticalImageYposInMicrons, ...
                    timeBinIndex, currentEyeMovementsInMicrons, sensorOutlineInMicrons, ...
                    shortHistoryXTResponse, current2DResponse, performance, D, ...
                    rotatedMDSprojection, coneIndices, coneColors, coneColors2, cLMPrime, cSPrime, pivotPrime, spatialExtent, trueConeTypes, trueConeXYLocations);
                
                if (~isempty(writerObj))
                    frame = getframe(gcf);
                    writeVideo(writerObj, frame);
                end
        
            end % timeBin
        end % sceneIndex
        
        eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
    end% rotationIndex
    
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



function RenderPartsFrame(axesStruct, fixationNo, ...
                    opticalImage, opticalImageXposInMicrons, opticalImageYposInMicrons, ...
                    eyeMovementIndex, eyeMovementsInMicrons, sensorOutlineInMicrons, ...
                    current2DResponse, current2DAdaptedResponse)
                
    opticalImageAxes = axesStruct.opticalImageAxes; 
    current2DResponseAxes = axesStruct.current2DResponseAxes;
    current2DAdaptedResponseAxes = axesStruct.current2DAdaptedResponseAxes;
    
     % Render the current scene and eye movement
    imagesc(opticalImageXposInMicrons, opticalImageYposInMicrons, opticalImage, 'parent', opticalImageAxes);
    hold(opticalImageAxes, 'on');
    plot(opticalImageAxes,-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'w.-', 'LineWidth', 2.0);
    plot(opticalImageAxes,-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'k.');
    plot(opticalImageAxes,-eyeMovementsInMicrons(eyeMovementIndex,1) + sensorOutlineInMicrons(:,1), eyeMovementsInMicrons(eyeMovementIndex,2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 3.0);
    hold(opticalImageAxes, 'off');
    axis(opticalImageAxes,'image');
    axis(opticalImageAxes,'off');
    box(opticalImageAxes,'off');
    set(opticalImageAxes, 'CLim', [0 1], 'XColor', [1 1 1], 'YColor', [1 1 1]); 
    set(opticalImageAxes, 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)]*(0.81), 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]*(0.81), 'XTick', [], 'YTick', []);
    if (fixationNo < 1000)
        title(opticalImageAxes,  sprintf('fixation #%03.2f', fixationNo), 'FontSize', 20, 'Color', [1 .8 .4]);
    else
        title(opticalImageAxes,  sprintf('fixation #%03.0f', fixationNo), 'FontSize', 20, 'Color', [1 .8 .4]);
    end
    
    % mosaic activation 
    hCurrRespPlot = pcolor(current2DResponseAxes, current2DResponse);
    set(hCurrRespPlot, 'EdgeColor', 'none');
    
    axis(current2DResponseAxes, 'square');
    axis(current2DResponseAxes, 'ij');
    axis(current2DResponseAxes, 'on');
    box(current2DResponseAxes, 'on');
    set(current2DResponseAxes, 'CLim', [0 1]);
    set(current2DResponseAxes, 'XLim', [1 size(current2DResponse,2)], 'YLim', [1 size(current2DResponse,1)]);
    set(current2DResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {});
    title(current2DResponseAxes, 'mosaic activation', 'FontSize', 20, 'Color', [1 .8 .4]);
    
    % Adapted respose
    hCurrRespPlot2 = pcolor(current2DAdaptedResponseAxes, current2DAdaptedResponse);
    set(hCurrRespPlot2, 'EdgeColor', 'none');
    
    axis(current2DAdaptedResponseAxes, 'square');
    axis(current2DAdaptedResponseAxes, 'ij');
    axis(current2DAdaptedResponseAxes, 'on');
    box(current2DAdaptedResponseAxes, 'on');
    set(current2DAdaptedResponseAxes, 'CLim', [0 1]);
    set(current2DAdaptedResponseAxes, 'XLim', [1 size(current2DResponse,2)], 'YLim', [1 size(current2DResponse,1)]);
    set(current2DAdaptedResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {});
    title(current2DAdaptedResponseAxes,  sprintf('adapted response'), 'FontSize', 20, 'Color', [1 .8 .4]);

    
    colormap(hot);
end


                
function RenderFrame(axesStruct, fixationNo, fixationTimeInMilliseconds, opticalImage, opticalImageXposInMicrons, opticalImageYposInMicrons, eyeMovementIndex, eyeMovementsInMicrons, sensorOutlineInMicrons, shortHistoryXTresponse, current2DResponse, performance, D, MDSprojection, coneIndices, coneColors, coneColors2, cLM, cS, pivot, spatialExtent, trueConeTypes, trueConeXYLocations)

    opticalImageAxes = axesStruct.opticalImageAxes; 
    xtResponseAxes = axesStruct.xtResponseAxes;
    current2DResponseAxes = axesStruct.current2DResponseAxes;
    dispMatrixAxes   = axesStruct.dispMatrixAxes;
    performanceAxes1  = axesStruct.performanceAxes1;
    performanceAxes2  = axesStruct.performanceAxes2;
    xyMDSAxes = axesStruct.xyMDSAxes;
    xzMDSAxes = axesStruct.xzMDSAxes;
    yzMDSAxes = axesStruct.yzMDSAxes;
    mosaicAxes = axesStruct.mosaicAxes;
    
    % Render the current scene and eye movement
    imagesc(opticalImageXposInMicrons, opticalImageYposInMicrons, opticalImage, 'parent', opticalImageAxes);
    hold(opticalImageAxes, 'on');
    plot(opticalImageAxes,-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'w.-');
    plot(opticalImageAxes,-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'k.');
    plot(opticalImageAxes,-eyeMovementsInMicrons(eyeMovementIndex,1) + sensorOutlineInMicrons(:,1), eyeMovementsInMicrons(eyeMovementIndex,2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 2.0);
    hold(opticalImageAxes, 'off');
    axis(opticalImageAxes,'image');
    axis(opticalImageAxes,'off');
    box(opticalImageAxes,'off');
    set(opticalImageAxes, 'CLim', [0 1], 'XColor', [1 1 1], 'YColor', [1 1 1]); 
    set(opticalImageAxes, 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)]*(0.81), 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]*(0.81), 'XTick', [], 'YTick', []);
   
    
    
    LconeIndices = coneIndices{1};
    MconeIndices = coneIndices{2};
    SconeIndices = coneIndices{3};
    
    % Determine specral range
    xx = squeeze(MDSprojection(:,1));
    minX = min(xx);
    maxX = max(xx);
    margin = 100 - (maxX - minX);
    if (margin < 0)
        margin = 0;
    end
    XLims = [minX-margin/2 maxX+margin/2];
    YLims = spatialExtent*[-1 1];
    ZLims = spatialExtent*[-1 1];
                
    coneMarkerSize = 9;
    
    for viewIndex = 1:3
        switch viewIndex
            case 1
                drawingAxes = xyMDSAxes;
                viewingAngles = [0 90];
                
            case 2
                drawingAxes = xzMDSAxes;
                viewingAngles = [0 0];
                
            case 3
                drawingAxes = yzMDSAxes;
                viewingAngles = [90 0];
        end
        
        for coneType = 1:numel(coneIndices)
            scatter3(drawingAxes, ...
                MDSprojection(coneIndices{coneType},1), ...
                MDSprojection(coneIndices{coneType},2), ...
                MDSprojection(coneIndices{coneType},3), ...
                70, 'filled',  ...
                'MarkerFaceColor',coneColors2(coneType,:), ...
                'MarkerEdgeColor',coneColors(coneType,:), ...
                'LineWidth', 1 ...
                );  
            if (coneType == 1)
                hold(drawingAxes, 'on');
            end
        end
        scatter3(drawingAxes, cLM(1), cLM(2), cLM(3), 'ms', 'filled');
        scatter3(drawingAxes, cS(1), cS(2), cS(3), 'cs', 'filled');
        scatter3(drawingAxes, pivot(1), pivot(2), pivot(3), 'ws', 'filled');
        plot3(drawingAxes, [cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'w-');
        if (viewIndex == 3)
            plot3(drawingAxes, [0 0], spatialExtent*[-1 1], [0 0], 'w-', 'LineWidth', 1);
            plot3(drawingAxes, [0 0], [0 0], spatialExtent*[-1 1], 'w-', 'LineWidth', 1);
        end
        hold(drawingAxes, 'off');
        grid(drawingAxes, 'on'); 
        box(drawingAxes, 'off'); 
        axis(drawingAxes, 'off')
        view(drawingAxes, viewingAngles);
        set(drawingAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
        set(drawingAxes, 'XTickLabel', {}, 'YTickLabel', {});
        if (~isempty(XLims))
            set(drawingAxes, 'XLim', XLims);
        end
        set(drawingAxes, 'YLim', YLims);
        set(drawingAxes, 'ZLim', ZLims);
        
        switch viewIndex
            case 1
                
            case 2
                
            case 3
                axis(drawingAxes, 'square');
                xlabel(drawingAxes, 'reconstructed mosaic', 'Color', [1 1 1], 'FontSize', 14);
        end
    end % viewIndex
    
    
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2) && (ismember(k, LconeIndices))
            plot(mosaicAxes,[trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'Color', coneColors(trueConeTypes(k)-1,:), 'LineWidth', 2);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColors2(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColors(trueConeTypes(k)-1,:), 'LineWidth', 1); 
            
        elseif (trueConeTypes(k) == 3) && (ismember(k, MconeIndices))
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'Color', coneColors(trueConeTypes(k)-1,:), 'LineWidth', 2);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColors2(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColors(trueConeTypes(k)-1,:), 'LineWidth', 1);
            
        elseif (trueConeTypes(k) == 4) && (ismember(k, SconeIndices))
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', coneColors(trueConeTypes(k)-1,:));
            hold(mosaicAxes,'on')
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColors2(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColors(trueConeTypes(k)-1,:), 'LineWidth', 1);

        else
            % incorrectly indentified cone
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', [0.8 0.8 0.8]);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerEdgeColor', [0.7 0.7 0.7], 'MarkerFaceColor', [0.8 0.8 0.8], 'LineWidth', 1);
        end  
    end
    plot(mosaicAxes, [0 0], spatialExtent*[-1 1], 'w-', 'LineWidth', 1);
    plot(mosaicAxes, spatialExtent*[-1 1], [0 0], 'w-', 'LineWidth', 1);
    hold(mosaicAxes,'off')
    set(mosaicAxes, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(mosaicAxes, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(mosaicAxes, 'XTickLabel', {}, 'YTickLabel', {});
    set(mosaicAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
    grid(mosaicAxes, 'on'); 
    box(mosaicAxes, 'off'); 
    axis(mosaicAxes, 'square')
    axis(mosaicAxes, 'off')
    xlabel(mosaicAxes, 'actual mosaic', 'Color', [1 1 1], 'FontSize', 14);
    
    % Short history XT response
    hXTrespPlot = pcolor(xtResponseAxes,shortHistoryXTresponse);
    set(hXTrespPlot, 'EdgeColor', 'none');
    colormap(hot);
    box(xtResponseAxes, 'on'); 
    axis(xtResponseAxes, 'ij')
    set(xtResponseAxes, 'CLim', [0 1]);
    set(xtResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTickLabel', {}, 'YTickLabel', {});
    
    % Current 2d respose
    hCurrRespPlot = pcolor(current2DResponseAxes, current2DResponse);
    set(hCurrRespPlot, 'EdgeColor', 'none');
    axis(current2DResponseAxes, 'square');
    axis(current2DResponseAxes, 'ij');
    axis(current2DResponseAxes, 'on');
    box(current2DResponseAxes, 'on');
    set(current2DResponseAxes, 'CLim', [0 1]);
    set(current2DResponseAxes, 'XLim', [1 size(current2DResponse,2)], 'YLim', [1 size(current2DResponse,1)]);
    set(current2DResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {});
    currentTimeHours = floor(fixationTimeInMilliseconds/(1000*60*60));
    currentTimeMinutes = floor((fixationTimeInMilliseconds - currentTimeHours*(1000*60*60)) / (1000*60));
    currentTimeSeconds = floor((fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60))/1000);
    currentTimeMilliSeconds = fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60) - currentTimeSeconds*1000;
    if (fixationNo < 1000)
        title(current2DResponseAxes,  sprintf('fixation #%03.3f\n(%02.0f : %02.0f : %02.0f : %03.0f)', fixationNo, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    else
        title(current2DResponseAxes,  sprintf('fixation #%03.0f\n(%02.0f : %02.0f : %02.0f : %03.0f)', fixationNo, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    end
    %xlabel(current2DResponseAxes, sprintf('mosaic activation'), 'Color', [1 1 1], 'FontSize', 16);
    
    % Disparity matrix
    visD = D.*tril(ones(size(D)));
    hdensityPlot = pcolor(dispMatrixAxes, visD);
    set(hdensityPlot, 'EdgeColor', 'none');
    colormap(hot);
    box(dispMatrixAxes, 'off'); 
    axis(dispMatrixAxes, 'square');
    axis(dispMatrixAxes, 'ij')
    set(dispMatrixAxes, 'CLim', [0 max(D(:))]);
    set(dispMatrixAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [],'XTickLabel', {}, 'YTickLabel', {});
    
    colormap(hot);
    
    
    % Performance as a function of time
    plot(performanceAxes1, performance.fixationsNum, 1-performance.correctlyIdentifiedLMcones, 'y-', 'LineWidth', 2.0);
    hold(performanceAxes1,'on')
    plot(performanceAxes1, performance.fixationsNum, 1-performance.correctlyIdentifiedScones, '-', 'Color', [0 0.6 1.0], 'LineWidth', 2.0);
    hold(performanceAxes1,'off')
    set(performanceAxes1, 'Color', [0 0 0], 'XColor', [0 0 0], 'YColor', [1 1 1], 'XLim', [0 max([10 max(performance.fixationsNum)])], 'YLim', [0 1.0], 'XTickLabel', {}, 'YTickLabel', {});
    ylabel(performanceAxes1, 'type error', 'FontSize', 16);
    hLeg = legend(performanceAxes1, 'L/M', 'S');
    set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'northeast');
    box(performanceAxes1, 'off'); 
    grid(performanceAxes1, 'on');
    
    
    
    plot(performanceAxes2, performance.fixationsNum, performance.meanDistanceLMmosaic, 'y-', 'LineWidth', 2.0);
    hold(performanceAxes2,'on')
    plot(performanceAxes2, performance.fixationsNum, performance.meanDistanceSmosaic, '-', 'Color', [0 0.6 1.0], 'LineWidth', 2.0);
    hold(performanceAxes2,'off')
    set(performanceAxes2, 'Color', [0 0 0], 'XColor', [0 0 0], 'YColor', [1 1 1], 'XLim', [0 max([10 max(performance.fixationsNum)])], 'YLim', [0 25], 'XTickLabel', {}, 'YTickLabel', {});
    ylabel(performanceAxes2, 'positional error', 'FontSize', 16);
    hLeg = legend(performanceAxes2, 'L/M', 'S');
    set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'northeast');
    box(performanceAxes2, 'off'); 
    grid(performanceAxes2, 'on');
    
    drawnow
end


function GenerateResultsFigure(resultsFile, adaptationModelToUse, noiseFlag, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    disp('Loading the raw data');
    %whos('-file', resultsFile)
    
    % load all but the opticalImageRGBrendering
    load(resultsFile, 'XTresponses',  'allSceneNames', 'eyeMovementParamsStruct', 'eyeMovements', ...               
         'opticalSampleSeparation', 'randomSeedForSensor', ...
          'sensorConversionGain', 'sensorExposureTime', 'sensorParamsStruct', ...
          'sensorRowsCols', 'sensorSampleSeparation', 'sensorTimeInterval', ...
          'trueConeTypes', 'trueConeXYLocations');
    
    % Set the rng for repeatable eye movements
    rng(randomSeedForEyeMovementsOnDifferentScenes);
    
    disp('Computing aggregate XT response - voltage');
    aggregateXTresponse = [];
    
    % use this for running on computers with low memory
    fixationsPerSceneToUse = inf;  % use all
    %fixationsPerSceneToUse = 24;  % use some
    
    kk = 1:eyeMovementParamsStruct.samplesPerFixation;
    
    midgetIR = midgetImpulseResponse();
    
    for sceneIndex = 1:numel(allSceneNames)
        
        if (ismember(sceneIndex, indicesOfScenesToExclude))
            continue;
        end
        
        fprintf('Permuting eye movements and XT responses for scene %d\n', sceneIndex);
        fixationsNum = size(XTresponses{sceneIndex},2) / eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        if (fixationsPerSceneToUse > fixationsNum)
            fixationsPerSceneToUse = fixationsNum;
        end
        
        if (~isinf(fixationsPerSceneToUse))
            fixationsNum = fixationsPerSceneToUse;
        end
        
        if (normalizeResponsesForEachScene)
            if (sceneIndex == 1)
                maxXTresponseForScene1 = max(abs(XTresponses{sceneIndex}));
            else
                XTresponses{sceneIndex} = XTresponses{sceneIndex} / max(abs(XTresponses{sceneIndex})) * maxXTresponseForScene1;
            end
        end
        
        
        tmp = XTresponses{sceneIndex}*0;
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
        end
        
        
        % empty to save space
        XTresponses{sceneIndex} = [];
        aggregateXTresponse = [aggregateXTresponse tmp]; 
    end
    
    if (strcmp(adaptationModelToUse, 'none'))
        disp('Will employ no cone adaptation model');
    elseif (strcmp(adaptationModelToUse, 'linear'))
        disp('Will employ the linear Rieke cone adaptation model');
        disp('Computing aggregate adapted XT response - linear adaptation');
        % covert to photonRate
        aggregateXTresponse = aggregateXTresponse / sensorConversionGain/sensorExposureTime;
        initialState = riekeInit;
        initialState.timeInterval  = sensorTimeInterval;
        initialState.Compress = false;
        % adapted response (linear filter)
        aggregateXTresponse = riekeLinearCone(aggregateXTresponse, initialState);
        if (strcmp(noiseFlag, 'RiekeNoise'))
            disp('Adding noise to adapted responses');
            params.seed = 349573409;
            params.sampTime = sensorTimeInterval;
            [aggregateXTresponse, ~] = riekeAddNoise(aggregateXTresponse, params);
        end
    end
    
    disp('Applying midget temporal filtering');
    % apply ganglion midget temporal filtering
    signalLength = size(aggregateXTresponse,2);
    for coneIndex = 1:size(aggregateXTresponse,1)
        tmp = conv(squeeze(aggregateXTresponse(coneIndex,:)), midgetIR);
        aggregateXTresponse(coneIndex,:) = tmp(1:signalLength);
    end
                
    disp('Computing correlation matrix');
    correlationMatrix = corrcoef(aggregateXTresponse');
    % Linear dissimilarity metric
    D = 1-(correlationMatrix+1.0)/2.0;
    if ~issymmetric(D)
        D = 0.5*(D+D');
    end
    
    disp('Computing MDS');
    dimensionsNum = 3;
    [MDSprojection,stress] = mdscale(D,dimensionsNum);
    
    disp('Saving MDS data');
    save(sprintf('MDS_%s', resultsFile), 'MDSprojection', 'stress', 'trueConeXYLocations', 'trueConeTypes');
    
    
    swapMDSdimsYZ = true;
    if (swapMDSdimsYZ)
        % swap MDS dimension Y with MDS dimension Z
        MDSdimensionForXspatialDim = 3;
        MDSdimensionForYspatialDim = 2;
        tmp_MDSprojection = MDSprojection;
        tmp_MDSprojection(:,2) = MDSprojection(:,MDSdimensionForXspatialDim);
        tmp_MDSprojection(:,3) = MDSprojection(:,MDSdimensionForYspatialDim);
        MDSprojection = tmp_MDSprojection;
    end
    
    [rotatedMDSprojection, LconeIndices, MconeIndices, SconeIndices, LMconeIndices,...
        cLM, cS, pivot, cLMPrime, cSPrime, pivotPrime] = ...
        mdsProcessor.estimateConeMosaicFromMDSprojection(MDSprojection);
    
    
    % For comparison to true spatial mosaic determine optimal scaling and
    % rotation (around the spectral (X) axis) of the MDS embedding so that 
    % the spatial enbedding best matches the original mosaic
    %coneIndices = LMconeIndices;
    coneIndices = (1:size(trueConeXYLocations,1));
    [d,Z,transform] = procrustes(trueConeXYLocations(coneIndices,:), rotatedMDSprojection(coneIndices,2:3));
    
    % Form the rotation matrix around X-axis
    rotationMatrixAroundXaxis = ...
        [1 0                0; ...
         0 transform.T(1,1) transform.T(1,2); ...
         0 transform.T(2,1) transform.T(2,2) ...
         ];

    MDSspatialScalingFactor = transform.b;
    
    % apply rotation and scaling
    rotatedMDSprojection = rotatedMDSprojection * rotationMatrixAroundXaxis;
    rotatedMDSprojection = rotatedMDSprojection * MDSspatialScalingFactor;

    cSPrime = cSPrime * MDSspatialScalingFactor;
    cLMPrime = cLMPrime * MDSspatialScalingFactor;
    pivotPrime = pivotPrime * MDSspatialScalingFactor;    
    
    
    subplotPosVector = NicePlot.getSubPlotPosVectors(...
        'rowsNum',      2, ...
        'colsNum',      2, ...
        'widthMargin',  0.07, ...
        'leftMargin',   0.03, ...
        'bottomMargin', 0.06, ...
        'heightMargin', 0.09, ...
        'topMargin',    0.03);
    
    MDSdims = {'MDS-x', 'MDS-y', 'MDS-z'};
    
    % Plot the result of stage-1: Separation of S and L/M
    coneIndices = {LMconeIndices(1:10), LMconeIndices(11:end), SconeIndices};
    coneColors = [0 0 0; 0 0 0; 0 0 1];
    coneColors2 = [0.5 0.5 0.5; 0.5 0.5 0.5; 0.3 0.7 1.0];
    
    spatialExtent = {[], [], []};
    h = figure(1); clf;
    set(h, 'Position', [100 10 760 700], 'Name', 'Step1: Identify S-cone positions', 'Color', [1 1 1]);
        subplot('Position', subplotPosVector(1,1).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, coneColors2, cLM, cS, pivot, spatialExtent, MDSdims, [0 90]);

        subplot('Position', subplotPosVector(1,2).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, coneColors2, cLM, cS, pivot, spatialExtent, MDSdims, [0 0]);

        subplot('Position', subplotPosVector(2,1).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, coneColors2, cLM, cS, pivot, spatialExtent, MDSdims, [90 0]);
    drawnow;
    NicePlot.exportFigToPDF('Raw.pdf',h,300);
    
    % Plot the result of stage-2: Rotation and Separation of L from M
    coneIndices = {LconeIndices, MconeIndices, SconeIndices};
    coneColors = [1 0 0; 0 1 0; 0 0.5 1.0];
    coneColors2 = [1 0.5 0.5; 0.5 1 0.5; 0.3 0.7 1.0];
    spatialExtent = max(trueConeXYLocations(:)) * 1.2;
    h = figure(2); clf;
    set(h, 'Position', [200 10 760 700], 'Name', 'Step2: Rotated', 'Color', [1 1 1]);
        subplot('Position', subplotPosVector(1,1).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, coneColors2, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 90]);
    
        subplot('Position', subplotPosVector(1,2).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, coneColors2, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 0]);
    
        subplot('Position', subplotPosVector(2,1).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, coneColors2, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [90 0]);
    
        % Finally, plot correspondence between true and recovered cone mosaic
        subplot('Position', subplotPosVector(2,2).v);
        mdsProcessor.DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, coneColors, coneColors2, spatialExtent);
    drawnow;
    NicePlot.exportFigToPDF('Rotated.pdf',h,300);

end




function IR = temporalImpulseResponse(type)
    t = (0:1:300)/1000;
    n  = 4;
    p1 = 1;
    if strcmp(type, 'RGCbiphasic')
        p2 = 0.15;
        tau1 = 30/1000;
    elseif strcmp(type, 'V1monophasic')
        p2 = 0.0;
        tau1 = 50/1000;
    else
        error('Unkown impulse response type %s', type);
    end
    tau2 = 80/1000;
    
    t1 = t/tau1;
    t2 = t/tau2;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1))  - p2 * (t2.^n) .* exp(-n*(t2-1));
    IR = IR / sum(abs(IR));
    if (1==2)
    figure(1);
    plot(t, IR, 'k.-');
    drawnow
    end
end