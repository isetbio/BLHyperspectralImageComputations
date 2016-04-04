function decodingDataDir = getDecodingDataDir(resultsDir)
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    decodingDataDir = fullfile(p.computedDataDir, resultsDir, 'decodingData');
    if (~exist(decodingDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', decodingDataDir);
        mkdir(decodingDataDir);
    end
end
