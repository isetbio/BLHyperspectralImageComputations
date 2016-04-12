function computeDecodingFilter(sceneSetName, resultsDir, onlyComputeDesignMatrixRank)

    decodingDataDir = core.getDecodingDataDir(resultsDir);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix (X) and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    % Compute the rank of X
    timeSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    fprintf('\n2a. Computing rank(X) [%d x %d]...',  timeSamples, filterDimensions);
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    fprintf('<strong>Rank(X) = %d</strong>\n', XtrainRank);
    
    if (onlyComputeDesignMatrixRank)
        return;
    end
    
%     if (expParams.decoderParams.designMatrixPreProcessing>0)
%         tic
%         fprintf('\n2aa. Centering (X) [%d x %d]...',  timeSamples, filterDimensions);
%         
%         % Compute degree of whiteness of Xtrain
%         varianceCovarianceMatrix = 1/timeSamples*(Xtrain')*Xtrain;
%         upperDiagElements = triu(varianceCovarianceMatrix, 1);
%         originalXtrainCovariances = upperDiagElements(:);
%         normOfOriginalXtrainCovariances = sqrt(1/numel(originalXtrainCovariances)*sum(originalXtrainCovariances.^2));
%    
%         % Compute centering operator
%         oneColVector = ones(timeSamples,1);
%         designMatrixPreprocessing.centeringOperator = (1/timeSamples*(Xtrain')*oneColVector)';
%         
%         % Center Xtrain
%         Xtrain = bsxfun(@minus, Xtrain, designMatrixPreprocessing.centeringOperator);
%         Xtrain(:,1) = 1;
%         fprintf('Done after %2.1f minutes.\n', toc/60);
%         
%         if (expParams.decoderParams.designMatrixPreProcessing > 1)  
%             tic
%             fprintf('\n2ab. Normalizing (X) [%d x %d]...',  timeSamples, filterDimensions);
%         
%             % Compute normalizing operator: divide by stddev
%             designMatrixPreprocessing.normalizingOperator = (1./(sqrt(1/timeSamples*((Xtrain.^2)')*oneColVector)))';
% 
%             % Normaize Xtrain
%             Xtrain = bsxfun(@times, Xtrain, designMatrixPreprocessing.normalizingOperator);
%             Xtrain(:,1) = 1;
%             fprintf('Done after %2.1f minutes.\n', toc/60);
%         
%             if (expParams.decoderParams.designMatrixPreProcessing > 2)
%                 tic
%                 fprintf('\n2ac. Whitening (X) [%d x %d]...',  timeSamples, filterDimensions);
%         
%                 % Compute whitening operator:
%                 Sigma = 1/timeSamples * (Xtrain') * Xtrain;
%                 [U, Gamma, V] = svd(Sigma, 'econ');
%                 designMatrixPreprocessing.whiteningOperator = U * (inv(sqrt(Gamma))) * V';
% 
%                 % Whiten Xtrain
%                 Xtrain = Xtrain * designMatrixPreprocessing.whiteningOperator;
%                 Xtrain(:,1) = 1;
%                 fprintf('Done after %2.1f minutes.\n', toc/60);
%             end
%         end
%         
%         tic
%         fprintf('\n2az. Computing rank (preproxessed X) [%d x %d]...',  timeSamples, filterDimensions);
%         
%         varianceCovarianceMatrix = 1/timeSamples*(Xtrain')*Xtrain;
%         upperDiagElements = triu(varianceCovarianceMatrix, 1);
%         whitenedXtrainCovariances = upperDiagElements(:);
%         normOfWhitenedXtrainCovariances = sqrt(1/numel(whitenedXtrainCovariances)*sum(whitenedXtrainCovariances.^2));
%    
%         XtrainRank = rank(Xtrain);
%         fprintf('Done after %2.1f minutes.\n', toc/60);
%         
%         fprintf('<strong>Rank(whitened X) = %d</strong>\n', XtrainRank);
%         fprintf('<string>normOfOriginalXtrainCovariances = %4.4f\n', normOfOriginalXtrainCovariances);
%         fprintf('<string>normOfWhitenedXtrainCovariances = %4.4f\n', normOfWhitenedXtrainCovariances);
%     else
%         designMatrixPreprocessing = [];  
%     end
    
    tic
    fprintf('\n2b. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', timeSamples, filterDimensions);
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    computeSVD = false;
    if (computeSVD)
        tic
        % Compute and save the SVD decomposition of X so we can check (later) how the
        % filter dynamics depend on the # of SVD components
        fprintf('\n2c. Computing SVD(X) [%d x %d]...',  size(Xtrain,1), size(Xtrain,2));
        [Utrain, Strain, Vtrain] = svd(Xtrain, 'econ');
        fprintf('Done after %2.1f minutes.\n', toc/60);
    end
    
    
    tic
    stimulusDimensions = size(Ctrain,2);
    fprintf('\n3. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', filterDimensions, stimulusDimensions);
    wVector = zeros(filterDimensions, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    tic
    fprintf('\n4. Computing in-sample predictions [%d x %d]...',  timeSamples, stimulusDimensions);
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    tic
    fprintf('\n5. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
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


