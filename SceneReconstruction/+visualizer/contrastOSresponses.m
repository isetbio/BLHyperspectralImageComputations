function contrastOSresponses(sceneSetName, linearDecodingDataDir, biophysDecodingDataDir)

    linearDecodingDataDir
    biophysDecodingDataDir
    pause
    InSampleOrOutOfSample = 'InSample';
    
    coneRow = 11;
    coneCol = 13;
    timePointsToReturn = 30000;
    
    [timeAxis1, linearResponseSequence] = retrieveResponseData(...
        sceneSetName, linearDecodingDataDir, coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample);
      
    [timeAxis2, biophysResponseSequence] = retrieveResponseData(...
        sceneSetName, biophysDecodingDataDir, coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample);
 
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1080 1080], 'MenuBar', 'none');
    subplot('Position', [0.06 0.06 0.93 0.93])
    plot(linearResponseSequence, biophysResponseSequence, 'k.');
    hold on;
    plot([-60 40], [-100 0], 'r-', 'LineWidth', 2.0);
    hold off
    set(gca, 'FontSize', 18, 'FontName', 'Menlo', 'YLim', [-100 0], 'XLim', [-60 40]);
    xlabel('@osLinear response', 'FontSize', 20, 'FontName', 'Menlo');
    ylabel('@osBiophys response', 'FontSize', 20, 'FonrName', 'Menlo');
    drawnow;
    imageFileName = fullfile(decodingDataDir, sprintf('LinearVsBiophysResponse'));
    fprintf(2, 'Figure saved in %s\n', imageFileName);
    NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
    save('data.mat', 'linearResponseSequence', 'biophysResponseSequence')
    
    
end

function [timeAxis,responseSequence] = retrieveResponseData(...
    sceneSetName, decodingDataDir,  coneRow, coneCol, timePointsToReturn, InSampleOrOutOfSample)
    
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        
        fprintf('Loading design matrix to reconstruct the original responses ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'Xtrain', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'expParams');
        expParams.preProcessingParams = preProcessingParams;
        responseSequence = decoder.reformatDesignMatrixToOriginalResponse(Xtrain, rawTrainingResponsePreprocessing, preProcessingParams, expParams.decoderParams, expParams.sensorParams);
        
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName, 'trainingTimeAxis');
        
        % Only keep the data for which we have reconstructed the signal
        timeAxis = trainingTimeAxis(1:timePointsToReturn);
        responseSequence = squeeze(responseSequence(coneRow, coneCol, 1:timePointsToReturn));
    end
    
    if (strcmp(InSampleOrOutOfSample, 'OutOfSample'))
        error('Not implemented')
    end 
end

