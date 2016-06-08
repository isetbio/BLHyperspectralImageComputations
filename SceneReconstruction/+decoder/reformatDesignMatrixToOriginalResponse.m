function responseSequence = reformatDesignMatrixToOriginalResponse(X,  rawTrainingResponsePreprocessing, expParams)

    if (expParams.preProcessingParams.designMatrixBased > 0)
        error('Undoing designMatric preprocessing not implemented yet');
    end
    
    if (expParams.preProcessingParams.rawResponseBased > 0)
        rawTrainingResponsePreprocessing
        error('Undoing raw response preprocessing not implemented yet');
    end
    
    
    latencyBins = expParams.decoderParams.latencyInMillseconds / expParams.decoderParams.temporalSamplingInMilliseconds;
    memoryBins  = expParams.decoderParams.memoryInMilliseconds / expParams.decoderParams.temporalSamplingInMilliseconds;
    if (latencyBins >= 0) 
        minTimeBin = 0;
    else
        minTimeBin = latencyBins;
    end
    
    [validTimeBins, neuralResponseFeaturesNum] = size(X);
    
    % Do not include the last (memoryBins-minTimeBin) bins because we do
    % not have points for all the filter lags
    totalBins = validTimeBins + (memoryBins-minTimeBin);
    conesNum = expParams.sensorParams.spatialGrid(1) * expParams.sensorParams.spatialGrid(2);
    signals = zeros(conesNum, totalBins);
    
    for row = 1:validTimeBins
        timeBins = latencyBins + row + (0:(memoryBins-1)) - minTimeBin;
        for coneIndex = 1:conesNum
            startingColumn = 2 + (coneIndex-1)*memoryBins;
            endingColumn = startingColumn + memoryBins - 1;
            if (timeBins(end) <= size(signals,2))
                signals(coneIndex, timeBins-latencyBins + minTimeBin) = X(row, startingColumn:endingColumn);
            else
                error('At row: %d (coneIndex:%d), column %d exceeds size(signals,2): %d\n', row, coneIndex, timeBins(end), size(signals,2));
            end 
        end % coneIndex
    end % row
    
    originalSize = [expParams.sensorParams.spatialGrid(1) expParams.sensorParams.spatialGrid(2) totalBins];
    responseSequence = decoder.reformatResponseSequence('FromDesignMatrixFormat', signals, originalSize); 
end

