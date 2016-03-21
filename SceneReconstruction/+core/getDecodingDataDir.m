function decodingDataDir = getDecodingDataDir(descriptionString)
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    decodingDataDir = fullfile(p.computedDataDir, descriptionString, 'decodingData');
    if (~exist(decodingDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', decodingDataDir);
        mkdir(decodingDataDir);
    end
end
