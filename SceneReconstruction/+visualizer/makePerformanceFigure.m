function makePerformanceFigure(sceneSetName, decodingDataDir)

    
    [cTrainInput, cTrainReconstructionPINV, cTrainReconstructionSVD, varianceExplained, includedComponentsNum, XtrainRank] = ...
        retrievePerformanceData(sceneSetName, decodingDataDir, 'inSamplePrediction');
    
    inSamplePINVrms = sqrt(mean((cTrainInput-cTrainReconstructionPINV).^2, 2));
    for k = 1:numel(includedComponentsNum)
        inSampleSVDrms(k,:,:) = sqrt(mean((cTrainInput-squeeze(cTrainReconstructionSVD(k,:,:))).^2, 2));
    end
    
    [cTestInput, cTestReconstructionPINV, cTestReconstructionSVD, varianceExplained, ~,~] = ...
        retrievePerformanceData(sceneSetName, decodingDataDir, 'outOfSamplePrediction');
    
    outOfSamplePINVrms = sqrt(mean((cTestInput-cTestReconstructionPINV).^2, 2));
    for k = 1:numel(includedComponentsNum)
        outOfSampleSVDrms(k,:,:) = sqrt(mean((cTestInput-squeeze(cTestReconstructionSVD(k,:,:))).^2, 2));
    end
    
    
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
           
           
    for coneIndex = 1:3         
    hFig = figure(20+coneIndex); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 100 1920 1080], 'MenuBar', 'none');
    
    errorRange = [0.1 0.6];
    
