function contrastOSresponses(sceneSetName, linearDecodingDataDir, biophysDecodingDataDir)

    linearDecodingDataDir
    biophysDecodingDataDir
    pause
    InSampleOrOutOfSample = 'InSample';
    
    coneRow = 11;
    coneCol = 13;
    timePointsToReturn = 5000;
    
    [timeAxis1, linearResponseSequence] = retrieveResponseData(...
        sceneSetName, linearDecodingDataDir, coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample);
      
    [timeAxis2, biophysResponseSequence] = retrieveResponseData(...
        sceneSetName, biophysDecodingDataDir, coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample);
 
    figure(1); clf;
    plot(linearResponseSequence, biophysResponseSequence, 'k.');
    drawnow;
    
end

function [timeAxis,responseSequence] = retrieveResponseData(...
    sceneSetName, decodingDataDir,  coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample)
    
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        
        fprintf('Loading design matrix to reconstruct the original responses ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'Xtrain', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'expParams');
        expParams.preProcessingParams = preProcessingParams;
        responseSequence = decoder.reformatDesignMatrixToOriginalResponse(Xtrain, rawTrainingResponsePreprocessing, preProcessingParams, expParams.decoderParams, expParams.sensorParams);
        
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName, 'trainingTimeAxis');
        
        % Only keep the data for which we have reconstructed the signal
        timeAxis = trainingTimeAxis(1:timePointsToReturn);
        responseSequence = squeeze(responseSequence(coneRow, coneCol, 1:timePointsToReturn));
    end
    
    if (strcmp(InSampleOrOutOfSample, 'OutOfSample'))
        error('Not implemented')
    end 
end

