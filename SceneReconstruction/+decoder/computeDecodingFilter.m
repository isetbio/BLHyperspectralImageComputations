function computeDecodingFilter(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix (X) and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n2. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', size(Xtrain,1), size(Xtrain,2));
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    % Compute and save the SVD decomposition of X so we can check (later) how the
    % filter dynamics depend on the # of SVD components
    fprintf('\n3a. Computing SVD(X) [%d x %d]...',  size(Xtrain,1), size(Xtrain,2));
    [Utrain, Strain, Vtrain] = svd(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    % Compute the rank of X 
    fprintf('\n3b. Computing rank(X) [%d x %d]...',  size(Xtrain,1), size(Xtrain,2));
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    fprintf('<strong>Rank(X) = %d</strong>\n', XtrainRank);
    tic
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('\n4. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', featuresNum, stimulusDimensions);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    tic
    fprintf('\n5. Computing in-sample predictions [%d x %d]...',  size(Xtrain,1), stimulusDimensions);
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    tic
    fprintf('\n6. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    save(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', ...
        'Utrain', 'Strain', 'Vtrain', 'XtrainRank', 'expParams', '-v7.3');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', ...
        'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
        'trainingScanInsertionTimes', 'trainingSceneLMSbackground', ...
        'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams',  '-v7.3');
    fprintf('Done after %2.1f minutes.\n', toc/60);
end


