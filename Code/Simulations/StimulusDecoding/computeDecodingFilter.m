function computeDecodingFilter(rootPath, osType, adaptingFieldType, configuration)

    minargs = 4;
    maxargs = 4;
    narginchk(minargs, maxargs);
    
    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    decodingDataFileName = fullfile(scansDir,sprintf('DecodingData_%s.mat', configuration));
    trainingVarList = {...
        'designMatrix', ...
        'trainingTimeAxis', ...
        'trainingPhotocurrents', ...
        'trainingLcontrastSequence', ...
        'trainingMcontrastSequence', ...
        'trainingScontrastSequence' ...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(trainingVarList)
        load(decodingDataFileName, trainingVarList{k});
    end

    
    trainingStimulusTrain = [
        trainingLcontrastSequence', ...
        trainingMcontrastSequence', ...
        trainingScontrastSequence' ...
        ];
    
    
    % Assemble X and c matrices
    [Xtrain, cTrain] = assembleDesignMatrixAndStimulusVector(designMatrix.T, designMatrix.lat, designMatrix.m, designMatrix.n, trainingPhotocurrents, trainingStimulusTrain);
    clear(trainingVarList{:});
    
    % Compute decoding filter, wVector
    pseudoInverseOfX = pinv(Xtrain);
    featuresNum = size(Xtrain,2)
    stimulusDimensions = size(cTrain,2)
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * cTrain(:,stimDim);
    end
    
    % Compute in-sample predictions
    cTrainPrediction = cTrain*0;
    for stimDim = 1:stimulusDimensions
        cTrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    
    decodingFiltersFileName = fullfile(scansDir, sprintf('DecodingFilters_%s.mat', configuration));
    save(decodingFiltersFileName, 'wVector', 'cTrainPrediction', 'cTrain'); 
    
end

    
