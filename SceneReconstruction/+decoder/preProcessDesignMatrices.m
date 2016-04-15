function preProcessDesignMatrices(sceneSetName, decodingDataDir)

    fileNameXtrain = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    fileNameXtest  = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    
    
    % Load train design matrix
    fprintf('\n1. Loading training design matrix from ''%s''  ... ', fileNameXtrain);
    tic
    load(fileNameXtrain, 'Xtrain', 'preProcessingParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    trainingSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    
    fprintf('2. Proprocessing training matrix  [%d x %d]... ', trainingSamples, filterDimensions);
    tic
    Xtrain = preProcessDesignMatrix(Xtrain, preProcessingParams);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('3. Saving training matrix  ... ');
    tic
    save(fileNameXtrain, 'Xtrain', '-append');
    clear 'Xtrain';
    
    
    % Load test design matrix
    fprintf('\n1. Loading test design matrix ''%s''... ', fileNameXtest);
    tic
    load(fileNameXtest, 'Xtest');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    testingSamples = size(Xtest,1);
    
    fprintf('2. Proprocessing test matrix  [%d x %d]... ', testingSamples, filterDimensions);
    tic
    Xtest = preProcessDesignMatrix(Xtest, preProcessingParams);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('3. Saving test matrix  ... ');
    tic
    save(fileNameXtest, 'Xtest', '-append');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    clear 'Xtest'
end


function X = preProcessDesignMatrix(X, preProcessingParams)

    timeSamples = size(X,1);
    filterDimensions = size(X,2);
    
    if (preProcessingParams.designMatrixBased > 0)
        tic
        fprintf('2a. Centering (X) [%d x %d]...',  timeSamples, filterDimensions);
        
        % Compute degree of whiteness of X
        varianceCovarianceMatrix = 1/timeSamples*(X')*X;
        upperDiagElements = triu(varianceCovarianceMatrix, 1);
        originalXCovariances = upperDiagElements(:);
        normOfOriginalXCovariances = sqrt(1/numel(originalXCovariances)*sum(originalXCovariances.^2));
   
        % Compute centering operator
        oneColVector = ones(timeSamples,1);
        designMatrixPreprocessing.centeringOperator = (1/timeSamples*(X')*oneColVector)';
        
        % Center X
        X = bsxfun(@minus, X, designMatrixPreprocessing.centeringOperator);
        X(:,1) = 1;
        fprintf('Done after %2.1f minutes.\n', toc/60);
        
        if (preProcessingParams.designMatrixBased > 1)  
            tic
            fprintf('2b. Normalizing (X) [%d x %d]...',  timeSamples, filterDimensions);
        
            % Compute normalizing operator: divide by stddev
            designMatrixPreprocessing.normalizingOperator = (1./(sqrt(1/timeSamples*((X.^2)')*oneColVector)))';

            % Normalize X
            X= bsxfun(@times, X, designMatrixPreprocessing.normalizingOperator);
            X(:,1) = 1;
            fprintf('Done after %2.1f minutes.\n', toc/60);
        
            if (preProcessingParams.designMatrixBased > 2)
                tic
                fprintf('2c. Whitening (X) [%d x %d]...',  timeSamples, filterDimensions);
        
                % Compute whitening operator:
                Sigma = 1/timeSamples * (X') * X;
                [U, Gamma, V] = svd(Sigma, 'econ');
                designMatrixPreprocessing.whiteningOperator = U * (inv(sqrt(Gamma))) * V';

                % Whiten X
                X = X * designMatrixPreprocessing.whiteningOperator;
                X(:,1) = 1;
                fprintf('Done after %2.1f minutes.\n', toc/60);
            end
        end
    end
end

