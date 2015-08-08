function ReconstructMosaicFromXTresponses2

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
    
    % Step1: Identify S-cone positions
    [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection);
    
    % Identify line connecting centroids of S and LM
    cS    = mean(MDSprojection(SconeIndices,:),1);
    cLM   = mean(MDSprojection(LMconeIndices,:),1); 
    pivot = (cS + cLM)/2;
    
    % undo rotation of S-LM line along Y and Z axes
    S_LM_Line = cS-cLM;
    
    u = [S_LM_Line(1) S_LM_Line(3)];
    v = [1 0];
    rotationYaxis = acos(dot(u,v)/(norm(u)*norm(v))) /pi*180;
    u = [S_LM_Line(1) S_LM_Line(2)];
    v = [1 0];
    rotationZaxis = acos(dot(u,v)/(norm(u)*norm(v))) /pi*180;
    
    % This is arbitary so as to make the spatialdim1, spatialdim2 as close
    % to original mosaic
    rotationXaxis = 2;
    
    cosTheta = cos(rotationYaxis/180*pi);
    sinTheta = sin(rotationYaxis/180*pi);
    rotationMatrixAroundYaxis = [cosTheta 0 sinTheta; 0 1 0; -sinTheta 0 cosTheta];
    
    cosTheta = cos(rotationZaxis/180*pi);
    sinTheta = sin(rotationZaxis/180*pi);
    rotationMatrixAroundZaxis = [cosTheta -sinTheta 0; sinTheta cosTheta 0; 0 0 1];
    
    cosTheta = cos(rotationXaxis/180*pi);
    sinTheta = sin(rotationXaxis/180*pi);
    rotationMatrixAroundXaxis = [1 0 0; 0 cosTheta -sinTheta ; 0 sinTheta cosTheta];
    
    
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@minus, MDSprojection(SconeIndices,:), pivot);
    rotatedMDSprojection(SconeIndices,:) = rotatedMDSprojection(SconeIndices,:) * rotationMatrixAroundYaxis*rotationMatrixAroundZaxis*rotationMatrixAroundXaxis;
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(SconeIndices,:), pivot);
    
    
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@minus, MDSprojection(LMconeIndices,:), pivot);
    rotatedMDSprojection(LMconeIndices,:) = rotatedMDSprojection(LMconeIndices,:) * rotationMatrixAroundYaxis*rotationMatrixAroundZaxis*rotationMatrixAroundXaxis;
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(LMconeIndices,:), pivot);
    
    cSprime    = cS - pivot;
    cLMprime   = cLM - pivot;
    cSprime = cSprime * rotationMatrixAroundYaxis*rotationMatrixAroundZaxis;
    cLMprime = cLMprime * rotationMatrixAroundYaxis*rotationMatrixAroundZaxis;
    cSprime = cSprime + pivot;
    cLMprime = cLMprime + pivot;
    pivotPrime = pivot;
    
    % center on yz origin
    for k = 2:3
        rotatedMDSprojection(:,k) = rotatedMDSprojection(:,k) - pivot(k);
        cSprime(k) = cSprime(k) - pivot(k);
        cLMprime(k) = cLMprime(k) - pivot(k);
        pivotPrime(k) = 0;
    end
    
    [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices);
    
    scaleF = max(max(abs(trueConeXYLocations))) / max(max(abs(rotatedMDSprojection(:,2:3))));
    
    
    
    
    
    % Plot the result of stage 1
    
    coneIndices = {LMconeIndices(1:10), LMconeIndices(11:end), SconeIndices};
    coneColors = [0 0 0; 0 0 0; 0 0 1];
    
    h = figure(1); clf;
    set(h, 'Position', [100 10 710 620], 'Name', 'Step1: Identify S-cone positions');
    subplot(2,2,1);
    
    % Draw the best fitting S-cone plane
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors);
    % Draw segment connecting centers
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([0,0]);
    axis 'square'
    
    subplot(2,2,2);
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors);
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([0,90]);
    axis 'square'
    drawnow;
    
    
    subplot(2,2,3);
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors);
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([90,0]);
    axis 'square'
    drawnow;
    
    
    % Plot the result of stage2
    h = figure(2); clf;
    set(h, 'Position', [200 10 710 620], 'Name', 'Step2: Rotated');
    subplot(2,2,1);
     hold on
    % Draw the cone positions
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    coneIndices = {LconeIndices, MconeIndices, SconeIndices};
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,0]);
    axis 'square'
    
    subplot(2,2,2);
    hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,90]);
    axis 'square'
    
    subplot(2,2,3);
    hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([90,0]);
    axis 'square'
    
    subplot(2,2,4)
    hold on
    for k = 1:size(trueConeXYLocations,1)
        
        if (trueConeTypes(k) == 2)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,3)*scaleF], ...
                 [trueConeXYLocations(k,2) -rotatedMDSprojection(k,2)*scaleF], 'r-');
 
        elseif (trueConeTypes(k) == 3)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,3)*scaleF], ...
                 [trueConeXYLocations(k,2) -rotatedMDSprojection(k,2)*scaleF], 'g-');
             
        elseif (trueConeTypes(k) == 4)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,3)*scaleF], ...
                 [trueConeXYLocations(k,2) -rotatedMDSprojection(k,2)*scaleF], 'b-');
        end  
    end
    axis 'square'
    
    drawnow;
end

function DrawConePositions(MDSprojection, coneIndices, coneColors)
    
    for coneType = 1:numel(coneIndices)

        scatter3(...
            MDSprojection(coneIndices{coneType},1), ...
            MDSprojection(coneIndices{coneType},2), ...
            MDSprojection(coneIndices{coneType},3), ...
            'filled', ...
            'MarkerFaceColor',coneColors(coneType,:)...
            );  
    end
    set(gca, 'YLim', 0.03*[-1 1], 'ZLim', 0.03*[-1 1]);
    grid on;
    box on;
    xlabel('x');
    ylabel('y');
    zlabel('z');
end




function [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices)
    
    xComponents = rotatedMDSprojection(LMconeIndices,1);
    
    rng(1); % For reproducibility
    %k-means with 2 clusters to find S cones
    [idx,~] = kmeans(xComponents,2);
    LconeIndices = LMconeIndices(find(idx==1));
    MconeIndices = LMconeIndices(find(idx==2));
    
    % Make sure that M cones closer to S than L cones to S
    xL = mean(squeeze(rotatedMDSprojection(LconeIndices,1)));
    xM = mean(squeeze(rotatedMDSprojection(MconeIndices,1)));
    xS = mean(squeeze(rotatedMDSprojection(SconeIndices,1)));
    
    if (abs(xL-xS) < abs(xM-xS))
        tmp = LconeIndices;
        LconeIndices = MconeIndices;
        MconeIndices = tmp;
    end
end

function [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection)
        
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
