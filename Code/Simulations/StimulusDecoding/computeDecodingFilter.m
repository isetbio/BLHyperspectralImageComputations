function computeDecodingFilter

    decodingDataFileName = 'decodingData.mat';
    load(decodingDataFileName, 'designMatrix', ...
        'trainingTimeAxis', 'trainingPhotocurrents', 'trainingLcontrastSequence', 'trainingMcontrastSequence', 'trainingScontrastSequence');
    
    minTimeBin = min([0 min([designMatrix.lat 0])])
    rowsOfX = designMatrix.T + minTimeBin;
    
    X = zeros(rowsOfX, 1+(designMatrix.n*designMatrix.m), 'single');
    lConeC= zeros(rowsOfX, 1, 'single');
    mConeC= zeros(rowsOfX, 1, 'single');
    sConeC= zeros(rowsOfX, 1, 'single');
    
    sizeXbefore = size(X);
    X(:,1) = 1;
    for row = 1:rowsOfX
        timeBins = designMatrix.lat + row + (0:(designMatrix.m-1)) - minTimeBin;
      %  [row rowsOfX size(X,2) timeBins(1) timeBins(end) size(trainingPhotocurrents,2)]
        for coneIndex = 1:designMatrix.n
            startingColumn = 2 + (coneIndex-1)*designMatrix.m;
            endingColumn = startingColumn + designMatrix.m - 1;
            %fprintf('row: %d cone: %d startingColumn: %d, timeBins: %d .. %d\n', row, coneIndex, startingColumn, timeBins(1), timeBins(end));
            if (endingColumn > size(X,2))
                [startingColumn endingColumn size(X,2)]
            end
            
            X(row, startingColumn:endingColumn) = trainingPhotocurrents(coneIndex, timeBins);
        end
%         
%         if (row == 100)
%             X(1:100, 1:5)
%         end
        
        lConeC(row) = trainingLcontrastSequence(row-minTimeBin);
        mConeC(row) = trainingMcontrastSequence(row-minTimeBin);
        sConeC(row) = trainingScontrastSequence(row-minTimeBin);
    end
    
    sizeXbefore
    sizeXafter = size(X)

    tic
    pseudoInverseOfX = pinv(X);
    fprintf('Pseudo inverse computation took %2.2f seconds\n', toc);
    
    wLcone = pseudoInverseOfX  * lConeC;
    wMcone = pseudoInverseOfX  * mConeC;
    wScone = pseudoInverseOfX  * sConeC;
    
    save('DecodingFilters.mat', 'wLcone', 'wMcone', 'wScone'); 
end

