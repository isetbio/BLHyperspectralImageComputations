function renderReconstructionVideo(sceneSetName, resultsDir, decodingDataDir, InSampleOrOutOfSample)

    computeSVDbasedLowRankFiltersAndPredictions = true;  % SVD based
  %  computeSVDbasedLowRankFiltersAndPredictions = false;  % PINV based
  
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        [timeAxis, LMScontrastInput, LMScontrastReconstruction, ...
         oiLMScontrastInput, ...
         sceneBackgroundExcitation,  opticalImageBackgroundExcitation, ...
         sceneIndexSequence, sensorPositionSequence, responseSequence, ...
         expParams, svdIndex, SVDvarianceExplained, videoPostFix] = retrieveReconstructionData(sceneSetName, decodingDataDir, InSampleOrOutOfSample, computeSVDbasedLowRankFiltersAndPredictions);
    end
    
    
    [decoder.filters, decoder.peakTimeBins, decoder.spatioTemporalSupport, decoder.coneTypes] = visualizer.retrieveDecoderData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, svdIndex);
    
    % Positions of visualized decoders
    targetLdecoderXYcoords = [7 10];
    targetMdecoderXYcoords = [14 -6];
    targetSdecoderXYcoords = [0 0];
    sensorData = visualizer.retrieveSensorData(sceneSetName, resultsDir, decoder, targetLdecoderXYcoords, targetMdecoderXYcoords, targetSdecoderXYcoords);
    
    makeVideoClip(timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, responseSequence, decoder, sensorData, SVDvarianceExplained, expParams, videoPostFix);
end



