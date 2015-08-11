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

    fixationsPerSceneRotation = 11;
    eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation;
    fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation)
    totalFixationsNum = fullSceneRotations*fixationsPerSceneRotation
    
    fullSceneRotations = input('Enter desired scene rotations: ');
    
    % Initialize
    aggregateXTresponse = [];
    eyeMovementIndex = 1;
    minSteps = 5;
    
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
    performance = [];
    
    hFig = figure(1); clf;
    set(hFig, 'unit','pixel', 'menubar','none', 'Position', [10 20 1280 800], 'Color', [0 0 0]);
    axesStruct.opticalImageAxes = axes('parent',hFig,'unit','pixel','position',[10 408 640 390], 'Color', [0 0 0]);
    axesStruct.xtResponseAxes   = axes('parent',hFig,'unit','pixel','position',[10 2 220 400], 'Color', [0 0 0]);
    axesStruct.dispMatrixAxes   = axes('parent',hFig,'unit','pixel','position',[265 2 400 400], 'Color', [0 0 0]);
    axesStruct.performanceAxes1  = axes('parent',hFig,'unit','pixel','position',[705 130 560 120], 'Color', [0 0 0]);
    axesStruct.performanceAxes2  = axes('parent',hFig,'unit','pixel','position',[705 4 560 120], 'Color', [0 0 0]);
    axesStruct.xyMDSAxes = axes('parent',hFig,'unit','pixel','position',[710 540 256 256], 'Color', [0 0 0]);
    axesStruct.xzMDSAxes = axes('parent',hFig,'unit','pixel','position',[1000 540 256 256], 'Color', [0 0 0]);
    axesStruct.yzMDSAxes = axes('parent',hFig,'unit','pixel','position',[710 275 256 256], 'Color', [0 0 0]);
    axesStruct.mosaicAxes = axes('parent',hFig,'unit','pixel','position',[1000 275 256 256], 'Color', [0 0 0]);
    
    for rotationIndex = 1:fullSceneRotations
        
        timeBins = eyeMovementIndex + (0:eyeMovementsPerSceneRotation-1);

        for sceneIndex = 1:numel(allSceneNames)
            
            aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}(:,timeBins)];

            for timeBinIndex = 1:eyeMovementsPerSceneRotation 

                disp('Updating correlation matrix');
                binRange = 1:size(aggregateXTresponse,2)-eyeMovementsPerSceneRotation+timeBinIndex;
                correlationMatrix = corrcoef((aggregateXTresponse(:,binRange))');
                D = -log((correlationMatrix+1.0)/2.0);
                if ~issymmetric(D)
                    D = 0.5*(D+D');
                end
                
                kSteps = kSteps + 1;
                if (kSteps < minSteps)
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
    
                
                
                disp('Drawing');
                % Plot the result of stage-2: Rotation and Separation of L from M
                coneIndices = {LconeIndices, MconeIndices, SconeIndices};
                coneColors = [1 0 0; 0 1 0; 0 1 1];
                spatialExtent = max(trueConeXYLocations(:)) * 1.2;
                
                % Update cone mosaic estimation performance
                performance = mdsProcessor.ComputePerformance(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, performance, kSteps-(minSteps-1), eyeMovementParamsStruct.samplesPerFixation);
                
                RenderFrame(axesStruct, binRange(end)/eyeMovementParamsStruct.samplesPerFixation, performance, D, ...
                    rotatedMDSprojection, coneIndices, coneColors, cLMPrime, cSPrime, pivotPrime, spatialExtent, trueConeTypes, trueConeXYLocations);
                
                if (1==2)
                hh = figure(1); clf;
                    subplot(2,1,1);
                    plot(performance.fixationsNum, performance.correctlyIdentifiedLMcones, 'rs-');
                    hold on;
                    plot(performance.fixationsNum, performance.correctlyIdentifiedScones, 'bs-');
                    hold off;
                    set(gca, 'FontSize', 12);
                    xlabel('fixations no', 'FontSize', 14);
                    ylabel('correctly identified cone types', 'FontSize', 14);
                    legend('L/M cones', 'S cones');
                    box on; grid on;
                
                    subplot(2,1,2);
                    plot(performance.fixationsNum, performance.meanDistanceLMmosaic ,'rs-');
                    hold on;
                    plot(performance.fixationsNum, performance.meanDistanceSmosaic, 'bs-');
                    hold off;
                    set(gca, 'FontSize', 12);
                    xlabel('fixations no', 'FontSize', 14);
                    ylabel('spatial misplacement', 'FontSize', 14);
                    legend('L/M cones', 'S cones');
                drawnow;
                end
                
                if (1==2)
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
                    mdsProcessor.DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, spatialExtent);
                    title(sprintf('Eye movements: %d\n', kSteps));
                drawnow;
                end
                
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

function RenderFrame(axesStruct, fixationNo,performance, D, MDSprojection, coneIndices, coneColors, cLM, cS, pivot, spatialExtent, trueConeTypes, trueConeXYLocations)

    opticalImageAxes = axesStruct.opticalImageAxes; 
    xtResponseAxes = axesStruct.xtResponseAxes;
    dispMatrixAxes   = axesStruct.dispMatrixAxes;
    performanceAxes1  = axesStruct.performanceAxes1 ;
    performanceAxes2  = axesStruct.performanceAxes2;
    xyMDSAxes = axesStruct.xyMDSAxes;
    xzMDSAxes = axesStruct.xzMDSAxes;
    yzMDSAxes = axesStruct.yzMDSAxes;
    mosaicAxes = axesStruct.mosaicAxes;
    
    LconeIndices = coneIndices{1};
    MconeIndices = coneIndices{2};
    SconeIndices = coneIndices{3};
    
    % Determine specral range
    xx = squeeze(MDSprojection(:,1));
    minX = min(xx);
    maxX = max(xx);
    margin = 100 - (maxX - minX);
    XLims = [minX-margin/2 maxX+margin/2];

    YLims = spatialExtent*[-1 1];
    ZLims = spatialExtent*[-1 1];
                
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
                'filled', ...
                'MarkerFaceColor',coneColors(coneType,:)...
                );  
            hold(drawingAxes, 'on');
        end
        scatter3(drawingAxes, cLM(1), cLM(2), cLM(3), 'ms', 'filled');
        scatter3(drawingAxes, cS(1), cS(2), cS(3), 'cs', 'filled');
        scatter3(drawingAxes, pivot(1), pivot(2), pivot(3), 'ws', 'filled');
        plot3(drawingAxes, [cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'w-');
        hold(drawingAxes, 'off');
        grid(drawingAxes, 'on'); 
        box(drawingAxes, 'on'); 
        axis(drawingAxes, 'square')
        axis(drawingAxes, 'off')
        view(drawingAxes, viewingAngles);
        set(drawingAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
        set(drawingAxes, 'XTickLabel', {}, 'YTickLabel', {});
        if (~isempty(XLims))
            set(drawingAxes, 'XLim', XLims);
        end
        set(drawingAxes, 'YLim', YLims);
        set(drawingAxes, 'ZLim', ZLims);
    end % viewIndex
    
    
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2) && (ismember(k, LconeIndices))
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            hold(mosaicAxes,'on')
            plot(mosaicAxes,[trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'r-');
        elseif (trueConeTypes(k) == 3) && (ismember(k, MconeIndices))
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            hold(mosaicAxes,'on')
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'g-');
        elseif (trueConeTypes(k) == 4) && (ismember(k, SconeIndices))
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'cs', 'MarkerFaceColor', 'c');
            hold(mosaicAxes,'on')
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'c-');
        else
            % incorrectly indentified cone
            plot(mosaicAxes, trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'ws', 'MarkerFaceColor', 'w');
            hold(mosaicAxes,'on')
            plot(mosaicAxes, [trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'w-');
        end  
    end
    hold(mosaicAxes,'off')
    set(mosaicAxes, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(mosaicAxes, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(mosaicAxes, 'XTickLabel', {}, 'YTickLabel', {});
    set(mosaicAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
    grid(mosaicAxes, 'on'); 
    box(mosaicAxes, 'on'); 
    axis(mosaicAxes, 'square')
    axis(mosaicAxes, 'off')
    
    % Disparity matrix
    pcolor(dispMatrixAxes, D.*tril(ones(size(D))));
    colormap(hot);
    box(dispMatrixAxes, 'on'); 
    axis(dispMatrixAxes, 'square');
    axis(dispMatrixAxes, 'ij')
    set(dispMatrixAxes, 'CLim', [0 max(D(:))]);
    set(dispMatrixAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTickLabel', {}, 'YTickLabel', {});
    
    
    % Performance as a function of time
    plot(performanceAxes1, performance.fixationsNum, performance.correctlyIdentifiedLMcones, 'y-', 'LineWidth', 2.0);
    hold(performanceAxes1,'on')
    plot(performanceAxes1, performance.fixationsNum, performance.correctlyIdentifiedScones, 'c-', 'LineWidth', 2.0);
    hold(performanceAxes1,'off')
    set(performanceAxes1, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XLim', [0 max([10 max(performance.fixationsNum)])], 'YLim', [0 1.02], 'XTickLabel', {}, 'YTickLabel', {});
    ylabel(performanceAxes1, '% correct', 'FontSize', 14);
    hLeg = legend(performanceAxes1, 'L/M', 'S');
    set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'southeast');
    box(performanceAxes1, 'off'); 
    grid(performanceAxes1, 'on');
    title(performanceAxes1, sprintf('fixations: %2.1f\n', fixationNo), 'FontSize', 16, 'Color', [1 1 1]);
    
    
    plot(performanceAxes2, performance.fixationsNum, performance.meanDistanceLMmosaic, 'y-', 'LineWidth', 2.0);
    hold(performanceAxes2,'on')
    plot(performanceAxes2, performance.fixationsNum, performance.meanDistanceSmosaic, 'c-', 'LineWidth', 2.0);
    hold(performanceAxes2,'off')
    set(performanceAxes2, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XLim', [0 max([10 max(performance.fixationsNum)])], 'YLim', [0 20], 'XTickLabel', {}, 'YTickLabel', {});
    ylabel(performanceAxes2, 'spatial jitter', 'FontSize', 14);
    hLeg = legend(performanceAxes2, 'L/M', 'S');
    set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'northeast');
    box(performanceAxes2, 'off'); 
    grid(performanceAxes2, 'on');
    
    drawnow
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
        mdsProcessor.DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, coneIndices, spatialExtent);
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
                
                for timeBinIndex = 1:eyeMovementsPerSceneRotation 
                    
                    binRange = (1:size(aggregateXTresponse,2)-(eyeMovementsPerSceneRotation-timeBinIndex));
                    
                    correlationMatrix = corrcoef((aggregateXTresponse(:,binRange))');
                    D = -log((correlationMatrix+1.0)/2.0);
                    if ~issymmetric(D)
                        D = 0.5*(D+D');
                    end
                    
                    disparityMatrices{timeBinIndex} = D;
                    
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
