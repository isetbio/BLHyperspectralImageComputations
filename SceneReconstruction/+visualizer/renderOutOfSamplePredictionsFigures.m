function renderOutOfSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctest', 'CtestPrediction', 'testingTimeAxis', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'originalTestingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    figNo = 2;
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end
    imageFileName = fullfile(core.getDecodingDataDir(descriptionString), sprintf('OutOfSamplePerformance%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
       
    visualizer.renderReconstructionPerformancePlots(...
        figNo, imageFileName, Ctest, CtestPrediction,  originalTestingStimulusSize, expParams ...
    );
    
    if (1==2)
    visualizer.renderScenePrediction(...
        Ctest, CtestPrediction,  originalTestingStimulusSize, ...
        testingSceneLMSbackground, expParams ...
    );

    end
    
end

    