function checkDesignMatrixRank(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix... ');
    load(fileName, 'Xtrain');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('\n2. Computing design matrix rank');
    fprintf('\n3. Rank of design matrix, which has %d features, is : %d.', size(Xtrain,2), rank(Xtrain));
    
    fprintf('\nComputing singular values of design matrix ...');
    [U, S, V] = svd(Xtrain);
    singularValues = diag(S);
    singularValues = singularValues/singularValues(1);
    numel(singularValues(singularValues > 1e-10))
    
    figure(1);
    clf;
    plot(1:numel(singularValues), singularValues, 'k.');
    xlabel('singular value index')
    ylabel('singular value');
    
end