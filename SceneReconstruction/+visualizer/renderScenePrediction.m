function renderScenePrediction(Ct, CtPrediction, originalStimulusSize, LMSbackground, expParams)

    % The stimulus used to form the CtPrediction has less bins
    % that the full stimulus sequence, so use only those bins
    originalStimulusSize(4) = size(CtPrediction,1);
    
    [LMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtPrediction, 'fromDecoderFormat', originalStimulusSize);
  
    originalStimulusSize(4) = size(Ct,1);
    [LMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(Ct, 'fromDecoderFormat', originalStimulusSize);
    
    RGBSequencePrediction = 0*LMScontrastSequencePrediction;
    RGBSequence = 0*LMScontrastSequence;
   
    backgroundExcitation = mean(LMSbackground, 2);
    
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 15;
    [coneFundamentals, displaySPDs, wave] = core.LMSRGBconversionData(displayName, gain);
 
    for kBin = 1:size(LMScontrastSequencePrediction,4)
        LMScontrastFrame  = LMScontrastSequencePrediction(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        [RGBSequencePrediction(:,:,:, kBin), predictionOutsideGamut] = ...
            core.LMStoRGBforSpecificDisplay(...
                LMSexcitationFrame, ...
                displaySPDs, coneFundamentals);
            
        LMScontrastFrame  = LMScontrastSequence(:,:,:,kBin);
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, backgroundExcitation);
        [RGBSequence(:,:,:, kBin), inputOutsideGamut] = ...
            core.LMStoRGBforSpecificDisplay(...
                LMSexcitationFrame, ...
                displaySPDs, coneFundamentals);
            
       if (any(inputOutsideGamut(:)>0))
            inputOutsideGamut
       end
    end % for kBin
    
    h = figure(100); clf; colormap(gray(1024))
    for tBin = 1:1:size(LMScontrastSequence,4)
        
        set(h, 'Name', sprintf('t: %2.3f seconds', tBin*expParams.decoderParams.temporalSamplingInMilliseconds/1000));
        for coneContrastIndex = 1:3
            actualFrame = squeeze(LMScontrastSequence(:,:,coneContrastIndex,tBin));
            predictedFrame = squeeze(LMScontrastSequencePrediction(:,:,coneContrastIndex,tBin));
        
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
            
            
            RGBframe = squeeze(RGBSequence(:,:,:, tBin));
            RGBframePrediction = squeeze(RGBSequencePrediction(:,:,:, tBin));

            aboveIndices = find(RGBframe>1);
            RGBframe(aboveIndices) = 1;
            belowIndices = find(RGBframe<0);
            RGBframe(belowIndices) = 0;
            above = numel(aboveIndices);
            below =  numel(belowIndices);
            if (above > 0 || below > 0)
                [above below]
            end
            
            aboveIndices = find(RGBframePrediction>1);
            RGBframePrediction(aboveIndices) = 1;
            belowIndices = find(RGBframePrediction<0);
            RGBframePrediction(belowIndices) = 0;
            above = numel(aboveIndices);
            below =  numel(belowIndices);
            if (above > 0 || below > 0)
                [above below]
            end
            
            
            subplot(4,3,10)
            imagesc(RGBframe.^(1.0/1.8));
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('inpout image');
            
            subplot(4,3, 11)
            imagesc(RGBframePrediction.^(1.0/1.8));
            axis 'xy'; axis 'image'
            set(gca, 'CLim', [0 1]);
            set(gca, 'XTick', [], 'YTick', []);
            title('reconstructed image');
    
        end
        drawnow;
    end
    
end
