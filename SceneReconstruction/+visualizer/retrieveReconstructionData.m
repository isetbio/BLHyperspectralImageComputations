function [timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
          sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, ...
          responseSequence, expParams, svdIndex,SVDvarianceExplained, videoPostfix] = ...
          retrieveReconstructionData(sceneSetName, decodingDataDir, InSampleOrOutOfSample, computeSVDbasedLowRankFiltersAndPredictions)
    
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        
        fprintf('Loading design matrix to reconstruct the original responses ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'Xtrain', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'expParams');
        expParams.preProcessingParams = preProcessingParams;
        responseSequence = decoder.reformatDesignMatrixToOriginalResponse(Xtrain, rawTrainingResponsePreprocessing, preProcessingParams, expParams.decoderParams, expParams.sensorParams);
        
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName, 'Ctrain', 'CtrainPrediction', 'oiCtrain', ...
                       'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', ...
                       'trainingTimeAxis', 'originalTrainingStimulusSize', ...
                       'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'expParams');
        videoPostfix = sprintf('PINVbased');
        svdIndex = [];
        SVDvarianceExplained = [];
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            if (numel(svdIndex)>1)
                return;
            end
            videoPostfix = sprintf('SVD_%2.3f%%VarianceExplained',SVDbasedLowRankFilterVariancesExplained(svdIndex));
            SVDvarianceExplained = SVDbasedLowRankFilterVariancesExplained(svdIndex);
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
        end
        
        LMScontrastInput = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(Ctrain, expParams.decoderParams), ...
            originalTrainingStimulusSize);
    
        LMScontrastReconstruction = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(CtrainPrediction, expParams.decoderParams), ...
            originalTrainingStimulusSize);
        
        oiLMScontrastInput = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(oiCtrain, expParams.decoderParams), ...
            originalTrainingStimulusSize);
    
        sceneBackgroundExcitation = mean(trainingSceneLMSbackground, 2);
        opticalImageBackgroundExcitation = mean(trainingOpticalImageLMSbackground,2);
        
        % Only keep the data for which we have reconstructed the signal
        timeAxis                = trainingTimeAxis(1:size(CtrainPrediction,1));
        sceneIndexSequence      = trainingSceneIndexSequence(1:numel(timeAxis));
        sensorPositionSequence  = trainingSensorPositionSequence(1:numel(timeAxis),:);
    end
    
    if (strcmp(InSampleOrOutOfSample, 'OutOfSample'))
        error('Not implemented')
    end 
end