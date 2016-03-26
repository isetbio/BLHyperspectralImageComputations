function computeDecodingFilter(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n2. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', size(Xtrain,1), size(Xtrain,2));
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('\n3. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', featuresNum, stimulusDimensions);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n4. Computing in-sample predictions [%d x %d]...',  size(Xtrain,1), stimulusDimensions);
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    % Generate the filter's spatiotemporal support and embed it in the decoding filter file
    sceneIndex = 1;
    scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
    load(scanFileName, 'scanData', 'expParams');
    scanData = scanData{sceneIndex};
    
    coneSeparation = sensorGet(scanData.scanSensor,'pixel size','um');
    sensorRowAxis   = (0:(sensorGet(scanData.scanSensor, 'row')-1))*coneSeparation(1);
    sensorColAxis   = (0:(sensorGet(scanData.scanSensor, 'col')-1))*coneSeparation(1);
    sensorRowAxis   = sensorRowAxis - (sensorRowAxis(end)-sensorRowAxis(1))/2;
    sensorColAxis   = sensorColAxis - (sensorColAxis(end)-sensorColAxis(1))/2;
        
    spatioTemporalSupport = struct(...
       'sensorRowAxis',  sensorRowAxis, ...
       'sensorColAxis',  sensorColAxis, ...
       'sensorFOVxaxis', scanData.sensorFOVxaxis, ...                  % spatial support of decoded scene
       'sensorFOVyaxis', scanData.sensorFOVyaxis, ...
       'timeAxis',       expParams.decoderParams.latencyInMillseconds + ...
                           (0:1:round(expParams.decoderParams.memoryInMilliseconds/expParams.decoderParams.temporalSamplingInMilliseconds)-1) * ...
                           expParams.decoderParams.temporalSamplingInMilliseconds);

    
    tic
    fprintf('\n5. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    save(fileName, 'wVector', 'spatioTemporalSupport');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
     
end


