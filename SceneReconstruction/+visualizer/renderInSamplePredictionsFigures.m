function renderInSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'CtrainPrediction', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    % The stimulus used to form the Ctrain/CtrainPrediction has less bins
    % that the full stimulus sequence, so use only those bins
    originalTrainingStimulusSize(4) = size(CtrainPrediction,1);
    
    [trainingSceneLMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtrainPrediction, 'fromDecoderFormat', originalTrainingStimulusSize);
    
    fprintf('\n Loading actual stimulus data ... ');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    load(fileName, 'Ctrain', 'originalTrainingStimulusSize', 'expParams');
    
    originalTrainingStimulusSize(4) = size(Ctrain,1);
    [trainingSceneLMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(Ctrain, 'fromDecoderFormat', originalTrainingStimulusSize);
    
    h = figure(100); clf; colormap(gray(1024))
    for tBin = 1:1:size(trainingSceneLMScontrastSequence,4)
        
        set(h, 'Name', sprintf('t: %2.3f seconds', tBin*expParams.decoderParams.temporalSamplingInMilliseconds/1000));
        for coneContrastIndex = 1:3
            actualFrame = squeeze(trainingSceneLMScontrastSequence(:,:,coneContrastIndex,tBin));
            predictedFrame = squeeze(trainingSceneLMScontrastSequencePrediction(:,:,coneContrastIndex,tBin));
        
            subplot(3,3,(coneContrastIndex-1)*3 + 1);
            imagesc(actualFrame)
            axis 'xy'; axis 'image',
            set(gca, 'CLim', [-1 3]);

            subplot(3,3,(coneContrastIndex-1)*3 + 2);
            imagesc(predictedFrame)
            axis 'xy'; axis 'image',
            set(gca, 'CLim', [-1 3]);

            subplot(3,3,(coneContrastIndex-1)*3 + 3);
            imagesc(actualFrame-predictedFrame)
            axis 'xy'; axis 'image',
            set(gca, 'CLim', [-1 1]);
        end
        drawnow;
    end
    
    
end

