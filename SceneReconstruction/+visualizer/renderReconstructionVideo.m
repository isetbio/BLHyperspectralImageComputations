function renderReconstructionVideo(sceneSetName, descriptionString)

    % Make hypothetical super display that can display the natural scenes
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 8;
    [coneFundamentals, displaySPDs, RGBtoXYZ, wave] = core.LMSRGBconversionData(displayName, gain);
    
    
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    whichOne = input('In-sample (1) or out-of-sample(2) data : ');
    if (whichOne == 1)
        
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName,  'oiCtrain', 'Ctrain', 'CtrainPrediction', ...
            'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
            'trainingScanInsertionTimes',  'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', ...
            'originalTrainingStimulusSize', 'expParams');
        if (expParams.outerSegmentParams.addNoise)
            outerSegmentNoiseString = 'Noise';
        else
            outerSegmentNoiseString = 'NoNoise';
        end
        videoName = sprintf('Reconstruction%s%sOverlap%2.1fMeanLum%dInSample', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance);
        makeVideo(videoName, sceneSetName, descriptionString, coneFundamentals, displaySPDs, RGBtoXYZ, Ctrain, CtrainPrediction, oiCtrain, ...
                trainingTimeAxis, trainingSceneIndexSequence, trainingSensorPositionSequence, trainingScanInsertionTimes, ...
                trainingSceneLMSbackground, trainingOpticalImageLMSbackground, originalTrainingStimulusSize, expParams);
    else
        fileName = fullfile(decodingDataDir, sprintf('%s_outOfSamplePrediction.mat', sceneSetName));
        load(fileName,  'oiCtest', 'Ctest', 'CtestPrediction', ...
            'testingTimeAxis', 'testingSceneIndexSequence', 'testingSensorPositionSequence', ...
            'testingScanInsertionTimes',  'testingSceneLMSbackground', 'testingOpticalImageLMSbackground', ...
            'originalTestingStimulusSize', 'expParams');
        if (expParams.outerSegmentParams.addNoise)
            outerSegmentNoiseString = 'Noise';
        else
            outerSegmentNoiseString = 'NoNoise';
        end
        videoName = sprintf('Reconstruction%s%sOverlap%2.1fMeanLum%dOutOfSample', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance);
        makeVideo(videoName, sceneSetName, descriptionString, coneFundamentals, displaySPDs, RGBtoXYZ, Ctest, CtestPrediction, oiCtest, ...
                testingTimeAxis, testingSceneIndexSequence, testingSensorPositionSequence, testingScanInsertionTimes, ...
                testingSceneLMSbackground, testingOpticalImageLMSbackground, originalTestingStimulusSize, expParams);
    end 
end




