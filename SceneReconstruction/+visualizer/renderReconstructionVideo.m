function renderReconstructionVideo(sceneSetName, resultsDir, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, visualizeSVDfiltersForVarianceExplained)

    % Retrieve resources needed to convert LMS RGB for a hypothetical super display that can display the natural scenes
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 8;
    [coneFundamentals, displaySPDs, RGBtoXYZ, wave] = core.LMSRGBconversionData(displayName, gain);
    
    whichOne = input('In-sample (1) out-of-sample(2) , or both (3) data : ');
    
    slideSize = [2560 1440]/2;
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1]);
    
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
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(kk,:, :));
        end
        
        videoFileName = fullfile(decodingDataDir, sprintf('Reconstruction%s%sOverlap%2.1fMeanLum%dInSample', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
        set(hFig, 'Name', videoFileName);
        videoFilename = sprintf('%s.m4v', videoFileName);
        fprintf('Will export video to %s.m4v\n', videoFileName);
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
    
        
        makeVideo(hFig, writerObj, sceneSetName, resultsDir, coneFundamentals, displaySPDs, RGBtoXYZ, Ctrain, CtrainPrediction, oiCtrain, ...
                trainingTimeAxis, trainingSceneIndexSequence, trainingSensorPositionSequence, trainingScanInsertionTimes, ...
                trainingSceneLMSbackground, trainingOpticalImageLMSbackground, originalTrainingStimulusSize, expParams);
            
        writerObj.close();
        
        
    elseif (whichOne == 2)
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
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            CtestPrediction = squeeze(CtestPredictionSVDbased(kk,:, :));
        end
        
        videoFileName = fullfile(decodingDataDir, sprintf('Reconstruction%s%sOverlap%2.1fMeanLum%dOutOfSample', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
        set(hFig, 'Name', videoFileName);
        videoFilename = sprintf('%s.m4v', videoFileName);
        fprintf('Will export video to %s.m4v\n', videoFileName);
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
        
        makeVideo(hFig, writerObj, sceneSetName, resultsDir, coneFundamentals, displaySPDs, RGBtoXYZ, Ctest, CtestPrediction, oiCtest, ...
                testingTimeAxis, testingSceneIndexSequence, testingSensorPositionSequence, testingScanInsertionTimes, ...
                testingSceneLMSbackground, testingOpticalImageLMSbackground, originalTestingStimulusSize, expParams);
            
        writerObj.close();
        
    else
        fileName = fullfile(decodingDataDir, sprintf('%s_OutOfSamplePrediction.mat', sceneSetName));
        
        load(fileName,  'oiCtest', 'Ctest', 'CtestPrediction', ...
            'testingTimeAxis', 'testingSceneIndexSequence', 'testingSensorPositionSequence', ...
            'testingScanInsertionTimes',  'testingSceneLMSbackground', 'testingOpticalImageLMSbackground', ...
            'originalTestingStimulusSize', 'expParams');
        
        if (expParams.outerSegmentParams.addNoise)
            outerSegmentNoiseString = 'Noise';
        else
            outerSegmentNoiseString = 'NoNoise';
        end
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtestPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            CtestPrediction = squeeze(CtestPredictionSVDbased(kk,:, :));
        end
        
        videoFileName = fullfile(decodingDataDir, sprintf('Reconstruction%s%sOverlap%2.1fMeanLum%dInAndOutOfSample', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
        set(hFig, 'Name', videoFileName);
        videoFilename = sprintf('%s.m4v', videoFileName);
        fprintf('Will export video to %s.m4v\n', videoFileName);
        
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
        
        % Make the video with the test data set
        makeVideo(hFig, writerObj, sceneSetName, resultsDir, coneFundamentals, displaySPDs, RGBtoXYZ, Ctest, CtestPrediction, oiCtest, ...
                testingTimeAxis, testingSceneIndexSequence, testingSensorPositionSequence, testingScanInsertionTimes, ...
                testingSceneLMSbackground, testingOpticalImageLMSbackground, originalTestingStimulusSize, expParams);
            
        % Followed by the video with the training data set
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName,  'oiCtrain', 'Ctrain', 'CtrainPrediction', ...
            'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
            'trainingScanInsertionTimes',  'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', ...
            'originalTrainingStimulusSize', 'expParams');
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            [~,kk] = min(abs(SVDbasedLowRankFilterVariancesExplained-visualizeSVDfiltersForVarianceExplained(1)));
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(kk,:, :));
        end
        
        makeVideo(hFig, writerObj, sceneSetName, resultsDir, coneFundamentals, displaySPDs, RGBtoXYZ, Ctrain, CtrainPrediction, oiCtrain, ...
                trainingTimeAxis, trainingSceneIndexSequence, trainingSensorPositionSequence, trainingScanInsertionTimes, ...
                trainingSceneLMSbackground, trainingOpticalImageLMSbackground, originalTrainingStimulusSize, expParams);
            
        writerObj.close();
    end 
end




function makeVideo(hFig, writerObj, sceneSetName, resultsDir, coneFundamentals, displaySPDs, RGBtoXYZ, Cinput, Creconstruction, oiCinput, ...
    timeAxis, sceneIndexSequence, sensorPositionSequence, scanInsertionTimes,  sceneLMSbackground, opticalImageLMSbackground, originalStimulusSize, expParams)
 
    LMScontrastReconstruction = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(Creconstruction, expParams.decoderParams), ...
            originalStimulusSize);
  
    LMScontrastInput = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(Cinput, expParams.decoderParams), ...
            originalStimulusSize...
        );
    
    oiLMScontrastInput = ...
        decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(oiCinput, expParams.decoderParams), ...
            originalStimulusSize...
        );
   
    sceneBackgroundExcitation = mean(sceneLMSbackground, 2);
    opticalImageBackgroundExcitation = mean(opticalImageLMSbackground, 2);  

    % Only keep the data for which we have reconstructed the signal
    timeAxis = timeAxis(1:size(Creconstruction,1));
    sensorPositionSequence = sensorPositionSequence(1:numel(timeAxis),:);
    sceneIndexSequence = sceneIndexSequence(1:numel(timeAxis));

    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    colormap(grayRedLUT); 
    
    
    tracesTimeRangeInMilliseconds = [-1000 0];
    luminanceRange = [0 1500];
    contrastRange = [-1.1 5];
    oiRGBgain = 40;
    gamma = 1.0/1.6;
    
    figPos = get(hFig, 'Position');
    figureWidth2HeightRatio = figPos(3)/figPos(4);
    
    
    lastSceneIndex = 0;
    for tBin = 1:numel(timeAxis)
        
    try
            
        % Compute RGB version of the sensor's view of the scene
        LMScontrastFrame = squeeze(LMScontrastInput(:,:,:,tBin));
        LMSexcitationFrame = core.excitationFromContrast(LMScontrastFrame, sceneBackgroundExcitation);
        [sensorFOVsceneRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(LMSexcitationFrame, displaySPDs, coneFundamentals);
        if (any(outsideGamut(:)) == 1)
            outsideGamut
        end
        % Compute RGB map for scene (as rendered in the super display)
        sensorFOVsceneLumMap = core.displayRGBtoLuminanceforSpecificDisplay(sensorFOVsceneRGBimage, RGBtoXYZ);
        % Clip RGBimage to [0..1], then gamma for display
        sensorFOVsceneRGBimage = linearRGBtoDisplay(sensorFOVsceneRGBimage, gamma);
        
        
        % Compute RGB version of the sensor's optical image view
        oiLMScontrastFrame = squeeze(oiLMScontrastInput(:,:,:,tBin));
        oiLMSexcitationFrame = core.excitationFromContrast(oiLMScontrastFrame, opticalImageBackgroundExcitation);
        [sensorFOVoiRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(oiLMSexcitationFrame, displaySPDs, coneFundamentals);
        if (any(outsideGamut(:)) == 1)
            outsideGamut
        end
        % Compute luminance map for the oi (as rendered in the super display)
        sensorFOVoiLumMap = core.displayRGBtoLuminanceforSpecificDisplay(sensorFOVoiRGBimage, RGBtoXYZ);
        % clip RGBimage to [0..1], then gamma for display
        sensorFOVoiRGBimage = linearRGBtoDisplay(oiRGBgain * sensorFOVoiRGBimage, gamma);
        
        % Compute RGB version of the sensor's reconstruction of the scene
        reconsctructedLMScontrastFrame = squeeze(LMScontrastReconstruction(:,:,:,tBin));
        reconstructedLMSexcitationFrame = core.excitationFromContrast(reconsctructedLMScontrastFrame, sceneBackgroundExcitation);
        % Special treatment: reconstructed contrast can go below -1, in
        % which case excitation goes < 0. Make it zero and print a mesage
        if (any(reconstructedLMSexcitationFrame(:) < 0))
            fprintf(2, 'Note that the reconstructed LMS excitations were < 0 for some pixels at this time bin (%d). Making them zero.\n', tBin);
            reconstructedLMSexcitationFrame(reconstructedLMSexcitationFrame<0) = 0;
        end
        
        [sensorFOVreconstructionRGBimage, outsideGamut] = core.LMStoRGBforSpecificDisplay(reconstructedLMSexcitationFrame, displaySPDs, coneFundamentals);
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
                oi, oiXData, oiYData, oiWidth2HeightRatio, ...
                sensorOutlineX, sensorOutlineY, sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, sensorWidthAxis, sensorHeightAxis, sensorWidth2HeightRatio, ...
                timeAxis ] = ...
                getSceneData(sceneSetName, resultsDir, sceneIndex);
            
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
           
            % Make RGB version of optical image
            [oiLMS, ~] = core.imageFromSceneOrOpticalImage(oi, 'LMS');
            [oiRGBforSuperDisplay, outsideGamut] = core.LMStoRGBforSpecificDisplay(oiLMS, displaySPDs, coneFundamentals);
            % Clip RGBimage to [0..1], then gamma for display
            oiRGBforSuperDisplay = linearRGBtoDisplay(oiRGBgain*oiRGBforSuperDisplay, gamma);
            
            % Clear figure
            clf(hFig);
            
            % Generate new axes
            [sceneAxes, oiAxes, sceneLumMapAxes, oiLumMapAxes, reconstructedSceneRGBaxes, ...
                sensorFOVsceneRGBaxes, sensorFOVsceneLumMapAxes, sensorFOVsceneLcontAxes, sensorFOVsceneMcontAxes, sensorFOVsceneScontAxes, ...
                sensorFOVoiRGBaxes, sensorFOVoiLumMapAxes, sensorFOVoiLcontAxes, sensorFOVoiMcontAxes, sensorFOVoiScontAxes, ...
                sensorFOVreconstructionSceneRGBaxes, sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLcontAxes, sensorFOVreconstructionMcontAxes, sensorFOVreconstructionScontAxes, ...
                sensorFOVContrastScatterAxes, LcontrastTracesAxes, McontrastTracesAxes, ScontrastTracesAxes] = makeAxes(hFig, figureWidth2HeightRatio , sceneWidth2HeightRatio, sensorWidth2HeightRatio);
    
            % Make new scene plot
            sceneRGBPlot = initializeSensorViewPlot(...
                sceneAxes, sceneRGBforSuperDisplay, [0 1], ...
                sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRetinalProjectionXData, sceneRetinalProjectionYData, 'scene');
                     
            % Initialize the sensor position on sceneRGB plot
            hold(sceneAxes , 'on');
            sensorOutlinePlot = plot(sceneAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(sceneAxes , 'off');
            axis(sceneAxes, 'image');
            set(sceneAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], ...
                           'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
                 
            % Make the new oi plot
            oiRGBPlot = initializeSensorViewPlot(...
                oiAxes, oiRGBforSuperDisplay, [0 1], ...
                oiXData, oiYData, oiXData, oiYData, 'optical image');
            
            % Initialize the sensor position on sceneRGB plot
            hold(oiAxes , 'on');
            sensorOutlinePlotOnOI = plot(oiAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(oiAxes , 'off');
            axis(oiAxes, 'image');
            set(oiAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], ...
                           'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
                       
            % Make new scene luminance map 
            sceneLuminancePlot = initializeSensorViewPlot(...
                sceneLumMapAxes, sceneLumMapForSuperDisplay, luminanceRange, ...
                sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneRetinalProjectionXData, sceneRetinalProjectionYData, 'scene luminance map (cd/m2)');
            
            % Initialize the sensor position on scene LumMap plot
            hold(sceneLumMapAxes , 'on');
            sensorOutlinePlotOnLumMap = plot(sceneLumMapAxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(sceneLumMapAxes , 'off');
            axis(sceneLumMapAxes, 'image');
            set(sceneLumMapAxes, 'XLim', [sceneRetinalProjectionXData(1) sceneRetinalProjectionXData(end)], ...
                                 'YLim', [sceneRetinalProjectionYData(1) sceneRetinalProjectionYData(end)]);
     
            Ticks = sort([expParams.viewModeParams.forcedSceneMeanLuminance 0 500 1000 1500 2000]);
            hCbar = colorbar('west', 'peer', sceneLumMapAxes, ...  % westoutside
                                'Ticks', Ticks, 'TickLabels', sprintf('%d\n',Ticks));
            %hCbar.Label.String = 'luminance (cd/m2)';
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
                reconstructedSceneRetinalProjectionXData, reconstructedSceneRetinalProjectionYData, reconstructedSceneRetinalProjectionXData, reconstructedSceneRetinalProjectionYData, 'reconstructed scene');
            
            % Initialize the sensor position on reconstructed sceneRGB plot
            hold(reconstructedSceneRGBaxes , 'on');
            sensorOutlinePlotOnReconstructedScene = plot(reconstructedSceneRGBaxes, sensorOutlineX, sensorOutlineY, 'r-', 'LineWidth', 2.0); 
            hold(reconstructedSceneRGBaxes , 'off');
            axis(reconstructedSceneRGBaxes, 'image');
            set(reconstructedSceneRGBaxes, 'XLim', [reconstructedSceneRetinalProjectionXData(1) reconstructedSceneRetinalProjectionXData(end)], ...
                           'YLim', [reconstructedSceneRetinalProjectionYData(1) reconstructedSceneRetinalProjectionYData(end)]);
                                  
            % Generate empty image to hold the patches of the reconstructed image
            reconstructedSceneRGBforSuperDisplay = zeros(numel(reconstructedSceneRetinalProjectionYData), numel(reconstructedSceneRetinalProjectionXData),3);
            visited = ones(numel(reconstructedSceneRetinalProjectionYData), numel(reconstructedSceneRetinalProjectionXData));
         
            % Initialize the sensorFOVsceneRGBplot
            sensorFOVsceneRGBPlot = initializeSensorViewPlot(...
                sensorFOVsceneRGBaxes, sensorFOVsceneRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, 'input scene');

            % Initialize the sensorFOVoiRGBplot
            sensorFOVoiRGBPlot = initializeSensorViewPlot(...
                sensorFOVoiRGBaxes, sensorFOVoiRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, 'optical image');
            
            % Iinitialize the sensorFOVreconstructionSceneRGBPlot
            sensorFOVreconstructionSceneRGBPlot = initializeSensorViewPlot(...
                sensorFOVreconstructionSceneRGBaxes, sensorFOVsceneRGBimage, [0 1], ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, 'reconstruction');
            
            % Initialize the sensorFOVsceneLumMapPlot
            sensorFOVsceneLumMapPlot = initializeSensorViewPlot(...
                sensorFOVsceneLumMapAxes, sensorFOVsceneLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, sprintf('scene\nluminance'));
            
            % Initialize the sensorFOVoiLumMapPlot
            sensorFOVoiLumMapPlot = initializeSensorViewPlot(...
                sensorFOVoiLumMapAxes, oiRGBgain*sensorFOVoiLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, sprintf('retinal\nilluminance'));
            
            % Initialize the sensorFOVreconstructionLumMapPlot
            sensorFOVreconstructionLumMapPlot = initializeSensorViewPlot(...
                sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLumMap, luminanceRange, ...
                sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, sprintf('reconstructed\nluminance'));
            
            % Initialize the sensorFOVLcontrast scatter plot
            sensorFOVContrastScatterPlot = initializeContrastScatterPlot(...
                sensorFOVContrastScatterAxes,  LMScontrastFrame,  reconsctructedLMScontrastFrame, contrastRange);
            
            % Initialize the contrast traces plot
            stimRowIndex = round(size(LMScontrastFrame,1)/2);
            stimColIndex = round(size(LMScontrastFrame,2)/2);
            dt = (timeAxis(2)-timeAxis(1));
            timeAxis = tracesTimeRangeInMilliseconds(1):dt:tracesTimeRangeInMilliseconds(end);
            tracesTimeBins = round(timeAxis/dt);
            timeAxisRange = [timeAxis(1) timeAxis(end)];
            
            LconeContrastTracesPlot = initializeContrastTracesPlot(LcontrastTracesAxes, timeAxis, 1, timeAxis*0, timeAxis*0, contrastRange, timeAxisRange, sprintf('Lcontrast\n@(%d,%d)', stimColIndex, stimRowIndex));
            MconeContrastTracesPlot = initializeContrastTracesPlot(McontrastTracesAxes, timeAxis, 2, timeAxis*0, timeAxis*0, contrastRange, timeAxisRange, sprintf('Mcontrast\n@(%d,%d)', stimColIndex, stimRowIndex));
            SconeContrastTracesPlot = initializeContrastTracesPlot(ScontrastTracesAxes, timeAxis, 3, timeAxis*0, timeAxis*0, contrastRange, timeAxisRange, sprintf('Scontrast\n@(%d,%d)', stimColIndex, stimRowIndex));
            
        end  % new scene
        
        % Update the reconstucted image with this patch
        halfRowsCovered = round((sensorPositionSequence(tBin,2) - max(sensorOutlineY) -min(sceneRetinalProjectionYData))/sensorSampleSeparation);
        halfColsCovered = round((sensorPositionSequence(tBin,1) - max(sensorOutlineX) -min(sceneRetinalProjectionXData))/sensorSampleSeparation);
        rowsCovered = halfRowsCovered+(1:size(sensorFOVreconstructionRGBimage,1));
        colsCovered = halfColsCovered+(1:size(sensorFOVreconstructionRGBimage,2));
        
        
        if ( (min(rowsCovered) >=1) && ...
             (min(colsCovered) >=1) && ...
             (max(rowsCovered) <= size(visited,1)) && ...
             (max(colsCovered) <= size(visited,2)) )
            
            rowsCovered = rowsCovered(rowsCovered>0);
            colsCovered = colsCovered(colsCovered>0);
            rowsCovered = rowsCovered(rowsCovered<=size(visited,1));
            colsCovered = colsCovered(colsCovered<=size(visited,2));

            % Update visited counter
            visited(rowsCovered, colsCovered) = visited(rowsCovered, colsCovered) + 1;
            tmpVisited = visited; idx = find(tmpVisited>1);tmpVisited(idx) = tmpVisited(idx)-1;

            % Update accumulated image
            reconstructedSceneRGBforSuperDisplay(rowsCovered, colsCovered,:) = ...
                reconstructedSceneRGBforSuperDisplay(rowsCovered, colsCovered,:) + sensorFOVreconstructionRGBimage;

            % Divide accumulated image by visited counter
            tmp_reconstructedSceneRGBforSuperDisplay = 0*reconstructedSceneRGBforSuperDisplay;
            for rgbChannel = 1:3
                tmp_reconstructedSceneRGBforSuperDisplay(:,:,rgbChannel) = ...
                squeeze(reconstructedSceneRGBforSuperDisplay(:,:,rgbChannel)) ./ tmpVisited;
            end
        
            % Clip RGBimage to [0..1], then gamma for display
            tmp_reconstructedSceneRGBforSuperDisplay = linearRGBtoDisplay(tmp_reconstructedSceneRGBforSuperDisplay, gamma);
            % Update the reconstructedSceneRGBPlot
            set(reconstructedSceneRGBPlot, 'CData',  tmp_reconstructedSceneRGBforSuperDisplay);
        
            % Update the sensor position plot (on the scene image) for current time bin
            set(sensorOutlinePlot, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));

             % Update the sensor position plot (on the optical image) for current time bin
            set(sensorOutlinePlotOnOI, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));

            % Update the sensor position plot (on the scene luminance map) for current time bin
            set(sensorOutlinePlotOnLumMap, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));

            % Update the sensor position plot (on the reconstructed scene) for current time bin
            set(sensorOutlinePlotOnReconstructedScene, 'XData', sensorOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorOutlineY + sensorPositionSequence(tBin,2));

            % Update the sensorFOV scene RGB plot
            set(sensorFOVsceneRGBPlot, 'CData', sensorFOVsceneRGBimage);

            % Update the sensorFOV oi RGBplot
            set(sensorFOVoiRGBPlot, 'CData', sensorFOVoiRGBimage);

            % Update the sensorFOV reconstruction RGB plot
            set(sensorFOVreconstructionSceneRGBPlot, 'CData', sensorFOVreconstructionRGBimage);

            % Update the sensorFOVsceneLumMapPlot
            set(sensorFOVsceneLumMapPlot, 'CData', sensorFOVsceneLumMap);

            % Update the sensorFOVoiLumMapPlot
            set(sensorFOVoiLumMapPlot, 'CData', oiRGBgain*sensorFOVoiLumMap);

            % Update the sensorFOVreconstructionLumMapPlot
            set(sensorFOVreconstructionLumMapPlot, 'CData', sensorFOVreconstructionLumMap)
            
            % Update the contrast scatter plots
            for coneContrastIndex = 1:3
                set(sensorFOVContrastScatterPlot(coneContrastIndex), ...
                        'XData', reshape(LMScontrastFrame(:,:,coneContrastIndex), [1 size(LMScontrastFrame,1)*size(LMScontrastFrame,2)]), ...
                        'YData', reshape(reconsctructedLMScontrastFrame(:,:,coneContrastIndex), [1 size(LMScontrastFrame,1)*size(LMScontrastFrame,2)]));
            end

            % Update the contrast traces plots
            binsToDisplay = tBin + tracesTimeBins;
            updateTracesPlot(LconeContrastTracesPlot, MconeContrastTracesPlot, SconeContrastTracesPlot, ...
                binsToDisplay, squeeze(LMScontrastInput(stimRowIndex,stimColIndex,:,:)), squeeze(LMScontrastReconstruction(stimRowIndex,stimColIndex,:,:)));

            drawnow;
            writerObj.writeVideo(getframe(hFig));
        end
        
    catch err
        fprintf('Saving video up to this point');
        writerObj.close();
        rethrow(err);
    end
    
    end % tBin
end

function updateTracesPlot(LconeContrastTracesPlot, MconeContrastTracesPlot, SconeContrastTracesPlot, binsToDisplay, LMScontrastInput, LMScontrastReconstruction)
        
    idx = find(binsToDisplay>0);
    
    inputLcontrast = zeros(1,numel(binsToDisplay));
    inputMcontrast = zeros(1,numel(binsToDisplay));
    inputScontrast = zeros(1,numel(binsToDisplay));
    
    reconstructedLcontrast = inputLcontrast;
    reconstructedMcontrast = inputMcontrast;
    reconstructedScontrast = inputScontrast;
    
    inputLcontrast(idx) = squeeze(LMScontrastInput(1,binsToDisplay(idx)));
    inputMcontrast(idx) = squeeze(LMScontrastInput(2,binsToDisplay(idx)));
    inputScontrast(idx) = squeeze(LMScontrastInput(3,binsToDisplay(idx)));
    
    reconstructedLcontrast(idx) = squeeze(LMScontrastReconstruction(1,binsToDisplay(idx)));
    reconstructedMcontrast(idx) = squeeze(LMScontrastReconstruction(2,binsToDisplay(idx)));
    reconstructedScontrast(idx) = squeeze(LMScontrastReconstruction(3,binsToDisplay(idx)));
    
    set(LconeContrastTracesPlot(1), 'YData', inputLcontrast);
    set(LconeContrastTracesPlot(2), 'YData', reconstructedLcontrast);
    
    set(MconeContrastTracesPlot(1), 'YData', inputMcontrast);
    set(MconeContrastTracesPlot(2), 'YData', reconstructedMcontrast);
    
    set(SconeContrastTracesPlot(1), 'YData', inputScontrast);
    set(SconeContrastTracesPlot(2), 'YData', reconstructedScontrast);
end



function contrastTracesPlot = initializeContrastTracesPlot(contrastTracesAxes, timeAxis, ...
       coneContrastIndex, inputTraces, reconstructedTraces, contrastRange, timeAxisRange, plotTitle)
    
    coneColors = 0.7*[1.0 0.0 0.5; 0.0 1.0 0.5; 0.0 0.5 1.0];
    
    plot(contrastTracesAxes, [0 0], contrastRange, 'k-', 'Color', [0.4 0.4 0.4]);
    hold(contrastTracesAxes, 'on');
    plot(contrastTracesAxes, timeAxisRange, [0 0], 'k-', 'Color', [0.4 0.4 0.4]);
    contrastTracesPlot(1) = plot(...
            contrastTracesAxes, timeAxis, inputTraces, '-', 'Color', squeeze(coneColors(coneContrastIndex,:)), 'LineWidth', 2.0);
    contrastTracesPlot(2) = plot(...
            contrastTracesAxes, timeAxis, reconstructedTraces, 'k-', 'LineWidth', 2.0);  
    hold(contrastTracesAxes, 'off');  
    set(contrastTracesAxes, 'XLim', timeAxisRange, 'YLim', contrastRange, 'YTick', (-1:5), 'XTick', [-1000:500:1000], 'FontSize', 12);
    if (coneContrastIndex == 1)
        set(contrastTracesAxes, 'YTickLabel', {-1:5});
    else
        set(contrastTracesAxes, 'YTickLabel', {});
    end
     if (coneContrastIndex == 3)
        set(contrastTracesAxes, 'XTickLabel', sprintf('%d\n',-1000:500:1000));
     else
        set(contrastTracesAxes, 'XTickLabel', {});
     end
    
    title(contrastTracesAxes, plotTitle, 'FontSize', 12)
end


function sensorFOVcontrastScatterPlot = initializeContrastScatterPlot(contrastScatterAxes, inputContrast, reconsctructedContrast, contrastRange)
    plot(contrastScatterAxes, [contrastRange(1) contrastRange(2)], [contrastRange(1) contrastRange(2)], 'k-');
    hold(contrastScatterAxes, 'on');
    plot(contrastScatterAxes, [0 0], [contrastRange(1) contrastRange(2)], 'k-');
    plot(contrastScatterAxes, [contrastRange(1) contrastRange(2)], [0 0], 'k-');
    coneColors = 0.7*[1.0 0.0 0.5; 0.0 1.0 0.5; 0.0 0.5 1.0];
    coneColors2 = 0.5*[1.0 0.5 0.7; 0.5 1.0 0.8; 0.5 0.7 1.0];
    for coneContrastIndex = 1:3
        sensorFOVcontrastScatterPlot(coneContrastIndex) = plot(contrastScatterAxes, ...
                            reshape(inputContrast(:,:,coneContrastIndex), [1 size(inputContrast,1)*size(inputContrast,2)]), ...
                            reshape(reconsctructedContrast(:,:,coneContrastIndex), [1 size(inputContrast,1)*size(inputContrast,2)]), 's', ...
                            'MarkerFaceColor', squeeze(coneColors(coneContrastIndex,:)), 'MarkerEdgeColor', 'none', 'MarkerSize', 6);
    end
    
    hold(contrastScatterAxes, 'off');
    set(contrastScatterAxes, 'XLim', contrastRange,  'YLim', [contrastRange(1) 3], 'FontSize', 12, 'XTick', (-1:10), 'YTick', (-1:10));
    box(contrastScatterAxes, 'off')
    xlabel(contrastScatterAxes, 'input contrast', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(contrastScatterAxes, 'reconstructed contrast', 'FontSize', 14, 'FontWeight', 'bold');
end

            
            
function sensorFOVPlot = initializeSensorViewPlot(sensorFOVAxes, sensorViewImage, imageDataRange, sensorFOVxaxis, sensorFOVyaxis, sensorWidthAxis, sensorHeightAxis, plotTitle)
    sensorFOVPlot = imagesc(sensorFOVxaxis, sensorFOVyaxis, sensorViewImage, 'parent', sensorFOVAxes);
    axis(sensorFOVAxes, 'image');
    set(sensorFOVAxes, 'XLim', [sensorWidthAxis(1) sensorWidthAxis(end)],  'YLim', [sensorHeightAxis(1) sensorHeightAxis(end)]);
    set(sensorFOVAxes, 'CLim', imageDataRange);
    set(sensorFOVAxes, 'XTick', [], 'YTick', []);
    title(sensorFOVAxes, plotTitle, 'FontSize', 12);
end

function RGBimage = linearRGBtoDisplay(RGBimage, gamma)
    RGBimage(RGBimage<0) = 0;
    RGBimage(RGBimage>1) = 1;
    RGBimage = RGBimage.^gamma;
end


function [sceneAxes, oiAxes, sceneLumMapAxes, oiLumMapAxes, reconstructedSceneRGBaxes, ...
           sensorFOVsceneRGBaxes, sensorFOVsceneLumMapAxes, sensorFOVsceneLcontAxes, sensorFOVsceneMcontAxes, sensorFOVsceneScontAxes, ...
           sensorFOVoiRGBaxes,    sensorFOVoiLumMapAxes, sensorFOVoiLcontAxes, sensorFOVoiMcontAxes, sensorFOVoiScontAxes, ...
           sensorFOVreconstructionSceneRGBaxes, sensorFOVreconstructionLumMapAxes, sensorFOVreconstructionLcontAxes, sensorFOVreconstructionMcontAxes, sensorFOVreconstructionScontAxes, ...
           sensorFOVContrastScatterAxes, LcontrastTracesAxes, McontrastTracesAxes, ScontrastTracesAxes] = makeAxes(hFig, figureWidth2HeightRatio, sceneWidth2HeightRatio, sensorWidth2HeightRatio)

    oiLumMapAxes = [];
    
    sensorFOVsceneLcontAxes = [];
    sensorFOVoiLcontAxes = [];
    sensorFOVreconstructionLcontAxes = [];
    
    sensorFOVsceneMcontAxes = [];
    sensorFOVoiMcontAxes = [];
    sensorFOVreconstructionMcontAxes = [];
    
    sensorFOVsceneScontAxes = [];
    sensorFOVoiScontAxes = [];
    sensorFOVreconstructionScontAxes = [];
    
    
    fullImageNormSize = 0.35;
    sceneAxes                 = axes('parent', hFig, 'unit', 'normalized', 'position', [0.005  0.331  fullImageNormSize  fullImageNormSize*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    reconstructedSceneRGBaxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.360  0.331  fullImageNormSize  fullImageNormSize*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
   
    %when % colorbar is located at westoutside use following
    % sceneLumMapAxes           = axes('parent', hFig, 'unit', 'normalized', 'position', [0.360  0.34  fullImageNormSize*1.113  fullImageNormSize*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    sceneLumMapAxes           = axes('parent', hFig, 'unit', 'normalized', 'position', [0.005 -0.165  fullImageNormSize  fullImageNormSize*sceneWidth2HeightRatio*figureWidth2HeightRatio]); 
    oiAxes                    = axes('parent', hFig, 'unit', 'normalized', 'position', [0.360 -0.165  fullImageNormSize  fullImageNormSize*sceneWidth2HeightRatio*figureWidth2HeightRatio]);
    
    sensorFOVoriginalAxesXcoord = 0.715;
    sensorViewNormWidth  = 0.12*0.75;
    
    % Sensor FOV scene RGB
    sensorFOVsceneRGBaxes               = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord         0.805  sensorViewNormWidth   sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVoiRGBaxes                  = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord+0.095   0.805 sensorViewNormWidth   sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVreconstructionSceneRGBaxes = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord+2*0.095 0.805  sensorViewNormWidth   sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    

    % Sensor FOV scene lum map
    sensorFOVsceneLumMapAxes            = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord         0.655  sensorViewNormWidth  sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVoiLumMapAxes               = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord+0.095   0.655 sensorViewNormWidth  sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
    sensorFOVreconstructionLumMapAxes   = axes('parent', hFig, 'unit', 'normalized', 'position', [sensorFOVoriginalAxesXcoord+2*0.095 0.655  sensorViewNormWidth  sensorViewNormWidth*sensorWidth2HeightRatio*figureWidth2HeightRatio]);
   
    % input/reconstructed contrast scatter plot
    contrastScatterAxesNormSize = 0.25;
    sensorFOVContrastScatterAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.738 0.05 contrastScatterAxesNormSize 4/6*contrastScatterAxesNormSize*figureWidth2HeightRatio]);
    
    % The contrast traces axes
    tracesAxesNormWidth = 0.074;
    tracesAxesNormHeight = 0.150;
    LcontrastTracesAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.728         0.383 tracesAxesNormWidth tracesAxesNormHeight*figureWidth2HeightRatio]);
    McontrastTracesAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.728+0.091   0.383 tracesAxesNormWidth tracesAxesNormHeight*figureWidth2HeightRatio]);
    ScontrastTracesAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [0.728+0.091*2 0.383 tracesAxesNormWidth tracesAxesNormHeight*figureWidth2HeightRatio]);
