function renderPerformanceFigures(sceneSetName, decodingDataDir,  visualizeSVDfiltersForVarianceExplained, InSampleOrOutOfSample)

    
    if (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample'))
        figureWidth = 1250;
    elseif ((strcmp(InSampleOrOutOfSample, 'InSample')) || (strcmp(InSampleOrOutOfSample, 'OutOfSample')))
        figureWidth = 600;
    else
        error('Unknown mode: ''%s''.', InSampleOrOutOfSample);
    end
    
    
    computeSVDbasedLowRankFiltersAndPredictions = true;
    
    hFigSummary = figure(1000); clf;
    set(hFigSummary, 'Position', [10 10 figureWidth 1150], 'Name', 'Reconstruction Performance Summary', 'Color', [1 1 1]);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 2, ...
               'heightMargin',   0.06, ...
               'widthMargin',    0.03, ...
               'leftMargin',     0.06, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.000);
           
    if ((strcmp(InSampleOrOutOfSample, 'InSample')) || (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample')))
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        else
            CtrainPredictionSVDbased = [];
            SVDbasedLowRankFilterVariancesExplained = [];
        end
        fprintf('Done.\n');
        
        componentString = 'PINVbased';
        imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
        figNo = 0;
        [inSamplePINVcorrelationCoeffs, inSamplePINVrmsErrors] = ...
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
                imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
                [inSampleSVDcorrelationCoeffs(:, kIndex), inSampleSVDrmsErrors(:, kIndex)] = ...
                    renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctrain, squeeze(CtrainPredictionSVDbased(kIndex,:, :)),  originalTrainingStimulusSize, expParams);
            end
            
            renderSummaryPerformancePlot(hFigSummary, 'InSample', subplotPosVectors(1,1).v, subplotPosVectors(2,1).v, SVDbasedLowRankFilterVariancesExplained, inSampleSVDcorrelationCoeffs, inSamplePINVcorrelationCoeffs, inSampleSVDrmsErrors, inSamplePINVrmsErrors);
        end
    end    
        
    if ((strcmp(InSampleOrOutOfSample, 'OutOfSample')) || (strcmp(InSampleOrOutOfSample, 'InAndOutOfSample')))
        fprintf('\nLoading out-of-sample  prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
        load(fileName,  'Ctest', 'CtestPrediction', 'testingTimeAxis', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'originalTestingStimulusSize', 'expParams');
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        else
            CtestPredictionSVDbased = [];
            SVDbasedLowRankFilterVariancesExplained = [];
        end
        fprintf('Done.\n');
        
        componentString = 'PINVbased';
        imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
        figNo = 10;
        [outOfSamplePINVcorrelationCoeffs, outOfSamplePINVrmsErrors] = ...
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
                imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
                [outOfSampleSVDcorrelationCoeffs(:, kIndex), outOfSampleSVDrmsErrors(:, kIndex)] = ...
                    renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, Ctest, squeeze(CtestPredictionSVDbased(kIndex,:, :)),  originalTestingStimulusSize, expParams);
            end
            
            renderSummaryPerformancePlot(hFigSummary, 'OutOfSample', subplotPosVectors(1,2).v, subplotPosVectors(2,2).v,  SVDbasedLowRankFilterVariancesExplained, outOfSampleSVDcorrelationCoeffs, outOfSamplePINVcorrelationCoeffs, outOfSampleSVDrmsErrors, outOfSamplePINVrmsErrors);
        end  
    end
    
    imageFileName = generateImageFileName('', 'Summary', decodingDataDir, expParams);
    NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFigSummary, 300);
     
end


function renderSummaryPerformancePlot(hFig, InOrOutOfSample, subplot1Position, subplot2Position, SVDbasedLowRankFilterVariancesExplained, SVDcorrelationCoefficients, PINVcorrelationCoefficients, SVDrmsErrors, PINVrmsErrors)
    
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
    set(gca, 'XLim', [xaxis(1)-0.5 xaxis(end)+0.5], 'YLim', [0 1], 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
    box 'off'
    xlabel('variance explained', 'FontSize', 14);
    ylabel('corr. coefficient',  'FontSize', 14);
    legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'PINV-based (L)', 'PINV-based (M)', 'PINV-based (S)', 'Location', 'NorthOutside', 'Orientation', 'horizontal');
    title(sprintf('Correlation Coefficients (%s)', InOrOutOfSample), 'FontSize', 12);
    
    figure(hFig);
    subplot('position',subplot2Position)
    plot(xaxis, SVDrmsErrors(1,:), 'ro-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [1.0 0.8 0.8]);
    hold on;
    plot(xaxis, SVDrmsErrors(2,:), 'go-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [0.8 1.0 0.8], 'MarkerEdgeColor', [0.6 0.8 0.6], 'Color', [0.0 0.8 0.0]);
    plot(xaxis, SVDrmsErrors(3,:), 'bo-', 'MarkerSize', 12, 'LineWidth', 2.0, 'MarkerFaceColor', [0.8 0.8 1.0]);
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(1)*[1 1], 'r--', 'LineWidth', 2.0);
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(2)*[1 1], 'g--', 'LineWidth', 2.0, 'Color', [0.0 0.8 0.0])
    plot([xaxis(1) xaxis(end)], PINVrmsErrors(3)*[1 1], 'b--', 'LineWidth', 2.0);
    hold off;
    set(gca, 'XLim', [xaxis(1)-0.5 xaxis(end)+0.5], 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
    box 'off'
    xlabel('variance explained', 'FontSize', 14);
    ylabel('rms error', 'FontSize', 14);
    title(sprintf('RMS errors (%s)', InOrOutOfSample), 'FontSize', 12);
     
    drawnow;
end

function [correlations, rmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, decodingDataDir, C, Creconstruction, originalStimulusSize, expParams)
    
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
            theCorrelationCoeff = corr(reshape(contrastInput, [numel(contrastInput(:)) 1]), reshape(contrastReconstruction, [numel(contrastReconstruction(:)) 1]));
            theRMSerror = sqrt(mean((contrastInput(:)-contrastReconstruction(:)).^2));
            correlations(coneContrastIndex) = correlations(coneContrastIndex) + theCorrelationCoeff;
            rmsErrors(coneContrastIndex) = rmsErrors(coneContrastIndex) + theRMSerror;
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
            title(sprintf('corr coeff: %2.3f, RMSerr = %2.2f', theCorrelationCoeff, theRMSerror));
        end
        drawnow
        end
        correlations(coneContrastIndex) = correlations(coneContrastIndex)/(numel(rowsToPlot)*numel(colsToPlot));
        rmsErrors(coneContrastIndex) = rmsErrors(coneContrastIndex)/(numel(rowsToPlot)*numel(colsToPlot));
        NicePlot.exportFigToPNG(figureFileName, hFig, 300);
    end
end

function imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams)
        if (expParams.outerSegmentParams.addNoise)
            outerSegmentNoiseString = 'Noise';
        else
            outerSegmentNoiseString = 'NoNoise';
        end
        imageFileName = fullfile(decodingDataDir, sprintf('%sPerformance%s%s%sOverlap%2.1fMeanLum%d', InSampleOrOutOfSample, componentString, expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
      
end
