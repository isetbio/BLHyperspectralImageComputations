function estimateClusters(varargin)

    if (nargin == 0)
        startup();
        
        [rootPath,~] = fileparts(which(mfilename));
        cd(rootPath); cd ..; cd 'Toolbox';
        addpath(genpath(pwd));
        cd(rootPath);
    
        load('results_20x20.mat');

        aggregateXTresponse = [];
        for sceneIndex = 1:numel(allSceneNames)
            % aggregate across all scenes
            XTresponse = XTresponses{currentSceneIndex};
            % Critical: Normalize XTresponse for each scene
            aggregateXTresponse = [aggregateXTresponse XTresponse/max(abs(XTresponse(:)))];
        end
        
        % compute MDS projection
        MDSprojection = ISETbioSceneProcessor.estimateReceptorIdentities(aggregateXTresponse, 'demoMode', false, 'selectTimeBins', []);
    
    
%         correlationMatrix = corrcoef(aggreggateXTresponse');
%         %D = -log((correlationMatrix+1.0)/2.0);
%         D = 1.0 - (correlationMatrix+1.0)/2.0; 
%         
%         if ~issymmetric(D)
%             D = 0.5*(D+D');
%         end
%         dimensionsNum = 3;
%         [MDSprojection,stress] = mdscale(D,dimensionsNum);
    
    else
        aggregateXTresponse = varargin{1};
        trueConeXYLocations = varargin{2};
        trueConeTypes = varargin{3};
        MDSprojection = ISETbioSceneProcessor.estimateReceptorIdentities(aggregateXTresponse, 'demoMode', false, 'selectTimeBins', []);
    end
    
    
    % scale MDS projection to match the scale of the cone mosaic 
    d1 = squeeze(MDSprojection(:,2)); % x
    d2 = squeeze(MDSprojection(:,3)); % y
    MDSprojection = MDSprojection * max(abs(squeeze(trueConeXYLocations(:,1))))/max([max(abs(d1)) max(abs(d2))]);
    
    indices1 = find(trueConeTypes == 2);
    indices2 = find(trueConeTypes == 3);
    indices3 = find(trueConeTypes == 4);
    
    h = figure(999);
    set(h, 'Position', [10 10 720 442]); % 1520 700]);
    clf;
   % subplot(2,2,1); 
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
    
        set(gca, 'FontSize', 12);
        
    box on; grid on; view([170 54]);
    
    
    if (1==2)
    subplot(2,2,2); hold on
    scatter3(MDSprojection(indices1,2), ...
            MDSprojection(indices1,3), ...
            MDSprojection(indices1,1), ...
            'filled', 'MarkerFaceColor',[1 0 0]);
        
     scatter3(MDSprojection(indices2,2), ...
            MDSprojection(indices2,3), ...
            MDSprojection(indices2,1), ...
            'filled', 'MarkerFaceColor',[0 1 0]);
        
    scatter3(MDSprojection(indices3,2), ...
            MDSprojection(indices3,3), ...
            MDSprojection(indices3,1), ...
            'filled', 'MarkerFaceColor', [0 0 1]);
    
    box on; grid on; view([-170 50]);
    
    subplot(2,2,3); hold on
    scatter3(MDSprojection(indices1,3), ...
            MDSprojection(indices1,1), ...
            MDSprojection(indices1,2), ...
            'filled', 'MarkerFaceColor',[1 0 0]);
        
     scatter3(MDSprojection(indices2,3), ...
            MDSprojection(indices2,1), ...
            MDSprojection(indices2,2), ...
            'filled', 'MarkerFaceColor',[0 1 0]);
        
    scatter3(MDSprojection(indices3,3), ...
            MDSprojection(indices3,1), ...
            MDSprojection(indices3,2), ...
            'filled', 'MarkerFaceColor', [0 0 1]);
    
    box on; grid on; view([-170 50]);
    end
    
    drawnow;
    pause
    
   % add path to SVC toolbox
   addpath(genpath('/Users/nicolas/Documents/1.Code/0.BitBucketPrivateRepos/svmtoolbox/SVC/Lee_SVC_toolbox'));
   
    
    figNum = 1000;
    argVal = 0.150%  + 0.01*(-2:2)
        cVal = 0.15 %+ 0.01*(-2:2)
            estimateClusters2(figNum,argVal, cVal,MDSprojection, trueConeXYLocations, trueConeTypes);
            figNum = figNum + 1;
        %end
    %end 
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
        
    
    MDSprojection2 = 2.5 * MDSprojection / max(abs(MDSprojection(:)));
    
    dimensionsForClustering = [1 2 3];
    data.X = (MDSprojection2(:,dimensionsForClustering))';
    
   
   
    options = struct('method','E-SVC','ker','rbf','arg',argVal,'C',cVal, 'NofK', numberOfDesiredClusters);
    
    
    try
        [model]=svc(data,options); 
    
    
        %plotsvc(data,model);

        cone1_indices = find(model.cluster_labels == 2)
        cone2_indices = find(model.cluster_labels == 1)
        cone3_indices = find(model.cluster_labels == 3)

        
        h = figure(figNum);
        set(h, 'Name', sprintf('argVal: %2.2f cVal: %2.2f', argVal, cVal));
        clf;
        
        
        subplot(2,2,1);
        hold on
        plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,2), 'go');
        plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,2), 'ro');
        plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,2), 'bo');
        hold off
        set(gca, 'YLim', [-15 15], 'XLim', [-20 100], 'FontSize', 12);
        box 'on'
        ylabel('Y-position', 'FontSize', 14);
        xlabel('Spectral position', 'FontSize', 14);
        title('d1-d2');
        
        
        subplot(2,2,2)
        hold on
        plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,3), 'go');
        plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,3), 'ro');
        plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,3), 'bo');
        hold off;
        set(gca, 'YLim', [-15 15], 'XLim', [-20 100], 'FontSize', 12);
        ylabel('X-position', 'FontSize', 14);
        xlabel('Spectral position', 'FontSize', 14);
        box on
        title('d1-d3');

        subplot(2,2,3)
        hold on
        plot(MDSprojection(cone1_indices,3), MDSprojection(cone1_indices,2), 'go');
        plot(MDSprojection(cone2_indices,3), MDSprojection(cone2_indices,2), 'ro');
        plot(MDSprojection(cone3_indices,3), MDSprojection(cone3_indices,2), 'bo');
        hold off;
        set(gca, 'XLim', [-15 15], 'YLim', [-15 15], 'FontSize', 12);
        xlabel('X - position', 'FontSize', 14);
        ylabel('Y - position', 'FontSize', 14);
        axis 'square'; box on
        title('d3-d2 (Reconstructed mosaic)');
        
        subplot(2,2,4)
        hold on
        for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot([trueConeXYLocations(k,1) MDSprojection(k,3)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,2)], 'r-');
            
        elseif (trueConeTypes(k) == 3)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot([trueConeXYLocations(k,1) MDSprojection(k,3)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,2)], 'g-');
        elseif (trueConeTypes(k) == 4)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot([trueConeXYLocations(k,1) MDSprojection(k,3)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,2)], 'b-');
        end
        end
        set(gca, 'XLim', [-15 15], 'YLim', [-15 15], 'FontSize', 12);
        xlabel('X - position', 'FontSize', 14);
        ylabel('Y - position', 'FontSize', 14);
        axis 'square'; box on
        title('Original mosaic');
        
        
    
