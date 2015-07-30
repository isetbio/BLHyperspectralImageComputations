function estimateClusters

    figNum = 1000;
    for argVal = 0.1:0.1:1.0
        for cVal = 0.1:0.1:1.0
            estimateClusters2(figNum,argVal, cVal);
            figNum = figNum + 1;
        end
    end
    
end


function estimateClusters2(figNum, argVal, cVal)

    if (nargin == 0)
        argVal = 0.5;
        cVal = 0.1;
    end
    
    sceneName = 'scene3';
    load(sprintf('%s_results.mat',sceneName));

    coneXYLocations = sensorGet(sensor, 'xy');
    coneTypes = sensorGet(sensor, 'cone type');
    
    
    figure(99)
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
        
    data.X = MDSprojection';
    data.X = 2.5 * data.X / max(abs(data.X(:)));
    
    figure(100);
    clf;
    subplot(2,2,1);
    plot(data.X(1,:), data.X(2,:), 'k.');
    title('1-2');
    
    subplot(2,2,2)
    plot(data.X(1,:), data.X(3,:), 'k.');
    title('1-3');
    
    subplot(2,2,3)
    plot(data.X(2,:), data.X(3,:), 'k.');
    title('2-3');
    drawnow;
    
    % add path to SVC toolbox
    addpath(genpath('/Users/nicolas/Documents/1.Code/0.BitBucketPrivateRepos/svmtoolbox/SVC/Lee_SVC_toolbox'));
    
    options=struct('method','CG','ker','rbf','arg',0.5,'C',0.1);
    numberOfDesiredClusters = 3;
    options = struct('method','E-SVC','ker','rbf','arg',argVal,'C',cVal, 'NofK', numberOfDesiredClusters);
    
    
    try
        [model]=svc(data,options); 
    
    
        plotsvc(data,model);

        cone1_indices = find(model.cluster_labels == 2);
        cone2_indices = find(model.cluster_labels == 1);
        cone3_indices = find(model.cluster_labels == 3);

        h = figure(figNum);
        set(h, 'Name', sprintf('argVal: %2.2f cVal: %2.2f', argVal, cVal));
        clf;
        subplot(2,2,1);
        hold on
        plot(data.X(1,cone1_indices), data.X(2,cone1_indices), 'bo');
        plot(data.X(1,cone2_indices), data.X(2,cone2_indices), 'ro');
        plot(data.X(1,cone3_indices), data.X(2,cone3_indices), 'go');
        hold off
        axis 'equal'
        title('1-2');

        subplot(2,2,2)
        hold on
        plot(data.X(1,cone1_indices), data.X(3,cone1_indices), 'bo');
        plot(data.X(1,cone2_indices), data.X(3,cone2_indices), 'ro');
        plot(data.X(1,cone3_indices), data.X(3,cone3_indices), 'go');
        hold off
        axis 'equal'
        title('1-3');

        subplot(2,2,3)
        hold on
        plot(data.X(2,cone1_indices), data.X(3,cone1_indices), 'bo');
        plot(data.X(2,cone2_indices), data.X(3,cone2_indices), 'ro');
        plot(data.X(2,cone3_indices), data.X(3,cone3_indices), 'go');
        axis 'equal'
        title('2-3');
        drawnow;
    
    catch
        fprintf('Failed for %f %f\n', argVal, cVal);
        
    end
    
    
end

