function renderInSamplePredictionsFigures(sceneSetName, descriptionString)

    fprintf('\nLoading stimulus prediction data ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    fprintf('Done.\n');
    
    figNo = 1;
    visualizer.renderReconstructionPerformancePlots(...
        figNo, Ctrain, CtrainPrediction,  originalTrainingStimulusSize ...
    );
    
    if (1==2)
    visualizer.renderScenePrediction(...
        Ctrain, CtrainPrediction,  originalTrainingStimulusSize, ...
        trainingSceneLMSbackground, expParams ...
    );
    end
    
end

