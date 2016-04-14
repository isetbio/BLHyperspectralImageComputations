function preProcessDesignMatrices(sceneSetName, decodingDataDir)

    fileNameXtrain = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    fileNameXtest  = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    
    tic
    % Load train design matrix
    fprintf('\n1a. Loading design matrix from ''%s''  ... ', fileNameXtrain);
    load(fileNameXtrain, 'Xtrain', 'preProcessingParams');
    
    fprintf('Done after %2.1f minutes.\n', toc/60);
    trainingSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    
    % Load test design matrix
    tic
    fprintf('1b. Loading test design matrix ''%s''... ', fileNameXtest);
    load(fileNameXtest, 'Xtest');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    testingSamples = size(Xtest,1);
    
    tic
    fprintf('1c. Computing rank(X) (before pre-processing) [%d x %d]...',  trainingSamples, filterDimensions);
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    fprintf('<strong>Rank (X) (before pre-processing) = %d</strong>\n', XtrainRank);
    
    % Concatenate matrices into a grand design matrix
    tic
    fprintf('1d. Concatenating traing and test design matrices...');
    Xgrand = cat(1, Xtrain, Xtest);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    clear 'Xtrain'
    clear 'Xtest'
    
    timeSamples = size(Xgrand,1);
    filterDimensions = size(Xgrand,2);
    
    if (preProcessingParams.designMatrixBased > 0)
        tic
        fprintf('2aa. Centering (X) [%d x %d]...',  timeSamples, filterDimensions);
        
        % Compute degree of whiteness of Xgrand
        varianceCovarianceMatrix = 1/timeSamples*(Xgrand')*Xgrand;
        upperDiagElements = triu(varianceCovarianceMatrix, 1);
        originalXgrandCovariances = upperDiagElements(:);
        normOfOriginalXgrandCovariances = sqrt(1/numel(originalXgrandCovariances)*sum(originalXgrandCovariances.^2));
   
        % Compute centering operator
        oneColVector = ones(timeSamples,1);
        designMatrixPreprocessing.centeringOperator = (1/timeSamples*(Xgrand')*oneColVector)';
        
        % Center Xgrand
        Xgrand = bsxfun(@minus, Xgrand, designMatrixPreprocessing.centeringOperator);
        Xgrand(:,1) = 1;
        fprintf('Done after %2.1f minutes.\n', toc/60);
        
        if (preProcessingParams.designMatrixBased > 1)  
            tic
            fprintf('2ab. Normalizing (X) [%d x %d]...',  timeSamples, filterDimensions);
        
            % Compute normalizing operator: divide by stddev
            designMatrixPreprocessing.normalizingOperator = (1./(sqrt(1/timeSamples*((Xgrand.^2)')*oneColVector)))';

            % Normalize Xgrand
            Xgrand= bsxfun(@times, Xgrand, designMatrixPreprocessing.normalizingOperator);
            Xgrand(:,1) = 1;
            fprintf('Done after %2.1f minutes.\n', toc/60);
        
            if (preProcessingParams.designMatrixBased > 2)
                tic
                fprintf('2ac. Whitening (X) [%d x %d]...',  timeSamples, filterDimensions);
        
                % Compute whitening operator:
                Sigma = 1/timeSamples * (Xgrand') * Xgrand;
                [U, Gamma, V] = svd(Sigma, 'econ');
                designMatrixPreprocessing.whiteningOperator = U * (inv(sqrt(Gamma))) * V';

                % Whiten Xgrand
                Xgrand = Xgrand * designMatrixPreprocessing.whiteningOperator;
                Xgrand(:,1) = 1;
                fprintf('Done after %2.1f minutes.\n', toc/60);
            end
        end
    end
    
    tic
    fprintf('3. Saving preprocessed design matrices ...');
    
    Xtrain = Xgrand(1:trainingSamples,:);
    Xtest  = Xgrand(trainingSamples+(1:testingSamples),:);
    clear 'Xgrand'
    
    save(fileNameXtrain, 'Xtrain', '-append');
    save(fileNameXtest, 'Xtest', '-append');
    fprintf('Done after %2.1f minutes.\n', toc/60);
end
