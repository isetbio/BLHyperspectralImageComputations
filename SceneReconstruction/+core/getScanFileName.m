function scanFileName = getScanFileName(sceneSetName, descriptionString, sceneIndex)
    sceneSet = core.sceneSetWithName(sceneSetName);
    scansDataDir = core.getScansDataDir(descriptionString);
    imsource  = sceneSet{sceneIndex};
    sceneName = sprintf('%s_%s', imsource{1}, imsource{2});
    scanFileName = fullfile(scansDataDir, sprintf('%s_scan_data.mat', sceneName));
end
