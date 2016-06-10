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
    
    fprintf('2. Preprocessing training matrix  [%d x %d]...\n ', trainingSamples, filterDimensions);
    tic
    computeRank = true;
    designMatrixPreprocessing = [];
    [Xtrain, originalXtrainRank, postProcessXtrainRank, designMatrixPreprocessing] = preProcessDesignMatrix(Xtrain, preProcessingParams, computeRank, designMatrixPreprocessing);
    fprintf('Done with pre-processing of training matrix after %2.1f minutes.\n', toc/60);
    
    fprintf('3. Saving training matrix  ... ');
    tic
    save(fileNameXtrain, 'Xtrain', 'originalXtrainRank', 'postProcessXtrainRank', 'designMatrixPreprocessing', '-append');
    clear 'Xtrain';
    
    
    % Load test design matrix
    fprintf('\n1. Loading test design matrix ''%s''... ', fileNameXtest);
    tic
    load(fileNameXtest, 'Xtest');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    testingSamples = size(Xtest,1);
    
    fprintf('2. Preprocessing test matrix  [%d x %d]... \n', testingSamples, filterDimensions);
    tic
    computeRank = false;
    [Xtest, ~, ~, ~] = preProcessDesignMatrix(Xtest, preProcessingParams, computeRank, designMatrixPreprocessing);
    fprintf('Done  with pre-processing of test matrix after %2.1f minutes.\n', toc/60);
    
    fprintf('3. Saving test matrix  ... ');
    tic
    save(fileNameXtest, 'Xtest', 'designMatrixPreprocessing', '-append');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    clear 'Xtest'
end


function [X, originalXRank, postProcessXRank, designMatrixPreprocessing] = preProcessDesignMatrix(X, preProcessingParams, computeRank, designMatrixPreprocessing)

    % remove first column of ones
    X = X(:,2:end);
    
    timeSamples = size(X,1);
    filterDimensions = size(X,2);
    originalXRank = [];
    postProcessXRank = [];
    
    if (~isempty(designMatrixPreprocessing))
        % Passed designMatrixPreprocessing is non empty, so use that one
        if (preProcessingParams.designMatrixBased > 0)
            fprintf('\t2a. Centering (X) [%d x %d]...',  timeSamples, filterDimensions);
            % Center X
            X = bsxfun(@minus, X, designMatrixPreprocessing.centeringOperator);
            fprintf('Done after %2.1f minutes.\n', toc/60);
            
            if (preProcessingParams.designMatrixBased > 1)  
                tic
                fprintf('\t2b. Normalizing (X) [%d x %d]...',  timeSamples, filterDimensions);

                % Normalize X
                X = bsxfun(@times, X, designMatrixPreprocessing.normalizingOperator);
                fprintf('Done after %2.1f minutes.\n', toc/60);
        
                if (preProcessingParams.designMatrixBased > 2)
                    tic
                    fprintf('\t2c. Whitening (X) [%d x %d]...',  timeSamples, filterDimensions);

                    % Whiten X
                    X = X * designMatrixPreprocessing.whiteningOperator;
                    fprintf('Done after %2.1f minutes.\n', toc/60);
                end
            end
        end
        
        % add first column of all ones back
        X = cat(2, ones(size(X,1), 1), X);
        return;
    end
    
    % Passed designMatrixPreprocessing is empty, so compute one
    if (preProcessingParams.designMatrixBased > 0)
        if (computeRank)
            fprintf('2aa. Computing rank (original X) [%d x %d]...',  timeSamples, filterDimensions);
            tic
            originalXRank = rank(X);
            fprintf('Done after %2.1f minutes.\n', toc/60);
            fprintf('<strong>Rank (originalX) = %d</strong>\n', originalXRank);
        end
        
        % Compute degree of whiteness of X
        %varianceCovarianceMatrix = 1/timeSamples*(X')*X;
        %upperDiagElements = triu(varianceCovarianceMatrix, 1);
        %originalXCovariances = upperDiagElements(:);
        %normOfOriginalXCovariances = sqrt(1/numel(originalXCovariances)*sum(originalXCovariances.^2));
   
        tic
        fprintf('\t2a. Centering (X) [%d x %d]...',  timeSamples, filterDimensions);
        % Compute centering operator
        oneColVector = ones(timeSamples,1);
        designMatrixPreprocessing.centeringOperator = (1/timeSamples*(X')*oneColVector)';
        
        % Center X
        X = bsxfun(@minus, X, designMatrixPreprocessing.centeringOperator);
        fprintf('Done after %2.1f minutes.\n', toc/60);
        
        if (preProcessingParams.designMatrixBased > 1)  
            tic
            fprintf('\t2b. Normalizing (X) [%d x %d]...',  timeSamples, filterDimensions);
        
            % Compute normalizing operator: divide by stddev
            designMatrixPreprocessing.normalizingOperator = (1./(sqrt(1/timeSamples*((X.^2)')*oneColVector)))';

            % Normalize X
            X = bsxfun(@times, X, designMatrixPreprocessing.normalizingOperator);
            fprintf('Done after %2.1f minutes.\n', toc/60);
        
            if (preProcessingParams.designMatrixBased > 2)
                tic
                fprintf('\t2c. Whitening (X) [%d x %d]...',  timeSamples, filterDimensions);
                
                % Compute whitening operator
                designMatrixPreprocessing.whiteningOperator = decoder.computeWhiteningMatrix(X, preProcessingParams.thresholdVarianceExplainedForWhiteningMatrix);
                % Whiten X
                X = X * designMatrixPreprocessing.whiteningOperator;
                fprintf('Done after %2.1f minutes.\n', toc/60);
            end
        end
        
        %varianceCovarianceMatrix = 1/timeSamples*(X')*X;
        %upperDiagElements = triu(varianceCovarianceMatrix, 1);
        %originalXCovariances = upperDiagElements(:);
        %normOfpreProcessedXCovariances = sqrt(1/numel(originalXCovariances)*sum(originalXCovariances.^2));
        %fprintf('\nNorm of covariances: original(X) = %2.2f, preProcessed(X) = %2.2f\n', normOfOriginalXCovariances, normOfpreProcessedXCovariances);
    
        if (computeRank)
            fprintf('2d. Computing rank (post-process X) [%d x %d]...',  timeSamples, filterDimensions);
            tic
            postProcessXRank = rank(X);
            fprintf('Done after %2.1f minutes.\n', toc/60);
            fprintf('<strong>Rank (post-process X) = %d</strong>\n', postProcessXRank);
        end
        
        % add first column of all ones back
        X = cat(2, ones(size(X,1), 1), X);
    end
end

