function renderReconstructionPerformancePlots(figNo, imageFileName, Ct, CtPrediction, originalStimulusSize, expParams)

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
    contrastRange = [-2.0 5];
    
    expParams.decoderParams
    rowsToPlot = 1:size(LMScontrastSequence,1)
    colsToPlot = 1:size(LMScontrastSequence,2)
    fprintf('Stimulus was decoded at a grid of (%d x%d), with a %2.1f micron resolution', size(LMScontrastSequence,1), size(LMScontrastSequence,2), expParams.decoderParams.spatialSamplingInRetinalMicrons)
    
    if (size(LMScontrastSequence,1) > 12)
        rowsToPlot = 3:6:size(LMScontrastSequence,1)
        fprintf('Stimulus y-positions are more than 12 will only show every 6th row\n');
    end
    
    if (size(LMScontrastSequence,2) > 12)
        colsToPlot = 3:6:size(LMScontrastSequence,2)
        fprintf('Stimulus y-positions are more than 12 will only show every 6th col\n');
    end
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(colsToPlot), ...
               'heightMargin',   0.008, ...
               'widthMargin',    0.008, ...
               'leftMargin',     0.008, ...
               'rightMargin',    0.000, ...
               'bottomMargin',   0.008, ...
               'topMargin',      0.000);
           
           
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    for coneContrastIndex = 1:3
        
        hFig = figure(figNo*10 + coneContrastIndex); clf;
        set(hFig, 'Position', [10 10 800 580], 'Color', [1 1 1]);
        
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
        
        NicePlot.exportFigToPNG(sprintf('%s%s.png', imageFileName, coneString{coneContrastIndex}), hFig, 300);
    end
    
    
    
end