%         cone1_indices = find(trueConeTypes == 2);
%         cone2_indices = find(trueConeTypes == 3);
%         cone3_indices = find(trueConeTypes == 4);
%         hold on
%         plot(MDSprojection(cone1_indices,1), MDSprojection(cone1_indices,2), 'ro');
%         plot(MDSprojection(cone2_indices,1), MDSprojection(cone2_indices,2), 'go');
%         plot(MDSprojection(cone3_indices,1), MDSprojection(cone3_indices,2), 'bo');
%         hold off
%         axis 'equal'
%         title('real identities')
    
        drawnow;
        
        figure(234);
        clf;
        hold on
        for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2)
           % plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot(MDSprojection(k,3), MDSprojection(k,2), 'ro');
            
        elseif (trueConeTypes(k) == 3)
           % plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot(MDSprojection(k,3), MDSprojection(k,2), 'go');
        elseif (trueConeTypes(k) == 4)
            %plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot(MDSprojection(k,3), MDSprojection(k,2), 'bo');
        end
        end
        set(gca, 'XLim', [-15 15], 'YLim', [-15 15], 'FontSize', 12);
        xlabel('X - position', 'FontSize', 14);
        ylabel('Y - position', 'FontSize', 14);
        axis 'square'; box on
        title('Original mosaic');
        
    
    catch
        fprintf('Failed for %f %f\n', argVal, cVal);
    end
    
    
end

