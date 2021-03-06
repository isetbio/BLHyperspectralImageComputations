function [X, C, Coi] = computeDesignMatrixAndStimulusVector(signals, stimulus, stimulusOI, decoderParams)

    conesNum  = size(signals,1);
    totalBins = size(signals,2);
    stimulusDimensions = size(stimulus,2);
    
    latencyBins = decoderParams.latencyInMillseconds / decoderParams.temporalSamplingInMilliseconds;
    memoryBins  = decoderParams.memoryInMilliseconds / decoderParams.temporalSamplingInMilliseconds;
     
    if (latencyBins >= 0) 
        minTimeBin = 0;
    else
        minTimeBin = latencyBins;
    end
    % Do not include the last (memoryBins-minTimeBin) bins because we do
    % not have points for all the filter lags
    validTimeBins = totalBins - (memoryBins-minTimeBin);
    
    X = zeros(validTimeBins, 1+(conesNum*memoryBins), 'single');
    C = zeros(validTimeBins, stimulusDimensions, 'single');
    Coi = zeros(validTimeBins, stimulusDimensions, 'single');
    
    fprintf('\nAssembling design matrix (%d x %d) and stimulus vector (%d x %d).\nThis will take a while. Please wait ...', size(X, 1), size(X, 2), size(C, 1), size(C, 2));
    
    X(:,1) = 1;
    for row = 1:validTimeBins
        timeBins = latencyBins + row + (0:(memoryBins-1)) - minTimeBin;
        
        % Update X
        for coneIndex = 1:conesNum
            startingColumn = 2 + (coneIndex-1)*memoryBins;
            endingColumn = startingColumn + memoryBins - 1;
            if (timeBins(end) <= size(signals,2))
                X(row, startingColumn:endingColumn) = signals(coneIndex, timeBins);
            else
                fprintf('At row: %d (coneIndex:%d), column %d exceeds size(signals,2): %d\n', row, coneIndex, timeBins(end), size(signals,2));
                pause
            end 
        end % coneIndex
        
        % Update C
        if (row-minTimeBin <= size(stimulus,1))
            C(row, :) = stimulus(row-minTimeBin,:);
            Coi(row, :) = stimulusOI(row-minTimeBin,:);
        else
            fprintf('index %d > size(stimulus): %d\n', row-minTimeBin, size(stimulus,1));
        end 
    end % row
    
    fprintf('Done.\n');
end
