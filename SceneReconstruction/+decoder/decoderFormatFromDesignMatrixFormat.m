function CdecoderFormat = decoderFormatFromDesignMatrixFormat(C, decoderParams)

    latencyBins = decoderParams.latencyInMillseconds / decoderParams.temporalSamplingInMilliseconds;
    memoryBins  = decoderParams.memoryInMilliseconds / decoderParams.temporalSamplingInMilliseconds;
    
    if (latencyBins >= 0)
            minTimeBin = 0;
        else
            minTimeBin = latencyBins;
    end
    minTimeBin 
    rowsOfX = size(C,1);
    stimulusDimensions = size(C,2);
    totalBins = rowsOfX - minTimeBin + memoryBins;
    CdecoderFormat = zeros(totalBins, stimulusDimensions);
    
    for row = 1:rowsOfX
         CdecoderFormat(row - minTimeBin,:) = C(row, :);
    end
    
end

