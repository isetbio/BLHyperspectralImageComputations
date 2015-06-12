% Method to estimate the identity of each cone by analysis of their responses to a set of stimuli
function estimateReceptorIdentities(obj, varargin)

    [coneRows coneCols timeBins] = size(obj.sensorActivationImage);
    totalConesNum = coneRows * coneCols;
    
    % compute distances between all cones
    coneXYLocations = sensorGet(obj.sensor, 'xy');
    coneTypes = sensorGet(obj.sensor, 'cone type');

    % Just for testing. Reconstruct the mosaic from the pair-wise distances of the cones
    
    % compute pair-wide distance matrix
    D = squareform(pdist(coneXYLocations, 'euclidean'));

    % Compute a 2-D embedding
    dimensionsNum = 2;
    [Y,stress] = mdscale(D,dimensionsNum);
    
    figure(2);
    clf;
    
    subplot(1,2,1);
    hold on;
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('X - position');
    ylabel('Y - position');
    axis 'square'
    title('Original mosaic');
    
    subplot(1,2,2);
    hold on;
    for k = 1:size(Y,1)
        if (coneTypes(k) == 2)
            plot(Y(k,1),Y(k,2), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(Y(k,1),Y(k,2), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(Y(k,1),Y(k,2), 'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('X - position');
    ylabel('Y - position');
    axis 'square'
    title('reconstructed mosaic from cone distances');
    
    
    
    % Step1. Compute the pairwise linear correlation matrix (totelConesNum x totelConesNum) 
    % for each pair of columns in the [timeBins * totelConesNum] response matrix X
    
    XTresponse = reshape(obj.sensorActivationImage, [totalConesNum timeBins]);
    correlationMatrix = corr(XTresponse');
    % extract a metric of distance from the correlation matrix
    % the higher the correlation, the lower the distance
    D = -log((correlationMatrix+1.0)/2.0);  % Benson's distance  metric from correlation
    D = 1.0 - (correlationMatrix+1.0)/2.0;  % My (linear) distance metric from correlation
    
    figure(3);
    clf;
    
    subplot(1,2,1);
    imagesc(D);
    set(gca, 'CLim', [0 1]);
    axis 'image'
    colormap(jet(512))
    title('distance matrix, D=-log((C+1)/2)');
    colorbar
    
    subplot(1,2,2);
    imagesc(correlationMatrix);
    set(gca, 'CLim', [-1 1]);
    axis 'image'
    colormap(jet(512))
    title('correlation matrix, C');
    colorbar
    
    fprintf('Computing MDS on correlation matrix');
    tic
    
    
    
    dimensionsNum = 3;
    [Y,stress] = mdscale(D,dimensionsNum);
    toc;
    
    figure(4);
    clf;
    hold on;
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            scatter3(Y(k,1), Y(k,2), Y(k,3), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            scatter3(Y(k,1), Y(k,2), Y(k,3), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            scatter3(Y(k,1), Y(k,2), Y(k,3),  'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('dimension 1');
    ylabel('dimension 2');
    zlabel('dimension 3');
    axis 'square'
    box on;
    view([-65 10]);
    
    drawnow;
    title('3D-MDS');
    

    figure(5);
    clf;
    subplot(2,2,1);
    hold on
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(coneXYLocations(k,1), coneXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('X - position');
    ylabel('Y - position');
    axis 'square'
    box on
    title('Original mosaic');
    
    
    subplot(2,2,2);
    hold on
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            plot(Y(k,1), Y(k,2), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(Y(k,1), Y(k,2), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(Y(k,1), Y(k,2),  'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('dimension 1');
    ylabel('dimension 2');
    axis 'square';
    box on
    
    subplot(2,2,3);
    hold on
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            plot(Y(k,1), Y(k,3), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(Y(k,1), Y(k,3), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(Y(k,1), Y(k,3),  'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('dimension 1');
    ylabel('dimension 3');
    axis 'square';
    box on
    
    subplot(2,2,4);
    hold on
    for k = 1:size(coneXYLocations,1)
        if (coneTypes(k) == 2)
            plot(Y(k,2), Y(k,3), 'rs', 'MarkerFaceColor', 'r');
        elseif (coneTypes(k) == 3)
            plot(Y(k,2), Y(k,3), 'gs', 'MarkerFaceColor', 'g');
        elseif (coneTypes(k) == 4)
            plot(Y(k,2), Y(k,3),  'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('dimension 2');
    ylabel('dimension 3');
    axis 'square';
    box on
    drawnow;
end

