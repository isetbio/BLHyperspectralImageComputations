function testMDSpostProcessingAnalysis

    conesAcross = 10
    load(sprintf('MDS_results_%dx%d.mat', conesAcross, conesAcross))
    whos
    
    % Step1: Identify S-cone positions
    [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection);
    
    MDSdims = {'MDS-x', 'MDS-y', 'MDS-z'};
    % switch MDS dimension Y with MDS dimension Z
    MDSdimensionForXspatialDim = 3;
    MDSdimensionForYspatialDim = 2;
    tmp_MDSprojection = MDSprojection;
    tmp_MDSprojection(:,2) = MDSprojection(:,MDSdimensionForXspatialDim);
    tmp_MDSprojection(:,3) = MDSprojection(:,MDSdimensionForYspatialDim);
    MDSprojection = tmp_MDSprojection;
    
    
    % Identify line connecting centroids of S and LM
    cS    = mean(MDSprojection(SconeIndices,:),1);
    cLM   = mean(MDSprojection(LMconeIndices,:),1); 
    pivot = (cS + cLM)/2;
    
    % these need to be determined online
    % undo rotation of S-LM line along Y and Z axes
    diffVector = cS-cLM;
    rotationZaxis =  atan2(diffVector(2), diffVector(1)) / pi*180;
    rotationYaxis = -atan2(diffVector(3), diffVector(1)) / pi*180;
    
    % form rotation matrix around Y-axis
    cosTheta = cos(rotationYaxis/180*pi);
    sinTheta = sin(rotationYaxis/180*pi);
    rotationMatrixAroundYaxis = [...
        cosTheta  0  sinTheta; ...
        0         1  0; ...
        -sinTheta 0  cosTheta];
    
    % form rotation matrix around Z-axis
    cosTheta = cos(rotationZaxis/180*pi);
    sinTheta = sin(rotationZaxis/180*pi);
    rotationMatrixAroundZaxis = [...
        cosTheta -sinTheta  0; ...
        sinTheta  cosTheta  0; ...
        0         0         1];   
    
    rotationMatrixAroundYZ = rotationMatrixAroundYaxis * rotationMatrixAroundZaxis;
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@minus, MDSprojection(SconeIndices,:), pivot);
    rotatedMDSprojection(SconeIndices,:) = rotatedMDSprojection(SconeIndices,:) * rotationMatrixAroundYZ;
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(SconeIndices,:), pivot);
    
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@minus, MDSprojection(LMconeIndices,:), pivot);
    rotatedMDSprojection(LMconeIndices,:) = rotatedMDSprojection(LMconeIndices,:) * rotationMatrixAroundYZ;
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(LMconeIndices,:), pivot);
    
    cSprime    = cS - pivot;
    cLMprime   = cLM - pivot;
    cSprime    = cSprime  * rotationMatrixAroundYZ;
    cLMprime   = cLMprime * rotationMatrixAroundYZ;
    cSprime    = cSprime + pivot;
    cLMprime   = cLMprime + pivot;
    pivotPrime = pivot;
    
    % center on yz origin (spaceX x spaceY)
    for k = 2:3
        rotatedMDSprojection(:,k) = rotatedMDSprojection(:,k) - pivot(k);
        cSprime(k) = cSprime(k) - pivot(k);
        cLMprime(k) = cLMprime(k) - pivot(k);
        pivotPrime(k) = 0;
    end
    
    % Now separate the L from M cones
    [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices);
   
    
    % Finally scale and rotate the MDS embedding so that we match the spatial
    % scale of the original mosaic
    [d,Z,transform] = procrustes(trueConeXYLocations(LMconeIndices,:), rotatedMDSprojection(LMconeIndices,2:3));
    
    % Form the rotation matrix around X-axis
    rotationMatrixAroundXaxis = ...
        [1 0                0; ...
         0 transform.T(1,1) transform.T(1,2); ...
         0 transform.T(2,1) transform.T(2,2) ...
         ];

    
    reflectionComponent = det(transform.T);
    MDSspatialScalingFactor = transform.b;
    
    % apply rotation and scaling
    rotatedMDSprojection = rotatedMDSprojection * rotationMatrixAroundXaxis;
    rotatedMDSprojection = rotatedMDSprojection * MDSspatialScalingFactor;

    cSprime = cSprime * MDSspatialScalingFactor;
    cLMprime = cLMprime * MDSspatialScalingFactor;
    pivotPrime = pivotPrime * MDSspatialScalingFactor;    
    
    
    subplotPosVector = NicePlot.getSubPlotPosVectors(...
        'rowsNum',      2, ...
        'colsNum',      2, ...
        'widthMargin',  0.07, ...
        'leftMargin',   0.06, ...
        'bottomMargin', 0.06, ...
        'heightMargin', 0.09, ...
        'topMargin',    0.01);
    
    % Plot the result of stage-1: Separation of S and L/M
    
    coneIndices = {LMconeIndices(1:10), LMconeIndices(11:end), SconeIndices};
    coneColors = [0 0 0; 0 0 0; 0 0 1];
    
    h = figure(1); clf;
    set(h, 'Position', [100 10 760 700], 'Name', 'Step1: Identify S-cone positions');
    
    
    subplot('Position', subplotPosVector(1,1).v);
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors, MDSdims);
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([0,90]);
    axis 'square'
    
    subplot('Position', subplotPosVector(1,2).v);
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors, MDSdims);
    % Draw segment connecting centers
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([0,0]);
    axis 'square'
    
    
    subplot('Position', subplotPosVector(2,1).v);
    hold on
    % Draw the cone positions
    DrawConePositions(MDSprojection, coneIndices, coneColors, MDSdims);
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    view([90,0]);
    axis 'square'
    
    
    drawnow;
    NicePlot.exportFigToPDF('Raw.pdf',h,300);
    
    
    % Plot the result of stage-2: Rotation and Separation of L from M
    h = figure(2); clf;
    
    subplot('Position', subplotPosVector(1,1).v);
    hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, MDSdims);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,90]);
    axis 'square'
    
    set(h, 'Position', [200 10 760 700], 'Name', 'Step2: Rotated');
    subplot('Position', subplotPosVector(1,2).v);
    hold on
    % Draw the cone positions
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    coneIndices = {LconeIndices, MconeIndices, SconeIndices};
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, MDSdims);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,0]);
    axis 'square'
    
    
    subplot('Position', subplotPosVector(2,1).v);
    hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors, MDSdims);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivotPrime(1), pivotPrime(2), pivotPrime(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    set(gca, 'YLim', (max(max(abs(trueConeXYLocations)))+4)*[-1 1], 'ZLim', (max(max(abs(trueConeXYLocations)))+4)*[-1 1]);
    set(gca, 'YTick', [-100:10:100], 'ZTick', [-100:10:100]);
    view([90,0]);
    axis 'square'
    
    
    % Finally, plot correspondence between true and recovered cone mosaic
    
    subplot('Position', subplotPosVector(2,2).v);
    hold on
    for k = 1:size(trueConeXYLocations,1)
        
        if (trueConeTypes(k) == 2)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'r-');
 
        elseif (trueConeTypes(k) == 3)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'g-');
             
        elseif (trueConeTypes(k) == 4)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'b-');
        end  
    end
    set(gca, 'XLim', (max(max(abs(trueConeXYLocations)))+4)*[-1 1], 'YLim', (max(max(abs(trueConeXYLocations)))+4)*[-1 1]);
    set(gca, 'XTick', [-100:10:100], 'YTick', [-100:10:100]);
    set(gca, 'FontSize', 12);
    grid on
    xlabel(sprintf('spatial X-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(sprintf('spatial Y-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
    
    axis 'square'
    box on
    drawnow;
    
    NicePlot.exportFigToPDF('Rotated.pdf',h,300);
    
end

function DrawConePositions(MDSprojection, coneIndices, coneColors, MDSdims)
    
    for coneType = 1:numel(coneIndices)

        scatter3(...
            MDSprojection(coneIndices{coneType},1), ...
            MDSprojection(coneIndices{coneType},2), ...
            MDSprojection(coneIndices{coneType},3), ...
            'filled', ...
            'MarkerFaceColor',coneColors(coneType,:)...
            );  
    end
    spatialExtent = max([max(abs(MDSprojection(:,2))) max(abs(MDSprojection(:,3)))]) * 1.04;
    set(gca, 'YLim', spatialExtent*[-1 1], 'ZLim', spatialExtent*[-1 1]);
    set(gca, 'FontSize', 12);
    grid on;
    box on;
    xlabel(MDSdims{1}, 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(MDSdims{2}, 'FontSize', 14, 'FontWeight', 'bold');
    zlabel(MDSdims{3}, 'FontSize', 14, 'FontWeight', 'bold');
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


