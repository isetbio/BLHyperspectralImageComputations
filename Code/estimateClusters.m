function estimateClusters(varargin)

    startup();
    
    if (nargin == 0)
        load('results.mat');
        
%         correlationMatrix = corrcoef(XTresponse');
%         %D = -log((correlationMatrix+1.0)/2.0);
%         D = 1.0 - (correlationMatrix+1.0)/2.0; 
%         
%         if ~issymmetric(D)
%             D = 0.5*(D+D');
%         end
%         dimensionsNum = 3;
%         [MDSprojection,stress] = mdscale(D,dimensionsNum);
    
    else
        MDSprojection = varargin{1};
        trueConeXYLocations = varargin{2};
        trueConeTypes = varargin{3};
    end
    
    indices1 = find(trueConeTypes == 2);
    indices2 = find(trueConeTypes == 3);
    indices3 = find(trueConeTypes == 4);
    
    figure(999)
    clf;
    hold on
    scatter3(MDSprojection(indices1,1), ...
            MDSprojection(indices1,2), ...
            MDSprojection(indices1,3), ...
            'filled', 'MarkerFaceColor',[1 0 0]);
        
     scatter3(MDSprojection(indices2,1), ...
            MDSprojection(indices2,2), ...
            MDSprojection(indices2,3), ...
            'filled', 'MarkerFaceColor',[0 1 0]);
        
    scatter3(MDSprojection(indices3,1), ...
            MDSprojection(indices3,2), ...
            MDSprojection(indices3,3), ...
            'filled', 'MarkerFaceColor', [0 0 1]);
    
    drawnow;

   % add path to SVC toolbox
   addpath(genpath('/Users/nicolas/Documents/1.Code/0.BitBucketPrivateRepos/svmtoolbox/SVC/Lee_SVC_toolbox'));
   
    
    figNum = 1000;
    for argVal = 0.160 + 0.01*(-2:2)
        for cVal = 0.15:0.15
            estimateClusters2(figNum,argVal, cVal,MDSprojection, trueConeXYLocations, trueConeTypes);
            figNum = figNum + 1;
        end
    end
    
end


function estimateClusters2(figNum, argVal, cVal,MDSprojection, trueConeXYLocations, trueConeTypes)

    if (nargin == 0)
        argVal = 0.5;
        cVal = 0.1;
    end
    
    numberOfDesiredClusters = 3;
     
    figure(99)
    hold on;
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
        elseif (trueConeTypes(k) == 3)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
        elseif (trueConeTypes(k) == 4)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
        end
    end
    xlabel('X - position');
    ylabel('Y - position');
    axis 'square'
    title('Original mosaic');
        
    
    MDSprojection = 2.5 * MDSprojection / max(abs(MDSprojection(:)));
    
    dimensionsForClustering = [1 2 3];
    data.X = (MDSprojection(:,dimensionsForClustering))';
    
   
   
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
        plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,2), 'go');
        plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,2), 'ro');
        plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,2), 'bo');
        hold off
        axis 'equal'
        title('1-2');

        subplot(2,2,2)
        hold on
        plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,3), 'go');
        plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,3), 'ro');
        plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,3), 'bo');
        hold off
        axis 'equal'
        title('1-3');

        subplot(2,2,3)
        hold on
        plot(MDSprojection(cone1_indices,2), MDSprojection(cone1_indices,3), 'go');
        plot(MDSprojection(cone2_indices,2), MDSprojection(cone2_indices,3), 'ro');
        plot(MDSprojection(cone3_indices,2), MDSprojection(cone3_indices,3), 'bo');
        axis 'equal'
        title('2-3');
        
        subplot(2,2,4)
        cone1_indices = find(trueConeTypes == 2);
        cone2_indices = find(trueConeTypes == 3);
        cone3_indices = find(trueConeTypes == 4);
        hold on
        plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,2), 'ro');
        plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,2), 'go');
        plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,2), 'bo');
        hold off
        axis 'equal'
        title('real identities')
    
    
    
        drawnow;
    
    catch
        fprintf('Failed for %f %f\n', argVal, cVal);
        
    end
    
    
end

