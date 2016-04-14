function resultsDir = getResultsDir(overlap,fixationMeanDuration, microFixationGain, osType)
    resultsDir = fullfile(sprintf('Overlap%2.2f_Fixation%dms_MicrofixationGain%2.1f', overlap, fixationMeanDuration, microFixationGain), sprintf('%s', osType));
end