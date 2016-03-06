function [X, C] = assembleDesignMatrixAndStimulusVector(totalBins, latencyBins, memoryBins, conesNum, signals, stimulus)

    minTimeBin = min([0 min([latencyBins 0])]);
    rowsOfX = totalBins + minTimeBin;
    stimulusDimensions = size(stimulus,2);
    X = zeros(rowsOfX, 1+(conesNum*memoryBins), 'single');
    C = zeros(rowsOfX, stimulusDimensions);
    
    fprintf('\nAssembling design matrix (%d x %d) and stimulus vector (%d x %d).\nThis will take a while. Please wait ...', size(X, 1), size(X, 2), size(C, 1), size(C, 2));
    
    X(:,1) = 1;
    for row = 1:rowsOfX
        timeBins = latencyBins + row + (0:(memoryBins-1)) - minTimeBin;
        for coneIndex = 1:conesNum
            startingColumn = 2 + (coneIndex-1)*memoryBins;
            endingColumn = startingColumn + memoryBins - 1;
%             if (endingColumn > size(X,2))
%                 [startingColumn endingColumn size(X,2)]
%             end
%            [timeBins(end) size(signals,2)]
            if (timeBins(end) <= size(signals,2))
                X(row, startingColumn:endingColumn) = signals(coneIndex, timeBins);
            else
                fprintf('column %d > size(signals): %d\n', timeBins(end), size(signals,2));
            end
            
        end % coneIndex
        if (row-minTimeBin <= size(stimulus,1))
            C(row, :) = stimulus(row-minTimeBin,:);
        else
            fprintf('index %d > size(stimulus): %d\n', row-minTimeBin, size(stimulus,1));
        end
        
    end % row

end