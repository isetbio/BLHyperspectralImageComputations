function computeOutOfSamplePredictions(varargin)
    
    minargs = 0;
    maxargs = 1;
    narginchk(minargs, maxargs);
    
    if (nargin == 0)
        configuration = 'manchester'
    else
        configuration = varargin{1}
    end
    
    decodingDataFileName = sprintf('decodingData_%s.mat', configuration);
    testingVarList = {...
        'designMatrix', ...
        'testingTimeAxis', ...
        'testingPhotocurrents', ...
        'testingLcontrastSequence', ...
        'testingMcontrastSequence', ...
        'testingScontrastSequence' ...
        };
    for k = 1:numel(testingVarList)
        load(decodingDataFileName, testingVarList{k});
    end
    
    testingStimulusTrain = [
        testingLcontrastSequence', ...
        testingMcontrastSequence', ...
        testingScontrastSequence' ...
        ];
    [Xtest, cTest] = assembleDesignMatrixAndStimulusVector(designMatrix.T, designMatrix.lat, designMatrix.m, designMatrix.n, testingPhotocurrents, testingStimulusTrain);
    
    load(sprintf('DecodingFilters_%s.mat', configuration), 'wVector', 'cTrainPrediction', 'cTrain');
    
    stimulusDimensions = size(cTest,2)
    cTestPrediction = cTest*0;
    for stimDim = 1:stimulusDimensions
        cTestPrediction(:, stimDim) = Xtest * wVector(:,stimDim);
    end
    
    h = figure(1);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    clf;
    plot(cTest(:,1), cTestPrediction(:,1), 'r.');
    hold on;
    plot(xTest(:,2), cTestPrediction(:,2), 'g.');
    plot(xTest(:,3), cTestPrediction(:,3), 'b.');
    drawnow; 
    
    h = figure(1);
    set(h, 'Name', 'In sample predictions');
    clf;
    clf;
    plot(cTrain(:,1), cTrainPrediction(:,1), 'r.');
    hold on;
    plot(xTrain(:,2), cTrainPrediction(:,2), 'g.');
    plot(xTrain(:,3), cTrainPrediction(:,3), 'b.');
    drawnow; 
    
end