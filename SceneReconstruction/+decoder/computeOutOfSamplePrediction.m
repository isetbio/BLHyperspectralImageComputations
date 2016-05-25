function computeOutOfSamplePrediction(sceneSetName, decodingDataDir)

    % Load test design matrices and stimulus vectors
    fileName = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    fprintf('\n1. Loading test design matrix and stim vector from ''%s''... ', fileName);
    load(fileName, 'Xtest', 'Ctest', 'oiCtest', 'testingTimeAxis', 'testingSceneIndexSequence', 'testingSensorPositionSequence', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'testingOpticalImageLMSbackground', 'originalTestingStimulusSize', 'expParams');
    fprintf('Done.\n');
   

    fprintf('2. Loading decoder filter ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector', 'spatioTemporalSupport';
    
    computeSVDbasedPredictions = true;
    if (computeSVDbasedPredictions)
        load(fileName, 'wVectorSVDbased', 'SVDbasedLowRankFilterVariancesExplained', 'includedComponentsNum');
    end
    fprintf('Done\n');
    
    tic
    stimulusDimensions = size(Ctest,2);
    fprintf('3. Computing out-of-sample predictions [%d x %d]...',  size(Xtest,1), stimulusDimensions);
    CtestPrediction = Xtest * wVector;    
        
    computeSVDbasedFPredictions = true;
    if (computeSVDbasedFPredictions)
        CtestPredictionSVDbased = zeros(numel(SVDbasedLowRankFilterVariancesExplained), size(CtestPrediction,1), size(CtestPrediction,2));
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            w = squeeze(wVectorSVDbased(kIndex,:,:));
            CtestPredictionSVDbased(kIndex,:, :) = Xtest * w;
        end
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('4. Saving out-of-sample prediction ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctest', 'CtestPrediction', 'oiCtest', 'testingTimeAxis', 'testingSceneIndexSequence', 'testingSensorPositionSequence', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'testingOpticalImageLMSbackground', 'originalTestingStimulusSize', 'expParams', '-v7.3');
    
    if (computeSVDbasedFPredictions)
        save(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained', 'includedComponentsNum', '-append');
    end
    
    fprintf('Done after %2.1f minutes.\n', toc/60);
end
