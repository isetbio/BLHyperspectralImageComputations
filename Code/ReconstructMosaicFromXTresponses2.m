function ReconstructMosaicFromXTresponses2

    generateVideo = true;
    
    conesAcross = 10;
    resultsFile = sprintf('results_%dx%d.mat', conesAcross,conesAcross);
    
    if (generateVideo)
        GenerateVideoFile(resultsFile);
    else
        GenerateResultsFigure(resultsFile);
    end
end

function GenerateVideoFile(resultsFile)
    load(resultsFile);
    
    % find minimal number of eye movements across all scenes
    minEyeMovements = 10*1000*1000;
    totalEyeMovementsNum = 0;
    for sceneIndex = 1:numel(allSceneNames)
        eyeMovementsNum = size(XTresponses{sceneIndex},2);
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end
    end

    fixationsPerSceneRotation = 20;
    eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation;
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation);
        
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    
    % Setup video stream
    writerObj = VideoWriter('NewMosaicReconstruction.m4v', 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
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
    for rotationIndex = 1:fullSceneRotations
        timeBins = eyeMovementIndex + [0:eyeMovementsPerSceneRotation-1];

        for sceneIndex = 1:numel(allSceneNames)
            aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];

            for timeBin = 1:eyeMovementsPerSceneRotation 

                disp('Updating correlation matrix');
                correlationMatrix = corrcoef((aggregateXTresponse(:,1:end-eyeMovementsPerSceneRotation+timeBin))');
                D = -log((correlationMatrix+1.0)/2.0);
                if ~issymmetric(D)
                    D = 0.5*(D+D');
                end
                
                kSteps = kSteps + 1;
                if (kSteps < 5)
                    disp('Skipping MDS');
                    continue;
                end
                
                disp('Computing MDS');
                dimensionsNum = 3;
                [MDSprojection,stress] = mdscale(D,dimensionsNum);
    
                disp('Post MDS processing');
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
                [d,Z,transform] = procrustes(trueConeXYLocations(LMconeIndices,:), rotatedMDSprojection(LMconeIndices,2:3));

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
    
                
                
                disp('Drawing');
                % Plot the result of stage-2: Rotation and Separation of L from M
                coneIndices = {LconeIndices, MconeIndices, SconeIndices};
                coneColors = [1 0 0; 0 1 0; 0 0 1];
                spatialExtent = max(trueConeXYLocations(:)) * 1.2;
                h = figure(2); clf;
                set(h, 'Position', [200 10 760 700], 'Name', 'Step2: Rotated');
                    subplot('Position', subplotPosVector(1,1).v);
                    mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 90]);

                    subplot('Position', subplotPosVector(1,2).v);
                    mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 0]);

                    subplot('Position', subplotPosVector(2,1).v);
                    mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [90 0]);

                    % Finally, plot correspondence between true and recovered cone mosaic
                    subplot('Position', subplotPosVector(2,2).v);
                    mdsProcessor.DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, spatialExtent);
                    title(sprintf('Eye movements: %d\n', kSteps));
                drawnow;
                
                if (~isempty(writerObj))
                    frame = getframe(gcf);
                    writeVideo(writerObj, frame);
                end
        
            end % timeBin
        end% sceneIndex
        
        eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
        
    end% rotationIndex
    
    % close video stream and save movie
    close(writerObj);
        
end

