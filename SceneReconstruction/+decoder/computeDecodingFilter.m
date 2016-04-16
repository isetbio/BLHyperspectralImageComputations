function computeDecodingFilter(sceneSetName, decodingDataDir, computeSVD)

    fprintf('\n1. Loading training design matrix (X) and stimulus vector ... ');
    tic
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    
    % Compute the rank of X
    timeSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    fprintf('2a. Computing rank(X) [%d x %d]...',  timeSamples, filterDimensions);
    tic
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    fprintf('<strong>Rank (X) = %d</strong>\n', XtrainRank);
     
    fprintf('2b. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', timeSamples, filterDimensions);
    tic
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    if (computeSVD)
        % Compute and save the SVD decomposition of X so we can check (later) how the
        % filter dynamics depend on the # of SVD components
        fprintf('2c. Computing SVD(X) [%d x %d]...',  size(Xtrain,1), size(Xtrain,2));
        tic
        [Utrain, Strain, Vtrain] = svd(Xtrain, 'econ');
        fprintf('Done after %2.1f minutes.\n', toc/60);
    end
    
    stimulusDimensions = size(Ctrain,2);
    fprintf('3. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', filterDimensions, stimulusDimensions);
    tic
    wVector = zeros(filterDimensions, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    fprintf('4. Computing in-sample predictions [%d x %d]...',  timeSamples, stimulusDimensions);
    tic
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    fprintf('5. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    tic
    if (computeSVD)
        save(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes',  ...
           'Utrain', 'Strain', 'Vtrain', 'XtrainRank', 'expParams', '-v7.3');
    else
        save(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', ...
            'XtrainRank', 'expParams', '-v7.3');
    end
    
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', ...
        'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
        'trainingScanInsertionTimes', 'trainingSceneLMSbackground', ...
        'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams',  '-v7.3');
    fprintf('Done after %2.1f minutes.\n', toc/60);
end