end


    
function [scene, sceneRetinalProjectionXData, sceneRetinalProjectionYData, sceneWidth2HeightRatio, ...
         oi, oiXData, oiYData, oiWidth2HeightRatio, ...
         sensorOutlineX, sensorOutlineY, sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, sensorWidthAxis, sensorHeightAxis, sensorWidth2HeightRatio, timeAxis] = getSceneData(sceneSetName, resultsDir, sceneIndex)
    scanFileName = core.getScanFileName(sceneSetName, resultsDir, sceneIndex);
    load(scanFileName, 'scanData', 'scene', 'oi');
    
    sceneRetinalProjectionXData = scanData{1}.sceneRetinalProjectionXData;
    sceneRetinalProjectionYData = scanData{1}.sceneRetinalProjectionYData;
    sceneWidth2HeightRatio = max(sceneRetinalProjectionXData)/max(sceneRetinalProjectionYData);
    
    oiXData = scanData{1}.opticalImageXData;
    oiYData = scanData{1}.opticalImageYData;
    oiWidth2HeightRatio = max(oiXData)/max(oiYData);
    
    sensorRetinalXaxis = scanData{1}.sensorRetinalXaxis;
    sensorRetinalYaxis = scanData{1}.sensorRetinalYaxis;
    sensorOutlineX = [sensorRetinalXaxis(1) sensorRetinalXaxis(end) sensorRetinalXaxis(end) sensorRetinalXaxis(1)   sensorRetinalXaxis(1)];
    sensorOutlineY = [sensorRetinalYaxis(1) sensorRetinalYaxis(1)   sensorRetinalYaxis(end) sensorRetinalYaxis(end) sensorRetinalYaxis(1)];
    
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
    
    timeAxis = scanData{1}.timeAxis;
end
