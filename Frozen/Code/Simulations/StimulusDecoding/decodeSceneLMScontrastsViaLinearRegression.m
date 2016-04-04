function decodeSceneLMScontrastsViaLinearRegression

    timeSampling = 5;            % sub-sample everything with a res of 5 milliseconds
    decodingFilterMemory = 100;
    fixationDuration = 200;      % each fixation lasts for 200 milliseconds
    
    % regressors: outersegment currents from all cones for the last
    % memoryBinsNum time bins (inputs)
    conesNum = 400
    memoryBinsNum = decodingFilterMemory/timeSampling
    microSaccadesBinsNum = (fixationDuration + decodingFilterMemory)/timeSampling
    
    % outputs: cone contrast sequence over trainingFixationsNum
    % each fixation consisting of microSaccadesNUm time bins 
    trainingFixationsNum = 20 * 30;
    testingFixationsNum  = 20 * 10;

    % Assemble design matrix for the training dataset from the outer-currents
    rowsNum  = microSaccadesBinsNum * trainingFixationsNum;
    colsNum = (1+memoryBinsNum) * conesNum;
    fprintf('\nComputing design matrix (%d x %d) for training ...', rowsNum, colsNum);
    tic
    designMatrix = randn(rowsNum, colsNum, 'single');
    fprintf('\nDesign matrix computation took %2.2f seconds', toc);

    
    % The spatiotemporal contrast for the training data set
    colsNum = 3;  % L, M and S contrast averaged across entire scene
    rowsNum = size(designMatrix,1);
    fprintf('\nComputing spatioTemporalLMSContrast matrix for training (%d x %d) ...', rowsNum, colsNum);
    tic
    spatioTemporalLMSContrast_Train = randn(rowsNum, colsNum, 'single');
    fprintf('\nSpatioTemporalLMSContrast matrix took %2.2f seconds', toc);
    
    % Compute decoding filter via linear regression on the training data set
    fprintf('\nComputing pseudo inverse of design matrix ...');
    tic
    Xdagger = pinv(designMatrix);
    fprintf('\nPseudo inverse took %2.2f seconds', toc);
    
    fprintf('\nComputing decoding filter ...');
    tic
    decodingFilter = Xdagger * spatioTemporalLMSContrast_Train;
    fprintf('\nDecoding filter (%d x %d) took %2.2f seconds', size(decodingFilter,1), size(decodingFilter,2), toc);
    
    % Assemble design matrix for the testing dataset (out of sample)
    rowsNum  = microSaccadesBinsNum * testingFixationsNum;
    colsNum = (1+memoryBinsNum) * conesNum;
    fprintf('\nComputing design matrix (%d x %d) for testing ...', rowsNum, colsNum);
    tic
    designMatrix = randn(rowsNum, colsNum, 'single');
    fprintf('\nDesign matrix computation took %2.2f seconds', toc);
    
    % The spatiotemporal contrast for the testing data set
    colsNum = 3;  % L, M and S contrast averaged across entire scene
    rowsNum = size(designMatrix,1);
    spatioTemporalLMSContrast_Test = randn(rowsNum, colsNum, 'single');
    
    fprintf('Decoding spatiotemporal LMS contrast from test outer segment currents\n');
    tic
    spatioTemporalLMScontrast_Decoded = designMatrix * decodingFilter;
    fprintf('\nContrast decoding took %2.2f seconds', toc);
    
    size(spatioTemporalLMScontrast_Decoded)
    size(spatioTemporalLMSContrast_Test)

end

