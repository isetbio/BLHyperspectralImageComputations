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
        
        imageFileName = generateImageFileName(InSampleOrOutOfSample, decodingDataDir, expParams);
        figNo = 0;
        componentString = 'Full';
        renderReconstructionPerformancePlots(figNo, imageFileName, componentString, Ctrain, CtrainPrediction,  originalTrainingStimulusSize, expParams);
    
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            fprintf('Hit enter to see in-sample performance of the filter accounting for %2.2f%% of the variance.\n', SVDbasedLowRankFilterVariancesExplained(kIndex));
            pause
            figNo = kIndex;
            componentString = sprintf('SVD_%2.3f', SVDbasedLowRankFilterVariancesExplained(kIndex));
            renderReconstructionPerformancePlots(figNo, imageFileName, componentString, Ctrain, squeeze(CtrainPredictionSVDbased(kIndex,:, :)),  originalTrainingStimulusSize, expParams);
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
        
        imageFileName = generateImageFileName(InSampleOrOutOfSample, decodingDataDir, expParams);
        figNo = 1000;
        componentString = 'Full';
        renderReconstructionPerformancePlots(figNo, imageFileName, componentString, Ctest, CtestPrediction,  originalTestingStimulusSize, expParams);
    
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            fprintf('Hit enter to see the out-of-sample performance of the filter accounting for %2.2f%% of the variance.\n', SVDbasedLowRankFilterVariancesExplained(kIndex));
            pause
            figNo = 1000+kIndex;
            componentString = sprintf('SVD_%2.3f', SVDbasedLowRankFilterVariancesExplained(kIndex));
            renderReconstructionPerformancePlots(figNo, imageFileName, componentString, Ctest, squeeze(CtestPredictionSVDbased(kIndex,:, :)),  originalTestingStimulusSize, expParams);
        end
        
    else
        error('Unknown mode: ''%s''.', InSampleOrOutOfSample);
    end
end

function renderReconstructionPerformancePlots(figNo, imageFileName, componentString, C, Creconstruction, originalStimulusSize, expParams)
    
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
    
    for coneContrastIndex = 1:3
        
        hFig = figure(figNo + 100*coneContrastIndex); clf;
        set(hFig, 'Position', [10 10 800 580], 'Color', [1 1 1]);
        
        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            rowPos = rowsToPlot(iRow);
            colPos = colsToPlot(iCol);
            contrastInput = squeeze(LMScontrastSequence(rowPos,colPos,coneContrastIndex,:));
            contrastReconstruction = squeeze(LMScontrastSequenceReconstruction(rowPos,colPos,coneContrastIndex,:));
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
        end
        drawnow
        end
        
        NicePlot.exportFigToPNG(sprintf('%s%s%s.png', imageFileName, componentString, coneString{coneContrastIndex}), hFig, 300);
    end
end

function imageFileName = generateImageFileName(InSampleOrOutOfSample, decodingDataDir, expParams)
        if (expParams.outerSegmentParams.addNoise)
            outerSegmentNoiseString = 'Noise';
        else
            outerSegmentNoiseString = 'NoNoise';
        end
        imageFileName = fullfile(decodingDataDir, sprintf('%sPerformance%s%sOverlap%2.1fMeanLum%d', InSampleOrOutOfSample, expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
      
end
