function displayConeMosaicLearningProgress(obj, performanceAxes1, performanceAxes2)

    if (isfield(obj.coneMosaicLearningProgress, 'fixationsNum'))
        plot(performanceAxes1, obj.coneMosaicLearningProgress.fixationsNum, 1-obj.coneMosaicLearningProgress.correctlyIdentifiedLMcones, 'y-', 'LineWidth', 2.0);
        hold(performanceAxes1,'on')
        plot(performanceAxes1, obj.coneMosaicLearningProgress.fixationsNum, 1-obj.coneMosaicLearningProgress.correctlyIdentifiedScones, '-', 'Color', [0 0.6 1.0], 'LineWidth', 2.0);
        hold(performanceAxes1,'off')
        set(performanceAxes1, 'Color', [0 0 0], 'XColor', [0 0 0], 'YColor', [1 1 1]);
        set(performanceAxes1, 'XLim', [0 max([10 obj.coneMosaicLearningProgress.fixationsNum])], ...
                              'YLim', [0.001 1.0], 'YScale', 'log', 'XTickLabel', {}, 'YTickLabel', {});
        ylabel(performanceAxes1, 'type error', 'FontSize', 16);
        hLeg = legend(performanceAxes1, 'L/M', 'S');
        set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'northeast');
        box(performanceAxes1, 'off'); 
        grid(performanceAxes1, 'on');

        plot(performanceAxes2, obj.coneMosaicLearningProgress.fixationsNum, obj.coneMosaicLearningProgress.meanDistanceLMmosaic, 'y-', 'LineWidth', 2.0);
        hold(performanceAxes2,'on')
        plot(performanceAxes2, obj.coneMosaicLearningProgress.fixationsNum, obj.coneMosaicLearningProgress.meanDistanceSmosaic, '-', 'Color', [0 0.6 1.0], 'LineWidth', 2.0);
        hold(performanceAxes2,'off')
        set(performanceAxes2, 'Color', [0 0 0], 'XColor', [0 0 0], 'YColor', [1 1 1]);
        set(performanceAxes2, 'XLim', [0 max([10 max(obj.coneMosaicLearningProgress.fixationsNum)])], ...
                              'YLim', [0.01 max([max(obj.coneMosaicLearningProgress.meanDistanceLMmosaic) max(obj.coneMosaicLearningProgress.meanDistanceSmosaic)])], ...
                              'YScale', 'log', ...
                              'XTickLabel', {}, 'YTickLabel', {});
        ylabel(performanceAxes2, 'positional error', 'FontSize', 16);
        hLeg = legend(performanceAxes2, 'L/M', 'S');
        set(hLeg, 'Color', [0.3 0.3 0.3], 'FontSize', 14, 'TextColor',[1 1 1], 'Location', 'northeast');
        box(performanceAxes2, 'off'); 
        grid(performanceAxes2, 'on');
    end
end

