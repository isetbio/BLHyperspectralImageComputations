function ReconstructMosaicFromXTresponses2

    conesAcross = 10;
    resultsFile = sprintf('results_%dx%d.mat', conesAcross,conesAcross);
      
    normalizeResponsesForEachScene = true;
    adaptationModelToUse = 'linear';  % choose from 'none' or 'linear'
    
    randomSeedForEyeMovementsOnDifferentScenes = 234823568;
    indicesOfScenesToExclude = [25];
     
    generateVideo = true;
    if (generateVideo)
        GenerateVideoFile(resultsFile, adaptationModelToUse, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude);
    else
        GenerateResultsFigure(resultsFile, adaptationModelToUse, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude);
    end
end

function GenerateVideoFile(resultsFile, adaptationModelToUse, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    load(resultsFile, '-mat');
    
    fixationsPerSceneRotation = 12;
    fixationsThreshold1 = ceil(100/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    % when conesAcross = 20 use: fixationsThreshold1 = ceil(1000/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    fixationsThreshold2 = ceil(1000/fixationsPerSceneRotation)*fixationsPerSceneRotation;
    
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
        
        tmp1 = XTresponses{sceneIndex}*0;
        tmp2 = eyeMovements{sceneIndex}*0;

        kk = 1:eyeMovementParamsStruct.samplesPerFixation;
        
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = eyeMovements{sceneIndex}(sourceIndices,:);
        end
        
        if (normalizeResponsesForEachScene)
            % normalize XT responses for each scene
            tmp1 = tmp1 / max(abs(tmp1(:)));
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
    
    fullSceneRotations = input('Enter desired scene rotations: ');
    
    
    
    % Setup video stream
    writerObj = VideoWriter('NewMosaicReconstruction.m4v', 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    % Open video stream
    open(writerObj); 
        
    subplotPosVector = NicePlot.getSubPlotPosVectors(...
        'rowsNum',      2, ...
        'colsNum',      2, ...
        'widthMargin',  0.07, ...
        'leftMargin',   0.06, ...
        'bottomMargin', 0.06, ...
        'heightMargin', 0.09, ...
        'topMargin',    0.01);
    MDSdims = {'MDS-x', 'MDS-y', 'MDS-z'};
    
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
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[30   10 600 110], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[680  10 600 110], 'Color', [0 0 0]);
    
    
    shortHistoryXTResponse = zeros(prod(sensorRowsCols), eyeMovementsPerSceneRotation);
    
    % Initialize
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    minSteps = 50;  % 1 minute + 2 seconds + 500 milliseconds
    
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

            if (strcmp(adaptationModelToUse, 'linear'))
                disp('Computing aggregate adapted XT response - linear adaptation');
                photonRate = reshape(aggregateXTresponse, [sensorRowsCols(1) sensorRowsCols(2) size(aggregateXTresponse,2)]) / ...
                     sensorConversionGain/sensorExposureTime;
                initialState = riekeInit;
                initialState.timeInterval  = sensorTimeInterval;
                initialState.Compress = false;
                aggregateAdaptedXTresponse = reshape(riekeLinearCone(photonRate, initialState), ...
                             [size(photonRate,1)*size(photonRate,2) size(photonRate,3)]);
                % normalize
                aggregateAdaptedXTresponse = aggregateAdaptedXTresponse / max(abs(aggregateAdaptedXTresponse(:)));
            end
        
            for timeBinIndex = 1:eyeMovementsPerSceneRotation 

                if (strcmp(adaptationModelToUse, 'none'))
                    %currentResponse = XTresponses{sceneIndex}(:,timeBins(timeBinIndex));
                    currentResponse = aggregateXTresponse(:, aggegateXTResponseOffset + timeBins(timeBinIndex));
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    currentResponse = aggregateAdaptedXTresponse(:, aggegateXTResponseOffset + timeBins(timeBinIndex));
                end
                
                shortHistoryXTResponse = circshift(shortHistoryXTResponse, -1, 2);
                shortHistoryXTResponse(:,end) = currentResponse;
                current2DResponse = reshape(currentResponse, [sensorRowsCols(1) sensorRowsCols(2)]);
                
                kSteps = kSteps + 1;
                
                % check if we need to accelerate
                if (fixationNo >= fixationsThreshold2)
                    if (timeBinIndex < eyeMovementsPerSceneRotation)
                        continue;
                    end
                elseif (fixationNo >= fixationsThreshold1)
                    if (mod(timeBinIndex-1,eyeMovementParamsStruct.samplesPerFixation) < eyeMovementParamsStruct.samplesPerFixation-1)
                        continue;
                    end
                end
                    
                
                
                binRange = 1:size(aggregateXTresponse,2)-eyeMovementsPerSceneRotation+timeBinIndex;
                
                if (strcmp(adaptationModelToUse, 'none'))
                    correlationMatrix = corrcoef((aggregateXTresponse(:,binRange))');
                elseif (strcmp(adaptationModelToUse, 'linear'))
                    correlationMatrix = corrcoef((aggregateAdaptedXTresponse(:,binRange))');
                end
                D = -log((correlationMatrix+1.0)/2.0);
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
    
               
                % Plot the result of stage-2: Rotation and Separation of L from M
                coneIndices = {LconeIndices, MconeIndices, SconeIndices};
                coneColors = [1 0 0; 0 1 0; 0 0.5 1.0];
                coneColors2 = [1 0.5 0.5; 0.5 1 0.5; 0.3 0.7 1.0];
                spatialExtent = max(trueConeXYLocations(:)) * 1.2;
                
                % Update cone mosaic estimation performance
                performance = mdsProcessor.ComputePerformance(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, performance, kSteps-(minSteps-1), eyeMovementParamsStruct.samplesPerFixation);
                
                fixationNo = (binRange(end)-1)/eyeMovementParamsStruct.samplesPerFixation;
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
    
    % close video stream and save movie
    close(writerObj);
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
    colormap(hot);
     
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
        title(current2DResponseAxes,  sprintf('fixation #%03.2f\n(%02.0f : %02.0f : %02.0f : %03.0f)', fixationNo, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
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


function GenerateResultsFigure(resultsFile, adaptationModelToUse, normalizeResponsesForEachScene, randomSeedForEyeMovementsOnDifferentScenes, indicesOfScenesToExclude)
    disp('Loading the raw data');
    load(resultsFile);
    
    % Set the rng for repeatable eye movements
    rng(randomSeedForEyeMovementsOnDifferentScenes);
    
    disp('Computing aggregate XT response - voltage');
    aggregateXTresponse = [];
    
    for sceneIndex = 1:numel(allSceneNames)
        
        if (ismember(sceneIndex, indicesOfScenesToExclude))
            continue;
        end
        
        fprintf('Permuting eye movements and XT responses for scene %d\n', sceneIndex);
        fixationsNum = size(XTresponses{sceneIndex},2) / eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
        
        tmp = XTresponses{sceneIndex}*0;
        
        kk = 1:eyeMovementParamsStruct.samplesPerFixation;
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp(:,destIndices) = XTresponses{sceneIndex}(:, sourceIndices);
        end
        
        if (normalizeResponsesForEachScene)
            % normalize XT responses for each scene
            tmp = tmp / max(abs(tmp(:)));
        end
        
        XTresponses{sceneIndex} = tmp;
        aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}];
    end
    
    if (strcmp(adaptationModelToUse, 'none'))
        disp('Will employ no cone adaptation model');
    elseif (strcmp(adaptationModelToUse, 'linear'))
        disp('Will employ the linear Rieke cone adaptation model');
        disp('Computing aggregate adapted XT response - linear adaptation');
        photonRate = reshape(aggregateXTresponse, [sensorRowsCols(1) sensorRowsCols(2) size(aggregateXTresponse,2)]) / ...
                     sensorConversionGain/sensorExposureTime;
        initialState = riekeInit;
        initialState.timeInterval  = sensorTimeInterval;
        initialState.Compress = false;
        aggregateXTresponse = reshape(riekeLinearCone(photonRate, initialState), ...
                             [size(photonRate,1)*size(photonRate,2) size(photonRate,3)]);
    end
    
    disp('Computing correlation matrix');
    correlationMatrix = corrcoef(aggregateXTresponse');
    D = -log((correlationMatrix+1.0)/2.0);
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
        'leftMargin',   0.06, ...
        'bottomMargin', 0.06, ...
        'heightMargin', 0.09, ...
        'topMargin',    0.01);
    
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




