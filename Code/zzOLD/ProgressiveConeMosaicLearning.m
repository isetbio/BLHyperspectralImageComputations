function ProgressiveConeMosaicLearning

    load('results_10x10.mat');
    whos
    fullCorrelationMatrix = corrcoef(aggregateXTresponse(1:20,:)');
    
    % compute gradually-learned correlation matrix
    totalTimeBins = size(aggregateXTresponse,2);
    memoryTimeBins = 100;
    currentTimeBin = memoryTimeBins;
    
    h = figure(1);
    set(h, 'Position', [20 40 1200 860]);
    clf;
    subplot(2,2,1);
    imagesc(fullCorrelationMatrix);
    set(gca, 'CLim', [0 1]);
    axis 'square';
    colormap(gray);
    
    alpha = 0.8;
    
    timeSeries = [];
    timeSeries2 = [];
    
    for timeBin = currentTimeBin:totalTimeBins
        recentTimeBins = timeBin-memoryTimeBins+1:timeBin;
        allTimeBinsToNow = 1:timeBin;
        currentCorrelationMatrix = corrcoef(aggregateXTresponse(1:20,recentTimeBins)');
        currentFullCorrelationMatrix = corrcoef(aggregateXTresponse(1:20,allTimeBinsToNow)');
        
        if (timeBin == currentTimeBin)
            learnedCorrelationMatrix = currentCorrelationMatrix;
        else
            learnedCorrelationMatrix = alpha*learnedCorrelationMatrix + (1-alpha)*currentCorrelationMatrix;
        end
        
        timeSeries = [timeSeries learnedCorrelationMatrix(1,2)];
        timeSeries2 = [timeSeries2 currentFullCorrelationMatrix(1,2)];
        
        subplot(2,2,2);
        imagesc(learnedCorrelationMatrix);
        set(gca, 'CLim', [0 1]);
        axis 'square';
        colormap(gray);
        
        subplot(2,2,[3 4]);
        plot([1:numel(timeSeries)], timeSeries, 'r-');
        hold on;
        plot([1:numel(timeSeries2)], timeSeries2, 'b-');
        plot([1:numel(timeSeries)], fullCorrelationMatrix(1,2)*ones(1,numel(timeSeries)), 'k-');
        hold off;
         set(gca, 'YLim', [0 1]);
         
        drawnow
    end
    
    
    Dfull    = -log((fullCorrelationMatrix+1.0)/2.0);
    Dlearned = -log((learnedCorrelationMatrix+1.0)/2.0);
    
    if ~issymmetric(Dfull)
        Dfull = 0.5*(Dfull+Dfull');
    end

    if ~issymmetric(Dlearned)
        Dfull = 0.5*(Dlearned+Dlearned');
    end
    
    dimensionsNum = 3;
	[MDSprojectionFull,stressFull]       = mdscale(Dfull,dimensionsNum);
    [MDSprojectionLearned,stressLearned] = mdscale(Dlearned,dimensionsNum);

    PlotMDSprojection(MDSprojectionFull, trueConeTypes,100, 'Full');
    PlotMDSprojection(MDSprojectionLearned, trueConeTypes,200, 'Learned');
end

function PlotMDSprojection(MDSprojection, trueConeTypes, figNo, figTitle)

    indices1 = find(trueConeTypes == 2);
    indices2 = find(trueConeTypes == 3);
    indices3 = find(trueConeTypes == 4);
    
    h = figure(figNo);
    set(h, 'Position', [10 10 1520 700], 'Name', figTitle);
    clf;
    subplot(2,2,1); hold on
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
    
    box on; grid on; view([-170 50]);
    
    
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
    
    drawnow;

end
