function decodingDataDir = getDecodingDataDir(resultsDir, preProcessingParams)

    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    decodingDataDir = fullfile(p.computedDataDir, resultsDir, 'decodingData');
    
    if (preProcessingParams.designMatrixBased > 0)
        decodingDataDir = fullfile(decodingDataDir, sprintf('designMatrixBasedPreProcessing%d', preProcessingParams.designMatrixBased));
    elseif (preProcessingParams.rawResponseBased > 0)
        decodingDataDir = fullfile(decodingDataDir, sprintf('responseBasedPreProcessing%d', preProcessingParams.rawResponseBased));
    else
        decodingDataDir = fullfile(decodingDataDir, sprintf('noPreprocessing'));
    end
    
    if (~exist(decodingDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.', decodingDataDir);
        mkdir(decodingDataDir);
    end
end
