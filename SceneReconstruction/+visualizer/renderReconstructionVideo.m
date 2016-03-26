function renderReconstructionVideo(sceneSetName, descriptionString)

    % Make hypothetical super display that can display the natural scenes
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 15;
    [coneFundamentals, displaySPDs, wave] = core.LMSRGBconversionData(displayName, gain);
    
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    load(fileName,  'oiCtrain', 'Ctrain', 'CtrainPrediction', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'trainingScanInsertionTimes',  'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams');
    
    
    makeVideo(sceneSetName, descriptionString, coneFundamentals, displaySPDs, Ctrain, CtrainPrediction, oiCtrain, ...
                trainingTimeAxis, trainingSceneIndexSequence, trainingSensorPositionSequence, trainingScanInsertionTimes, ...
                trainingSceneLMSbackground, originalTrainingStimulusSize, expParams);
end

function makeVideo(sceneSetName, descriptionString, coneFundamentals, displaySPDs, Cinput, Creconstruction, oiCinput, timeAxis, sceneIndexSequence, sensorPositionSequence, scanInsertionTimes,  sceneLMSbackground, originalStimulusSize, expParams)
 
    [LMScontrastReconstruction,~] = ...
        decoder.stimulusSequenceToDecoderFormat(...
            decoder.decoderFormatFromDesignMatrixFormat(Creconstruction, expParams.decoderParams), ...
            'fromDecoderFormat', originalStimulusSize...
        );
  
    [LMScontrastInput,~] = ...
        decoder.stimulusSequenceToDecoderFormat(...
            decoder.decoderFormatFromDesignMatrixFormat(Cinput, expParams.decoderParams), ...
            'fromDecoderFormat', originalStimulusSize...
        );
    
    [oiLMScontrastInput,~] = ...
        decoder.stimulusSequenceToDecoderFormat(...
            decoder.decoderFormatFromDesignMatrixFormat(oiCinput, expParams.decoderParams), ...
            'fromDecoderFormat', originalStimulusSize...
        );
    
    RGBSequencePrediction = 0*LMScontrastReconstruction;
    RGBSequence = 0*LMScontrastInput;
   
    sceneBackgroundExcitation = mean(sceneLMSbackground, 2);
    
    
    sceneSet = core.sceneSetWithName(sceneSetName);
    slideSize = [2560 1440]/2;
    figureWidth2HeightRatio = slideSize(1)/slideSize(2);
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1]);
    colormap(gray(1024));
    
    scenePlotAxes = [];
    sensorFOVsceneLcontrastAxes = [];
    opticalImageFOVsceneLcontrastAxes = [];
    
    scenePlot = [];
    sensorOutlinePlot = [];
    sensorFOVsceneLcontrastPlot = [];
    opticalImageFOVsceneLcontrastPlot = [];
    
    
    % Only keep the data for which we have reconstructed the signal
    timeAxis = timeAxis(1:size(Creconstruction,1));
    sensorPositionSequence = sensorPositionSequence(1:numel(timeAxis),:);
    sceneIndexSequence = sceneIndexSequence(1:numel(timeAxis));
    
    size(LMScontrastInput)
    size(timeAxis)
    size(sceneIndexSequence)
    size(sensorPositionSequence)

    
    lastSceneIndex = 0;
    for tBin = 1:numel(timeAxis)
        
        sceneIndex = sceneIndexSequence(tBin);
        [tBin numel(timeAxis) sceneIndex]
        
        if (sceneIndex ~= lastSceneIndex)
            fprintf('New scene index: %d at bin: %d\n', sceneIndex, tBin);
            lastSceneIndex = sceneIndex;
            scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
            load(scanFileName, 'scanData', 'scene', 'oi');
            sensorRetinalXaxis = scanData{1}.sensorRetinalXaxis;
            sensorRetinalYaxis = scanData{1}.sensorRetinalYaxis;
            sensorOutlineX = [sensorRetinalXaxis(1) sensorRetinalXaxis(end) sensorRetinalXaxis(end) sensorRetinalXaxis(1)   sensorRetinalXaxis(1)];
            sensorOutlineY = [sensorRetinalYaxis(1) sensorRetinalYaxis(1)   sensorRetinalYaxis(end) sensorRetinalYaxis(end) sensorRetinalYaxis(1)];
            sceneRetinalProjectionXData = scanData{1}.sceneRetinalProjectionXData;
            sceneRetinalProjectionYData = scanData{1}.sceneRetinalProjectionYData;
            sceneWidth2HeightRatio = max(sceneRetinalProjectionXData)/max(sceneRetinalProjectionYData);
            sensorFOVRowRange = scanData{1}.sensorFOVRowRange;
            sensorFOVColRange = scanData{1}.sensorFOVColRange;
            sensorFOVxaxis = scanData{1}.sensorFOVxaxis;
            sensorFOVyaxis = scanData{1}.sensorFOVyaxis;
            
            if (max(sensorRetinalXaxis) > max(sensorFOVxaxis))
                sensorWidthAxis  = sensorRetinalXaxis;
            else
                sensorWidthAxis  = sensorFOVxaxis;
            end
            if (max(sensorRetinalYaxis) > max(sensorFOVyaxis))
                sensorHeightAxis  = sensorRetinalYaxis;
            else
                sensorHeightAxis  = sensorFOVyaxis;
            end
            sensorSizeRatio = max(sensorWidthAxis)/max(sensorHeightAxis);
            
            [sceneLMS, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
            [sceneRGBforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(sceneLMS, displaySPDs, coneFundamentals);
            outsideGamut
            
            LMScontrastInputFrame = squeeze(LMScontrastInput(:,:,:,tBin));
            [RGBcontrastInputforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMScontrastInputFrame, displaySPDs, coneFundamentals);
            outsideGamut
            
            scenePlotAxes                     = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01       0.40 0.320  0.320*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
            sensorFOVsceneRGBAxes             = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01       0.12 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
            sensorFOVopticalImageRGBAxes      = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01      -0.07 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
            
            sensorFOVsceneLcontrastAxes       = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01+0.15  0.12 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
            opticalImageFOVsceneLcontrastAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01+0.15 -0.07 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
           
            
            % The full scene in RGB format
            if (isempty(scenePlot))
                % Initialize the scene plot
                scenePlot = imagesc(sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRGBforSuperDisplay, 'parent', scenePlotAxes);
                set(scenePlotAxes, 'XTick', [], 'YTick', []);
                
                % Initialize the sensor position plot
                hold(scenePlotAxes , 'on');
                sensorOutlinePlot = plot(scenePlotAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
                hold(scenePlotAxes , 'off');
                axis(scenePlotAxes, 'image');
                set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
            
                % Initialize the
                sensorFOVsceneRGBPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, RGBcontrastInputforSuperDisplay, 'parent', sensorFOVsceneRGBAxes);
                axis(sensorFOVsceneRGBAxes, 'image');
                set(sensorFOVsceneRGBAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
                set(sensorFOVsceneRGBAxes, 'CLim', [0 1]);
                set(sensorFOVsceneRGBAxes, 'XTick', [], 'YTick', []);
                
                
                sensorFOVopticalRGBPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, RGBcontrastInputforSuperDisplay, 'parent', sensorFOVopticalImageRGBAxes);
                axis(sensorFOVopticalImageRGBAxes, 'image');
                set(sensorFOVopticalImageRGBAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
                set(sensorFOVopticalImageRGBAxes, 'CLim', [0 1]);
                set(sensorFOVopticalImageRGBAxes, 'XTick', [], 'YTick', []);
                
                % Initialize the scene L-contrast frame  plot
                sensorFOVsceneLcontrastPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(LMScontrastInputFrame(:,:,1)), 'parent', sensorFOVsceneLcontrastAxes);
                axis(sensorFOVsceneLcontrastAxes, 'image');
                set(sensorFOVsceneLcontrastAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
                set(sensorFOVsceneLcontrastAxes, 'CLim', [-1 3]);
                set(sensorFOVsceneLcontrastAxes, 'XTick', [], 'YTick', []);
            
            
                % Initialize the optical image L-contrast frame  plot
                opticalImageFOVsceneLcontrastPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(oiLMScontrastInput(:,:,1,tBin)), 'parent', opticalImageFOVsceneLcontrastAxes);
                axis(opticalImageFOVsceneLcontrastAxes, 'image');
                set(opticalImageFOVsceneLcontrastAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
                set(opticalImageFOVsceneLcontrastAxes, 'CLim', [-1 3]);
                set(opticalImageFOVsceneLcontrastAxes, 'XTick', [], 'YTick', []);
            else
                % Update the scene plot
                set(scenePlot, 'XData',  sceneRetinalProjectionXData, 'YData',  sceneRetinalProjectionYData, 'CData', sceneRGBforSuperDisplay);
                set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
            end
        end
        
        % Update the sensor position plot
        set(sensorOutlinePlot, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));
        
        
        % Update the scene RGB frame plot
        set(sensorFOVsceneRGBPlot, 'CData', RGBcontrastInputforSuperDisplay);
        
        % Update the scene L-contrast frame  plot
        set(sensorFOVsceneLcontrastPlot, 'CData', squeeze(LMScontrastInputFrame(:,:,1)));

        % Update the optical image L-contrast frame  plot
        set(opticalImageFOVsceneLcontrastPlot, 'CData', squeeze(oiLMScontrastInput(:,:,1,tBin)));
        
        drawnow
            
    end % tBin
    

end
