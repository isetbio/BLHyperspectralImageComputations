function responseSequence = reformatDesignMatrixToOriginalResponse(X,  rawTrainingResponsePreprocessing, preProcessingParams, decoderParams, sensorParams)

    if (preProcessingParams.designMatrixBased > 1)
        error('Undoing designMatric preprocessing at level (%d) not implemented yet', preProcessingParams.designMatrixBased);
    end
    
    if (preProcessingParams.rawResponseBased > 0)
        rawTrainingResponsePreprocessing
        error('Undoing raw response preprocessing not implemented yet');
    end
    
    
    latencyBins = decoderParams.latencyInMillseconds / decoderParams.temporalSamplingInMilliseconds;
    memoryBins  = decoderParams.memoryInMilliseconds / decoderParams.temporalSamplingInMilliseconds;
    if (latencyBins >= 0) 
        minTimeBin = 0;
    else
        minTimeBin = latencyBins;
    end
    
    [validTimeBins, neuralResponseFeaturesNum] = size(X);
    
    % Do not include the last (memoryBins-minTimeBin) bins because we do
    % not have points for all the filter lags
    totalBins = validTimeBins + (memoryBins-minTimeBin);
    conesNum = sensorParams.spatialGrid(1) * sensorParams.spatialGrid(2);
    signals = zeros(conesNum, totalBins);
    
    shiftToAlignWithScene = 0;
    
    for row = 1:validTimeBins
        timeBins = latencyBins + row + (0:(memoryBins-1)) - minTimeBin;
        for coneIndex = 1:conesNum
            startingColumn = 2 + (coneIndex-1)*memoryBins;
            endingColumn = startingColumn + memoryBins - 1;
            if (timeBins(end)+ shiftToAlignWithScene <= size(signals,2)) && (timeBins(1)+shiftToAlignWithScene >= 1)
                signals(coneIndex, timeBins + shiftToAlignWithScene) = X(row, startingColumn:endingColumn);
            end 
        end % coneIndex
    end % row
    
    originalSize = [sensorParams.spatialGrid(1) sensorParams.spatialGrid(2) totalBins];
    responseSequence = decoder.reformatResponseSequence('FromDesignMatrixFormat', signals, originalSize); 
end

