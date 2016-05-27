function computeDecodingFilter(sceneSetName, decodingDataDir, SVDbasedLowRankFilterVariancesExplained)

    fprintf('\n1. Loading training design matrix (X) and stimulus vector ... ');
    tic
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
   
    
    % Compute the rank of X
    timeSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('2a. Computing rank(X) [%d (time samples) x %d (filter dimensions)]... ',  timeSamples, filterDimensions);
    tic
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes. ', toc/60);
    fprintf('<strong>Rank (X) = %d</strong>\n', XtrainRank);
     
    fprintf('2b. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', timeSamples, filterDimensions);
    tic
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('2c. Computing optimal linear decoding filter: coefficients [%d (filter dimensions) x %d (stimulus dimensions)] ... ', filterDimensions, stimulusDimensions);
    tic
    wVector = pseudoInverseOfX * Ctrain;
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    computeSVDbasedFilters = true;
    if (computeSVDbasedFilters)
        % Compute and save the SVD decomposition of X so we can check (later) how the
        % filter dynamics depend on the # of SVD components
        fprintf('2d. Computing SVD-based low-rank approximation filters [%d x %d]... ',  size(Xtrain,1), size(Xtrain,2));
        tic
        [Utrain, Strain, Vtrain] = svd(Xtrain, 'econ');
        
        % Add one more variance explained, corresponding to the XtrainRank
        SVDcomponentsNum = XtrainRank;
        varianceExplainedAtTrainRankComponents = decoder.determineVarianceExplainedBySpecificNumberOfComponents(Strain, SVDcomponentsNum);
        SVDbasedLowRankFilterVariancesExplained(numel(SVDbasedLowRankFilterVariancesExplained)+1) = varianceExplainedAtTrainRankComponents;
        SVDbasedLowRankFilterVariancesExplained = sort(SVDbasedLowRankFilterVariancesExplained);
        
        
        wVectorSVDbased = zeros(numel(SVDbasedLowRankFilterVariancesExplained), filterDimensions, stimulusDimensions);
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            varExplained = SVDbasedLowRankFilterVariancesExplained(kIndex);
            [wVectorSVDbased(kIndex,:,:), includedComponentsNum(kIndex)] = decoder.lowRankSVDbasedDecodingVector(Utrain, Strain, Vtrain, Ctrain, varExplained);
        end
        fprintf('Done after %2.1f minutes.\n', toc/60);
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

    fprintf('4. Saving decoder filter and in-sample predictions ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    tic
    save(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', 'XtrainRank', 'expParams', '-v7.3');
    if (computeSVDbasedFilters)
        save(fileName, 'Utrain', 'Strain', 'Vtrain', 'wVectorSVDbased', 'includedComponentsNum', 'SVDbasedLowRankFilterVariancesExplained', '-append'); 
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


