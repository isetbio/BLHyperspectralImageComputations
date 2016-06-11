function [Ctrain, CtrainPrediction, Ctest, CtestPrediction, SVDvarianceExplained, svdIndex, expParams] = retrievePerformanceData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions)
    fprintf('\nLoading in-sample prediction data ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    whos('-file', fileName);
    pause
    load(fileName, 'Ctrain', 'CtrainPrediction', 'originalTrainingStimulusSize', 'expParams');
  
    % Perform conversion to single and save it back to file
    conversionWasPerformed = false;
    if (isa(Ctrain, 'double'))
        Ctrain = single(Ctrain);
        CtrainPrediction = single(CtrainPrediction);
        conversionWasPerformed = true;
    end
    
    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        if (isa(Ctrain, 'CtrainPredictionSVDbased'))
            CtrainPredictionSVDbased = single(CtrainPredictionSVDbased);
            conversionWasPerformed = true;
        end
        svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
        if (numel(svdIndex)>1)
            return;
        end
        SVDvarianceExplained = SVDbasedLowRankFilterVariancesExplained(svdIndex);
        CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
    end
       
    if (conversionWasPerformed)
        fprintf('Saving single-precision in-sample data\n');
        save(fileName, 'Ctrain', 'CtrainPrediction', 'CtrainPredictionSVDbased', '-append');
    end
    
    
    fprintf('\nLoading out-of-sample prediction data ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
    load(fileName, 'Ctest', 'CtestPrediction', 'originalTestingStimulusSize');
    
    conversionWasPerformed = false;
    if (isa(Ctest, 'double'))
        Ctest = single(Ctest);
        CtestPrediction= single(CtestPrediction);
        conversionWasPerformed = true;
    end
    
    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
        if (isa(CtestPredictionSVDbased, 'double'))
            CtestPredictionSVDbased = single(CtestPredictionSVDbased);
            conversionWasPerformed = true;
        end
        CtestPrediction = squeeze(CtestPredictionSVDbased(svdIndex,:, :));
    end
    
    if (conversionWasPerformed)
        fprintf('Saving single-precision outof-sample data\n');
        save(fileName, 'Ctest', 'CtestPrediction', 'CtestPredictionSVDbased', '-append');
    end
    
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
