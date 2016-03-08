function computeDecodingFilter(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)

    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);
    
    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    decodingDataFileName = fullfile(decodingDirectory, 'DecodingData.mat');
    trainingVarList = {...
        'designMatrix', ...
        'trainingTimeAxis', ...
        'trainingPhotocurrents', ...
        'trainingLcontrastSequence', ...
        'trainingMcontrastSequence', ...
        'trainingScontrastSequence', ...
        'resampledSpatialXdataInRetinalMicrons', ...
        'resampledSpatialYdataInRetinalMicrons' ...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(trainingVarList)
        load(decodingDataFileName, trainingVarList{k});
    end
    
    filterSpatialXdataInRetinalMicrons = resampledSpatialXdataInRetinalMicrons;
    filterSpatialYdataInRetinalMicrons = resampledSpatialYdataInRetinalMicrons;
    
    trainingStimulusTrain = [
        trainingLcontrastSequence', ...
        trainingMcontrastSequence', ...
        trainingScontrastSequence' ...
        ];
    
    designMatrix.lat
    designMatrix.m

    % Assemble X and c matrices
    [Xtrain, cTrain] = assembleDesignMatrixAndStimulusVector(designMatrix.T, designMatrix.lat, designMatrix.m, designMatrix.n, trainingPhotocurrents, trainingStimulusTrain);
    clear(trainingVarList{:});
    
    % Compute decoding filter, wVector
    pseudoInverseOfX = pinv(Xtrain);
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(cTrain,2);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * cTrain(:,stimDim);
    end
    
    % Compute in-sample predictions
    cTrainPrediction = cTrain*0;
    for stimDim = 1:stimulusDimensions
        cTrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    save(decodingFiltersFileName, 'wVector', 'cTrainPrediction', 'cTrain', 'filterSpatialXdataInRetinalMicrons', 'filterSpatialYdataInRetinalMicrons', '-v7.3'); 
    
end

    
