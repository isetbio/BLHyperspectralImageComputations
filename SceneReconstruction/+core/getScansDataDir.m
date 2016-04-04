function scansDataDir = getScansDataDir(resultsDir)
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    scansDataDir = fullfile(p.computedDataDir, resultsDir, 'scansData');
    if (~exist(scansDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', scansDataDir);
        mkdir(scansDataDir);
    end
end

