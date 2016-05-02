function exportExpParamsToJSONfile(sceneSetName, decodingDataDir, expParams, SVDbasedLowRankFilterVariancesExplained)

    fileName = fullfile(decodingDataDir, sprintf('%s_expParams.json', sceneSetName));
    expParams.SVDbasedLowRankFilterVariancesExplained = SVDbasedLowRankFilterVariancesExplained;
    opt.FileName = fileName;
    savejson('', expParams, opt);
    fprintf('<strong>\nExperiment params saved to ''%s''.</strong>\n', fileName);
end
