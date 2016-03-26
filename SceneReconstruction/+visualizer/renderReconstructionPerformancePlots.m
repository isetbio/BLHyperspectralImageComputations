function renderReconstructionPerformancePlots(figNo, Ct, CtPrediction, originalStimulusSize, expParams)

    % The stimulus used to form the CtPrediction has less bins
    % that the full stimulus sequence, so use only those bins
   % originalStimulusSize(4) = size(CtPrediction,1);
    
    CtPredictionDecoderFormat = decoder.decoderFormatFromDesignMatrixFormat(CtPrediction, expParams.decoderParams);
    CtDecoderFormat = decoder.decoderFormatFromDesignMatrixFormat(Ct, expParams.decoderParams);
    
    [LMScontrastSequencePrediction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtPredictionDecoderFormat, 'fromDecoderFormat', originalStimulusSize);
  
   % originalStimulusSize(4) = size(Ct,1);
    [LMScontrastSequence,~] = ...
        decoder.stimulusSequenceToDecoderFormat(CtDecoderFormat, 'fromDecoderFormat', originalStimulusSize);
    

    maxContrast = max([max(LMScontrastSequence(:)) max(LMScontrastSequencePrediction(:))]);
    minContrast = min([min(LMScontrastSequence(:)) min(LMScontrastSequencePrediction(:))]);
    contrastRange = [minContrast maxContrast];
    
    rowsToPlot = 1:size(LMScontrastSequence,1);
    colsToPlot = 1:size(LMScontrastSequence,2);
    
    if (size(LMScontrastSequence,1) > 12)
        rowsToPlot = round(size(LMScontrastSequence,1)/2) + (-3:3);
        fprintf('Stimulus y-positions are more than 12 will only show central %d\n', rowsToPlot);
    end
    
    if (size(LMScontrastSequence,2) > 12)
        colsToPlot = round(size(LMScontrastSequence,2)/2) + (-2:2);
        fprintf('Stimulus x-positions are more than 12 will only show central %d\n', colsToPlot);
    end
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(colsToPlot), ...
               'heightMargin',   0.002, ...
               'widthMargin',    0.002, ...
               'leftMargin',     0.005, ...
               'rightMargin',    0.002, ...
               'bottomMargin',   0.002, ...
               'topMargin',      0.005);
           
           
    
    for coneContrastIndex = 1:3
        
        figure(figNo*10 + coneContrastIndex); clf;
        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            rowPos = rowsToPlot(iRow);
            colPos = colsToPlot(iCol);
            contrastInput = squeeze(LMScontrastSequence(rowPos,colPos,coneContrastIndex,:));
            contrastPrediction = squeeze(LMScontrastSequencePrediction(rowPos,colPos,coneContrastIndex,:));
            subplot('position',subplotPosVectors(iRow,iCol).v)
            plot(contrastInput(:), contrastPrediction(:), 'k.');
            hold on;
            plot(contrastRange, contrastRange, 'r-');
            plot(contrastRange, 0*contrastRange, 'r-');
            plot(0*contrastRange, contrastRange, 'r-');
            hold off;
            set(gca, 'XLim', contrastRange, 'YLim', contrastRange, 'XTick', (-1:1:100), 'YTick', (-1:1:100), 'XTickLabel', {}, 'YTickLabel', {});
            %xlabel('input contrast');
            %ylabel('reconstructed contrast');
            hold off;
            axis 'square'
        end
        drawnow
        end
    end
    
    drawnow;
    
end
