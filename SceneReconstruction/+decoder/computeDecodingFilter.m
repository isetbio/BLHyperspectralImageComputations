function computeDecodingFilter(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_designMatrices.mat', sceneSetName));
    
    fprintf('\nLoading design matrix and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'originalTrainingStimulusSize');
    fprintf('Done\n');
    
    fprintf('\nComputing optimal linear decoding filter: pinv(X) ... ');
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done\n');
    
    fprintf('\nComputing optimal linear decoding filter: filter ... ');
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(cTrain,2);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * cTrain(:,stimDim);
    end
    fprintf('Done\n');
    
    fprintf('\nComputing in-sample predictions ...');
    cTrainPrediction = cTrain*0;
    for stimDim = 1:stimulusDimensions
        cTrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done\n');
    
    [testingSceneLMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtrainPrediction, 'fromDecoderFormat', originalTrainingStimulusSize);

    [testingSceneLMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(Ctrain, 'fromDecoderFormat', originalTrainingStimulusSize);

    size(testingSceneLMScontrastSequencePrediction)
    size(testingSceneLMScontrastSequence)
    
    %     'Xtest', 'Ctest', 'originalTestingStimulusSize', ...
    %     'expParams');
     
end


