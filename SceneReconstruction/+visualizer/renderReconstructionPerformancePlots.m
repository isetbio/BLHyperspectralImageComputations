function renderReconstructionPerformancePlots(figNo, Ct, CtPrediction, originalStimulusSize)

    % The stimulus used to form the CtPrediction has less bins
    % that the full stimulus sequence, so use only those bins
    originalStimulusSize(4) = size(CtPrediction,1);
    
    [LMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtPrediction, 'fromDecoderFormat', originalStimulusSize);
  
    originalStimulusSize(4) = size(Ct,1);
    [LMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(Ct, 'fromDecoderFormat', originalStimulusSize);
    

    maxContrast = max([max(LMScontrastSequence(:)) max(LMScontrastSequencePrediction(:))]);
    minContrast = min([min(LMScontrastSequence(:)) min(LMScontrastSequencePrediction(:))]);
    contrastRange = [minContrast maxContrast];
    

    figure(figNo); clf;
    for coneContrastIndex = 1:3
        contrastInput = squeeze(LMScontrastSequence(:,:,coneContrastIndex,:));
        contrastPrediction = squeeze(LMScontrastSequencePrediction(:,:,coneContrastIndex,:));
        subplot(1,3,coneContrastIndex);
        plot(contrastInput(:), contrastPrediction(:), 'k.');
        hold on;
        plot(contrastRange, contrastRange, 'r-');
        hold off;
        set(gca, 'XLim', contrastRange, 'YLim', contrastRange);
        xlabel('input contrast');
        ylabel('reconstructed contrast');
        hold off;
        axis 'square'
    end
    
    drawnow;
    
end