function GenerateResultsFigure(resultsFile)
    disp('Loading the raw data');
    load(resultsFile);
    
    disp('Computing aggregate XT response');
    aggregateXTresponse = [];
    for sceneIndex = 1:numel(allSceneNames)
        aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}];
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
    [d,Z,transform] = procrustes(trueConeXYLocations(LMconeIndices,:), rotatedMDSprojection(LMconeIndices,2:3));
    
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
    coneColors  = [0 0 0; 0 0 0; 0 0 1];
    spatialExtent = {[], [], []};
    h = figure(1); clf;
    set(h, 'Position', [100 10 760 700], 'Name', 'Step1: Identify S-cone positions');
        subplot('Position', subplotPosVector(1,1).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, cLM, cS, pivot, spatialExtent, MDSdims, [0 90]);

        subplot('Position', subplotPosVector(1,2).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, cLM, cS, pivot, spatialExtent, MDSdims, [0 0]);

        subplot('Position', subplotPosVector(2,1).v);
        mdsProcessor.DrawConePositions(MDSprojection, coneIndices, coneColors, cLM, cS, pivot, spatialExtent, MDSdims, [90 0]);
    drawnow;
    NicePlot.exportFigToPDF('Raw.pdf',h,300);
    
    % Plot the result of stage-2: Rotation and Separation of L from M
    coneIndices = {LconeIndices, MconeIndices, SconeIndices};
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    spatialExtent = max(trueConeXYLocations(:)) * 1.2;
    h = figure(2); clf;
    set(h, 'Position', [200 10 760 700], 'Name', 'Step2: Rotated');
        subplot('Position', subplotPosVector(1,1).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 90]);
    
        subplot('Position', subplotPosVector(1,2).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [0 0]);
    
        subplot('Position', subplotPosVector(2,1).v);
        mdsProcessor.DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, {[],spatialExtent, spatialExtent}, MDSdims, [90 0]);
    
        % Finally, plot correspondence between true and recovered cone mosaic
        subplot('Position', subplotPosVector(2,2).v);
        mdsProcessor.DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, spatialExtent);
    drawnow;
    NicePlot.exportFigToPDF('Rotated.pdf',h,300);

