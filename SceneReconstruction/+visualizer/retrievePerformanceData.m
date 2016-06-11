function [Ctrain, CtrainPrediction, Ctest, CtestPrediction, SVDvarianceExplained, svdIndex] = retrievePerformanceData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions)
    fprintf('\nLoading in-sample prediction data ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName, 'Ctrain', 'CtrainPrediction', 'originalTrainingStimulusSize', 'expParams');
  
    % Perform conversion to single and save it back to file
    CtrainSinglePrecision = single(Ctrain);
    CtrainPredictionSinglePrecision = single(CtrainPrediction);
    
    whos('-file', fileName);
    pause
    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        CtrainPredictionSVDbasedSinglePrecision = single(CtrainPredictionSVDbased);
        svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
        if (numel(svdIndex)>1)
            return;
        end
        SVDvarianceExplained = SVDbasedLowRankFilterVariancesExplained(svdIndex);
        CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
    end
       
    fprintf('Saving single-precision in-sample data\n');
    save(fileName, 'CtrainSinglePrecision', 'CtrainPredictionSinglePrecision', 'CtrainPredictionSVDbasedSinglePrecision', '-append');
    
    fprintf('\nLoading out-of-sample prediction data ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
    load(fileName, 'Ctest', 'CtestPrediction', 'originalTestingStimulusSize');
    CtestSinglePrecision = single(Ctest);
    CtestPredictionSinglePrecision = single(CtestPrediction);
    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        CtestPredictionSVDbasedSinglePrecision = single(CtestPredictionSVDbased);
        CtestPrediction = squeeze(CtestPredictionSVDbased(svdIndex,:, :));
    end
    
    fprintf('Saving single-precision outof-sample data\n');
    save(fileName, 'CtestSinglePrecision', 'CtestPredictionSinglePrecision', 'CtestPredictionSVDbasedSinglePrecision', '-append');
    
    CtrainPrediction  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(CtrainPrediction, expParams.decoderParams), ...
            originalTrainingStimulusSize ...
        );
  
    Ctrain  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(Ctrain, expParams.decoderParams), ...
            originalTrainingStimulusSize ...
        );
    
    CtestPrediction  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(CtestPrediction, expParams.decoderParams), ...
            originalTestingStimulusSize ...
        );
  
    Ctest  = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat', ...
            decoder.shiftStimulusSequence(Ctest, expParams.decoderParams), ...
            originalTestingStimulusSize ...
        );
    
end
