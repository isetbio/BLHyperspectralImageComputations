function [X, C] = assembleDesignMatrixAndStimulusVector(totalBins, latencyBins, memoryBins, conesNum, signals, stimulus)

    minTimeBin = min([0 min([latencyBins 0])]);
    rowsOfX = totalBins + minTimeBin;
    stimulusDimensions = size(stimulus,2);
    X = zeros(rowsOfX, 1+(conesNum*memoryBins), 'single');
    C = zeros(rowsOfX, stimulusDimensions);
    
    X(:,1) = 1;
    for row = 1:rowsOfX
        timeBins = latencyBins + row + (0:(memoryBins-1)) - minTimeBin;
        for coneIndex = 1:conesNum
            startingColumn = 2 + (coneIndex-1)*memoryBins;
            endingColumn = startingColumn + memoryBins - 1;
%             if (endingColumn > size(X,2))
%                 [startingColumn endingColumn size(X,2)]
%             end
            X(row, startingColumn:endingColumn) = signals(coneIndex, timeBins);
            C(row, :) = stimulus(row-minTimeBin,:);
        end % coneIndex
    end % row
end