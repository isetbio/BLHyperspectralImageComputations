function ReconstructMosaicFromXTresponses

    generateVideo = false;
    
    mosaicWidth = 10;
    resultsFile = sprintf('results_%dx%d.mat', mosaicWidth, mosaicWidth);
    
    if (generateVideo)
        GenerateVideoFile(resultsFile);
    else
        GenerateResultsFigure(resultsFile);
    end
end

function GenerateResultsFigure(resultsFile)
    
    load(resultsFile);

    aggregateXTresponse = [];
    for sceneIndex = 1:numel(allSceneNames)
        aggregateXTresponse = [aggregateXTresponse XTresponses{sceneIndex}];
    end
    
    
    correlationMatrix = corrcoef(aggregateXTresponse');
    D = -log((correlationMatrix+1.0)/2.0);
    if ~issymmetric(D)
        D = 0.5*(D+D');
    end
    
    figure(1)
    clf;
    
    dimensionsNum = 3;
    symbolColor = [1 0 0; 0 1 0; 0 0 1];
    
        [MDSprojection,stress] = mdscale(D,dimensionsNum);
        
        [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection);
        SconeSpatialPositions = [MDSprojection(SconeIndices,2) MDSprojection(SconeIndices,3)];
        SconePositionCentroid = mean(SconeSpatialPositions,1)
        SconeSpectralLocation = mean(MDSprojection(SconeIndices,1),1)
        
        [alpha, beta, gamma, delta] = FitPlaneTo3Ddata(MDSprojection(SconeIndices,1), MDSprojection(SconeIndices,2), MDSprojection(SconeIndices,3));
        SconePlaneNormal = [alpha, beta, gamma]
        
        SconePlaneAngles(1) = AngleBetweenLineAndPlane(alpha, beta, gamma, 1,0, 0)/pi*180; % plane rotation around the spectral dimension
        SconePlaneAngles(2) = AngleBetweenLineAndPlane(alpha, beta, gamma, 0,1, 0)/pi*180; % plane rotation around the spatial dimension-1
        SconePlaneAngles(3) = AngleBetweenLineAndPlane(alpha, beta, gamma, 0,0, 1)/pi*180; % plane rotation around the spatial dimension-2
        SconePlaneAngles
        
        
        [alpha, beta, gamma, delta] = FitPlaneTo3Ddata(MDSprojection(LMconeIndices,1), MDSprojection(LMconeIndices,2), MDSprojection(LMconeIndices,3));
        LMconePlaneNormal = [alpha, beta, gamma]
        LMconePlaneAngles(1) = AngleBetweenLineAndPlane(alpha, beta, gamma, 1,0, 0)/pi*180;
        LMconePlaneAngles(2) = AngleBetweenLineAndPlane(alpha, beta, gamma, 0,1, 0)/pi*180;
        LMconePlaneAngles(3) = AngleBetweenLineAndPlane(alpha, beta, gamma, 0,0, 1)/pi*180;
        LMconePlaneAngles
        
        
        sinTheta2 = sin(-LMconePlaneAngles(1)/180*pi);
        cosTheta2 = cos(-LMconePlaneAngles(1)/180*pi);
        sinTheta1 = sin(-LMconePlaneAngles(2)/180*pi);
        cosTheta1 = cos(-LMconePlaneAngles(2)/180*pi);
       
        % compute rotation matrix around spatialdimension-2 (z-axis)
        LMrotationMatrix1 = [cosTheta1 -sinTheta1 0; sinTheta1 cosTheta1 0; 0 0 1];
        LMrotationMatrix2 = [cosTheta2 0 sinTheta2; 0 1 0; -sinTheta2 0 cosTheta2];
        LMrotationMatrix = LMrotationMatrix1 * LMrotationMatrix2
        
        LMconeSpatialPositions = [MDSprojection(LMconeIndices,2) MDSprojection(LMconeIndices,3)];
        LMconePositionCentroid = mean(LMconeSpatialPositions,1)
        LMconeSpectralLocation = mean(MDSprojection(LMconeIndices,1),1)
        
        cLM = mean(MDSprojection(LMconeIndices,:),1);
        cS = mean(MDSprojection(SconeIndices,:),1); 
        
        % Rotate LM positions by - LMconePlaneAngles(2)
        % translate the mean LMcone position
        centeredMDSprojection(LMconeIndices,:) = bsxfun(@minus, MDSprojection(LMconeIndices,:), cLM);
        centeredMDSprojection(SconeIndices,:)  = bsxfun(@minus, MDSprojection(SconeIndices,:), cS);
       
        %rotate
        rotatedMDSprojection(LMconeIndices,:) = centeredMDSprojection(LMconeIndices,:) * LMrotationMatrix;
        rotatedMDSprojection(SconeIndices,:)  = centeredMDSprojection(SconeIndices,:) * LMrotationMatrix;
        
        %move back to mean LMconePosition
        rotatedMDSprojection(LMconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(LMconeIndices,:),  cLM);
        rotatedMDSprojection(SconeIndices,:)  = bsxfun(@plus, rotatedMDSprojection(SconeIndices,:),   cS);
        
        [coneAindices, coneBindices] = DetermineLMconeIndices(MDSprojection(LMconeIndices,:));
        coneAindices = LMconeIndices(coneAindices);
        coneBindices = LMconeIndices(coneBindices);

        indices = {coneAindices, coneBindices, SconeIndices};
        
        hold on
        for coneType = 1:numel(indices)
        
            scatter3(...
                MDSprojection(indices{coneType},1), ...
                MDSprojection(indices{coneType},2), ...
                MDSprojection(indices{coneType},3), ...
                'filled', ...
                'MarkerFaceColor',symbolColor(coneType,:)...
                );
        end
        
        
       
        plot3(cLM(1), cLM(2), cLM(3), 'ms');
        
        
        
        plot3([LMconeSpectralLocation     SconeSpectralLocation], ...
              [LMconePositionCentroid(1), SconePositionCentroid(1)], ...
              [LMconePositionCentroid(2), SconePositionCentroid(2)], 'k-');
        hold off;
        

    set(gca, 'FontSize', 12);
    box on; grid on; view([170 54]);
    set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'ZColor', [0.8 0.8 0.6], 'FontSize', 12);
    xlabel('spectral dim'); ylabel('spatial dim-1'); zlabel('spatial dim-2');
    title('MDSembedding', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
    
    figure(2);
    clf;
    hold on
    for coneType = 1:numel(indices)
            scatter3(...
                rotatedMDSprojection(indices{coneType},1), ...
                rotatedMDSprojection(indices{coneType},2), ...
                rotatedMDSprojection(indices{coneType},3), ...
                'filled', ...
                'MarkerFaceColor',symbolColor(coneType,:)...
                );
    end
    hold off
    drawnow;
    
    
    
    figure(3);
    clf;
    hold on
    for coneType = 1:numel(indices)
            scatter3(...
                centeredMDSprojection(indices{coneType},1), ...
                centeredMDSprojection(indices{coneType},2), ...
                centeredMDSprojection(indices{coneType},3), ...
                'filled', ...
                'MarkerFaceColor',symbolColor(coneType,:)...
                );
    end
    hold off
    drawnow;
    
    
end

function angle = AngleBetweenLineAndPlane(a, b, c, f,g, h)
    norm1 = sqrt ( a^2 + b^2 + c^2 );
    if ( norm1 == 0.0 )
        angle = Inf;
        return 
    end
    norm2 = sqrt ( f * f + g *g + h * h );
    if ( norm2 == 0.0 )
        angle = Inf;
        return 
    end
    cosine = ( a * f + b * g + c * h) / ( norm1 * norm2 );
    angle = pi/2 - acos(cosine);
end

function [alpha, beta, gamma, delta] = FitPlaneTo3Ddata(x,y,z)
    % z = x * C(1) + y*C(2) + C(3);
    % c(1) * x + c(2) * y + (-1)  * z + c(3) = 0
    % alpha* x + beta * y + gamma * z + delta = 0

    xx = x(:);
    yy = y(:);
    zz = z(:);
    N = length(xx);
    O = ones(N,1);

    C = [xx yy O]\zz;
    alpha = C(1);
    beta = C(2);
    gamma = -1;
    delta = C(3);
end


function [coneAindices, coneBindices] = DetermineLMconeIndices(MDSprojection)
    rng(1); % For reproducibility
    %k-means with 2 clusters to find L vs M cones
    [idx,~] = kmeans(MDSprojection,2,'Replicates',5);

    coneAindices = find(idx==1);
    coneBindices = find(idx==2);
end

function  [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection)
        
    rng(1); % For reproducibility
    %k-means with 2 clusters to find S cones
    [idx,~] = kmeans(MDSprojection,2);
    coneAindices = find(idx==1);
    coneBindices = find(idx==2);

    if (numel(coneAindices) < numel(coneBindices))
        SconeIndices = coneAindices;
        LMconeIndices = coneBindices;
    else
        SconeIndices = coneBindices;
        LMconeIndices = coneAindices;
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
        eyeMovementsPerSceneRotation = fixationsPerSceneRotation * eyeMovementParamsStruct.samplesPerFixation
        fullSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation)
    
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

                VisualizeResults(initialPass, trueConeTypes, disparityMatrices, previousXTresponse, XTresponses{sceneIndex}(:,timeBins), opticalImageRGBrendering{sceneIndex}, opticalSampleSeparation{sceneIndex}, eyeMovements{sceneIndex}(timeBins,:), ...
                    sensorSampleSeparation, sensorRowsCols, writerObj);
                
                previousXTresponse = XTresponses{sceneIndex}(:,timeBins);
                initialPass = false;
                end
            end
            eyeMovementIndex = eyeMovementIndex + eyeMovementsPerSceneRotation;
        end
        % close video stream and save movie
        close(writerObj);
end        


function VisualizeResults(initialPass, trueConeTypes, disparityMatrices, previousXTresponse, XTresponse, opticalImage, opticalSampleSeparation, eyeMovements, sensorSampleSeparation, sensorRowsCols, writerObj)

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
