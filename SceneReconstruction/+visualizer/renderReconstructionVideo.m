function renderReconstructionVideo(sceneSetName, descriptionString)

    % Make hypothetical super display that can display the natural scenes
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 15;
    [coneFundamentals, displaySPDs, wave] = core.LMSRGBconversionData(displayName, gain);
    
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'trainingScanInsertionTimes',  'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    
    
    makeVideo(sceneSetName, descriptionString, coneFundamentals, displaySPDs, Ctrain, CtrainPrediction, ...
                trainingTimeAxis, trainingSceneIndexSequence, trainingSensorPositionSequence, trainingScanInsertionTimes, ...
                trainingSceneLMSbackground, originalTrainingStimulusSize, expParams);
end

function makeVideo(sceneSetName, descriptionString, coneFundamentals, displaySPDs, Cinput, Creconstruction, timeAxis, sceneIndexSequence, sensorPositionSequence, scanInsertionTimes,  sceneLMSbackground, originalStimulusSize, expParams)
    
    reconstructionDecoderFormat = decoder.decoderFormatFromDesignMatrixFormat(Creconstruction, expParams.decoderParams);
    inputDecoderFormat = decoder.decoderFormatFromDesignMatrixFormat(Cinput, expParams.decoderParams);
    
    [LMScontrastReconstruction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(reconstructionDecoderFormat, 'fromDecoderFormat', originalStimulusSize);
  
    [LMScontrastInput,~] = ...
        decoder.stimulusSequenceToDecoderFormat(inputDecoderFormat, 'fromDecoderFormat', originalStimulusSize);
    
    RGBSequencePrediction = 0*LMScontrastReconstruction;
    RGBSequence = 0*LMScontrastInput;
   
    sceneBackgroundExcitation = mean(sceneLMSbackground, 2);
    
    
    sceneSet = core.sceneSetWithName(sceneSetName);
    slideSize = [2560 1440]/2;
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1]);
    
    scenePlotAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01 0.5 0.4 0.48]);
    scenePlot = [];
    sensorOutlinePlot = [];
    
    sensorFOVsceneLcontrastAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01 0.42 0.1 0.1]);
    sensorFOVsceneLcontrastPlot = [];
    
    % Only keep the data for which we have reconstructed the signal
    timeAxis = timeAxis(1:size(Creconstruction,1));
    sensorPositionSequence = sensorPositionSequence(1:numel(timeAxis),:);
    sceneIndexSequence = sceneIndexSequence(1:numel(timeAxis));
    
    size(LMScontrastInput)
    size(timeAxis)
    size(sceneIndexSequence)
    size(sensorPositionSequence)
    pause;
    
    lastSceneIndex = 0;
    for tBin = 1:numel(timeAxis)
        
        sceneIndex = sceneIndexSequence(tBin);
        [tBin numel(timeAxis) sceneIndex]
        
        if (sceneIndex ~= lastSceneIndex)
            fprintf('New scene index: %d at bin: %d\n', sceneIndex, tBin);
            lastSceneIndex = sceneIndex;
            scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
            load(scanFileName, 'scanData', 'scene', 'oi');
            sensorOutlineX = [scanData{1}.sensorRetinalXaxis(1) scanData{1}.sensorRetinalXaxis(end) scanData{1}.sensorRetinalXaxis(end) scanData{1}.sensorRetinalXaxis(1)   scanData{1}.sensorRetinalXaxis(1)];
            sensorOutlineY = [scanData{1}.sensorRetinalYaxis(1) scanData{1}.sensorRetinalYaxis(1)   scanData{1}.sensorRetinalYaxis(end) scanData{1}.sensorRetinalYaxis(end) scanData{1}.sensorRetinalYaxis(1)];
            sceneRetinalProjectionXData = scanData{1}.sceneRetinalProjectionXData;
            sceneRetinalProjectionYData = scanData{1}.sceneRetinalProjectionYData;
            sensorFOVRowRange = scanData{1}.sensorFOVRowRange;
            sensorFOVColRange = scanData{1}.sensorFOVColRange;
            sensorFOVxaxis = scanData{1}.sensorFOVxaxis;
            sensorFOVyaxis = scanData{1}.sensorFOVyaxis;
            [sceneLMS, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
            [sceneRGBforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(sceneLMS, displaySPDs, coneFundamentals);
            outsideGamut
            
            % The full scene in RGB format
            if (isempty(scenePlot))
                % Initialize the scene plot
                scenePlot = imagesc(sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRGBforSuperDisplay, 'parent', scenePlotAxes);
                
                % Initialize the sensor position plot
                hold(scenePlotAxes , 'on');
                sensorOutlinePlot = plot(scenePlotAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
                hold(scenePlotAxes , 'off');
                axis(scenePlotAxes, 'image');
                set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
            
                % Initialize the scene L-contrast frame  plot
                sensorFOVsceneLcontrastPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(LMScontrastInput(:,:,1,tBin)), 'parent', sensorFOVsceneLcontrastAxes);
            else
                % Update the scene plot
                set(scenePlot, 'XData',  sceneRetinalProjectionXData, 'YData',  sceneRetinalProjectionYData, 'CData', sceneRGBforSuperDisplay);
                set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
            end
        end
        
        % Update the sensor position plot
        set(sensorOutlinePlot, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));
        
        % Update the scene L-contrast frame  plot
        set(sensorFOVsceneLcontrastPlot, 'CData', squeeze(LMScontrastInput(:,:,1,tBin)));

                
        drawnow
            
    end % tBin
    

end
