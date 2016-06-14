function makePerformanceFigure(sceneSetName, decodingDataDir)

    
    [cTrainInput, cTrainReconstructionPINV, cTrainReconstructionSVD, varianceExplained, includedComponentsNum, XtrainRank] = ...
        visualizer.retrievePerformanceDataFull(sceneSetName, decodingDataDir, 'inSamplePrediction');
    
    inSamplePINVrms = sqrt(mean((cTrainInput-cTrainReconstructionPINV).^2, 2));
    for k = 1:numel(includedComponentsNum)
        inSampleSVDrms(k,:,:) = sqrt(mean((cTrainInput-squeeze(cTrainReconstructionSVD(k,:,:))).^2, 2));
    end
    
    [cTestInput, cTestReconstructionPINV, cTestReconstructionSVD, varianceExplained, ~,~] = ...
        visualizer.retrievePerformanceDataFull(sceneSetName, decodingDataDir, 'outOfSamplePrediction');
    
    outOfSamplePINVrms = sqrt(mean((cTestInput-cTestReconstructionPINV).^2, 2));
    for k = 1:numel(includedComponentsNum)
        outOfSampleSVDrms(k,:,:) = sqrt(mean((cTestInput-squeeze(cTestReconstructionSVD(k,:,:))).^2, 2));
    end
    
    minOutOfSampleErrorLdecoder = min(min(min(outOfSampleSVDrms(:,1,:))))
    minOutOfSampleErrorMdecoder = min(min(min(outOfSampleSVDrms(:,2,:))))
    minOutOfSampleErrorSdecoder = min(min(min(outOfSampleSVDrms(:,3,:))))
    pause
    
    minComponentIndex = 3;
    maxError = max([ ...
        max(max(inSampleSVDrms(minComponentIndex :end,:))) ...
        max(inSamplePINVrms(:)) ...
        max(max(outOfSampleSVDrms(minComponentIndex :end,:))) ...
        max(outOfSamplePINVrms(:)) ...
        ])
    
   
    
     % Generate colors for L,M,S contrast traces
    LconeContrastColor = [255 170 190]/255;
    MconeContrastColor = [120 255 224]/255;
    SconeContrastColor = [170 180 255]/255;
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 6, ...
               'heightMargin',   0.002, ...
               'widthMargin',    0.01, ...
               'leftMargin',     0.04, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.10, ...
               'topMargin',      0.01);
           
           
    coneNames = {'Lcone', 'Mcone', 'Scone'};
    
    for decodedContrastIndex = 1:numel(coneNames)
        
        hFig = figure(20+decodedContrastIndex); clf;
        set(hFig, 'Color', [1 1 1], 'Position', [100 100 1920 1080], 'MenuBar', 'none');

       % errorRange = [0.06 0.6];  % @osLinear, noise-free
        errorRange = [0.1 0.6];   % osLinear, noise
       % errorRange = [0.2 0.6];   % osIdentity, no-noise
        
    %     if (strcmp(osType, '@osBiophys'))
    %         if (decodedContrastIndex == 3)
    %             errorRange = [0.20 0.6];
    %         else
    %             errorRange = [0.20 0.6];
    %         end
    %     elseif (strcmp(osType, '@osLinear'))
    %         if (decodedContrastIndex == 3)
    %             errorRange = [0.2 0.50];
    %         else
    %             errorRange = [0.12 0.40];
    %         end
    %     end

        errorTicks = round(logspace(log10(errorRange(1)), log10(errorRange(2)),5)*100)/100;
        contrastRange = [-2 5];
        contrastTicks = -1:5;
    
    
        pos = subplotPosVectors(1,1).v;
        subplot('Position', [pos(1) pos(2) 0.95 pos(4)]);
        plot(includedComponentsNum(minComponentIndex :end), inSampleSVDrms(minComponentIndex :end, decodedContrastIndex), 'ro-', 'MarkerSize', 14, 'MarkerFaceColor', [1 0.5 0.5], 'MarkerEdgeColor', [1 0 0], 'LineWidth', 3.0);
        hold on;
        plot(includedComponentsNum(minComponentIndex :end), outOfSampleSVDrms(minComponentIndex :end, decodedContrastIndex), 'bo-', 'MarkerSize', 14, 'MarkerFaceColor', [0.5 0.5 1.0], 'MarkerEdgeColor', [0 0 1], 'LineWidth', 3.0);
        plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [inSamplePINVrms(decodedContrastIndex) inSamplePINVrms(decodedContrastIndex)], 'r--', 'LineWidth', 3.0);
        plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [outOfSamplePINVrms(decodedContrastIndex) outOfSamplePINVrms(decodedContrastIndex)], 'b--', 'LineWidth', 3.0);

        box off; grid on;
        set(gca, 'XScale', 'log', 'Yscale', 'log', 'XLim', [1 includedComponentsNum(end)], 'XTick', [1 3 10 30 100 300 1000 3000 10000 30000], 'YLim', errorRange, 'YTick', errorTicks );
        set(gca, 'FontSize', 16, 'FontName', 'Menlo', 'LineWidth', 1.5);
        xlabel('# of SVD vectors', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
        ylabel('RMS residual', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
        hL = legend({'in-sample (SVD)', 'out-of-sample (SVD)', 'in-sample (PINV)', 'out-of-sample (PINV)'}, 'Location', 'SouthWest');
        set(hL, 'FontName', 'Menlo', 'FontSize', 16); 
   
    
        dy = -0.07;
        subplot('Position', subplotPosVectors(2,1).v + [0 dy 0 0]);
        plot(cTrainInput(decodedContrastIndex,:), cTrainReconstructionPINV(decodedContrastIndex,:), 'r.');
        hold on
        plot(contrastRange, contrastRange, 'k-');
        plot(contrastRange, contrastRange*0, 'k-');
        plot(contrastRange*0, contrastRange, 'k-');
        hold off;
        box off; grid on
        text(2.0,-1.5, sprintf('RMS: %2.4f', inSamplePINVrms(decodedContrastIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
        set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'XTickLabel', {}, 'YTick', contrastTicks, 'FontSize', 16, 'FontName', 'Menlo');
        axis 'square';
        ylabel('reconstructed contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
        title('PINV', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
        subplot('Position', subplotPosVectors(3,1).v + [0 dy 0 0]);
        plot(cTestInput(decodedContrastIndex,:), cTestReconstructionPINV(decodedContrastIndex,:), 'b.');
        hold on
        plot(contrastRange, contrastRange, 'k-');
        plot(contrastRange, contrastRange*0, 'k-');
        plot(contrastRange*0, contrastRange, 'k-');
        hold off
        box off; grid on;
        text(2.0,-1.5, sprintf('RMS: %2.4f', outOfSamplePINVrms(decodedContrastIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
        set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'FontSize', 16, 'FontName', 'Menlo');
        axis 'square';
        xlabel('scene contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
        ylabel('reconstructed contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    
        selectedSVDindices = [9 12 17 18 19];
        for svdIter = 1:numel(selectedSVDindices)
            svdIndex = selectedSVDindices(svdIter);

            subplot('Position', subplotPosVectors(2,1+svdIter).v + [0 dy 0 0]);
            plot(squeeze(cTrainInput(decodedContrastIndex,:)), squeeze(cTrainReconstructionSVD(svdIndex,decodedContrastIndex,:)), 'r.');
            hold on
            plot(contrastRange, contrastRange, 'k-');
            plot(contrastRange, contrastRange*0, 'k-');
            plot(contrastRange*0, contrastRange, 'k-');
            hold off
            box off; grid on
            text(2.0,-1.5, sprintf('RMS: %2.4f', inSampleSVDrms(svdIndex,decodedContrastIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
            set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'XTickLabel', {}, 'YTickLabel', {}, 'FontSize', 16, 'FontName', 'Menlo');
            axis 'square';
            title(sprintf('%d SVD vectors (%2.3f%%)', includedComponentsNum(svdIndex), varianceExplained(svdIndex)), 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');

            subplot('Position', subplotPosVectors(3,1+svdIter).v + [0 dy 0 0]);
            plot(squeeze(cTestInput(decodedContrastIndex,:)), squeeze(cTestReconstructionSVD(svdIndex,decodedContrastIndex,:)), 'b.');
            hold on
            plot(contrastRange, contrastRange, 'k-');
            plot(contrastRange, contrastRange*0, 'k-');
            plot(contrastRange*0, contrastRange, 'k-');
            hold off
            box off; grid on
             text(2.0,-1.5, sprintf('RMS: %2.4f', outOfSampleSVDrms(svdIndex,decodedContrastIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
            set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'YTickLabel', {}, 'FontSize', 16, 'FontName', 'Menlo');
            axis 'square';
            xlabel('scene contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
        end
    
        drawnow;
        imageFileName = fullfile(decodingDataDir, sprintf('Performance_%s', coneNames{decodedContrastIndex}));
        fprintf(2, 'Figure saved in %s\n', imageFileName);
        NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
   
    end % decodedContrastIndex
    
    return;
    
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 100 1350 560]);
    
    subplot(1,2,1);
    plot(includedComponentsNum(minComponentIndex :end), inSampleSVDrms(minComponentIndex :end, 1), 'ro-', 'MarkerSize', 14, 'MarkerFaceColor', LconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    hold on;
    plot(includedComponentsNum(minComponentIndex :end), inSampleSVDrms(minComponentIndex :end, 2), 'go-', 'MarkerSize', 14, 'MarkerFaceColor', MconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    plot(includedComponentsNum(minComponentIndex :end), inSampleSVDrms(minComponentIndex :end, 3), 'bo-', 'MarkerSize', 14, 'MarkerFaceColor', SconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [inSamplePINVrms(1) inSamplePINVrms(1)], 'k--', 'Color', LconeContrastColor, 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [inSamplePINVrms(2) inSamplePINVrms(2)], 'k--', 'Color', MconeContrastColor, 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [inSamplePINVrms(3) inSamplePINVrms(3)], 'k--', 'Color', SconeContrastColor, 'LineWidth', 3.0);
    
    box off; grid on;
    set(gca, 'XScale', 'log', 'XLim', [1 includedComponentsNum(end)], 'XTick', [1 3 10 30 100 300 1000 3000 10000 30000], 'YLim', [0 min([1.0 maxError])], 'YTick', [0:0.1:1.0] );
    set(gca, 'FontSize', 16, 'FontName', 'Menlo', 'LineWidth', 1.5);
    xlabel('# of SVD vectors', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    ylabel('RMS residual', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    title('In-Sample', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    subplot(1,2,2);
    plot(includedComponentsNum(minComponentIndex :end), outOfSampleSVDrms(minComponentIndex :end, 1), 'ro-', 'MarkerSize', 14, 'MarkerFaceColor', LconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    hold on;
    plot(includedComponentsNum(minComponentIndex :end), outOfSampleSVDrms(minComponentIndex :end, 2), 'go-', 'MarkerSize', 14, 'MarkerFaceColor', MconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    plot(includedComponentsNum(minComponentIndex :end), outOfSampleSVDrms(minComponentIndex :end, 3), 'bo-', 'MarkerSize', 14, 'MarkerFaceColor', SconeContrastColor, 'MarkerEdgeColor', [0 0 0], 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [outOfSamplePINVrms(1) outOfSamplePINVrms(1)], 'k--', 'Color', LconeContrastColor, 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [outOfSamplePINVrms(2) outOfSamplePINVrms(2)], 'k--', 'Color', MconeContrastColor, 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [outOfSamplePINVrms(3) outOfSamplePINVrms(3)], 'k--', 'Color', SconeContrastColor, 'LineWidth', 3.0);
    
    box off; grid on;
    set(gca, 'XScale', 'log', 'XLim', [1 includedComponentsNum(end)], 'XTick', [1 3 10 30 100 300 1000 3000 10000 30000], 'YLim', [0 min([1.0 maxError])], 'YTick', [0:0.1:1.0] );
    set(gca, 'FontSize', 16, 'FontName', 'Menlo', 'LineWidth', 1.5);
    xlabel('# of SVD vectors', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    ylabel('RMS residual', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    title('Out-of-Sample', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    drawnow
end

