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
    
    fprintf('Done \n');
     
     
     % select a range to plot
    timeBins = 1:size(cTest,1);
    
    h = figure(11);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    subplot(1,3,1);
    plot(cTest(timeBins,1), cTestPrediction(timeBins,1), 'r.');
    set(gca, 'XLim', cLimits(1,:), 'YLim', cLimits(1,:));
    axis 'square';
    subplot(1,3,2);
    plot(cTest(timeBins,2), cTestPrediction(timeBins,2), 'g.');
    set(gca, 'XLim', cLimits(2,:), 'YLim', cLimits(2,:));
    axis 'square';
    subplot(1,3,3);
    plot(cTest(timeBins,3), cTestPrediction(timeBins,3), 'b.');
    set(gca, 'XLim', cLimits(3,:), 'YLim', cLimits(3,:));
    axis 'square';
    
    
    h = figure(12);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 1, ...
       'heightMargin',  0.04, ...
       'widthMargin',    0.01, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.01, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.03);

    subplot('Position', subplotPosVectors(1,1).v);
    plot(timeBins, cTest(timeBins,1), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,1), 'r-'); hold off;
    subplot('Position', subplotPosVectors(2,1).v);
    plot(timeBins, cTest(timeBins,2), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,2), 'g-'); hold off;
    subplot('Position', subplotPosVectors(3,1).v);
    plot(timeBins, cTest(timeBins,3), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,3), 'b-'); hold off
    drawnow; 
    
end