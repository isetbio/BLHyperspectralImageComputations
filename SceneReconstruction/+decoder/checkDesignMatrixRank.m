function checkDesignMatrixRank(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix... ');
    load(fileName, 'Xtrain');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('Computing matrix rank');
    fprintf('Rank of design matrix, which has %d features, is : %d \n', size(Xtrain,2), rank(Xtrain));
    
    
    
end