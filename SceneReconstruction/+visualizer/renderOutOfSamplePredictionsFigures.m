function renderOutOfSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctest', 'CtestPrediction', 'testingTimeAxis', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'originalTestingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    figNo = 2;
    visualizer.renderReconstructionPerformancePlots(...
        figNo, Ctest, CtestPrediction,  originalTestingStimulusSize ...
    );
    
    if (1==1)
    visualizer.renderScenePrediction(...
        Ctest, CtestPrediction,  originalTestingStimulusSize, ...
        testingSceneLMSbackground, expParams ...
    );

    end
    
end

    