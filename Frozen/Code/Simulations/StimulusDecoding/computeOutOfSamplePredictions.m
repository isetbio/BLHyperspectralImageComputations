function computeOutOfSamplePredictions(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)
    
    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);

    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);

    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    decodingFiltersVarList = {...
        'wVector'...
    };
    
    fprintf('\nLoading ''%s'' ...', decodingFiltersFileName);
    for k = 1:numel(decodingFiltersVarList)
        load(decodingFiltersFileName, decodingFiltersVarList{k});
    end
    
    
    decodingDataFileName = fullfile(decodingDirectory, sprintf('DecodingData.mat'));
    testingVarList = {...
        'designMatrixTest', ...
        'testingTimeAxis', ...
        'testingPhotocurrents', ...
        'testingLcontrastSequence', ...
        'testingMcontrastSequence', ...
        'testingScontrastSequence' ...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(testingVarList)
        load(decodingDataFileName, testingVarList{k});
    end
    

    fprintf('\nPlease wait. Computing out-of-sample predictions ....');
    
    % Compute out-of-sample design matrix and stimulus vector
    testingStimulusTrain = [
        testingLcontrastSequence', ...
        testingMcontrastSequence', ...
        testingScontrastSequence' ...
        ];
    [Xtest, cTest] = assembleDesignMatrixAndStimulusVector(designMatrixTest.T, designMatrixTest.lat, designMatrixTest.m, designMatrixTest.n, testingPhotocurrents, testingStimulusTrain);

    % Compute out-of-sample predictions
    stimulusDimensions = size(cTest,2)
    cTestPrediction = cTest*0;
    for stimDim = 1:stimulusDimensions
        cTestPrediction(:, stimDim) = Xtest * wVector(:,stimDim);
    end
    
    outOfSamplePredictionDataFileName = fullfile(decodingDirectory, sprintf('OutOfSamplePredicition.mat'));
    save(outOfSamplePredictionDataFileName, 'cTestPrediction', 'cTest' ...
        );
    fprintf('Done \n');
     
end