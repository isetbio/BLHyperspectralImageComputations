function resultsDir = getResultsDir(opticalElements, inertPigments, overlap,fixationMeanDuration, microFixationGain, mosaicSize, mosaicLMSdensities, reconstructedStimulusSpatialResolutionInMicrons, osType)
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    resultsDir = fullfile(p.computedDataDir, ...
        sprintf('OpticalElements%s_InertPigments%s', upper(opticalElements), upper(inertPigments)), ...
        sprintf('Overlap%2.2f_Fixation%dms_MicrofixationGain%2.1f_MosaicSize%dx%d_LMSdens%1.2fx%1.2fx%1.2f_ReconstructedStimulusSpatialResolution%3.1fMicrons', overlap, fixationMeanDuration, microFixationGain, mosaicSize(1), mosaicSize(2), mosaicLMSdensities(1), mosaicLMSdensities(2), mosaicLMSdensities(3), reconstructedStimulusSpatialResolutionInMicrons), ...
        sprintf('%s', osType) ...
    );

    if (~exist(resultsDir, 'dir'))
        fprintf('Directory ''%s'' does not exist. Will create it now.\n', resultsDir);
        mkdir(resultsDir);
    end
    
end