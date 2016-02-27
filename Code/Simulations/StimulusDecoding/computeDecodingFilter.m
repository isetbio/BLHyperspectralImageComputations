function computeDecodingFilter

    minargs = 0;
    maxargs = 1;
    narginchk(minargs, maxargs);
    
    if (nargin == 0)
        configuration = 'manchester'
    else
        configuration = varargin{1}
    end
    
    decodingDataFileName = sprintf('decodingData_%s.mat', configuration);
    trainingVarList = {...
        'designMatrix', ...
        'trainingTimeAxis', ...
        'trainingPhotocurrents', ...
        'trainingLcontrastSequence', ...
        'trainingMcontrastSequence', ...
        'trainingScontrastSequence' ...
        };
    
    for k = 1:numel(trainingVarList)
        load(decodingDataFileName, trainingVarList{k});
    end
    
    whos
    pause
    
    trainingStimulusTrain = [
        trainingLcontrastSequence', ...
        trainingMcontrastSequence', ...
        trainingScontrastSequence' ...
        ];
    
    % Assemble X and c matrices
    [Xtrain, cTrain] = assembleDesignMatrixAndStimulusVector(designMatrix.T, designMatrix.lat, designMatrix.m, designMatrix.n, trainingPhotocurrents, trainingStimulusTrain);
    clear(trainingVarList{:});
    
    % Compute decoding filter, wVector
    pseudoInverseOfX = pinv(Xtrain);
    featuresNum = size(Xtrain,2)
    stimulusDimensions = size(cTrain,2)
    wVector = zeros(featuresNum, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * cTrain(:,stimDim);
    end
    
    % Compute in-sample predictions
    cTrainPrediction = cTrain*0;
    for stimDim = 1:stimulusDimensions
        cTrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    
    save(sprintf('DecodingFilters_%s.mat', configuration), 'wVector', 'cTrainPrediction', 'cTrain'); 
    
    

    return;
    
    wLcone = pseudoInverseOfX  * lConeC;
    wMcone = pseudoInverseOfX  * mConeC;
    wScone = pseudoInverseOfX  * sConeC;
    
    size(trainingTimeAxis)
    size(trainingPhotocurrents)
    
    
    minTimeBin = min([0 min([designMatrix.lat 0])])
    rowsOfX = designMatrix.T + minTimeBin

    
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
    
    decoding
    save(sprintf('DecodingFilters_%s.mat', configuration), 'wLcone', 'wMcone', 'wScone'); 
end


