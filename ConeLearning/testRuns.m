function testRuns

    adaptationType = 'linearAdaptation';
    noiseType = 'RiekeNoise';
    disparityMetric= 'linearDisparityMetric';
    
    timeConstant = input('Enter time constant, e.g. 125 :');
    temporalFilter = sprintf('monophasicPrecorrFilter_%dmsTimeConstant', timeConstant);
    
    matFile = sprintf('MosaicReconstruction_%s_%s_%s_%s.mat', adaptationType, noiseType, disparityMetric, temporalFilter)
    load(matFile, '-mat')
    
    coneMosaicLearningProgress
    
    h = figure(1);
    set(h, 'Position', [10 10 630 882]);
    clf;
    subplot(3,1,1);
    time = 1:numel(precorrelationFilter);
    plot(time, precorrelationFilter, 'k-');
    title(sprintf('Time constant: %dms', timeConstant));
    xlabel('time (ms)');
    
    subplot(3,1,2);
    LMconeTypeError = 1-coneMosaicLearningProgress.correctlyIdentifiedLMcones;
    SconeTypeError = 1-coneMosaicLearningProgress.correctlyIdentifiedScones;
    plot(coneMosaicLearningProgress.fixationsNum, LMconeTypeError, 'r-');
    hold on;
    plot(coneMosaicLearningProgress.fixationsNum, SconeTypeError, 'b-');
    set(gca, 'YLim', [0 1.05*max([max(LMconeTypeError) max(SconeTypeError)])]);
    set(gca, 'XLim', [1 max(coneMosaicLearningProgress.fixationsNum)], 'Xscale', 'log');
    xlabel('fixations');
    ylabel('receptor type error');
    
    subplot(3,1,3);
    plot(coneMosaicLearningProgress.fixationsNum, coneMosaicLearningProgress.meanDistanceLMmosaic, 'r-');
    hold on;
    plot(coneMosaicLearningProgress.fixationsNum, coneMosaicLearningProgress.meanDistanceSmosaic, 'b-');
    set(gca, 'XLim', [1 max(coneMosaicLearningProgress.fixationsNum)], 'Xscale', 'log');
    xlabel('fixations');
    ylabel('receptor position error');
    drawnow
    
    NicePlot.exportFigToPDF(sprintf('TimeConstant%dms.pdf', timeConstant), h, 300);
end