function makeVideoClip(timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, responseSequence, decoder, sensorData, SVDvarianceExplained, expParams, videoPostFix)
    
    % Get luminance colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    colormap(grayRedLUT); 
    
    % Generate colors for L,M,S contrast traces
    LconeContrastColor = [255 170 190]/255;
    MconeContrastColor = [120 255 224]/255;
    SconeContrastColor = [170 180 255]/255;
    
    
    
    
    % Generate super display for rendering
    gain = 80;  displayGamma = 1/2.0;  boostFactorForOpticalImage = 50;
    renderingDisplay = displayCreate('LCD-Apple');
    displaySPDs = displayGet(renderingDisplay, 'spd');
    renderingDisplay = displaySet(renderingDisplay, 'spd', displaySPDs*gain);

    % Compute displayed ranges for all variables
    outerSegmentResponseRange = round([min(responseSequence(:)) max(responseSequence(:))]/10)*10;
    outerSegmentResponseTicks = [outerSegmentResponseRange(1) outerSegmentResponseRange(end)];
    luminanceRange = [0 7000]; luminanceRangeTicks = (0: 2000: 10000); 
    luminanceRangeTickLabels = sprintf('%2.0fK\n', luminanceRangeTicks/1000);
    coneContrastRange = [-2 5];
    recentTbinsNum = 50;  % 500 milliseconds
    
    % Generate axes and figure handle
    slideSize = [1920 1080]; slideCols = 6; slideRows = 4;
    [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows);

    % Generate video object
    videoFilename = fullfile(expParams.decodingDataDir, sprintf('ReconstructionInSample%s.m4v', videoPostFix));
    videoOBJ = generateVideoObject(videoFilename);

    % Reset all plots (Left side)
    inputSceneLuminanceMapPlot = [];
    inputSceneRGBrenditionPlot = [];
    inputOpticalImageLuminanceMapPlot = [];
    inputOpticalImageRGBrenditionPlot = [];
    reconstructedSceneLuminanceMapPlot = [];
    reconstructedSceneRGBrenditionPlot = [];
    
    % Reset center plot 
    instantaneousSensorXYactivationPlot = [];
    
    % Reset all plots (Right side)
    sensorXTtracesForTargetLcontrastDecoderPlot = [];
    sensorXTtracesForTargetMcontrastDecoderPlot = [];
    sensorXTtracesForTargetScontrastDecoderPlot = [];
    
    comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot = [];
    comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot = [];
    comboInputAndReconstructionTracesForTargetScontrastDecoderPlot = [];
    
    % The reconstructed/input cone contrast and ratios scatter plots
    reconstructedVSinputContrastPlot = [];
    reconstructedVSinputLvsMratioPlot = [];
    reconstructedVSinputSvsLMratioPlot = [];
    
    
    previousSceneIndex = 0;
    for tBin = recentTbinsNum+1:numel(timeAxis)
        
        recentTbins = tBin-recentTbinsNum:1:tBin;
        recentTime  = timeAxis(recentTbins)-timeAxis(recentTbins(end));
        recentTimeRange = [recentTime(1) recentTime(end)];
            
        % Get the current scene data
        if (sceneIndexSequence(tBin) ~= previousSceneIndex)
            fprintf('Retrieving new scene data at time bin: %d\n', tBin);
            [sceneData, oiData] = retrieveComputedDataForCurrentScene(expParams.sceneSetName, expParams.resultsDir, sceneIndexSequence(tBin), ...
                renderingDisplay, boostFactorForOpticalImage, displayGamma);
            
            previousSceneIndex = sceneIndexSequence(tBin);
            
            % The decoder region outline
            theDecodedRegionOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 0 0]);
            
            % The full input scene
            sensorOutline.x = sensorData.spatialOutlineX + sensorPositionSequence(tBin,1);
            sensorOutline.y = sensorData.spatialOutlineY + sensorPositionSequence(tBin,2);
            decodedRegionOutline.x = sensorData.decodedImageOutlineX + sensorPositionSequence(tBin,1);
            decodedRegionOutline.y = sensorData.decodedImageOutlineY + sensorPositionSequence(tBin,2);
            decodedRegionOutline.color = theDecodedRegionOutline.color;
            [fullSceneSensorOutlinePlot, fullSceneDecodedRegionOutlinePlot] = initializeFullScenePlot(axesDictionary('fullInputScene'), sceneData, sensorOutline, decodedRegionOutline);
        end
        
        % Convert the various LMS contrasts to RGB settings and luminances for the rendering display
        RGBsettingsAndLuminanceData = LMScontrastsToRGBsettingsAndLuminanceforRenderingDisplay(tBin, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
                        sceneBackgroundExcitation,  opticalImageBackgroundExcitation, renderingDisplay, boostFactorForOpticalImage, displayGamma);
         
        % Update sensor position in optical image
        sensorOutline.x = sensorData.spatialOutlineX + sensorPositionSequence(tBin,1);
        sensorOutline.y = sensorData.spatialOutlineY + sensorPositionSequence(tBin,2);
        decodedRegionOutline.x = sensorData.decodedImageOutlineX + sensorPositionSequence(tBin,1);
        decodedRegionOutline.y = sensorData.decodedImageOutlineY + sensorPositionSequence(tBin,2);
        updateFullScenePlot(axesDictionary('fullInputScene'), fullSceneSensorOutlinePlot, sensorOutline, fullSceneDecodedRegionOutlinePlot, decodedRegionOutline, sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY);
        
        
        % TOP PLOTS
        % The luminance map of the input optical image patch
        decodedRegionOutline = theDecodedRegionOutline;
        decodedRegionOutline.x = decodedRegionOutline.x + sensorPositionSequence(tBin,1);
        decodedRegionOutline.y = decodedRegionOutline.y + sensorPositionSequence(tBin,2);
        if (isempty(inputOpticalImageLuminanceMapPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = 'optical image';
            titleString = 'luminance map';
            colorbarStruct = [];
            axesColor = [0 0 0];
            identifyTargetDecoderPositions = true;
            labelMosaicCenterUsingCrossHairs = true;
            decoderSpatialFilterProfiles = [];
            [inputOpticalImageLuminanceMapPlot, inputOpticalImageLuminanceMapDecodedRegionOutlinePlot] = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageIlluminanceMap'), titleString, ...
                  oiData.LuminanceMap, luminanceRange,...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  oiData.fullOpticalImageSpatialSupportX, oiData.fullOpticalImageSpatialSupportY, ...
                  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData,...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);  
        else
            set(axesDictionary('inputOpticalImageIlluminanceMap'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            set(inputOpticalImageLuminanceMapDecodedRegionOutlinePlot, 'XData', decodedRegionOutline.x, 'YData', decodedRegionOutline.y);
        end
        
        % The RGB rendition  of the input optical image patch
        decodedRegionOutline = theDecodedRegionOutline;
        decodedRegionOutline.x = decodedRegionOutline.x + sensorPositionSequence(tBin,1);
        decodedRegionOutline.y = decodedRegionOutline.y + sensorPositionSequence(tBin,2);
        if (isempty(inputOpticalImageRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = 'RGB rendition';
            colorbarStruct = [];
            axesColor = [0 0 0];
            identifyTargetDecoderPositions = false;
            labelMosaicCenterUsingCrossHairs = false;
            decoderSpatialFilterProfiles = [];
            [inputOpticalImageRGBrenditionPlot, inputOpticalImageRGBrenditionDecodedRegionOutlinePlot] = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageRGBrendition'), titleString, ...
                  oiData.RGBforRenderingDisplay, [0 1],...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  oiData.fullOpticalImageSpatialSupportX, oiData.fullOpticalImageSpatialSupportY, ...
                  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);
        else
            set(axesDictionary('inputOpticalImageRGBrendition'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            set(inputOpticalImageRGBrenditionDecodedRegionOutlinePlot, 'XData', decodedRegionOutline.x, 'YData', decodedRegionOutline.y);
        end
        
        
        % MIDDLE
        % The luminance map of the input scene patch
        decodedRegionOutline = theDecodedRegionOutline;
        decodedRegionOutline.x = decodedRegionOutline.x + sensorPositionSequence(tBin,1);
        decodedRegionOutline.y = decodedRegionOutline.y + sensorPositionSequence(tBin,2);
        if (isempty(inputSceneLuminanceMapPlot))
            xTicks = []; yTicks = [];
            xlabelString = ''; ylabelString = 'input scene';
            titleString = ''; 
            colorbarStruct = struct(...
                'position', 'South', ...
                'ticks', luminanceRangeTicks, ...
                'tickLabels', luminanceRangeTickLabels, ...
                'orientation', 'horizontal', ...
                'title', '', ...
                'fontSize', 14, ...
                'fontName', 'Menlo', ...
                'color', [0 1 0.7]...
                );
            axesColor = [0 0 0];
            identifyTargetDecoderPositions = false;
            labelMosaicCenterUsingCrossHairs = false;
            decoderSpatialFilterProfiles = [];
            [inputSceneLuminanceMapPlot, inputSceneLuminanceMapDecodedRegionOutlinePlot] = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneLuminanceMap'), titleString, ...
                  sceneData.LuminanceMap, luminanceRange,...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY,  ...
                  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);  
        else
            set(axesDictionary('inputSceneLuminanceMap'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            set(inputSceneLuminanceMapDecodedRegionOutlinePlot, 'XData', decodedRegionOutline.x, 'YData', decodedRegionOutline.y);
        end
        
        % The RGB rendition of the input scene patch
        decodedRegionOutline = theDecodedRegionOutline;
        decodedRegionOutline.x = decodedRegionOutline.x + sensorPositionSequence(tBin,1);
        decodedRegionOutline.y = decodedRegionOutline.y + sensorPositionSequence(tBin,2);
        if (isempty(inputSceneRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = '';
            colorbarStruct = [];
            axesColor = [0 0 0];
            identifyTargetDecoderPositions = false;
            labelMosaicCenterUsingCrossHairs = false;
            decoderSpatialFilterProfiles = [];
            [inputSceneRGBrenditionPlot, inputSceneRGBrenditionDecodedRegionOutlinePlot] = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneRGBrendition'), titleString, ...
                  sceneData.RGBforRenderingDisplay, [0 1],...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+[sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY, ...
                  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);  
        else
            set(axesDictionary('inputSceneRGBrendition'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            set(inputSceneRGBrenditionDecodedRegionOutlinePlot, 'XData', decodedRegionOutline.x, 'YData', decodedRegionOutline.y);
        end
        
        
        % BOTTOM
        % The luminance map of the reconstructed scene patch
        if (isempty(reconstructedSceneLuminanceMapPlot))
            xTicks = [sensorData.decodedImageSpatialSupportX(1) 0 sensorData.decodedImageSpatialSupportX(end)];
            yTicks = [];
            xlabelString = 'microns';
            ylabelString = 'reconstruction';
            titleString = ' ';
            colorbarStruct = [];
            axesColor = [0 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            labelMosaicCenterUsingCrossHairs = false;
            decoderSpatialFilterProfiles = [];
            [reconstructedSceneLuminanceMapPlot, ~] = initializeDecodedImagePlot(...
                    axesDictionary('reconstructedSceneLuminanceMap'), titleString, ...
                    RGBsettingsAndLuminanceData.reconstructedLuminanceMap , luminanceRange,...
                    [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                    sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY,  ...
                    decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                    decoderSpatialFilterProfiles, sensorData, ...
                    xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);
        else
            set(reconstructedSceneLuminanceMapPlot, 'CData', RGBsettingsAndLuminanceData.reconstructedLuminanceMap);
        end

        
        % The RGB rendition of the reconstructed scene patch
        if (isempty(reconstructedSceneRGBrenditionPlot))
            xTicks = [sensorData.decodedImageSpatialSupportX(1) 0 sensorData.decodedImageSpatialSupportX(end)];
            yTicks = [];
            xlabelString = 'microns';
            ylabelString = '';
            titleString = ' ';
            colorbarStruct = [];
            axesColor = [0 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            labelMosaicCenterUsingCrossHairs = false;
            [reconstructedSceneRGBrenditionPlot, ~] = initializeDecodedImagePlot(...
                  axesDictionary('reconstructedSceneRGBrendition'), titleString, ...
                  RGBsettingsAndLuminanceData.reconstructedRGBforRenderingDisplay , [0 1],...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, ...
                  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);
        else
            set(reconstructedSceneRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.reconstructedRGBforRenderingDisplay);
        end
        
        
        
        if (tBin == recentTbinsNum+1)
            % The Decoder's spatial filter plots 
            xTicks = []; 
            yTicks = []; % [sensorData.spatialSupportY(1) 0 sensorData.spatialSupportY(end)];
            xlabelString = '';
            ylabelString = ''; % 'microns';
            titleStrings = {'Lcontrast decoder', 'Mcontrast decoder', 'Scontrast decoder'};
            decodedRegionOutline = [];
            labelMosaicCenterUsingCrossHairs = true;
            axesColor = [0 0 0];
            backgroundColor = [1 1 1];
            theDecoderSpatialFilterProfiles = initializeDecoderPlots(...
                    axesDictionary('targetLcontastDecoderFilter'), ...
                    axesDictionary('targetMcontastDecoderFilter'), ...
                    axesDictionary('targetScontastDecoderFilter'), ...
                    decoder, SVDvarianceExplained, ...
                    sensorData.targetLCone, sensorData.targetMCone, sensorData.targetSCone, ...
                    [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                    decodedRegionOutline, labelMosaicCenterUsingCrossHairs, xTicks, yTicks, xlabelString, ylabelString, titleStrings, axesColor, backgroundColor , LconeContrastColor, MconeContrastColor, SconeContrastColor);
        
        
            % The LMS cone mosaic
            titleString = '';
            xTicks = [sensorData.spatialSupportX(1) 0 sensorData.spatialSupportX(end)]; 
            yTicks = []; % [sensorData.spatialSupportY(1) 0 sensorData.spatialSupportY(end)];
            xlabelString = 'microns';
            ylabelString = '';
            axesColor = [0 0 0];
            backgroundColor = [0.3 0.3 0.3];
            decodedRegionOutline = [];
            labelMosaicCenterUsingCrossHairs = true;
            decoderSpatialFilterProfiles = theDecoderSpatialFilterProfiles;
            initializeConeMosaicPlot(axesDictionary('LMSmosaic'), titleString, sensorData,...
                [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                sensorData.spatialSupportX, sensorData.spatialSupportY, ...
                decodedRegionOutline,  labelMosaicCenterUsingCrossHairs,  decoderSpatialFilterProfiles, LconeContrastColor, MconeContrastColor, SconeContrastColor, ...
                xTicks, yTicks, xlabelString, ylabelString, axesColor, backgroundColor);
        end
        
        
        % CENTER
        % The instantaneous photocurrent of the @os mosaic 
        if (isempty(instantaneousSensorXYactivationPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = sprintf('photocurrent map\n%s, t: %2.2f sec', expParams.outerSegmentParams.type, timeAxis(tBin)/1000);
            colorbarStruct = struct(...
                'position', 'NorthOutside', ...
                'ticks', outerSegmentResponseTicks, ...
                'tickLabels', sprintf('%2.0f\n',outerSegmentResponseTicks), ...
                'orientation', 'horizontal', ...
                'title', '', ...
                'fontSize', 14, ...
                'fontName', 'Menlo', ...
                'color', [0 0 0]...
                );
            axesColor = [0 0 0];
            decodedRegionOutline = theDecodedRegionOutline;
            identifyTargetDecoderPositions = true;
            labelMosaicCenterUsingCrossHairs = false;
            decoderSpatialFilterProfiles = theDecoderSpatialFilterProfiles;
            instantaneousSensorXYactivationPlot = initializeDecodedImagePlot(...
                  axesDictionary('instantaneousSensorXYactivation'), titleString, ...
                  squeeze(responseSequence(:,:,tBin)), outerSegmentResponseRange,...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.spatialSupportX, sensorData.spatialSupportY,  decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, ...
                  decoderSpatialFilterProfiles, sensorData, xTicks, yTicks, xlabelString, ylabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, colorbarStruct);
        else
            set(instantaneousSensorXYactivationPlot, 'CData', squeeze(responseSequence(:,:,tBin)));
            title(axesDictionary('instantaneousSensorXYactivation'),  sprintf('photocurrent map\n%s, t: %2.2f sec', expParams.outerSegmentParams.type, timeAxis(tBin)/1000));
        end
        
        
        
        
        
        % The photocurrent traces for the target Lcone
        traces = squeeze(responseSequence(sensorData.targetLCone.rowcolCoord(1), sensorData.targetLCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetLcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end);
            if (strcmp(expParams.outerSegmentParams.type, '@osIdentity'))
                responseRangeStep = round((outerSegmentResponseRange(end)-outerSegmentResponseRange(1))/5); 
                yLabelString = 'isomerization rate';
            else
                responseRangeStep = 20; 
                yLabelString = 'photocurrent (pA)';
            end
            yTicks = outerSegmentResponseRange(1): responseRangeStep: outerSegmentResponseRange(end);
            yTickLabels = sprintf('%+2.0f\n', yTicks);
            xLabelString = ''; xTickLabels = {};
            titleString  = ''; 
            addScaleBars = false; backgroundColor = [1 1 1];
            sensorXTtracesForTargetLcontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetLcontrastDecoder'), titleString, ...
                recentTime, traces, [0 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetLcontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The photocurrent traces for the target Mcone
        traces = squeeze(responseSequence(sensorData.targetMCone.rowcolCoord(1), sensorData.targetMCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetMcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = ''; yLabelString = ''; xTickLabels = {}; yTickLabels = {};
            titleString  = ''; 
            addScaleBars = false; backgroundColor = [1 1 1];
            sensorXTtracesForTargetMcontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetMcontrastDecoder'), titleString, ...
                recentTime, traces, [0 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetMcontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The photocurrent traces for the target Scone
        traces = squeeze(responseSequence(sensorData.targetSCone.rowcolCoord(1), sensorData.targetSCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetScontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = ''; yLabelString = ''; xTickLabels = {}; yTickLabels = {};
            titleString  = '';
            addScaleBars = false; backgroundColor = [1 1 1];
            sensorXTtracesForTargetScontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetScontrastDecoder'), titleString, ...
                recentTime, traces, [0 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetScontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The decoded Lcone contrast for the target L-cone decoder
        recentReconstructedContrastTrace = squeeze(LMScontrastReconstruction(sensorData.targetLCone.nearestDecoderRowColCoord(1), sensorData.targetLCone.nearestDecoderRowColCoord(2), 1, recentTbins));
        recentInputContrastTrace = squeeze(LMScontrastInput(sensorData.targetLCone.nearestDecoderRowColCoord(1), sensorData.targetLCone.nearestDecoderRowColCoord(2), 1, recentTbins));
        if (isempty(comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end); xTickLabels = {};
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            xLabelString = ''; yLabelString = 'Weber cone contrast';
            inputColor = LconeContrastColor;
            reconstructionColor = [0 0 0];
            titleString  = '';
            backgroundColor = [1 1 1];
            addScaleBars = false; 
            comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetLcontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, addScaleBars, recentTimeRange, coneContrastRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot.input, 'YData', recentInputContrastTrace);
            set(comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot.reconstruction, 'YData', recentReconstructedContrastTrace);
        end
        
        
        % The decoded Mcone contrast for the target M-cone decoder
        recentReconstructedContrastTrace = squeeze(LMScontrastReconstruction(sensorData.targetMCone.nearestDecoderRowColCoord(1), sensorData.targetMCone.nearestDecoderRowColCoord(2), 2, recentTbins));
        recentInputContrastTrace = squeeze(LMScontrastInput(sensorData.targetMCone.nearestDecoderRowColCoord(1), sensorData.targetMCone.nearestDecoderRowColCoord(2), 2, recentTbins));
        if (isempty(comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end); xTickLabels = {};
            yTicks = -1:1:4; yTickLabels = {};
            xLabelString = ''; yLabelString = '';
            inputColor = MconeContrastColor;
            reconstructionColor = [0 0 0];
            titleString  = ''; 
            backgroundColor = [1 1 1];
            addScaleBars = false; 
            comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetMcontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, addScaleBars, recentTimeRange, coneContrastRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot.input, 'YData', recentInputContrastTrace);
            set(comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot.reconstruction, 'YData', recentReconstructedContrastTrace);
        end
        
        
        % The decoded Scone contrast for the target S-cone decoder
        recentReconstructedContrastTrace = squeeze(LMScontrastReconstruction(sensorData.targetSCone.nearestDecoderRowColCoord(1), sensorData.targetSCone.nearestDecoderRowColCoord(2), 3, recentTbins));
        recentInputContrastTrace = squeeze(LMScontrastInput(sensorData.targetSCone.nearestDecoderRowColCoord(1), sensorData.targetSCone.nearestDecoderRowColCoord(2), 3, recentTbins));
        if (isempty(comboInputAndReconstructionTracesForTargetScontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end); xTickLabels = {};
            yTicks = -1:1:4; yTickLabels = {};
            xLabelString = ''; yLabelString = '';
            inputColor = SconeContrastColor;
            reconstructionColor = [0 0 0];
            titleString  = '';
            backgroundColor = [1 1 1];
            addScaleBars = true; 
            comboInputAndReconstructionTracesForTargetScontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetScontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, addScaleBars, recentTimeRange, coneContrastRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(comboInputAndReconstructionTracesForTargetScontrastDecoderPlot.input, 'YData', recentInputContrastTrace);
            set(comboInputAndReconstructionTracesForTargetScontrastDecoderPlot.reconstruction, 'YData', recentReconstructedContrastTrace);
        end
        
        
        inputConeContrasts = squeeze(LMScontrastInput(:,:,1:3,tBin));
        reconstructedConeContrasts = squeeze(LMScontrastReconstruction(:,:,1:3,tBin));
        if (isempty(reconstructedVSinputContrastPlot))
            titleString = '';
            xLabelString = 'scene LMS contrast';
            yLabelString = 'reconstr. LMS contrast';
            xTicks = -1:1:4; xTickLabels = sprintf('%+2.0f\n', xTicks);
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            markerColors = [LconeContrastColor; MconeContrastColor; SconeContrastColor];
            backgroundColor = [1 1 1];
            reconstructedVSinputContrastPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputContrasts'), titleString, ...
                inputConeContrasts, reconstructedConeContrasts, ...
                coneContrastRange, markerColors, backgroundColor, xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            updateContrastScatterPlot(reconstructedVSinputContrastPlot, inputConeContrasts, reconstructedConeContrasts);
        end
        
        
        
        inputContrastRatios = squeeze(LMScontrastInput(:,:,1,tBin)) ./ squeeze(LMScontrastInput(:,:,2,tBin));
        reconstructedContrastRatios = squeeze(LMScontrastReconstruction(:,:,1,tBin)) ./ squeeze(LMScontrastReconstruction(:,:,2,tBin));
        if (isempty(reconstructedVSinputLvsMratioPlot))
            titleString = '';
            xLabelString = 'scene L:M cRatio';
            yLabelString = 'reconstr. L:M cRatio';
            contrastRatioRange = [-5 5];
            xyTicks = contrastRatioRange(1)+1:2:contrastRatioRange(end)-1; xyTickLabels = sprintf('%+2.0f\n', xyTicks);
            markerColor = [1 0.6 0.9]; 
            backgroundColor = [1 1 1];
            reconstructedVSinputLvsMratioPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputLvsMratios'), titleString, ...
                inputContrastRatios, reconstructedContrastRatios, ...
                contrastRatioRange, markerColor, backgroundColor, xyTicks, xyTicks, xyTickLabels, xyTickLabels, xLabelString, yLabelString);
        else
            set(reconstructedVSinputLvsMratioPlot, 'XData', inputContrastRatios(:), 'YData', reconstructedContrastRatios(:));
        end
        
        inputLUMContrast = squeeze(LMScontrastInput(:,:,1,tBin) + LMScontrastInput(:,:,2,tBin));
        reconstructedLUMContrast = squeeze(LMScontrastReconstruction(:,:,1,tBin) + LMScontrastReconstruction(:,:,2,tBin));
        inputContrastRatios = squeeze(LMScontrastInput(:,:,3,tBin)) ./ inputLUMContrast;
        reconstructedContrastRatios = squeeze(LMScontrastReconstruction(:,:,3,tBin)) ./ reconstructedLUMContrast;
        if (isempty(reconstructedVSinputSvsLMratioPlot))
            titleString = '';
            xLabelString = 'scene S:(L+M) cRatio';
            yLabelString = 'reconstr. S:(L+M) cRatio';
            contrastRatioRange = [-7 7];
            xyTicks = contrastRatioRange(1)+1:3:contrastRatioRange(end)-1; xyTickLabels = sprintf('%+2.0f\n', xyTicks);
            markerColor = (1-SconeContrastColor).^0.3; 
            backgroundColor = [1 1 1];
            reconstructedVSinputSvsLMratioPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputSvsLMratios'), titleString, ...
                inputContrastRatios, reconstructedContrastRatios, ...
                contrastRatioRange, markerColor, backgroundColor, xyTicks, xyTicks, xyTickLabels, xyTickLabels, xLabelString, yLabelString);
        else
            set(reconstructedVSinputSvsLMratioPlot, 'XData', inputContrastRatios(:), 'YData', reconstructedContrastRatios(:));
        end
        
        
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
     end % tBin  
     
     videoOBJ.close();
end


function contrastScatterPlot = initializeContrastScatterPlot(theAxes, titleString, inputContrasts, reconstructedContrasts, coneContrastRange, markerColors, backgroundColor, ...
    xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString)

    plot(theAxes, [0 0], [coneContrastRange(1) coneContrastRange(end)], 'k-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
    hold(theAxes, 'on');
    plot(theAxes, [coneContrastRange(1) coneContrastRange(end)], [0 0], 'k-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5); 
    plot(theAxes, [coneContrastRange(1) coneContrastRange(end)], [coneContrastRange(1) coneContrastRange(end)], 'k-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
    if (ndims(inputContrasts) == 2)
        input = inputContrasts(:);
        reconstruction = reconstructedContrasts(:);
        markerColor = markerColors;
        contrastScatterPlot = plot(theAxes, input(:), reconstruction(:), ...
                'ko', 'MarkerFaceColor', markerColor, 'MarkerEdgeColor', markerColor/2, 'MarkerSize', 10);
    elseif (ndims(inputContrasts) == 3)
        for coneType = 1:3
            input = inputContrasts(:,:,coneType);
            reconstruction = reconstructedContrasts(:,:,coneType);
            markerColor = squeeze(markerColors(coneType,:));
            contrastScatterPlot(coneType) = plot(theAxes, input(:), reconstruction(:), ...
                    'ko', 'MarkerFaceColor', markerColor, 'MarkerEdgeColor', markerColor/2, 'MarkerSize', 10);
        end
    end
    hold(theAxes, 'off');
    set(theAxes, 'XLim', coneContrastRange, 'YLim', coneContrastRange, ...
                 'XTick', xTicks, 'XTickLabel', xTickLabels, ...
                 'YTick', yTicks, 'YTickLabel', yTickLabels, ...
                 'XColor', [0.0 0.0 0.0], 'YColor', [0.0 0.0 0.0], ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    axis(theAxes, 'square');
    box(theAxes, 'off'); grid(theAxes, 'off');
    set(theAxes, 'GridLineStyle',  ':', 'GridColor', [0.5 0.5 0.8], 'GridAlpha', 0.8);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold'); 
end

function updateContrastScatterPlot(contrastScatterPlot, inputContrasts, reconstructedContrasts)
    for coneType = 1:3
        input = inputContrasts(:,:,coneType);
        reconstruction = reconstructedContrasts(:,:,coneType);
        set(contrastScatterPlot(coneType), 'XData', input(:), 'YData', reconstruction(:));
    end
end


function comboContrastPlot = initializeComboInputReconstructionTracesPlot(theAxes, titleString, recentTime, inputContrastTrace, reconstructedContrastTrace, ...
                theInputColor, theReconstructionColor, backgroundColor, addScaleBars, theXDataRange, theYDataRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString)
            
    comboContrastPlot.input = area(theAxes, recentTime, inputContrastTrace, 'EdgeColor', theInputColor/3, 'FaceColor', theInputColor, 'LineWidth', 1.5, 'BaseValue', 0, 'parent', theAxes);
    hold(theAxes, 'on');
    comboContrastPlot.reconstruction = plot(theAxes, recentTime, reconstructedContrastTrace, '-', 'Color', theReconstructionColor, 'LineWidth', 3);
    % Plot the baseline
    plot(theAxes, recentTime, recentTime*0, 'k-', 'Color', 1-backgroundColor, 'LineWidth', 1.5);
    if (addScaleBars)
        yo = yTicks(end) + 0.75;
        dy = 0.5;
        dx = -350;
        plot(theAxes, [recentTime(end)+dx recentTime(end)+dx + 300], yo*[1 1], 'k-', 'Color', 1-backgroundColor, 'LineWidth', 2.0);
        textXcoord = double(recentTime(end)+dx+70); textYcoord = yo-dy;
        text(textXcoord, textYcoord, '300 msec', 'Parent', theAxes, 'Color', 1-backgroundColor, 'FontName', 'Menlo', 'FontSize', 16);
    end
    hold(theAxes, 'off');
    set(theAxes, 'XLim', theXDataRange, 'YLim', [theYDataRange(1) theYDataRange(2)], ...
                 'XTick', xTicks, 'XTickLabel', xTickLabels, ...
                 'YTick', yTicks, 'YTickLabel', yTickLabels, ...
                 'XColor', [0.0 0.0 0.0], 'YColor', [0.0 0.0 0.0], ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);
    %hL = legend({'input', 'reconstruction'}, 'Parent', theAxes);
   % set(hL, 'FontName', 'Menlo', 'FontSize', 16, 'Location', 'SouthWest')
    axis(theAxes, 'square');
    box(theAxes, 'off'); grid(theAxes, 'on');
    set(theAxes, 'GridLineStyle',  ':', 'GridColor', [0.5 0.5 0.8], 'GridAlpha', 0.8);
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    set(theAxes,'yAxisLocation','left');
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold'); 
    
end


function osTracePlot = initializeSensorTracesPlot(theAxes, titleString, recentTime, traces, theColor, backgroundColor, addScaleBars, theXDataRange, theYDataRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels,xLabelString, yLabelString)

    osTracePlot = plot(theAxes, recentTime, traces, 'k-', 'Color', theColor, 'LineWidth', 3);
    hold(theAxes, 'on');
    % Plot the baseline
    %plot(theAxes, recentTime, recentTime*0, 'k-', 'Color', 1-backgroundColor, 'LineWidth', 1.5);
    if (addScaleBars)
        dy = 10;
        dx = 10;
        plot(theAxes, [recentTime(1)+dx recentTime(1)+dx + 300], yTicks(end)*[1 1], 'k-', 'Color', 1-backgroundColor, 'LineWidth', 2.0);
        textXcoord = double(recentTime(1)+dx+70); textYcoord = yTicks(end)-dy;
        text(textXcoord, textYcoord, '300 msec', 'Parent', theAxes, 'Color', 1-backgroundColor, 'FontName', 'Menlo', 'FontSize', 16);
    end
    hold(theAxes, 'off');

    set(theAxes, 'XLim', theXDataRange, 'YLim', [theYDataRange(1) theYDataRange(2)], ...
                 'XTick', xTicks, 'XTickLabel', xTickLabels, ...
                 'YTick', yTicks, 'YTickLabel', yTickLabels, ...
                 'XColor', [0 0 0], 'YColor', [0 0 0], ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);
    axis(theAxes, 'square');
    box(theAxes, 'off'); grid(theAxes, 'on');
    set(theAxes, 'GridLineStyle',  ':', 'GridColor', [0.5 0.5 0.8], 'GridAlpha', 0.8);
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    set(theAxes,'yAxisLocation','left');
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold');   
end


function [decodedImagePlot, decodedRegionOutlinePlot] = initializeDecodedImagePlot(theAxes, titleString, theCData, theCDataRange, theXDataRange, theYDataRange, spatialSupportX, spatialSupportY, ...
    decodedRegionOutline, identifyTargetDecoderPositions, labelMosaicCenterUsingCrossHairs, decoderContours, sensorData, ...
    xTicks, yTicks, xLabelString, yLabelString, axesColor, LconeContrastColor, MconeContrastColor, SconeContrastColor, cbarStruct)

    decodedImagePlot = imagesc(spatialSupportX, spatialSupportY, theCData, 'parent', theAxes);
    
    hold(theAxes, 'on');
    if (~isempty(decodedRegionOutline))
        decodedRegionOutlinePlot = plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
    else
        decodedRegionOutlinePlot = [];
    end


    if (identifyTargetDecoderPositions)
        % Identify the target decoder locations
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetLCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetLCone.nearestDecoderRowColCoord(1)), ...
             's', 'LineWidth', 2.0, 'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', LconeContrastColor);
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetMCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetMCone.nearestDecoderRowColCoord(1)), ...
             's', 'LineWidth', 2.0, 'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', MconeContrastColor);
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetSCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetSCone.nearestDecoderRowColCoord(1)), ...
             's', 'LineWidth', 2.0,  'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', SconeContrastColor);
    end
    
    if (~isempty(decoderContours))
        C = decoderContours('LconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', LconeContrastColor, 'LineWidth', 3.0);
        end
        C = decoderContours('MconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', MconeContrastColor, 'LineWidth', 3.0);
        end
        C = decoderContours('SconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', SconeContrastColor, 'LineWidth', 3.0);
        end
    end
    
    dx = spatialSupportX(2)-spatialSupportX(1);
    dy = spatialSupportY(2)-spatialSupportY(1);
    if (labelMosaicCenterUsingCrossHairs)
         plot(theAxes, [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], [0 0 ], 'k-', 'LineWidth', 1.5);
         plot(theAxes, [0 0], [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], 'k-', 'LineWidth', 1.5);
    end
        
    hold(theAxes, 'off');  
    
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, 'XLim', [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], ...
                 'YLim', [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'YTick', yTicks, 'YTickLabel', sprintf('%2.1f\n', yTicks), ...
                 'XColor', axesColor, 'YColor', axesColor, ...
                 'CLim', theCDataRange, 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', [0 0 0], 'LineWidth', 2.0);
           
    % Add colorbar
    if (~isempty(cbarStruct))
        originalPosition = get(theAxes, 'position');
        % Add colorbar
        hCbar = colorbar(cbarStruct.position, 'peer', theAxes, 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
        hCbar.Orientation = cbarStruct.orientation; 
        hCbar.Label.String = cbarStruct.title; 
        hCbar.FontSize = cbarStruct.fontSize; 
        hCbar.FontName = cbarStruct.fontName; 
        hCbar.Color = cbarStruct.color;
        % The addition changes the figure size, so undo this change
        newPosition = get(theAxes, 'position');
        set(theAxes,'position',[newPosition(1) newPosition(2) originalPosition(3) originalPosition(4)]);
    end
            
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);   
end


function updateFullScenePlot(theAxes, fullSceneSensorOutlinePlot, sensorOutline, fullSceneDecodedRegionOutlinePlot, decodedRegionOutline, spatialSupportX, spatialSupportY)
    
    dx = max(sensorOutline.x) - min(sensorOutline.x);
    dy = max(sensorOutline.y) - min(sensorOutline.y);
    xo = min(sensorOutline.x) + dx/2;
    yo = min(sensorOutline.y) + dy/2;
    windowWidth = 2.5*dx;
    xLeft  = xo - windowWidth;
    xRight = xo + windowWidth;
    if (xLeft < min(spatialSupportX))
        xShift = min(spatialSupportX)-xLeft;
        xLeft = xLeft + xShift;
        xRight = xRight + xShift;
    end
    if (xRight > max(spatialSupportX))
        xShift =xRight - max(spatialSupportX);
        xLeft = xLeft - xShift;
        xRight = xRight - xShift;
    end
    
    axesPos = get(theAxes, 'Position');
    aspectRatio = 0.5*axesPos(4)/axesPos(3);
    set(theAxes, 'XLim', [xLeft xRight], 'YLim', yo + windowWidth*aspectRatio * [-1 1]);
    
    set(fullSceneSensorOutlinePlot, 'XData', sensorOutline.x, 'YData', sensorOutline.y);
    set(fullSceneDecodedRegionOutlinePlot, 'XData', decodedRegionOutline.x, 'YData', decodedRegionOutline.y);
end

function [fullScenePlotSensorOutlinePlot, fullScenePlotDecodedRegionOutlinePlot] = initializeFullScenePlot(theAxes, sceneData, sensorOutline, decodedRegionOutline)

    imagesc(sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY, sceneData.RGBforRenderingDisplay, 'parent', theAxes);
    hold(theAxes, 'on');
    fullScenePlotSensorOutlinePlot = plot(theAxes, sensorOutline.x, sensorOutline.y, 'r-', 'LineWidth', 2.0);
    fullScenePlotDecodedRegionOutlinePlot = plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
    hold(theAxes, 'off');
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, 'XTick', [], 'YTick', []);
end


function initializeConeMosaicPlot(theAxes, titleString, sensorData, theXDataRange, theYDataRange, ...
    spatialSupportX, spatialSupportY, ...
    decodedRegionOutline, labelMosaicCenterUsingCrossHairs, decoderContours, LconeContrastColor, MconeContrastColor, SconeContrastColor, ...
    xTicks, yTicks, xLabelString, yLabelString, axesColor, backgroundColor)

    lConeIndices = find(sensorData.coneTypes == 2);
    mConeIndices = find(sensorData.coneTypes == 3);
    sConeIndices = find(sensorData.coneTypes == 4);
    
    markerSize = 140;
    markerSymbol = 's';
    scatter(theAxes, squeeze(sensorData.conePositions(lConeIndices,1)), squeeze(sensorData.conePositions(lConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', LconeContrastColor*0.7,  'MarkerEdgeColor', 'none');
    hold(theAxes, 'on');
    scatter(theAxes, squeeze(sensorData.conePositions(mConeIndices,1)), squeeze(sensorData.conePositions(mConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', MconeContrastColor*0.7,  'MarkerEdgeColor', 'none');
    scatter(theAxes, squeeze(sensorData.conePositions(sConeIndices,1)), squeeze(sensorData.conePositions(sConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', SconeContrastColor*0.7,  'MarkerEdgeColor', 'none');
    
    if (~isempty(decodedRegionOutline))
        plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
    end
    
    dx = spatialSupportX(2)-spatialSupportX(1);
    dy = spatialSupportY(2)-spatialSupportY(1);
    if (labelMosaicCenterUsingCrossHairs)
        plot(theAxes, [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], [0 0 ], 'k-', 'LineWidth', 1.5);
        plot(theAxes, [0 0], [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], 'k-', 'LineWidth', 1.5);
    end
    
    
    if (~isempty(decoderContours))
        C = decoderContours('LconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', LconeContrastColor, 'LineWidth', 3.0);
        end
        C = decoderContours('MconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', MconeContrastColor, 'LineWidth', 3.0);
        end
        C = decoderContours('SconeMosaic');
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'Color', SconeContrastColor, 'LineWidth', 3.0);
        end
    end
    
    hold(theAxes, 'off');
    box(theAxes, 'off'); grid(theAxes, 'off');
    
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, 'XLim', [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], ...
                 'YLim', [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'YTick', yTicks, 'YTickLabel', sprintf('%2.1f\n', yTicks), ...
                 'XColor', axesColor, 'YColor', axesColor, ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);   
    box(theAxes, 'on');
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);  

end


function decoderContours = initializeDecoderPlots(theLdecoderAxes, theMdecoderAxes, theSdecoderAxes, decoder, SVDvarianceExplained, targetLcone, targetMcone, targetScone, ...
    theXDataRange, theYDataRange, decodedRegionOutline, labelMosaicCenterUsingCrossHairs, xTicks, yTicks, xLabelString, yLabelString, titleStrings, axesColor, backgroundColor, LconeContrastColor, MconeContrastColor, SconeContrastColor)
    
    % Normalize to -1 .. +1 for plotting
    decoder.filters = decoder.filters / max(abs(decoder.filters(:)));
    individualMosaicContourLevels = [-0.95 -0.75 -0.5 -0.25  0.25 0.5 0.75 0.95];
    
    spatialSupportX = decoder.spatioTemporalSupport.sensorRetinalXaxis;
    spatialSupportY = decoder.spatioTemporalSupport.sensorRetinalYaxis;
    
    lConeIndices = find(decoder.coneTypes == 2);
    mConeIndices = find(decoder.coneTypes == 3);
    sConeIndices = find(decoder.coneTypes == 4);
             
    decodedContrastNames = {'LconeMosaic', 'MconeMosaic', 'SconeMosaic'};
    decoderContours = containers.Map();
    
    
    for decodedContrastIndex = 1:numel(decodedContrastNames)
        
        switch decodedContrastIndex
            case 1
                    targetCone = targetLcone;
                    theAxes = theLdecoderAxes;
                    targetConeOutlineColor = [0 0 0];
            case 2
                    targetCone = targetMcone;
                    theAxes = theMdecoderAxes;
                    targetConeOutlineColor = [0 0 0];
            case 3
                    targetCone = targetScone;
                    theAxes = theSdecoderAxes;
                    targetConeOutlineColor = [0 0.0 0];
        end
        
        
        spatialFilter = squeeze(decoder.filters(decodedContrastIndex, targetCone.nearestDecoderRowColCoord(1), targetCone.nearestDecoderRowColCoord(2),:,:, decoder.peakTimeBins(decodedContrastIndex)));      
        imagesc(spatialSupportX, spatialSupportY, spatialFilter, 'parent', theAxes);
        hold(theAxes, 'on');
        
        
        contourDataStruct = visualizer.computeContourData(spatialFilter/max(abs(spatialFilter(:))), individualMosaicContourLevels, spatialSupportX, spatialSupportY, lConeIndices, mConeIndices, sConeIndices);
        switch decodedContrastIndex
            case 1
                    principalMosaicContours = contourDataStruct.LconeMosaicSamplingContours;
                    theOtherMosaicContours  = contourDataStruct.MconeMosaicSamplingContours;
            case 2
                    principalMosaicContours = contourDataStruct.MconeMosaicSamplingContours;
                    theOtherMosaicContours  = contourDataStruct.LconeMosaicSamplingContours;
            case 3
                    principalMosaicContours = contourDataStruct.SconeMosaicSamplingContours;
                    
                    theOtherMosaicContours  = contourDataStruct.LMconeMosaicSamplingContours;
        end
        
        C.principalMosaicContour = [];
        C.theOtherMosaicContour = [];
        
        maxLength = 0;
        for contourNo = 1:numel(principalMosaicContours)
            fprintf('principal contour %d/%d: level:%f, length: %d\n', contourNo, numel(principalMosaicContours), principalMosaicContours(contourNo).level, principalMosaicContours(contourNo).length);
            if ((principalMosaicContours(contourNo).level == 0.5) && (maxLength < principalMosaicContours(contourNo).length))
                C.principalMosaicContour = principalMosaicContours(contourNo);
                maxLength = principalMosaicContours(contourNo).length;
            end
        end
        
        maxLength = 0;
        for contourNo = 1:numel(theOtherMosaicContours)
            fprintf('theOther contour %d/%d: level:%f, length: %d\n', contourNo, numel(theOtherMosaicContours), theOtherMosaicContours(contourNo).level, theOtherMosaicContours(contourNo).length);
            if ((theOtherMosaicContours(contourNo).level == 0.5) && (maxLength < theOtherMosaicContours(contourNo).length))
                C.theOtherMosaicContour = theOtherMosaicContours(contourNo);
                maxLength = theOtherMosaicContours(contourNo).length;
            end
        end
        
        
        decoderContours(decodedContrastNames{decodedContrastIndex}) = C;
        if (~isempty(C.principalMosaicContour))
            plot(theAxes, C.principalMosaicContour.x, C.principalMosaicContour.y, 'k-', 'LineWidth', 2.0);
        end
        if (~isempty(C.theOtherMosaicContour))
            plot(theAxes, C.theOtherMosaicContour.x, C.theOtherMosaicContour.y, 'k--', 'LineWidth', 2.0);
        end
        
        
        % Superimpose the decoded region outline
        if (~isempty(decodedRegionOutline))
            decodedRegionOutlinePlot = plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
        else
            decodedRegionOutlinePlot = [];
        end
        
        % Superimpose the target cone
        targetConeOutline.x = spatialSupportX(targetCone.rowcolCoord(2)) + [-1.5 -1.5 1.5 1.5  -1.5];
        targetConeOutline.y = spatialSupportY(targetCone.rowcolCoord(1)) + [-1.5  1.5 1.5 -1.5 -1.5];
        plot(theAxes, targetConeOutline.x, targetConeOutline.y, 'k-', 'Color', targetConeOutlineColor, 'LineWidth', 2.0);
        
        dx = spatialSupportX(2)-spatialSupportX(1);
        dy = spatialSupportY(2)-spatialSupportY(1);
        if (labelMosaicCenterUsingCrossHairs)
            plot(theAxes, [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], [0 0 ], 'k-', 'LineWidth', 1.5);
            plot(theAxes, [0 0], [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], 'k-', 'LineWidth', 1.5);
        end
        
        hold(theAxes, 'off');
        
        axis(theAxes, 'image'); axis(theAxes, 'ij');
        set(theAxes, ...
            'XLim', [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], ...
            'YLim', [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], ...
            'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
            'YTick', yTicks, 'YTickLabel', sprintf('%2.1f\n', yTicks), ...
            'XColor', axesColor, 'YColor', axesColor, ...
            'CLim', [-1 1], 'FontSize', 16, 'FontName', 'Menlo', ...
            'Color', backgroundColor, 'LineWidth', 1.5);
             
        xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
        ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
        peakTimeInMilliseconds = decoder.spatioTemporalSupport.timeAxis(decoder.peakTimeBins(decodedContrastIndex));
        title(theAxes,  sprintf('%s (%2.0fms)',titleStrings{decodedContrastIndex}, peakTimeInMilliseconds),  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);  
    end
        
end

                
function [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows)

    hFig = figure(1); clf; 
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1], 'MenuBar', 'none');
    drawnow;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', slideRows, ...
               'colsNum', slideCols, ...
               'heightMargin',   0.0125, ...
               'widthMargin',    0.004, ...
               'leftMargin',     0.011, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.05, ...
               'topMargin',      0.012);
           
    axesDictionary = containers.Map();
    
    % The full input scene
    pos = subplotPosVectors(1,1).v;
    axesDictionary('fullInputScene') = axes('parent', hFig, 'unit', 'normalized', 'position', [pos(1)+0.003 pos(2)+0.02 pos(3)*1.98 pos(4)]);
    
    % The left 2 columns with luminance maps and RGB renditions
    axesDictionary('inputSceneLuminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,1).v);
    axesDictionary('inputSceneRGBrendition') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,2).v);
    axesDictionary('inputOpticalImageIlluminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,1).v);
    axesDictionary('inputOpticalImageRGBrendition')   = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,2).v);
    axesDictionary('reconstructedSceneLuminanceMap')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,1).v);
    axesDictionary('reconstructedSceneRGBrendition')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,2).v);
    
    % The middle: sensor activation
    dx = 0; % 0.005;
    axesDictionary('instantaneousSensorXYactivation') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,3).v + [dx 0 0 0]);
    
    % The LMS mosaic
    axesDictionary('LMSmosaic') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,3).v + [dx 0 0 0]);
    
    % The right side: 
    dx =  0.010;
    % First row: L,M,S contrast decoder filters at 3 select spatial positions
    axesDictionary('targetLcontastDecoderFilter')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,4).v+[dx 0 0 0]);
    axesDictionary('targetMcontastDecoderFilter') = axes('parent', hFig, 'unit', 'normalized', 'position',  subplotPosVectors(1,5).v+[dx 0 0 0]);
    axesDictionary('targetScontastDecoderFilter') = axes('parent', hFig, 'unit', 'normalized', 'position',  subplotPosVectors(1,6).v+[dx 0 0 0]);
    
    % Second row: outer-segment traces, weighted by the above L,M,S decoder spatial profiles
    dx = 0.011;
    axesDictionary('sensorXTtracesForTargetLcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,4).v+[dx 0 0 0]);
    axesDictionary('sensorXTtracesForTargetMcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,5).v+[dx 0 0 0]);
    axesDictionary('sensorXTtracesForTargetScontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,6).v+[dx 0 0 0]);
    
    % Third row: input and reconstructed L,M,S cone contrasts at the 3 chosen decoded locations
    axesDictionary('inputAndReconstructionTracesForTargetLcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,4).v+[dx 0 0 0]);
    axesDictionary('inputAndReconstructionTracesForTargetMcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,5).v+[dx 0 0 0]);
    axesDictionary('inputAndReconstructionTracesForTargetScontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,6).v+[dx 0 0 0]);
    
    % Fourth row: instaneous scatter of reconstructed vs. input L,M,S cone contrasts at all decoded locations
    axesDictionary('reconstructedVSinputContrasts') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,4).v+[dx 0 0 0]);
    axesDictionary('reconstructedVSinputLvsMratios') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,5).v+[dx 0 0 0]);
    axesDictionary('reconstructedVSinputSvsLMratios') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,6).v+[dx 0 0 0]);
end

function videoOBJ = generateVideoObject(videoFilename)
    fprintf('Will export video to %s\n', videoFilename);
    videoOBJ = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    videoOBJ.FrameRate = 5; 
    videoOBJ.Quality = 100;
    videoOBJ.open();
end

function RGBsettingsAndLuminanceData = LMScontrastsToRGBsettingsAndLuminanceforRenderingDisplay(tBin, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, sceneBackgroundExcitation,  opticalImageBackgroundExcitation, renderingDisplay, boostFactorForOpticalImage, displayGamma)
    
    % Get the input LMS contrast
    inputLMScontrastFrame = squeeze(LMScontrastInput(:,:,:,tBin));
    inputLMSexcitationFrame = core.excitationFromContrast(inputLMScontrastFrame, sceneBackgroundExcitation);
    % Compute the input RGB and luminance maps 
    beVerbose = true; boostFactor = 1.0;
    [inputImageRGB, ~, ~, inputImageLum] = core.LMStoRGBforSpecificDisplay(inputLMSexcitationFrame, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get the input optical image
    oiLMScontrastFrame = squeeze(oiLMScontrastInput(:,:,:,tBin));
    oiLMSexcitationFrame = core.excitationFromContrast(oiLMScontrastFrame, opticalImageBackgroundExcitation);
    % Compute the optical image RGB and luminance maps 
    beVerbose = true; boostFactor = boostFactorForOpticalImage;
    [opticalImageRGB, ~, ~, opticalImageLum] = core.LMStoRGBforSpecificDisplay(oiLMSexcitationFrame, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get the output (reconstructed) LMS contrast
    reconstructedLMScontrastFrame = squeeze(LMScontrastReconstruction(:,:,:,tBin));
    reconstructedLMSexcitationFrame = core.excitationFromContrast(reconstructedLMScontrastFrame, sceneBackgroundExcitation);
    % Compute the input RGB and luminance maps 
    beVerbose = true; boostFactor = 1.0;
    [reconstructedImageRGB, ~, ~, reconstructedImageLum] = core.LMStoRGBforSpecificDisplay(reconstructedLMSexcitationFrame, renderingDisplay, boostFactor, displayGamma, beVerbose);

    RGBsettingsAndLuminanceData = struct(...
        'inputRGBforRenderingDisplay',          inputImageRGB, ...
        'inputLuminanceMap',                    inputImageLum, ...
        'reconstructedRGBforRenderingDisplay',  reconstructedImageRGB, ...
        'reconstructedLuminanceMap',            reconstructedImageLum, ...
        'inputOpticalImageRGBforRenderingDisplay',   opticalImageRGB, ...
        'inputOpticalImageLuminanceMap',             opticalImageLum ...
     );
end



    
function [sceneData, oiData] = retrieveComputedDataForCurrentScene(sceneSetName, resultsDir, sceneIndex, renderingDisplay, boostFactorForOpticalImage, displayGamma)

    scanFileName = core.getScanFileName(sceneSetName, resultsDir, sceneIndex);
    load(scanFileName, 'scanData', 'scene', 'oi');
    
    % Get the LMS excitations
    [sceneLMSexcitations, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
    
    % Transform them to RGB
    beVerbose = true; 
    boostFactor = 1;
    [sceneData.RGBforRenderingDisplay, sceneData.RGBpixelsBelowGamut, sceneData.RGBpixelsAboveGamut, sceneData.LuminanceMap] = ...
        core.LMStoRGBforSpecificDisplay(sceneLMSexcitations, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get retinal projection coords
    sceneData.fullSceneSpatialSupportX = scanData{1}.sceneRetinalProjectionXData;
    sceneData.fullSceneSpatialSupportY = scanData{1}.sceneRetinalProjectionYData;
    
    % Get the LMS excitations of the optical image
    [opticalImageLMSexcitations, ~] = core.imageFromSceneOrOpticalImage(oi, 'LMS');
    boostFactor = boostFactorForOpticalImage;
    [oiData.RGBforRenderingDisplay, oiData.RGBpixelsBelowGamut, oiData.RGBpixelsAboveGamut, oiData.LuminanceMap] = ...
        core.LMStoRGBforSpecificDisplay(opticalImageLMSexcitations, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get spatial support data
    %oiData.sceneRetinalProjectionSpatialSupportX = scanData{1}.sceneRetinalProjectionXData;
    %oiData.sceneRetinalProjectionSpatialSupportY = scanData{1}.sceneRetinalProjectionYData;
    oiData.fullOpticalImageSpatialSupportX  = scanData{1}.opticalImageXData;
    oiData.fullOpticalImageSpatialSupportY  = scanData{1}.opticalImageYData;
end





function [timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
          sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, ...
          responseSequence, expParams, svdIndex,SVDvarianceExplained, videoPostfix] = ...
          retrieveReconstructionData(sceneSetName, decodingDataDir, InSampleOrOutOfSample, computeSVDbasedLowRankFiltersAndPredictions)
    
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        
        fprintf('Loading design matrix to reconstruct the original responses ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'Xtrain', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'expParams');
        expParams.preProcessingParams = preProcessingParams;
        responseSequence = decoder.reformatDesignMatrixToOriginalResponse(Xtrain, rawTrainingResponsePreprocessing, preProcessingParams, expParams.decoderParams, expParams.sensorParams);
        
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName, 'Ctrain', 'CtrainPrediction', 'oiCtrain', ...
                       'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', ...
                       'trainingTimeAxis', 'originalTrainingStimulusSize', ...
                       'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'expParams');
        videoPostfix = sprintf('PINVbased');
        svdIndex = [];
        SVDvarianceExplained = [];
        
        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            if (numel(svdIndex)>1)
                return;
            end
            videoPostfix = sprintf('SVD_%2.3f%%VarianceExplained',SVDbasedLowRankFilterVariancesExplained(svdIndex));
            SVDvarianceExplained = SVDbasedLowRankFilterVariancesExplained(svdIndex);
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
        end
        
        LMScontrastInput = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(Ctrain, expParams.decoderParams), ...
            originalTrainingStimulusSize);
    
        LMScontrastReconstruction = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(CtrainPrediction, expParams.decoderParams), ...
            originalTrainingStimulusSize);
        
        oiLMScontrastInput = decoder.reformatStimulusSequence('FromDesignMatrixFormat',...
            decoder.shiftStimulusSequence(oiCtrain, expParams.decoderParams), ...
            originalTrainingStimulusSize);
    
        sceneBackgroundExcitation = mean(trainingSceneLMSbackground, 2);
        opticalImageBackgroundExcitation = mean(trainingOpticalImageLMSbackground,2);
        
        % Only keep the data for which we have reconstructed the signal
        timeAxis                = trainingTimeAxis(1:size(CtrainPrediction,1));
        sceneIndexSequence      = trainingSceneIndexSequence(1:numel(timeAxis));
        sensorPositionSequence  = trainingSensorPositionSequence(1:numel(timeAxis),:);
    end
    
    if (strcmp(InSampleOrOutOfSample, 'OutOfSample'))
        error('Not implemented')
    end 
end