function computeDecodingFilter(sceneSetName, decodingDataDir, SVDbasedLowRankFilterVariancesExplained)

    fprintf('\n1. Loading training design matrix (X) and stimulus vector ... ');
    tic
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', ...
        'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', ...
        'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    
    
    timeSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
        
    computeSVDbasedFilters = true;
    if (computeSVDbasedFilters)
        % Compute and save the SVD decomposition of X so we can check (later) how the
        % filter dynamics depend on the # of SVD components
        fprintf('2a. Computing SVD of design matrix [%d x %d]... ',  size(Xtrain,1), size(Xtrain,2));
        tic
        [Utrain, Strain, Vtrain] = svd(Xtrain, 'econ');
        
        s = diag(Strain);
        tol = max(size(Xtrain))*eps(max(s));
        XtrainRank = sum(s > tol);
        fprintf('Done after %2.1f minutes.\n', toc/60);
        fprintf('<strong>Rank (X) (computed via its SVD) = %d</strong>\n', XtrainRank);
    else
        % Compute the rank of X
        fprintf('2a. Computing rank(X) [%d (time samples) x %d (filter dimensions)]... ',  timeSamples, filterDimensions);
        tic
        XtrainRank = rank(Xtrain);
        fprintf('Done after %2.1f minutes. ', toc/60);
        fprintf('<strong>Rank (X) (computed directly) = %d</strong>\n', XtrainRank);
    end
      
     
    fprintf('2b. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', timeSamples, filterDimensions);
    tic
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('2c. Computing optimal linear decoding filter: coefficients [%d (filter dimensions) x %d (stimulus dimensions)] ... ', filterDimensions, stimulusDimensions);
    tic
    wVector = pseudoInverseOfX * Ctrain;
    fprintf('Done after %2.1f minutes.\n', toc/60);

    if (computeSVDbasedFilters)
        
        % Add one more variance explained, corresponding to the XtrainRank
        SVDcomponentsNum = XtrainRank;
        varianceExplainedAtTrainRankComponents = decoder.determineVarianceExplainedBySpecificNumberOfComponents(Strain, SVDcomponentsNum);
        SVDbasedLowRankFilterVariancesExplained(numel(SVDbasedLowRankFilterVariancesExplained)+1) = varianceExplainedAtTrainRankComponents;
        SVDbasedLowRankFilterVariancesExplained = sort(SVDbasedLowRankFilterVariancesExplained);
        
        fprintf('2ad. Computing SVD-based low-rank approximation filters [%d x %d]... ',  size(Xtrain,1), size(Xtrain,2));
        wVectorSVDbased = zeros(numel(SVDbasedLowRankFilterVariancesExplained), filterDimensions, stimulusDimensions);
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            varExplained = SVDbasedLowRankFilterVariancesExplained(kIndex);
            [wVectorSVDbased(kIndex,:,:), includedComponentsNum(kIndex)] = decoder.lowRankSVDbasedDecodingVector(Utrain, Strain, Vtrain, Ctrain, varExplained);
        end
    end
    
    
    fprintf('3. Computing in-sample predictions [%d x %d]...',  timeSamples, stimulusDimensions);
    tic
    CtrainPrediction = Xtrain * wVector;

    if (computeSVDbasedFilters)
        CtrainPredictionSVDbased = zeros(numel(SVDbasedLowRankFilterVariancesExplained), size(CtrainPrediction,1), size(CtrainPrediction,2));
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            CtrainPredictionSVDbased(kIndex,:, :) = Xtrain * squeeze(wVectorSVDbased(kIndex,:,:));
        end
    end
    
    fprintf('Done after %2.1f minutes.\n', toc/60);

    if (preProcessingParams.designMatrixBased > 0)
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'designMatrixPreprocessing');
        wVectorAdjusted = adjustWvector(preProcessingParams, wVector, designMatrixPreprocessing);
        if (computeSVDbasedFilters)
            wVectorSVDbasedAdjusted = adjustWvector(preProcessingParams, wVectorSVDbased, designMatrixPreprocessing);
        end
    else
        wVectorAdjusted = wVector;
        if (computeSVDbasedFilters)
            wVectorSVDbasedAdjusted = wVectorSVDbased;
        end
    end
    
    fprintf('4. Saving decoder filter and in-sample predictions ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    tic
    save(fileName, 'wVector', 'wVectorAdjusted', 'spatioTemporalSupport', 'coneTypes', 'XtrainRank', 'expParams', '-v7.3');
    if (computeSVDbasedFilters)
        save(fileName, 'Utrain', 'Strain', 'Vtrain', 'wVectorSVDbased', 'wVectorSVDbasedAdjusted', 'includedComponentsNum', 'SVDbasedLowRankFilterVariancesExplained', '-append'); 
    end
    
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', 'XtrainRank', ...
        'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
        'trainingScanInsertionTimes', 'trainingSceneLMSbackground', ...
        'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams',  '-v7.3');
    if (computeSVDbasedFilters)
        save(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained', 'includedComponentsNum', '-append');
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    
    
    % Save to params to JSON file
    core.exportExpParamsToJSONfile(sceneSetName, decodingDataDir, expParams, SVDbasedLowRankFilterVariancesExplained);
end


function wVectorAdjusted = adjustWvector(preProcessingParams, wVector, designMatrixPreprocessing)
    % We can only undo the scaling, the offset affects the b0 term (bias)
    if (preProcessingParams.designMatrixBased == 2) && (~isempty(designMatrixPreprocessing))
        if (ndims(wVector) == 3)
            for kIndex = 1:size(wVector,1)
                wVectorAdjusted(kIndex,:,:) = undoScalingPreProcessing(squeeze(wVector(kIndex,:,:)), designMatrixPreprocessing);
            end
        else
            wVectorAdjusted = undoScalingPreProcessing(wVector, designMatrixPreprocessing);
        end
    else
        wVectorAdjusted = wVector;
    end
end

function wVectorAdjusted = undoScalingPreProcessing(wVector, designMatrixPreprocessing)
    [neuralFeaturesNum, stimFeaturesNum] = size(wVector);
    wVectorAdjusted = wVector;
    if (isfield(designMatrixPreprocessing, 'normalizingOperator'))
       wVectorAdjusted(2:end,:) = bsxfun(@times, wVector(2:end,:), reshape(designMatrixPreprocessing.normalizingOperator, [neuralFeaturesNum-1 1]));
    end 
   
end
