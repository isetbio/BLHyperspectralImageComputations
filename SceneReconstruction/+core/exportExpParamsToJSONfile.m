function exportExpParamsToJSONfile(sceneSetName, decodingDataDir, expParams, SVDbasedLowRankFilterVariancesExplained)

    opt.FileName = fullfile(decodingDataDir, sprintf('%s_expParams.json', sceneSetName));
    expParams.SVDbasedLowRankFilterVariancesExplained = SVDbasedLowRankFilterVariancesExplained;
    savejson('', expParams, opt);
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    fprintf('Experiment params saved to ''%s''.\n', strrep(opt.FileName, sprintf('%s/',p.computedDataDir),''));
end