%     if (strcmp(osType, '@osBiophys'))
%         if (coneIndex == 3)
%             errorRange = [0.20 0.6];
%         else
%             errorRange = [0.20 0.6];
%         end
%     elseif (strcmp(osType, '@osLinear'))
%         if (coneIndex == 3)
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
    plot(includedComponentsNum(minComponentIndex :end), inSampleSVDrms(minComponentIndex :end, coneIndex), 'ro-', 'MarkerSize', 14, 'MarkerFaceColor', [1 0.5 0.5], 'MarkerEdgeColor', [1 0 0], 'LineWidth', 3.0);
    hold on;
    plot(includedComponentsNum(minComponentIndex :end), outOfSampleSVDrms(minComponentIndex :end, coneIndex), 'bo-', 'MarkerSize', 14, 'MarkerFaceColor', [0.5 0.5 1.0], 'MarkerEdgeColor', [0 0 1], 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [inSamplePINVrms(coneIndex) inSamplePINVrms(coneIndex)], 'r--', 'LineWidth', 3.0);
    plot([includedComponentsNum(minComponentIndex) includedComponentsNum(end)], [outOfSamplePINVrms(coneIndex) outOfSamplePINVrms(coneIndex)], 'b--', 'LineWidth', 3.0);
    
    box off; grid on;
    set(gca, 'XScale', 'log', 'Yscale', 'log', 'XLim', [1 includedComponentsNum(end)], 'XTick', [1 3 10 30 100 300 1000 3000 10000 30000], 'YLim', errorRange, 'YTick', errorTicks );
    set(gca, 'FontSize', 16, 'FontName', 'Menlo', 'LineWidth', 1.5);
    xlabel('# of singular vectors', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    ylabel('RMS residual', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    hL = legend({'in-sample (SVD)', 'out-of-sample (SVD)', 'in-sample (PINV)', 'out-of-sample (PINV)'}, 'Location', 'SouthWest');
    set(hL, 'FontName', 'Menlo', 'FontSize', 16); 
   
    
    dy = -0.07;
    subplot('Position', subplotPosVectors(2,1).v + [0 dy 0 0]);
    plot(cTrainInput(coneIndex,:), cTrainReconstructionPINV(coneIndex,:), 'r.');
    hold on
    plot(contrastRange, contrastRange, 'k-');
    plot(contrastRange, contrastRange*0, 'k-');
    plot(contrastRange*0, contrastRange, 'k-');
    hold off;
    box off; grid on
    text(2.0,-1.5, sprintf('RMS: %2.4f', inSamplePINVrms(coneIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
    set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'XTickLabel', {}, 'YTick', contrastTicks, 'FontSize', 16, 'FontName', 'Menlo');
    axis 'square';
    ylabel('reconstructed contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    title('PINV', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    subplot('Position', subplotPosVectors(3,1).v + [0 dy 0 0]);
    plot(cTestInput(coneIndex,:), cTestReconstructionPINV(coneIndex,:), 'b.');
    hold on
    plot(contrastRange, contrastRange, 'k-');
    plot(contrastRange, contrastRange*0, 'k-');
    plot(contrastRange*0, contrastRange, 'k-');
    hold off
    box off; grid on;
    text(2.0,-1.5, sprintf('RMS: %2.4f', outOfSamplePINVrms(coneIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
    set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'FontSize', 16, 'FontName', 'Menlo');
    axis 'square';
    xlabel('scene contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    ylabel('reconstructed contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    
    selectedSVDindices = [9 11 12 17 19];
    for svdIter = 1:numel(selectedSVDindices)
        svdIndex = selectedSVDindices(svdIter);
        
        subplot('Position', subplotPosVectors(2,1+svdIter).v + [0 dy 0 0]);
        plot(squeeze(cTrainInput(coneIndex,:)), squeeze(cTrainReconstructionSVD(svdIndex,coneIndex,:)), 'r.');
        hold on
        plot(contrastRange, contrastRange, 'k-');
        plot(contrastRange, contrastRange*0, 'k-');
        plot(contrastRange*0, contrastRange, 'k-');
        hold off
        box off; grid on
        text(2.0,-1.5, sprintf('RMS: %2.4f', inSampleSVDrms(svdIndex,coneIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
        set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'XTickLabel', {}, 'YTickLabel', {}, 'FontSize', 16, 'FontName', 'Menlo');
        axis 'square';
        title(sprintf('%d SVD vectors (%2.3f%%)', includedComponentsNum(svdIndex), varianceExplained(svdIndex)), 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
        subplot('Position', subplotPosVectors(3,1+svdIter).v + [0 dy 0 0]);
        plot(squeeze(cTestInput(coneIndex,:)), squeeze(cTestReconstructionSVD(svdIndex,coneIndex,:)), 'b.');
        hold on
        plot(contrastRange, contrastRange, 'k-');
        plot(contrastRange, contrastRange*0, 'k-');
        plot(contrastRange*0, contrastRange, 'k-');
        hold off
        box off; grid on
         text(2.0,-1.5, sprintf('RMS: %2.4f', outOfSampleSVDrms(svdIndex,coneIndex,:)), 'FontSize', 16, 'FontName', 'Menlo'); 
        set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', contrastTicks, 'YTick', contrastTicks, 'YTickLabel', {}, 'FontSize', 16, 'FontName', 'Menlo');
        axis 'square';
        xlabel('scene contrast', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    end
    end % coneIndex
    
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
    xlabel('# of singular vectors', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    ylabel('RMS residual', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    title('Out-of-Sample', 'FontSize', 18, 'FontName', 'Menlo', 'FontWeight', 'bold');
    
    drawnow
end

function [Cin, CoutPINV, CoutSVD, SVDbasedLowRankFilterVariancesExplained, includedComponentsNum, XtrainRank] = retrievePerformanceData(sceneSetName, decodingDataDir, InorOutOfSample)

    includedComponentsNum = [];
    XtrainRank = [];
    
%     p = getpref('HyperSpectralImageIsetbioComputations');
%     decodingDataDir = fullfile(p.sceneReconstructionProject.computedDataDir, ...
%                     'OpticalElementsDEFAULT_InertPigmentsDEFAULT', ...
%                     'Overlap0.80_Fixation150ms_MicrofixationGain1.0_MosaicSize22x26_LMSdens0.60x0.30x0.10_ReconstructedStimulusSpatialResolution3.0Microns', ...
%                     osType, 'decodingData', 'noPreprocessing');
%               
%     sceneSetName = 'harvard_machester_upenn';
    fileName = fullfile(decodingDataDir, sprintf('%s_%s.mat', sceneSetName, InorOutOfSample));

    decoderRow = 5;
    decoderCol = 7;
    
    if (strcmp(InorOutOfSample, 'inSamplePrediction')) 
        fprintf(2,'Loading from in-sample data from %s\n', fileName);
        load(fileName, 'Ctrain', 'CtrainPrediction', ...
            'includedComponentsNum', 'XtrainRank', ...
            'originalTrainingStimulusSize', 'expParams');

        Ctrain  = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(Ctrain, expParams.decoderParams), ...
            originalTrainingStimulusSize ...
        );
        Cin = squeeze(Ctrain(decoderRow, decoderCol, :,:)); clear 'Ctrain';
        
        CtrainPrediction  = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(CtrainPrediction, expParams.decoderParams), ...
            originalTrainingStimulusSize ...
        );
        CoutPINV = squeeze(CtrainPrediction(decoderRow, decoderCol, :,:)); clear 'CtrainPrediction';
        
        load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        for svdIndex = 1:size(CtrainPredictionSVDbased,1)
            tmp = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
                decoder.shiftStimulusSequence(squeeze(CtrainPredictionSVDbased(svdIndex,:,:)), expParams.decoderParams), ...
                originalTrainingStimulusSize ...
            );
            CoutSVD(svdIndex, :,:) = squeeze(tmp(decoderRow, decoderCol, :,:));
        end
        clear 'CtrainPredictionSVDbased'
    else
        fprintf(2,'Loading from out of-sample data from %s\n', fileName);
        load(fileName, 'Ctest', 'CtestPrediction', 'originalTestingStimulusSize', 'expParams');

        Ctest  = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(Ctest, expParams.decoderParams), ...
            originalTestingStimulusSize ...
        );
        Cin = squeeze(Ctest(decoderRow, decoderCol, :,:)); clear 'Ctest';
        
        CtestPrediction  = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(CtestPrediction, expParams.decoderParams), ...
            originalTestingStimulusSize ...
        );
        CoutPINV = squeeze(CtestPrediction(decoderRow, decoderCol, :,:)); clear 'CtestPrediction';
        
        load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        for svdIndex = 1:size(CtestPredictionSVDbased,1)
            tmp = decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
                decoder.shiftStimulusSequence(squeeze(CtestPredictionSVDbased(svdIndex,:,:)), expParams.decoderParams), ...
                originalTestingStimulusSize ...
            );
            CoutSVD(svdIndex, :,:) = squeeze(tmp(decoderRow, decoderCol, :,:));
        end
        clear 'CtestPredictionSVDbased'
    end
    
end
