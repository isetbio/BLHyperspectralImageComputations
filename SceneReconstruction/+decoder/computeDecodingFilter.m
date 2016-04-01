function computeDecodingFilter(sceneSetName, descriptionString)

    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    
    tic
    fprintf('\n1. Loading design matrix (X) and stimulus vector ... ');
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    fprintf('\n2. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', size(Xtrain,1), size(Xtrain,2));
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    % Compute and save the SVD decomposition of X so we can check (later) how the
    % filter dynamics depend on the # of SVD components
    fprintf('\n3. Computing SVD(X) [%d x %d]...',  size(Xtrain,1), size(Xtrain,2));
    [Utrain, Strain, Vtrain] = svd(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    tic
    featuresNum = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('\n4. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', featuresNum, stimulusDimensions);
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);

    tic
    fprintf('\n5. Computing in-sample predictions [%d x %d]...',  size(Xtrain,1), stimulusDimensions);
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
        
    spatioTemporalSupport = struct(...
       'sensorColAxis',  scanData.sensorRetinalXaxis, ...
       'sensorRowAxis',  scanData.sensorRetinalYaxis, ...
       'sensorFOVxaxis', scanData.sensorFOVxaxis, ...                  % spatial support of decoded scene
       'sensorFOVyaxis', scanData.sensorFOVyaxis, ...
       'timeAxis',       expParams.decoderParams.latencyInMillseconds + (0:1:round(expParams.decoderParams.memoryInMilliseconds/expParams.decoderParams.temporalSamplingInMilliseconds)-1) * ...
                           expParams.decoderParams.temporalSamplingInMilliseconds);

    tic
    fprintf('\n6. Saving decoder filter and in-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    save(fileName, 'wVector', 'spatioTemporalSupport', 'Utrain', 'Strain', 'Vtrain');
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done after %2.1f minutes.\n', toc/60);
end


