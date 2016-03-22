function computeDecodingFilter(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n2. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', size(Xtrain,1), size(Xtrain,2));
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('\n3. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', featuresNum, stimulusDimensions);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n4. Computing in-sample predictions [%d x %d]...',  size(Xtrain,1), stimulusDimensions);
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n5. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    save(fileName, 'wVector');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'CtrainPrediction', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    %  [trainingSceneLMScontrastSequencePrediction,~] = ...
    %    decoder.stimulusSequenceToDecoderFormat(CtrainPrediction, 'fromDecoderFormat', originalTrainingStimulusSize);

    %size(testingSceneLMScontrastSequencePrediction)
    %size(testingSceneLMScontrastSequence)
    
    %     'Xtest', 'Ctest', 'originalTestingStimulusSize', ...
    %     'expParams');
     
end


