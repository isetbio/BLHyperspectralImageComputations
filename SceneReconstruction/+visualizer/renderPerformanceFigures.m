function renderPerformanceFigures(sceneSetName, decodingDataDir,  visualizeSVDfiltersForVarianceExplained, InSampleOrOutOfSample)


    if (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample'))
        figureWidth = 2000; figureHeight = 1490;
    elseif ((strcmp(InSampleOrOutOfSample, 'InSample')) || (strcmp(InSampleOrOutOfSample, 'OutOfSample')))
        figureWidth = 600; figureHeight = 1150;
    else
        error('Unknown mode: ''%s''.', InSampleOrOutOfSample);
    end
    
    
    computeSVDbasedLowRankFiltersAndPredictions = true;
    
    hFigSummary = figure(5000); clf;
    set(hFigSummary, 'Position', [10 10 figureWidth figureHeight], 'Name', 'Reconstruction Performance Summary', 'Color', [1 1 1]);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 2, ...
               'heightMargin',   0.05, ...
               'widthMargin',    0.04, ...
               'leftMargin',     0.04, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.01);
    
    rmsErrorRange = [];
    
    if ((strcmp(InSampleOrOutOfSample, 'InSample')) || (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample')))
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained', 'includedComponentsNum', 'XtrainRank');
        else
            CtrainPredictionSVDbased = [];
            SVDbasedLowRankFilterVariancesExplained = [];
        end
        fprintf('Done.\n');
        
        componentString = 'PINVbased';
        imageFileName = generateImageFileName('InSample', componentString, decodingDataDir, expParams);
        figNo = 0;
        [inSamplePINVcorrelationCoeffs, inSamplePINVcoefficientsOfDetermination, inSamplePINVrmsErrors] = ...
            renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctrain, CtrainPrediction,  originalTrainingStimulusSize, expParams);

        if (computeSVDbasedLowRankFiltersAndPredictions)  
            inSampleSVDcorrelationCoeffs = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            inSampleSVDrmsErrors = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            figNo = 1000;
            if (isempty(visualizeSVDfiltersForVarianceExplained))
                kk = 1:numel(SVDbasedLowRankFilterVariancesExplained);
            else
                [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            end
            for kIndex = kk
                componentString = sprintf('SVD_%2.3f%%VarianceExplained', SVDbasedLowRankFilterVariancesExplained(kIndex));
                imageFileName = generateImageFileName('InSample', componentString, decodingDataDir, expParams);
                [inSampleSVDcorrelationCoeffs(:, kIndex), inSampleSVDcoefficientsOfDetermination(:, kIndex), inSampleSVDrmsErrors(:, kIndex)] = ...
                    renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctrain, squeeze(CtrainPredictionSVDbased(kIndex,:, :)),  originalTrainingStimulusSize, expParams);
                fprintf('Components: %d, varianceExplained: %2.3f, DesignMatrixRank: %d: LMS RMSerrors: %2.3f %2.3f, %2.3f\n', includedComponentsNum(kIndex), SVDbasedLowRankFilterVariancesExplained(kIndex), XtrainRank, inSampleSVDrmsErrors(1, kIndex),  inSampleSVDrmsErrors(2, kIndex),  inSampleSVDrmsErrors(3, kIndex));
            end
            
            rmsErrorRange = [min(inSampleSVDrmsErrors(:)) max(inSampleSVDrmsErrors(:))];
            renderSummaryPerformancePlot(hFigSummary, 'InSample', subplotPosVectors(1,1).v, subplotPosVectors(2,1).v, subplotPosVectors(3,1).v, SVDbasedLowRankFilterVariancesExplained, includedComponentsNum, ...
                inSampleSVDcorrelationCoeffs, inSamplePINVcorrelationCoeffs, inSampleSVDcoefficientsOfDetermination, inSamplePINVcoefficientsOfDetermination, inSampleSVDrmsErrors, inSamplePINVrmsErrors, rmsErrorRange);
        end
    end    
        
    if ((strcmp(InSampleOrOutOfSample, 'OutOfSample')) || (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample')))
        fprintf('\nLoading out-of-sample  prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
        load(fileName,  'Ctest', 'CtestPrediction', 'testingTimeAxis', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'originalTestingStimulusSize', 'expParams');
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained', 'includedComponentsNum', 'XtrainRank');
        else
            CtestPredictionSVDbased = [];
            SVDbasedLowRankFilterVariancesExplained = [];
        end
        fprintf('Done.\n');
        
        componentString = 'PINVbased';
        imageFileName = generateImageFileName('OutOfSample', componentString, decodingDataDir, expParams);
        figNo = 10;
        [outOfSamplePINVcorrelationCoeffs, outOfSamplePINVcoefficientsOfDetermination, outOfSamplePINVrmsErrors] = ...
            renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctest, CtestPrediction,  originalTestingStimulusSize, expParams);
    
        if (computeSVDbasedLowRankFiltersAndPredictions)  
            outOfSampleSVDcorrelationCoeffs = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            outOfSampleSVDrmsErrors = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            if (isempty(visualizeSVDfiltersForVarianceExplained))
                kk = 1:numel(SVDbasedLowRankFilterVariancesExplained);
            else
                [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            end
           
            figNo = 2000;
            for kIndex = kk
                componentString = sprintf('SVD_%2.3f%%VarianceExplained', SVDbasedLowRankFilterVariancesExplained(kIndex));
                imageFileName = generateImageFileName('OutOfSample', componentString, decodingDataDir, expParams);
                [outOfSampleSVDcorrelationCoeffs(:, kIndex), outOfSampleSVDcoefficientsOfDetermination(:, kIndex), outOfSampleSVDrmsErrors(:, kIndex)] = ...
                    renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctest, squeeze(CtestPredictionSVDbased(kIndex,:, :)),  originalTestingStimulusSize, expParams);
            end
            
            if (isempty(rmsErrorRange))
                rmsErrorRange = [min(inSampleSVDrmsErrors(:)) max(inSampleSVDrmsErrors(:))];
            end
            renderSummaryPerformancePlot(hFigSummary, 'OutOfSample', subplotPosVectors(1,2).v, subplotPosVectors(2,2).v, subplotPosVectors(3,2).v, SVDbasedLowRankFilterVariancesExplained, includedComponentsNum, ...
                outOfSampleSVDcorrelationCoeffs, outOfSamplePINVcorrelationCoeffs, outOfSampleSVDcoefficientsOfDetermination, outOfSamplePINVcoefficientsOfDetermination, outOfSampleSVDrmsErrors, outOfSamplePINVrmsErrors, rmsErrorRange);
        end  
    end
    
    imageFileName = generateImageFileName('', 'Summary', decodingDataDir, expParams);
    NicePlot.exportFigToPDF(sprintf('%s.pdf', imageFileName), hFigSummary, 300);
     
end


function renderSummaryPerformancePlot(hFig, InOrOutOfSample, subplot1Position, subplot2Position, subplot3Position, SVDbasedLowRankFilterVariancesExplained, includedComponentsNum, ...
    SVDcorrelationCoefficients, PINVcorrelationCoefficients, SVDcoefficientsOfDetermination, PINVcoefficientsOfDetermination, SVDrmsErrors, PINVrmsErrors, rmsErrorRange)
    
    figure(hFig);
    subplot('position',subplot1Position);
    xaxis = 1:numel(SVDbasedLowRankFilterVariancesExplained);
    plot(xaxis, SVDcorrelationCoefficients(1,:), 'ro-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.8 0.8]);
    hold on;
    plot(xaxis, SVDcorrelationCoefficients(2,:), 'go-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [0.8 1.0 0.8], 'MarkerEdgeColor', [0.6 0.8 0.6], 'Color', [0.0 0.8 0.0]);
    plot(xaxis, SVDcorrelationCoefficients(3,:), 'bo-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 1.0]);
    plot([xaxis(1) xaxis(end)], PINVcorrelationCoefficients(1)*[1 1], 'r--', 'LineWidth', 2.0);
    plot([xaxis(1) xaxis(end)], PINVcorrelationCoefficients(2)*[1 1], 'g--', 'LineWidth', 2.0, 'Color', [0.0 0.8 0.0]);
    plot([xaxis(1) xaxis(end)], PINVcorrelationCoefficients(3)*[1 1], 'b--', 'LineWidth', 2.0);
    hold off;
    set(gca, 'XLim', [xaxis(1)-0.5 xaxis(end)+0.5], 'YLim', [0.5 1], 'XTick', xaxis, 'XTickLabel', sprintf('%2.3f\n', SVDbasedLowRankFilterVariancesExplained),  'FontSize', 14);
    box 'off'
    xlabel('variance explained', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(sprintf('input/output correlation coefficient (%s)',InOrOutOfSample),  'FontSize', 16, 'FontWeight', 'bold');
    hL = legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'PINV-based (L)', 'PINV-based (M)', 'PINV-based (S)', 'Location', 'SouthEast');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    title(sprintf('%s performance', InOrOutOfSample), 'FontSize', 16);
    
    
    subplot('position',subplot2Position);
    plot(xaxis, SVDcoefficientsOfDetermination(1,:), 'ro-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.8 0.8]);
    hold on;
    plot(xaxis, SVDcoefficientsOfDetermination(2,:), 'go-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [0.8 1.0 0.8], 'MarkerEdgeColor', [0.6 0.8 0.6], 'Color', [0.0 0.8 0.0]);
    plot(xaxis, SVDcoefficientsOfDetermination(3,:), 'bo-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 1.0]);
    plot([xaxis(1) xaxis(end)], PINVcoefficientsOfDetermination(1)*[1 1], 'r--', 'LineWidth', 2.0);
    plot([xaxis(1) xaxis(end)], PINVcoefficientsOfDetermination(2)*[1 1], 'g--', 'LineWidth', 2.0, 'Color', [0.0 0.8 0.0]);
    plot([xaxis(1) xaxis(end)], PINVcoefficientsOfDetermination(3)*[1 1], 'b--', 'LineWidth', 2.0);
    hold off;
    set(gca, 'XLim', [xaxis(1)-0.5 xaxis(end)+0.5], 'YLim', [0.0 1], 'XTick', xaxis, 'XTickLabel', sprintf('%2.3f\n', SVDbasedLowRankFilterVariancesExplained),  'FontSize', 14);
    box 'off'
    xlabel('variance explained', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(sprintf('coefficient of determination (%s)',InOrOutOfSample),  'FontSize', 16, 'FontWeight', 'bold');
    hL = legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'PINV-based (L)', 'PINV-based (M)', 'PINV-based (S)', 'Location', 'SouthEast');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    title(sprintf('%s performance', InOrOutOfSample), 'FontSize', 16);
    

    
    subplot('position',subplot3Position)
    plot(xaxis, SVDrmsErrors(1,:), 'ro-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [1.0 0.8 0.8]);
    hold on;
    plot(xaxis, SVDrmsErrors(2,:), 'go-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [0.8 1.0 0.8], 'MarkerEdgeColor', [0.6 0.8 0.6], 'Color', [0.0 0.8 0.0]);
    plot(xaxis, SVDrmsErrors(3,:), 'bo-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [0.8 0.8 1.0]);
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(1)*[1 1], 'r--', 'LineWidth', 2.0);
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(2)*[1 1], 'g--', 'LineWidth', 2.0, 'Color', [0.0 0.8 0.0])
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(3)*[1 1], 'b--', 'LineWidth', 2.0);
    hold off;
    set(gca, 'XLim', [xaxis(1)-0.5 xaxis(end)+0.5], 'YLim', rmsErrorRange, 'XTick', xaxis, 'XTickLabel', sprintf('%2.0f\n', includedComponentsNum),  'FontSize', 14);
    box 'off'
    xlabel('# of SVD components', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(sprintf('RMS contrast residual (%s)',InOrOutOfSample), 'FontSize', 16, 'FontWeight', 'bold');
    hL = legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'PINV-based (L)', 'PINV-based (M)', 'PINV-based (S)', 'Location', 'NorthEast');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    drawnow;
end

function [correlations, coefficientsOfDetermination, rmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, C, Creconstruction, originalStimulusSize, expParams)
    
    LMScontrastSequenceReconstruction  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(Creconstruction, expParams.decoderParams), ...
            originalStimulusSize ...
        );
  
    LMScontrastSequence  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(C, expParams.decoderParams), ...
            originalStimulusSize ...
        );

    rowNumToPlot = 2;
    if (size(LMScontrastSequence,1) > rowNumToPlot)
        skip = floor(size(LMScontrastSequence,1)/rowNumToPlot);
        rowsToPlot = round(size(LMScontrastSequence,1)/rowNumToPlot/2) + (0:(rowNumToPlot-1))*skip + 1;
    else
        rowsToPlot = 1:size(LMScontrastSequence,1);
    end
    
    colNumToPlot = 3;
    if (size(LMScontrastSequence,2) > colNumToPlot)
        skip = floor(size(LMScontrastSequence,2)/colNumToPlot);
        colsToPlot = round(size(LMScontrastSequence,2)/colNumToPlot/2) + (0:(colNumToPlot-1))*skip + 1;
    else
        colsToPlot = 1:size(LMScontrastSequence,2);
    end
    
    fprintf('Stimulus x-positions plottted: %s (out of %d-%d)\n', sprintf('%d ',colsToPlot), 1, size(LMScontrastSequence,2));
    fprintf('Stimulus x-positions plottted: %s (out of %d-%d)\n', sprintf('%d ',rowsToPlot), 1, size(LMScontrastSequence,1));
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(colsToPlot), ...
               'heightMargin',   0.02, ...
               'widthMargin',    0.008, ...
               'leftMargin',     0.005, ...
               'rightMargin',    0.005, ...
               'bottomMargin',   0.008, ...
               'topMargin',      0.02);
           
           
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    contrastRange = [-2.0 5];
    
    correlations = zeros(3, 1);
    rmsErrors = zeros(3,1);
    coefficientsOfDetermination = zeros(3,1);
    
    for coneContrastIndex = 1:3
        
        hFig = figure(figNo + coneContrastIndex); clf;
        figureFileName = sprintf('%s%s.png', imageFileName, coneString{coneContrastIndex});
        set(hFig, 'Position', [10 10 800 650], 'Name', strrep(figureFileName, decodingDataDir, ''),'Color', [1 1 1]);
         
        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            rowPos = rowsToPlot(iRow);
            colPos = colsToPlot(iCol);   
            contrastInput = squeeze(LMScontrastSequence(rowPos,colPos,coneContrastIndex,:));
            contrastReconstruction = squeeze(LMScontrastSequenceReconstruction(rowPos,colPos,coneContrastIndex,:));
            
            theCoefficientOfDetermination = 1 - (sum((contrastInput-contrastReconstruction).^2))/(sum((contrastInput - mean(contrastInput)).^2));
            theCorrelationCoeff = corr(reshape(contrastInput, [numel(contrastInput(:)) 1]), reshape(contrastReconstruction, [numel(contrastReconstruction(:)) 1]));
            theRMSerror = sqrt(mean((contrastInput(:)-contrastReconstruction(:)).^2));
            
            correlations(coneContrastIndex) = correlations(coneContrastIndex) + theCorrelationCoeff;
            rmsErrors(coneContrastIndex) = rmsErrors(coneContrastIndex) + theRMSerror;
            coefficientsOfDetermination(coneContrastIndex) = coefficientsOfDetermination(coneContrastIndex) + theCoefficientOfDetermination;
            subplot('position',subplotPosVectors(iRow,iCol).v);
            sampleIndices = 1:5:numel(contrastInput);
            plot(contrastInput(sampleIndices), contrastReconstruction(sampleIndices), 'k.');
            hold on;
            plot(contrastRange, contrastRange, 'r-');
            plot(contrastRange, 0*contrastRange, 'r-');
            plot(0*contrastRange, contrastRange, 'r-');
            hold off;
            set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', (-1:1:100), 'YTick', (-1:1:100), 'XTickLabel', {}, 'YTickLabel', {});
            %xlabel('input contrast');
            %ylabel('reconstructed contrast');
            hold off;
            axis 'square'
            title(sprintf('corr coeff: %2.3f, coeff of Determination: %2.3f, RMSerr = %2.2f', theCorrelationCoeff, theCoefficientOfDetermination, theRMSerror));
        end
        drawnow
        end
        correlations(coneContrastIndex) = correlations(coneContrastIndex)/(numel(rowsToPlot)*numel(colsToPlot));
        rmsErrors(coneContrastIndex) = rmsErrors(coneContrastIndex)/(numel(rowsToPlot)*numel(colsToPlot));
        coefficientsOfDetermination(coneContrastIndex) = coefficientsOfDetermination(coneContrastIndex)/(numel(rowsToPlot)*numel(colsToPlot));
        
        NicePlot.exportFigToPNG(figureFileName, hFig, 300);
    end
end

function imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams)
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end
    imageFileName = fullfile(decodingDataDir, sprintf('%sPerformance%s', InSampleOrOutOfSample, componentString));
    
end
