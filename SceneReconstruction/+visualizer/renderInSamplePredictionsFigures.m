function renderInSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    figNo = 1;
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end
    imageFileName = fullfile(core.getDecodingDataDir(descriptionString), sprintf('InSamplePerformance%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
    
    visualizer.renderReconstructionPerformancePlots(...
        figNo, imageFileName, Ctrain, CtrainPrediction,  originalTrainingStimulusSize, expParams ...
    );
    
    if (1==2)
    visualizer.renderScenePrediction(...
        Ctrain, CtrainPrediction,  originalTrainingStimulusSize, ...
        trainingSceneLMSbackground, expParams ...
    );
    end
    
    
end

