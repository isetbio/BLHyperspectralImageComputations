function renderPredictionsFigures(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, InSampleOrOutOfSample)

    fprintf('\nLoading stimulus prediction data ...');

    if (strcmp(InSampleOrOutOfSample, 'InSample'))
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
        [inSamplePINVcorrelations, inSamplePINVrmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, Ctrain, CtrainPrediction,  originalTrainingStimulusSize, expParams);

        
        if (computeSVDbasedLowRankFiltersAndPredictions)  
            inSampleSVDcorrelations = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            inSampleSVDrmsErrors = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
                figNo = kIndex;
                componentString = sprintf('SVD_%2.3f%%VarianceExplained', SVDbasedLowRankFilterVariancesExplained(kIndex));
                imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
                [inSampleSVDcorrelations(:, kIndex), inSampleSVDrmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, Ctrain, squeeze(CtrainPredictionSVDbased(kIndex,:, :)),  originalTrainingStimulusSize, expParams);
            end
            
            hFig = figure(222);
            set(hFig, 'Position', [10 10 740 1024], 'Name', 'In-sample performance');
            clf;
            subplot(2,1,1);
            xaxis = 1:numel(SVDbasedLowRankFilterVariancesExplained);
            plot(xaxis, inSampleSVDcorrelations(1,:), 'r-');
            hold on;
            plot(xaxis, inSampleSVDcorrelations(2,:), 'g-');
            plot(xaxis, inSampleSVDcorrelations(3,:), 'b-');
            plot([xaxis(1) xaxis(end)], inSamplePINVcorrelations(1)*[1 1], 'r--');
            plot([xaxis(1) xaxis(end)], inSamplePINVcorrelations(2)*[1 1], 'g--');
            plot([xaxis(1) xaxis(end)], inSamplePINVcorrelations(3)*[1 1], 'b--');
            hold off;
            set(gca, 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
            xlabel('variance explained', 'FontSize', 12);
            ylabel('corr. coefficient',  'FontSize', 12);
            legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'Pinv-based (L)', 'Pinv-based (M)', 'Pinv-based (S)');
            subplot(2,1,2);
            plot(xaxis, inSampleSVDrmsErrors(1,:), 'r-');
            hold on;
            plot(xaxis, inSampleSVDrmsErrors(2,:), 'g-');
            plot(xaxis, inSampleSVDrmsErrors(3,:), 'b-');
            plot([xaxis(1) xaxis(end)], inSamplePINVrmsErrors(1)*[1 1], 'r--');
            plot([xaxis(1) xaxis(end)], inSamplePINVrmsErrors(2)*[1 1], 'g--');
            plot([xaxis(1) xaxis(end)], inSamplePINVrmsErrors(3)*[1 1], 'b--');
            hold off;
            legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'Pinv-based (L)', 'Pinv-based (M)', 'Pinv-based (S)')
            set(gca, 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
            xlabel('variance explained', 'FontSize', 12);
            ylabel('rms error', 'FontSize', 12);
            drawnow;
        end
        
        
    elseif (strcmp(InSampleOrOutOfSample, 'OutOfSample'))
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
        figNo = 1000;
        [outOfSamplePINVcorrelations, outOfSamplePINVrmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, Ctest, CtestPrediction,  originalTestingStimulusSize, expParams);
    
        if (computeSVDbasedLowRankFiltersAndPredictions)  
            outOfSampleSVDcorrelations = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            outOfSampleSVDrmsErrors = zeros(3, numel(SVDbasedLowRankFilterVariancesExplained));
            for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
                figNo = 1000+kIndex;
                componentString = sprintf('SVD_%2.3f%%VarianceExplained', SVDbasedLowRankFilterVariancesExplained(kIndex));
                imageFileName = generateImageFileName(InSampleOrOutOfSample, componentString, decodingDataDir, expParams);
                [outOfSampleSVDcorrelations(:, kIndex), outOfSampleSVDrmsErrors(:, kIndex)]   = renderReconstructionPerformancePlots(figNo, imageFileName, Ctest, squeeze(CtestPredictionSVDbased(kIndex,:, :)),  originalTestingStimulusSize, expParams);
            end
            
            hFig = figure(223);
            set(hFig, 'Position', [10 10 740 1024],  'Name', 'Out-of-sample performance');
            clf;
            xaxis = 1:numel(SVDbasedLowRankFilterVariancesExplained);
            subplot(2,1,1)
            plot(xaxis, outOfSampleSVDcorrelations(1,:), 'r-');
            hold on;
            plot(xaxis, outOfSampleSVDcorrelations(2,:), 'g-');
            plot(xaxis, outOfSampleSVDcorrelations(3,:), 'b-');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVcorrelations(1)*[1 1], 'r--');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVcorrelations(2)*[1 1], 'g--');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVcorrelations(3)*[1 1], 'b--');
            hold off;
            legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'Pinv-based (L)', 'Pinv-based (M)', 'Pinv-based (S)')
            set(gca, 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
            xlabel('variance explained');
            ylabel('corr. coefficient');
            
            subplot(2,1,2);
            plot(xaxis, outOfSampleSVDrmsErrors(1,:), 'r-');
            hold on;
            plot(xaxis, outOfSampleSVDrmsErrors(2,:), 'g-');
            plot(xaxis, outOfSampleSVDrmsErrors(3,:), 'b-');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVrmsErrors(1)*[1 1], 'r--');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVrmsErrors(2)*[1 1], 'g--');
            plot([xaxis(1) xaxis(end)], outOfSamplePINVrmsErrors(3)*[1 1], 'b--');
            hold off;
            legend('SVD-based (L)', 'SVD-based (M)', 'SVD-based (S)', 'Pinv-based (L)', 'Pinv-based (M)', 'Pinv-based (S)')
            set(gca, 'XTick', xaxis, 'XTickLabel', SVDbasedLowRankFilterVariancesExplained,  'FontSize', 12);
            xlabel('variance explained', 'FontSize', 12);
            ylabel('rms error', 'FontSize', 12);
            drawnow;
            
        end
        
    else
        error('Unknown mode: ''%s''.', InSampleOrOutOfSample);
    end
end

function [correlations, rmsErrors] = renderReconstructionPerformancePlots(figNo, imageFileName, C, Creconstruction, originalStimulusSize, expParams)
    
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

    rowNumToPlot = 3;
    if (size(LMScontrastSequence,1) > rowNumToPlot)
        skip = floor(size(LMScontrastSequence,1)/rowNumToPlot);
        rowsToPlot = round(size(LMScontrastSequence,1)/rowNumToPlot/2) + (0:(rowNumToPlot-1))*skip + 1;
    else
        rowsToPlot = 1:size(LMScontrastSequence,1);
    end
    
    colNumToPlot = 4;
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
               'heightMargin',   0.008, ...
               'widthMargin',    0.008, ...
               'leftMargin',     0.008, ...
               'rightMargin',    0.000, ...
               'bottomMargin',   0.008, ...
               'topMargin',      0.000);
           
           
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    contrastRange = [-2.0 5];
    
    correlations = zeros(3, 1);
    rmsErrors = zeros(3,1);
    for coneContrastIndex = 1:3
        
        hFig = figure(figNo + 100*coneContrastIndex); clf;
        set(hFig, 'Position', [10 10 800 580], 'Color', [1 1 1]);
         
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
            subplot('position',subplotPosVectors(iRow,iCol).v)
            plot(contrastInput(:), contrastReconstruction(:), 'k.');
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
        
        NicePlot.exportFigToPNG(sprintf('%s%s.png', imageFileName, coneString{coneContrastIndex}), hFig, 300);
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
