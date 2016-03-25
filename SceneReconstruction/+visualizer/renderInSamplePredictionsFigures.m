function renderInSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    
    % The stimulus used to form the Ctrain/CtrainPrediction has less bins
    % that the full stimulus sequence, so use only those bins
    originalTrainingStimulusSize(4) = size(CtrainPrediction,1);
    
    
    [trainingSceneLMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtrainPrediction, 'fromDecoderFormat', originalTrainingStimulusSize);
    
    originalTrainingStimulusSize(4) = size(Ctrain,1);
    [trainingSceneLMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(Ctrain, 'fromDecoderFormat', originalTrainingStimulusSize);
    
    
    trainingSceneRGBSequencePrediction = 0*trainingSceneLMScontrastSequencePrediction;
    trainingSceneRGBSequence = 0* trainingSceneLMScontrastSequence;
    
    backgroundExcitation = mean(trainingSceneLMSbackground, 2)
    
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 25;
    [coneFundamentals, displaySPDs, wave] = core.LMSRGBconversionData(displayName, gain);
    
    for kBin = 1:size(trainingSceneLMScontrastSequencePrediction,4)
        LMScontrastFrame  = trainingSceneLMScontrastSequencePrediction(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        [trainingSceneRGBSequencePrediction(:,:,:, kBin), predictionOutsideGamut] = ...
            core.LMStoRGBforSpecificDisplay(...
                LMSexcitationFrame, ...
                displaySPDs, coneFundamentals);
        
%         if (any(predictionOutsideGamut(:)>0))
%             predictionOutsideGamut
%         end
        
        LMScontrastFrame  = trainingSceneLMScontrastSequence(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        [trainingSceneRGBSequence(:,:,:, kBin), inputOutsideGamut] = ...
            core.LMStoRGBforSpecificDisplay(...
                LMSexcitationFrame, ...
                displaySPDs, coneFundamentals);
            
       if (any(inputOutsideGamut(:)>0))
            inputOutsideGamut
       end
       
    end
    
    
    maxSRGB = 1;
    
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
            RGBframe = squeeze(trainingSceneRGBSequence(:,:,:, tBin));
            aboveIndices = find(RGBframe>1);
            RGBframe(aboveIndices) = 1;
            belowIndices = find(RGBframe<0);
            RGBframe(belowIndices) = 0;
            above = numel(aboveIndices);
            below =  numel(belowIndices);
            if (above > 0 || below > 0)
                [above below]
            end
            RGBframe = RGBframe.^(1.0/1.8);
            
            imagesc(RGBframe);
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('inpout image');
            
            subplot(4,3, 11)
            RGBframe = squeeze(trainingSceneRGBSequencePrediction(:,:,:, tBin));
            
            aboveIndices = find(RGBframe>1);
            RGBframe(aboveIndices) = 1;
            belowIndices = find(RGBframe<0);
            RGBframe(belowIndices) = 0;
            above = numel(aboveIndices);
            below =  numel(belowIndices);
            if (above > 0 || below > 0)
                [above below]
            end
            RGBframe = RGBframe.^(1.0/1.8);
            
            imagesc(RGBframe);
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('reconstructed image');
    
        end
        drawnow;
    end
    
    
end

