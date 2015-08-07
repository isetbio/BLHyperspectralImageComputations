function testRotation

    load('MDS.mat')
    whos

    %X,Y range for plotting the planes
    x = [-0.02 0.08];  % spectral dimension
    y = [-0.1 0.1];    % spatial dimension-1
    
    
    % Step1: Identify S-cone positions
    [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection);
    cS    = mean(MDSprojection(SconeIndices,:),1);
    cLM   = mean(MDSprojection(LMconeIndices,:),1); 
    pivot = (cS + cLM)/2;
    
    % these need to be determined online
    rotationYaxis = 3.5;
    rotationZaxis = 1;
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
 
    
    % center on yz origin
    for k = 2:3
        rotatedMDSprojection(:,k) = rotatedMDSprojection(:,k) - pivot(k);
        cSprime(k) = cSprime(k) - pivot(k);
        cLMprime(k) = cLMprime(k) - pivot(k);
        pivot(k) = 0;
    end
    
    [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices);
    
    coneIndices = {LMconeIndices(1:10), LMconeIndices(11:end), SconeIndices};
    coneColors = [0 0 0; 0 0 0; 0 0 1];
    
    % Plot the result
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
    % Draw the best fitting S-cone plane
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
    % Draw the best fitting S-cone plane
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
    
    
    % Step 2: Unrotate all data so that S-cone plane is normal to the spectral dimension
    h = figure(2); clf;
    set(h, 'Position', [200 10 710 620], 'Name', 'Step2: Rotated');
    subplot(2,2,1);
    
    % Draw the best fitting S-cone plane
     hold on
    % Draw the cone positions
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    coneIndices = {LconeIndices, MconeIndices, SconeIndices};
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,0]);
    axis 'square'
    
    subplot(2,2,2);
    % Draw the best fitting S-cone plane
     hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([0,90]);
    axis 'square'
    
    subplot(2,2,3);
    % Draw the best fitting S-cone plane
     hold on
    % Draw the cone positions
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    DrawConePositions(rotatedMDSprojection, coneIndices, coneColors);
    scatter3(cLMprime(1), cLMprime(2), cLMprime(3), 'ms', 'filled');
    scatter3(cSprime(1), cSprime(2), cSprime(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLMprime(1) cSprime(1)],[cLMprime(2) cSprime(2)], [cLMprime(3) cSprime(3)], 'k-');
    view([90,0]);
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

function DrawPlane(x,y, plane, planeColor)
    [X,Y] = meshgrid(x,y);
    Z = -(plane.delta + plane.alpha * X + plane.beta * Y)/plane.gamma;
    surf(X,Y,Z)
    colormap(planeColor)
    shading flat
end

function angle = AngleBetweenPlaneAndLine(plane, f, g, h)
% line given by following equations:
% x = x0+ft 
% y = y0 + gt
% z = z0 + ht

    norm1 = sqrt ( plane.alpha^2 + plane.beta^2 + plane.gamma^2 );
    if (norm1 == 0.0 )
        angle = Inf;
        return 
    end
    norm2 = sqrt ( f * f + g *g + h * h );
    if ( norm2 == 0.0 )
        angle = Inf;
        return 
    end
    cosine = ( plane.alpha * f + plane.beta * g + plane.gamma * h) / ( norm1 * norm2 );
    angle = pi/2 - acos(cosine);
end


function p = FitPlaneTo3Ddata(x,y,z)
    % z = x * C(1) + y*C(2) + C(3);
    % c(1) * x + c(2) * y + (-1)  * z + c(3) = 0
    % alpha* x + beta * y + gamma * z + delta = 0

    xx = x(:);
    yy = y(:);
    zz = z(:);
    N = length(xx);
    O = ones(N,1);

    C = [xx yy O]\zz;
    p.alpha = C(1);
    p.beta = C(2);
    p.gamma = -1;
    p.delta = C(3);
    
    lengthV = sqrt(p.alpha^2 + p.beta^2 + p.gamma^2);
    p.alpha = p.alpha/lengthV;
    p.beta = p.beta/lengthV;
    p.gamma = p.gamma/lengthV;
    p.delta = p.delta/lengthV;
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
