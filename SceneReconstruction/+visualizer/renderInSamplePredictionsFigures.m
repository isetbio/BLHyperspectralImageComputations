function renderInSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
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
    
    trainingSceneSRGBSequencePrediction = 0*trainingSceneLMScontrastSequencePrediction;
    trainingSceneSRGBSequence = 0* trainingSceneLMScontrastSequence;
    
    backgroundExcitation = mean(trainingSceneLMSbackground, 2)
    
    
    for kBin = 1:size(trainingSceneLMScontrastSequencePrediction,4)
        LMScontrastFrame  = trainingSceneLMScontrastSequencePrediction(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        
        SRGBframe = core.XYZtoSRGB(core.StockmanSharpe2DegToXYZ(LMSexcitationFrame), []);
        trainingSceneSRGBSequencePrediction(:,:,:, kBin) = SRGBframe;

        
        LMScontrastFrame  = trainingSceneLMScontrastSequence(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        SRGBframe = core.XYZtoSRGB(core.StockmanSharpe2DegToXYZ(LMSexcitationFrame), []);
        trainingSceneSRGBSequence(:,:,:, kBin) = SRGBframe;
    end
    
   
   
    
    maxSRGB = 5; % max([max(trainingSceneSRGBSequence(:)) max(trainingSceneSRGBSequencePrediction(:))])
    
    h = figure(100); clf; colormap(gray(1024))
    for tBin = 1:1:size(trainingSceneLMScontrastSequence,4)
        
        set(h, 'Name', sprintf('t: %2.3f seconds', tBin*expParams.decoderParams.temporalSamplingInMilliseconds/1000));
        for coneContrastIndex = 1:3
            actualFrame = squeeze(trainingSceneLMScontrastSequence(:,:,coneContrastIndex,tBin));
            predictedFrame = squeeze(trainingSceneLMScontrastSequencePrediction(:,:,coneContrastIndex,tBin));
        
            subplot(4,3,(coneContrastIndex-1)*3 + 1);
            imagesc(actualFrame)
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [-1 5]);

            subplot(4,3,(coneContrastIndex-1)*3 + 2);
            imagesc(predictedFrame)
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [-1 5]);

            subplot(4,3,(coneContrastIndex-1)*3 + 3);
            imagesc(actualFrame-predictedFrame)
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [-3 3]);
            
            subplot(4,3,10)
            SRGBframe = squeeze(trainingSceneSRGBSequence(:,:,:, tBin));
            SRGBframe = SRGBframe/ maxSRGB;
            SRGBframe(SRGBframe>1) = 1;
            SRGBframe(SRGBframe<0) = 0;
            imagesc(SRGBframe);
             axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('inpout image');
            
            subplot(4,3, 11)
            SRGBframe = squeeze(trainingSceneSRGBSequencePrediction(:,:,:, tBin));
            
            SRGBframe = SRGBframe/ maxSRGB;
            SRGBframe(SRGBframe>1) = 1;
            SRGBframe(SRGBframe<0) = 0;
            imagesc(SRGBframe);
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('reconstructed image');
    
        end
        drawnow;
    end
    
    
end