function makeVideo(videoName, sceneSetName, descriptionString, coneFundamentals, displaySPDs, RGBtoXYZ, Cinput, Creconstruction, oiCinput, ...
    timeAxis, sceneIndexSequence, sensorPositionSequence, scanInsertionTimes,  sceneLMSbackground, opticalImageLMSbackground, originalStimulusSize, expParams)
 
    
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
   
    sceneBackgroundExcitation = mean(sceneLMSbackground, 2);
    opticalImageBackgroundExcitation = mean(opticalImageLMSbackground, 2);  

    % Only keep the data for which we have reconstructed the signal
    timeAxis = timeAxis(1:size(Creconstruction,1));
    sensorPositionSequence = sensorPositionSequence(1:numel(timeAxis),:);
    sceneIndexSequence = sceneIndexSequence(1:numel(timeAxis));

    
    slideSize = [2560 1440]/2;
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1], 'Name', videoName);
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'spectralLUT');
    colormap(spectralLUT);
    
    luminanceRange = [0 1500];
    oiRGBgain = 50;
    
    gamma = 1.0/1.6;
    lastSceneIndex = 0;
    
    for tBin = 1:numel(timeAxis)
        
        % Compute RGB version of the sensor's view of the scene
        LMSexcitationFrame = core.excitationFromContrast(squeeze(LMScontrastInput(:,:,:,tBin)), sceneBackgroundExcitation);
        [sensorFOVsceneRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMSexcitationFrame, displaySPDs, coneFundamentals);
        if (any(outsideGamut(:)) == 1)
            outsideGamut
        end
        % Compute RGB map for scene (as rendered in the super display)
        sensorFOVsceneLumMap = core.displayRGBtoLuminanceforSpecificDisplay(sensorFOVsceneRGBimage, RGBtoXYZ);
        % Clip RGBimage to [0..1], then gamma for display
        sensorFOVsceneRGBimage = linearRGBtoDisplay(sensorFOVsceneRGBimage, gamma);
        
        
        % Compute RGB version of the sensor's optical image view
        LMSexcitationFrame = core.excitationFromContrast(squeeze(oiLMScontrastInput(:,:,:,tBin)), opticalImageBackgroundExcitation);
        [sensorFOVoiRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMSexcitationFrame, displaySPDs, coneFundamentals);
        if (any(outsideGamut(:)) == 1)
            outsideGamut
        end
        % Compute luminance map for the oi (as rendered in the super display)
        sensorFOVoiLumMap = core.displayRGBtoLuminanceforSpecificDisplay(sensorFOVoiRGBimage, RGBtoXYZ);
        % clip RGBimage to [0..1], then gamma for display
        sensorFOVoiRGBimage = linearRGBtoDisplay(oiRGBgain * sensorFOVoiRGBimage, gamma);
        
        
        % Compute RGB version of the sensor's reconstruction of the scene
        LMSexcitationFrame = core.excitationFromContrast(squeeze(LMScontrastReconstruction(:,:,:,tBin)), sceneBackgroundExcitation);
        [sensorFOVreconstructionRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMSexcitationFrame, displaySPDs, coneFundamentals);
        if (any(outsideGamut(:)) == 1)
            outsideGamut
        end 
        % Compute luminance map for the sensor reconstruction (as rendered in the super display)
        sensorFOVreconstructionLumMap = core.displayRGBtoLuminanceforSpecificDisplay(sensorFOVreconstructionRGBimage, RGBtoXYZ);
        % Clip RGBimage to [0..1], then gamma for display
        sensorFOVreconstructionRGBimage = linearRGBtoDisplay(sensorFOVreconstructionRGBimage, gamma);
        
        
        sceneIndex = sceneIndexSequence(tBin);
        
        if (sceneIndex ~= lastSceneIndex)
            fprintf('New scene index: %d at bin: %d\n', sceneIndex, tBin);
            lastSceneIndex = sceneIndex;
            [scene, sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneWidth2HeightRatio, ...
                sensorOutlineX, sensorOutlineY, sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, sensorWidthAxis, sensorHeightAxis, sensorWidth2HeightRatio, ...
                 ] = ...
                getSceneData(sceneSetName, descriptionString, sceneIndex);
            
            % Make RGB, LMS, and Lum maps versions of scene
            [sceneLMS, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
            [sceneRGBforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(sceneLMS, displaySPDs, coneFundamentals);
            if (any(outsideGamut(:)) == 1)
                outsideGamut
            end
            % Compute luminance map for scene (as rendered in the super display)
            sceneLumMapForSuperDisplay = core.displayRGBtoLuminanceforSpecificDisplay(sceneRGBforSuperDisplay, RGBtoXYZ);
            [min(sceneLumMapForSuperDisplay(:)) max(sceneLumMapForSuperDisplay(:))]
            % Clip RGBimage to [0..1], then gamma for display
            sceneRGBforSuperDisplay = linearRGBtoDisplay(sceneRGBforSuperDisplay, gamma);
           
            % Generate new axes
            [sceneAxes, oiAxes, sceneLumMapAxes, oiLumMapAxes, reconstructedSceneRGBaxes, ...
                sensorFOVsceneRGBaxes, sensorFOVsceneLumMapAxes, sensorFOVsceneLcontAxes, sensorFOVsceneMcontAxes, sensorFOVsceneScontAxes, ...
                sensorFOVoiRGBaxes, sensorFOVoiLumMapAxes, sensorFOVoiLcontAxes, sensorFOVoiMcontAxes, sensorFOVoiScontAxes, ...
                sensorFOVreconstructionRGBaxes, sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLcontAxes, sensorFOVreconstructionMcontAxes, sensorFOVreconstructionScontAxes ...
                ] = makeAxes(hFig, slideSize(1)/slideSize(2), sceneWidth2HeightRatio, sensorWidth2HeightRatio);
    
            
            % Make new scene plot
            imagesc(sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRGBforSuperDisplay, 'parent', sceneAxes);
            set(sceneAxes, 'XTick', [], 'YTick', []);
                                  
            % Initialize the sensor position on sceneRGB plot
            hold(sceneAxes , 'on');
            sensorOutlinePlot = plot(sceneAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(sceneAxes , 'off');
            axis(sceneAxes, 'image');
            set(sceneAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], ...
                           'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
                  
            % Make new scene luminance map 
            imagesc(sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneLumMapForSuperDisplay, 'parent', sceneLumMapAxes);
            set(sceneLumMapAxes, 'XTick', [], 'YTick', [], 'CLim', luminanceRange);
            
            % Initialize the sensor position on scene LumMap plot
            hold(sceneLumMapAxes , 'on');
            sensorOutlinePlotOnLumMap = plot(sceneLumMapAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(sceneLumMapAxes , 'off');
            axis(sceneLumMapAxes, 'image');
            set(sceneLumMapAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], ...
                                 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
            hCbar = colorbar('eastoutside', 'peer', sceneLumMapAxes, ...
                                'Ticks', [0 100 500 1000 1500 2000], 'TickLabels', {'0', '100', '500', '1000', '1500', '2000'});
            hCbar.Label.String = 'luminance (cd/m2)';
            hCbar.FontSize = 12;
    
            % Initialize the reconstructedSceneRGBPlot
            sensorSampleSeparation = sensorFOVxaxis(2)-sensorFOVxaxis(1);
            reconstructedSceneRetinalProjectionXData = linspace(...
                sceneRetinalProjectionXData(1), sceneRetinalProjectionXData(end), ...
                round((sceneRetinalProjectionXData(end)-sceneRetinalProjectionXData(1))/sensorSampleSeparation));
            reconstructedSceneRetinalProjectionYData = linspace(...
                sceneRetinalProjectionYData(1), sceneRetinalProjectionYData(end), ...
                round((sceneRetinalProjectionYData(end)-sceneRetinalProjectionYData(1))/sensorSampleSeparation));
            reconstructedSceneRGBPlot = initializeSensorViewPlot(...
                reconstructedSceneRGBaxes, zeros(numel(reconstructedSceneRetinalProjectionYData), numel(reconstructedSceneRetinalProjectionXData), 3), [0 1], ...
                reconstructedSceneRetinalProjectionXData, reconstructedSceneRetinalProjectionYData, reconstructedSceneRetinalProjectionXData, reconstructedSceneRetinalProjectionYData);
            
            % Generate empty image to hold the patches of the reconstructed image
            reconstructedSceneRGBforSuperDisplay = zeros(numel(reconstructedSceneRetinalProjectionYData), numel(reconstructedSceneRetinalProjectionXData),3);
            visited = zeros(numel(reconstructedSceneRetinalProjectionYData), numel(reconstructedSceneRetinalProjectionXData));
         
            
            % Initialize the sensorFOVsceneRGBplot
            sensorFOVsceneRGBPlot = initializeSensorViewPlot(...
                sensorFOVsceneRGBaxes, sensorFOVsceneRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);

            % Initialize the sensorFOVoiRGBplot
            sensorFOVoiRGBPlot = initializeSensorViewPlot(...
                sensorFOVoiRGBaxes, sensorFOVoiRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);
            
            % Iinitialize the sensorFOVreconstructionRGBPlot
            sensorFOVreconstructionRGBPlot = initializeSensorViewPlot(...
                sensorFOVreconstructionRGBaxes, sensorFOVsceneRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);
            
            % Initialize the sensorFOVsceneLumMapPlot
            sensorFOVsceneLumMapPlot = initializeSensorViewPlot(...
                sensorFOVsceneLumMapAxes, sensorFOVsceneLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);
            
            % Initialize the sensorFOVoiLumMapPlot
            sensorFOVoiLumMapPlot = initializeSensorViewPlot(...
                sensorFOVoiLumMapAxes, oiRGBgain*sensorFOVoiLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);
            
            % Initialize the sensorFOVreconstructionLumMapPlot
            sensorFOVreconstructionLumMapPlot = initializeSensorViewPlot(...
                sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis);
            
        end  % new scene
        
        % Update the reconstucted image with this patch
        halfRowsCovered = round((sensorPositionSequence(tBin,2) - max(sensorOutlineY) -min(sceneRetinalProjectionYData))/sensorSampleSeparation);
        halfColsCovered = round((sensorPositionSequence(tBin,1) - max(sensorOutlineX) -min(sceneRetinalProjectionXData))/sensorSampleSeparation);
        rowsCovered = halfRowsCovered+(0:size(sensorFOVreconstructionRGBimage,1)-1);
        colsCovered = halfColsCovered+(0:size(sensorFOVreconstructionRGBimage,2)-1);
        
        [rowsCovered(1) rowsCovered(end)]
        [colsCovered(1) colsCovered(end)]
        [reconstructedSceneRetinalProjectionYData(rowsCovered(1))  reconstructedSceneRetinalProjectionYData(rowsCovered(end)) sensorPositionSequence(tBin,2)]
        [reconstructedSceneRetinalProjectionXData(colsCovered(1))  reconstructedSceneRetinalProjectionXData(colsCovered(end)) sensorPositionSequence(tBin,1)]

        visited(rowsCovered, colsCovered) = visited(rowsCovered, colsCovered) + 1;

        reconstructedSceneRGBforSuperDisplay(rowsCovered, colsCovered,:) = ...
            reconstructedSceneRGBforSuperDisplay(rowsCovered, colsCovered,:) + sensorFOVreconstructionRGBimage;
        idx = find(visited(:) > 0);
        [visitedRows, visitedCols] = ind2sub(size(visited), idx);
        tmp_reconstructedSceneRGBforSuperDisplay = 0*reconstructedSceneRGBforSuperDisplay;
        for rgbChannel = 1:3
            tmp_reconstructedSceneRGBforSuperDisplay(visitedRows, visitedCols,rgbChannel) = ...
            reconstructedSceneRGBforSuperDisplay(visitedRows, visitedCols,rgbChannel) ./ visited(visitedRows, visitedCols);
        end
        % Clip RGBimage to [0..1], then gamma for display
        tmp_reconstructedSceneRGBforSuperDisplay = linearRGBtoDisplay(tmp_reconstructedSceneRGBforSuperDisplay, gamma);
        % Update the reconstructedSceneRGBPlot
        set(reconstructedSceneRGBPlot, 'CData',  tmp_reconstructedSceneRGBforSuperDisplay);
        
        
        % Update the sensor position plot (on the scene image) for current time bin
        set(sensorOutlinePlot, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));
        
        % Update the sensor position plot (on the scene luminance map) for current time bin
        set(sensorOutlinePlotOnLumMap, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));
        
        % Update the sensorFOV scene RGB plot
        set(sensorFOVsceneRGBPlot, 'CData', sensorFOVsceneRGBimage);
        
        % Update the sensorFOV oi RGBplot
        set(sensorFOVoiRGBPlot, 'CData', sensorFOVoiRGBimage);
            
        % Update the sensorFOV reconstruction RGB plot
        set(sensorFOVreconstructionRGBPlot, 'CData', sensorFOVreconstructionRGBimage);
            
        % Update the sensorFOVsceneLumMapPlot
        set(sensorFOVsceneLumMapPlot, 'CData', sensorFOVsceneLumMap);
            
        % Update the sensorFOVoiLumMapPlot
        set(sensorFOVoiLumMapPlot, 'CData', oiRGBgain*sensorFOVoiLumMap);
            
        % Update the sensorFOVreconstructionLumMapPlot
        set(sensorFOVreconstructionLumMapPlot, 'CData', sensorFOVreconstructionLumMap)
            
        drawnow;
    end % tBin
    
end


function sensorFOVPlot = initializeSensorViewPlot(sensorFOVAxes, sensorViewImage, imageDataRange, sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis)
    sensorFOVPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, sensorViewImage, 'parent', sensorFOVAxes);
    axis(sensorFOVAxes, 'image');
    set(sensorFOVAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
    set(sensorFOVAxes, 'CLim', imageDataRange);
    set(sensorFOVAxes, 'XTick', [], 'YTick', []);
end

function RGBimage = linearRGBtoDisplay(RGBimage, gamma)
    RGBimage(RGBimage<0) = 0;
    RGBimage(RGBimage>1) = 1;
    RGBimage = RGBimage.^gamma;
end

function [sceneAxes, oiAxes, sceneLumMapAxes, oiLumMapAxes, reconstructedSceneRGBaxes, ...
           sensorFOVsceneRGBaxes, sensorFOVsceneLumMapAxes, sensorFOVsceneLcontAxes, sensorFOVsceneMcontAxes, sensorFOVsceneScontAxes, ...
           sensorFOVoiRGBaxes,    sensorFOVoiLumMapAxes, sensorFOVoiLcontAxes, sensorFOVoiMcontAxes, sensorFOVoiScontAxes, ...
           sensorFOVreconstructionRGBaxes, sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLcontAxes, sensorFOVreconstructionMcontAxes, sensorFOVreconstructionScontAxes ...
        ] = makeAxes(hFig, figureWidth2HeightRatio, sceneWidth2HeightRatio, sensorWidth2HeightRatio)
   
    sensorViewNormWidth = 0.14;
    sensorViewNormHeight = 0.125;
    sceneAxes       = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01 0.40 0.320  0.320*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    sceneLumMapAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.34 0.40 0.358  0.320*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    
    reconstructedSceneRGBaxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.66 0.40 0.320  0.320*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    oiAxes = []
    oiLumMapAxes = [];
    
    sensorFOVsceneRGBaxes               = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01   0.30 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVoiRGBaxes                  = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01   0.12 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVreconstructionRGBaxes      = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01  -0.06 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
            
    sensorFOVsceneLumMapAxes            = axes('parent', hFig, 'unit', 'normalized', 'position', [0.21   0.30 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVoiLumMapAxes               = axes('parent', hFig, 'unit', 'normalized', 'position', [0.21   0.12 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVreconstructionLumMapAxes   = axes('parent', hFig, 'unit', 'normalized', 'position', [0.21  -0.06 sensorViewNormWidth  sensorViewNormHeight*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    
    sensorFOVsceneLcontAxes = [];
    sensorFOVoiLcontAxes = [];
    sensorFOVreconstructionLcontAxes = [];
    
    sensorFOVsceneMcontAxes = [];
    sensorFOVoiMcontAxes = [];
    sensorFOVreconstructionMcontAxes = [];
    
    sensorFOVsceneScontAxes = [];
    sensorFOVoiScontAxes = [];
    sensorFOVreconstructionScontAxes = [];
end


    
function [scene, sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneWidth2HeightRatio, ...
                 sensorOutlineX, sensorOutlineY, sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, sensorWidthAxis, sensorHeightAxis, sensorWidth2HeightRatio] = getSceneData(sceneSetName, descriptionString, sceneIndex)
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
    sensorWidth2HeightRatio = max(sensorWidthAxis)/max(sensorHeightAxis);
end

    
%     scenePlotAxes = [];
%     sensorFOVsceneLcontrastAxes = [];
%     opticalImageFOVsceneLcontrastAxes = [];
%     
%     scenePlot = [];
%     sensorOutlinePlot = [];
%     sensorFOVsceneLcontrastPlot = [];
%     opticalImageFOVsceneLcontrastPlot = [];
%     
%     
%     % Only keep the data for which we have reconstructed the signal
%     timeAxis = timeAxis(1:size(Creconstruction,1));
%     sensorPositionSequence = sensorPositionSequence(1:numel(timeAxis),:);
%     sceneIndexSequence = sceneIndexSequence(1:numel(timeAxis));
%     
%     size(LMScontrastInput)
%     size(timeAxis)
%     size(sceneIndexSequence)
%     size(sensorPositionSequence)
% 
%     
%     lastSceneIndex = 0;
%     for tBin = 1:numel(timeAxis)
%         
%         sceneIndex = sceneIndexSequence(tBin);
%         [tBin numel(timeAxis) sceneIndex]
%         
%         if (sceneIndex ~= lastSceneIndex)
%             fprintf('New scene index: %d at bin: %d\n', sceneIndex, tBin);
%             lastSceneIndex = sceneIndex;
%             scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
%             load(scanFileName, 'scanData', 'scene', 'oi');
%             sensorRetinalXaxis = scanData{1}.sensorRetinalXaxis;
%             sensorRetinalYaxis = scanData{1}.sensorRetinalYaxis;
%             sensorOutlineX = [sensorRetinalXaxis(1) sensorRetinalXaxis(end) sensorRetinalXaxis(end) sensorRetinalXaxis(1)   sensorRetinalXaxis(1)];
%             sensorOutlineY = [sensorRetinalYaxis(1) sensorRetinalYaxis(1)   sensorRetinalYaxis(end) sensorRetinalYaxis(end) sensorRetinalYaxis(1)];
%             sceneRetinalProjectionXData = scanData{1}.sceneRetinalProjectionXData;
%             sceneRetinalProjectionYData = scanData{1}.sceneRetinalProjectionYData;
%             sceneWidth2HeightRatio = max(sceneRetinalProjectionXData)/max(sceneRetinalProjectionYData);
%             sensorFOVRowRange = scanData{1}.sensorFOVRowRange;
%             sensorFOVColRange = scanData{1}.sensorFOVColRange;
%             sensorFOVxaxis = scanData{1}.sensorFOVxaxis;
%             sensorFOVyaxis = scanData{1}.sensorFOVyaxis;
%             
%             if (max(sensorRetinalXaxis) > max(sensorFOVxaxis))
%                 sensorWidthAxis  = sensorRetinalXaxis;
%             else
%                 sensorWidthAxis  = sensorFOVxaxis;
%             end
%             if (max(sensorRetinalYaxis) > max(sensorFOVyaxis))
%                 sensorHeightAxis  = sensorRetinalYaxis;
%             else
%                 sensorHeightAxis  = sensorFOVyaxis;
%             end
%             sensorSizeRatio = max(sensorWidthAxis)/max(sensorHeightAxis);
%             
%             [sceneLMS, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
%             [sceneRGBforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(sceneLMS, displaySPDs, coneFundamentals);
%             outsideGamut
%             
%             LMScontrastInputFrame = squeeze(LMScontrastInput(:,:,:,tBin));
%             [RGBcontrastInputforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMScontrastInputFrame, displaySPDs, coneFundamentals);
%             outsideGamut
%             
%             scenePlotAxes                     = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01       0.40 0.320  0.320*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
%             sensorFOVsceneRGBAxes             = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01       0.12 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
%             sensorFOVopticalImageRGBAxes      = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01      -0.07 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
%             
%             sensorFOVsceneLcontrastAxes       = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01+0.15  0.12 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
%             opticalImageFOVsceneLcontrastAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.01+0.15 -0.07 0.14  0.125*sensorSizeRatio*figureWidth2HeightRatio]);
%            
%             
%             % The full scene in RGB format
%             if (isempty(scenePlot))
%                 % Initialize the scene plot
%                 scenePlot = imagesc(sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRGBforSuperDisplay, 'parent', scenePlotAxes);
%                 set(scenePlotAxes, 'XTick', [], 'YTick', []);
%                 
%                 % Initialize the sensor position plot
%                 hold(scenePlotAxes , 'on');
%                 sensorOutlinePlot = plot(scenePlotAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
%                 hold(scenePlotAxes , 'off');
%                 axis(scenePlotAxes, 'image');
%                 set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
%             
%                 % Initialize the
%                 sensorFOVsceneRGBPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, RGBcontrastInputforSuperDisplay, 'parent', sensorFOVsceneRGBAxes);
%                 axis(sensorFOVsceneRGBAxes, 'image');
%                 set(sensorFOVsceneRGBAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
%                 set(sensorFOVsceneRGBAxes, 'CLim', [0 1]);
%                 set(sensorFOVsceneRGBAxes, 'XTick', [], 'YTick', []);
%                 
%                 
%                 sensorFOVopticalRGBPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, RGBcontrastInputforSuperDisplay, 'parent', sensorFOVopticalImageRGBAxes);
%                 axis(sensorFOVopticalImageRGBAxes, 'image');
%                 set(sensorFOVopticalImageRGBAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
%                 set(sensorFOVopticalImageRGBAxes, 'CLim', [0 1]);
%                 set(sensorFOVopticalImageRGBAxes, 'XTick', [], 'YTick', []);
%                 
%                 % Initialize the scene L-contrast frame  plot
%                 sensorFOVsceneLcontrastPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(LMScontrastInputFrame(:,:,1)), 'parent', sensorFOVsceneLcontrastAxes);
%                 axis(sensorFOVsceneLcontrastAxes, 'image');
%                 set(sensorFOVsceneLcontrastAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
%                 set(sensorFOVsceneLcontrastAxes, 'CLim', [-1 3]);
%                 set(sensorFOVsceneLcontrastAxes, 'XTick', [], 'YTick', []);
%             
%             
%                 % Initialize the optical image L-contrast frame  plot
%                 opticalImageFOVsceneLcontrastPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(oiLMScontrastInput(:,:,1,tBin)), 'parent', opticalImageFOVsceneLcontrastAxes);
%                 axis(opticalImageFOVsceneLcontrastAxes, 'image');
%                 set(opticalImageFOVsceneLcontrastAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
%                 set(opticalImageFOVsceneLcontrastAxes, 'CLim', [-1 3]);
%                 set(opticalImageFOVsceneLcontrastAxes, 'XTick', [], 'YTick', []);
%             else
%                 % Update the scene plot
%                 set(scenePlot, 'XData',  sceneRetinalProjectionXData, 'YData',  sceneRetinalProjectionYData, 'CData', sceneRGBforSuperDisplay);
%                 set(scenePlotAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
%             end
%         end
%         
%         % Update the sensor position plot
%         set(sensorOutlinePlot, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));
%         
%         
%         % Update the scene RGB frame plot
%         set(sensorFOVsceneRGBPlot, 'CData', RGBcontrastInputforSuperDisplay);
%         
%         % Update the scene L-contrast frame  plot
%         set(sensorFOVsceneLcontrastPlot, 'CData', squeeze(LMScontrastInputFrame(:,:,1)));
% 
%         % Update the optical image L-contrast frame  plot
%         set(opticalImageFOVsceneLcontrastPlot, 'CData', squeeze(oiLMScontrastInput(:,:,1,tBin)));
%         
%         drawnow
%             
%     end % tBin
%     

