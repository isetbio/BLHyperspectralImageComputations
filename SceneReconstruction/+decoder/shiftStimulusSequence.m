function shiftedSequence = shiftStimulusSequence(sequence, decoderParams)

    % Shifts and zeropads a stimulus sequence that is in DesignMatrix format so that 
    % it is time-aligned with the stimulus sequence in the original format
    latencyBins = decoderParams.latencyInMillseconds / decoderParams.temporalSamplingInMilliseconds;
    memoryBins  = decoderParams.memoryInMilliseconds / decoderParams.temporalSamplingInMilliseconds;
    
    if (latencyBins >= 0)
        minTimeBin = 0;
    else
        minTimeBin = latencyBins;
    end
    
    validTimeBins = size(sequence,1);
    stimulusDimensions = size(sequence,2);
    totalBins = validTimeBins + (memoryBins-minTimeBin);
    shiftedSequence = zeros(totalBins, stimulusDimensions);
    
    for row = 1:validTimeBins
         shiftedSequence(row - minTimeBin,:) = sequence(row, :);
    end
    
end

