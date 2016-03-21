function scansDataDir = getScansDataDir(descriptionString)
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    scansDataDir = fullfile(p.computedDataDir, descriptionString, 'scansData');
    if (~exist(scansDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', scansDataDir);
        mkdir(scansDataDir);
    end
end