end

 function GenerateVideoFileOLD(resultsFile)
        
        load(resultsFile);
    
        % find minimal number of eye movements across all scenes
        minEyeMovements = 10*1000*1000;
        totalEyeMovementsNum = 0;
        for sceneIndex = 1:numel(allSceneNames)
            eyeMovementsNum = size(XTresponses{sceneIndex},2);
            totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
            if (eyeMovementsNum < minEyeMovements)
                minEyeMovements = eyeMovementsNum;
            end
        end
    
        fixationsPerSceneRotation = 20;
        eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation
        fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation);
    
        fprintf('Total eye movements: %d. Eye movements with equal visits across all scenes: %d\n', totalEyeMovementsNum, fullSceneRotations*eyeMovementsPerSceneRotation)
        initialPass = true;
        eyeMovementIndex = 1;
        aggregateXTresponse = [];
        previousXTresponse = [];
    
        % Setup video stream
        writerObj = VideoWriter('MosaicReconstruction.m4v', 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        % Open video stream
        open(writerObj); 

        for rotationIndex = 1:fullSceneRotations
            timeBins = eyeMovementIndex + [0:eyeMovementsPerSceneRotation-1];

            for sceneIndex = 1:numel(allSceneNames)
                aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];
                
                for timeBin = 1:eyeMovementsPerSceneRotation 
                    
                    correlationMatrix = corrcoef((aggregateXTresponse(:,1:end-eyeMovementsPerSceneRotation+timeBin))');
                    D = -log((correlationMatrix+1.0)/2.0);
                    if ~issymmetric(D)
                        D = 0.5*(D+D');
                    end
                    
                    disparityMatrices{timeBin} = D;
                    RenderResults(initialPass, trueConeTypes, disparityMatrices, previousXTresponse, XTresponses{sceneIndex}(:,timeBins), opticalImageRGBrendering{sceneIndex}, opticalSampleSeparation{sceneIndex}, eyeMovements{sceneIndex}(timeBins,:), ...
                        sensorSampleSeparation, sensorRowsCols, writerObj)
                    %VisualizeResultsOLD(initialPass, trueConeTypes, disparityMatrices, previousXTresponse, XTresponses{sceneIndex}(:,timeBins), opticalImageRGBrendering{sceneIndex}, opticalSampleSeparation{sceneIndex}, eyeMovements{sceneIndex}(timeBins,:), ...
                %        sensorSampleSeparation, sensorRowsCols, writerObj);
                
                    previousXTresponse = XTresponses{sceneIndex}(:,timeBins);
                    initialPass = false;
                end
            end
            eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
        end
        % close video stream and save movie
        close(writerObj);
end        

function RenderResultsOLD(initialPass, trueConeTypes, trueConeXYLocations, disparityMatrices, previousXTresponse, XTresponse, opticalImage, opticalSampleSeparation, eyeMovements, sensorSampleSeparation, sensorRowsCols, writerObj)

    % optical image axes in microns
    opticalImageXposInMicrons = (0:size(opticalImage,2)-1) * opticalSampleSeparation(1);
    opticalImageYposInMicrons = (0:size(opticalImage,1)-1) * opticalSampleSeparation(2);
    opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
    opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);
    selectXPosIndices = 1:2:size(opticalImage,2);
    selectYPosIndices = 1:2:size(opticalImage,1);
    
    eyeMovementsInMicrons(:,1) = eyeMovements(:,1) * sensorSampleSeparation(1);
    eyeMovementsInMicrons(:,2) = eyeMovements(:,2) * sensorSampleSeparation(2);

    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparation(1);
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparation(2);
    
    
    for eyeMovementIndex = 1:size(eyeMovementsInMicrons,1)
    end
    
end


function VisualizeResultsOLD(initialPass, trueConeTypes, disparityMatrices, previousXTresponse, XTresponse, opticalImage, opticalSampleSeparation, eyeMovements, sensorSampleSeparation, sensorRowsCols, writerObj)

    % optical image axes in microns
    opticalImageXposInMicrons = (0:size(opticalImage,2)-1) * opticalSampleSeparation(1);
    opticalImageYposInMicrons = (0:size(opticalImage,1)-1) * opticalSampleSeparation(2);
    opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
    opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);
    selectXPosIndices = 1:2:size(opticalImage,2);
    selectYPosIndices = 1:2:size(opticalImage,1);
    
    eyeMovementsInMicrons(:,1) = eyeMovements(:,1) * sensorSampleSeparation(1);
    eyeMovementsInMicrons(:,2) = eyeMovements(:,2) * sensorSampleSeparation(2);

    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparation(1);
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparation(2);
    
    visibleXTresponse = XTresponse*0;
    
    opticalImageSubPlotPosition  = [0.025 0.29 0.47 0.68];
    xtResponseSubPlotPosition    = [0.025 0.04 0.47 0.20];
    sensor2DactivationSubPlotPosition = [0.53 0.64 0.17 0.17*1440/770 ];
    disparityMatrixSubPlotPosition  = [0.80 0.64 0.17 0.17*1440/770 ];
    MDSprojectionSubPlotPosition = [0.55 0.05 0.41 0.45];
    
    h = figure(1);
    set(h, 'Position', [100 100 1440 770], 'Color', [0 0 0]);
    clf;
    
    subplot('Position', opticalImageSubPlotPosition);
    imagesc(opticalImageXposInMicrons(selectXPosIndices), opticalImageYposInMicrons(selectYPosIndices), opticalImage(selectYPosIndices,selectXPosIndices,:));
    axis 'image'
    set(gca, 'CLim', [0 1]); 
    set(gca, 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)]*0.81, 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]*0.81);
    
    if (opticalImageXposInMicrons(end) > 2000)
        set(gca, 'XTick', [-4000:500:4000], 'YTick', [-4000:500:4000]);
    else
        set(gca, 'XTick', [-2000:250:2000], 'YTick', [-2000:250:2000]);
    end
    set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
    xlabel('microns', 'FontSize', 14);
    hold on;
    
    for eyeMovementIndex = 1:size(eyeMovementsInMicrons,1)
        
        subplot('Position', opticalImageSubPlotPosition);
        plot(-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'w.-');
        plot(-eyeMovementsInMicrons(1:eyeMovementIndex,1), eyeMovementsInMicrons(1:eyeMovementIndex,2), 'k.');
        plot(-eyeMovementsInMicrons(eyeMovementIndex,1) + sensorOutlineInMicrons(:,1), eyeMovementsInMicrons(eyeMovementIndex,2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 2.0);
        
        subplot('Position', xtResponseSubPlotPosition);
        if isempty(previousXTresponse)
            visibleXTresponse(:, 1:eyeMovementIndex) = XTresponse(:, 1:eyeMovementIndex);
        else
           visibleXTresponse = circshift(previousXTresponse, -eyeMovementIndex, 2);
           indices = 1:eyeMovementIndex;
           visibleXTresponse(:, end-eyeMovementIndex+1+indices) = XTresponse(:, indices);
        end
        imagesc(visibleXTresponse);
        set(gca, 'XLim', [1 size(XTresponse,2)], 'CLim', [0 1.0]);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'YTick', [], 'FontSize', 12);
        xlabel('time', 'FontSize', 16, 'FontWeight', 'b'); ylabel('mosaic activation', 'FontSize', 16, 'FontWeight', 'b');
        
        
        % 2D ensor activation 
        subplot('Position', sensor2DactivationSubPlotPosition);
        XYresponse = reshape(XTresponse(:, eyeMovementIndex), [sensorRowsCols(1) sensorRowsCols(2)]);
        imagesc((1:sensorRowsCols(2))*sensorSampleSeparation(1), (1:sensorRowsCols(1))*sensorSampleSeparation(2), XYresponse);
        set(gca, 'CLim', [0 1]);
        set(gca, 'XTick', sensorSampleSeparation(1)*(-20:20), 'YTick',sensorSampleSeparation(2)*(-20:20));
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
        axis 'image'
        xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);
        title('mosaic XY activation', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        % Disparity matrix
        subplot('Position', disparityMatrixSubPlotPosition);
        if (eyeMovementIndex > 2)||(initialPass==false)
            imagesc(disparityMatrices{eyeMovementIndex});
            set(gca, 'CLim', [0 max(disparityMatrices{eyeMovementIndex}(:))]);
        else
            imagesc(zeros(sensorRowsCols(1)*sensorRowsCols(2)));
            set(gca, 'CLim', [0 1]);
        end
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
        title('disparity matrix', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        
        if (eyeMovementIndex > 10)||(initialPass==false)
            subplot('Position', MDSprojectionSubPlotPosition);
           
            dimensionsNum = 3;
            SymbolColor = [1 0 0; 0 1 0; 0 0 1];
            try
            [MDSprojection,stress] = mdscale(disparityMatrices{eyeMovementIndex},dimensionsNum);
            for actualConeType = 2:4
                indices = find(trueConeTypes == actualConeType);
                scatter3(MDSprojection(indices,1), ...
                    MDSprojection(indices,2), ...
                    MDSprojection(indices,3), ...
                    'filled', 'MarkerFaceColor',SymbolColor(actualConeType-1,:));
                if (actualConeType == 2)
                    hold on;
                end
                if (actualConeType == 4)
                    hold off;
                end
            end
            
            catch
                fprintf('Failed to mDscale\n');
            end
            set(gca, 'FontSize', 12);
            box on; grid on; view([170 54]);
            set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'ZColor', [0.8 0.8 0.6], 'FontSize', 12);
            xlabel('spectral dim'); ylabel('spatial dim'); zlabel('spatial dim');
            title('MDSembedding', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        end
        
        colormap(hot(512));
    
        
        drawnow;
        
        if (~isempty(writerObj))
            frame = getframe(gcf);
            writeVideo(writerObj, frame);
        end
        
    end

end
