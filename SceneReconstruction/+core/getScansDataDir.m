function scansDataDir = getScansDataDir(resultsDir)
    scansDataDir = fullfile(resultsDir, 'scansData');
    if (~exist(scansDataDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', scansDataDir);
        mkdir(scansDataDir);
    end
end

