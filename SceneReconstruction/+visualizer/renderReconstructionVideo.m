function renderReconstructionVideo(sceneSetName, resultsDir, decodingDataDir, InSampleOrOutOfSample)

    computeSVDbasedLowRankFiltersAndPredictions = true;  % SVD based
  %  computeSVDbasedLowRankFiltersAndPredictions = false;  % PINV based
  
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        [timeAxis, LMScontrastInput, LMScontrastReconstruction, ...
         oiLMScontrastInput, ...
         sceneBackgroundExcitation,  opticalImageBackgroundExcitation, ...
         sceneIndexSequence, sensorPositionSequence, responseSequence, ...
         expParams, videoPostFix] = retrieveReconstructionData(sceneSetName, decodingDataDir, InSampleOrOutOfSample, computeSVDbasedLowRankFiltersAndPredictions);
    end
    
    makeVideoClip(timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, responseSequence, expParams, videoPostFix);
end



function makeVideoClip(timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, responseSequence, expParams, videoPostFix)
    
    % Get luminance colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    colormap(grayRedLUT); 
    
    % Generate colors for L,M,S contrast traces
    LconeContrastColor = [255 200 180]/255;
    MconeContrastColor = [120 255 224]/255;
    SconeContrastColor = [170 180 255]/255;
    
    % Positions of visualized decoders
    targetLdecoderXYcoords = [7 10];
    targetMdecoderXYcoords = [14 -6];
    targetSdecoderXYcoords = [0 0];
    
    
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
    
    reconstructedVSinputLcontrastPlot = [];
    reconstructedVSinputMcontrastPlot = [];
    reconstructedVSinputScontrastPlot = [];
    
    previousSceneIndex = 0;
    for tBin = recentTbinsNum+1:numel(timeAxis)
        
        recentTbins = tBin-recentTbinsNum:1:tBin;
        recentTime  = timeAxis(recentTbins)-timeAxis(recentTbins(end));
        recentTimeRange = [recentTime(1) recentTime(end)];
        
            
        % Get the current scene data
        if (sceneIndexSequence(tBin) ~= previousSceneIndex)
            fprintf('Retrieving new scene data at time bin: %d\n', tBin);
            [sceneData, oiData, sensorData] = retrieveComputedDataForCurrentScene(expParams.sceneSetName, expParams.resultsDir, sceneIndexSequence(tBin), ...
                renderingDisplay, boostFactorForOpticalImage, displayGamma, targetLdecoderXYcoords, targetMdecoderXYcoords, targetSdecoderXYcoords);
            
            previousSceneIndex = sceneIndexSequence(tBin);
            
            % The full input scene
            sensorOutline.x = sensorData.spatialOutlineX + sensorPositionSequence(tBin,1);
            sensorOutline.y = sensorData.spatialOutlineY + sensorPositionSequence(tBin,2);
            fullSceneSensorOutlinePlot = initializeFullScenePlot(axesDictionary('fullInputScene'), sceneData, sensorOutline);
            
            % The decoder region outline
            theDecodedRegionOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 0 1]);
        end
        

        
        % Convert the various LMS contrasts to RGB settings and luminances for the rendering display
        RGBsettingsAndLuminanceData = LMScontrastsToRGBsettingsAndLuminanceforRenderingDisplay(tBin, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
                        sceneBackgroundExcitation,  opticalImageBackgroundExcitation, renderingDisplay, boostFactorForOpticalImage, displayGamma);
        
                    
        % Update sensor position in optical image
        sensorOutline.x = sensorData.spatialOutlineX + sensorPositionSequence(tBin,1);
        sensorOutline.y = sensorData.spatialOutlineY + sensorPositionSequence(tBin,2);
        updateFullScenePlot(axesDictionary('fullInputScene'), fullSceneSensorOutlinePlot, sensorOutline, sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY);
        
        
        % The luminance map of the input optical image patch
        if (isempty(inputOpticalImageLuminanceMapPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = 'optical image';
            titleString = 'luminance map';
            colorbarStruct = [];
            axesColor = [1 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            inputOpticalImageLuminanceMapPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageIlluminanceMap'), titleString, ...
                  oiData.LuminanceMap, luminanceRange,...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  oiData.fullOpticalImageSpatialSupportX, oiData.fullOpticalImageSpatialSupportY, decodedRegionOutline, identifyTargetDecoderPositions, sensorData,...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);  
        else
            set(axesDictionary('inputOpticalImageIlluminanceMap'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            %set(inputOpticalImageLuminanceMapPlot, 'CData', RGBsettingsAndLuminanceData.inputOpticalImageLuminanceMap);
        end
        
        % The RGB rendition  of the input optical image patch
        if (isempty(inputOpticalImageRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = 'RGB rendition';
            colorbarStruct = [];
            axesColor = [1 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            inputOpticalImageRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageRGBrendition'), titleString, ...
                  oiData.RGBforRenderingDisplay, [0 1],...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  oiData.fullOpticalImageSpatialSupportX, oiData.fullOpticalImageSpatialSupportY, decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);
        else
            set(axesDictionary('inputOpticalImageRGBrendition'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            % set(inputOpticalImageRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.inputOpticalImageRGBforRenderingDisplay);
        end
        
        
        % The luminance map of the input scene patch
        if (isempty(inputSceneLuminanceMapPlot))
            xTicks = []; yTicks = [];
            xlabelString = ''; ylabelString = 'input scene';
            titleString = ''; colorbarStruct = [];
            axesColor = [1 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            inputSceneLuminanceMapPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneLuminanceMap'), titleString, ...
                  sceneData.LuminanceMap, luminanceRange,...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY,  decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);  
        else
            set(axesDictionary('inputSceneLuminanceMap'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            %set(inputSceneLuminanceMapPlot, 'CData', RGBsettingsAndLuminanceData.inputLuminanceMap);
        end
        
        % The RGB rendition of the input scene patch
        if (isempty(inputSceneRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = '';
            colorbarStruct = [];
            axesColor = [1 0 0];
            decodedRegionOutline = [];
            identifyTargetDecoderPositions = false;
            inputSceneRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneRGBrendition'), titleString, ...
                  sceneData.RGBforRenderingDisplay, [0 1],...
                  sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], sensorPositionSequence(tBin,2)+[sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY, decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);  
        else
            set(axesDictionary('inputSceneRGBrendition'), ...
                'XLim', sensorPositionSequence(tBin,1)+ [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                'YLim', sensorPositionSequence(tBin,2)+ [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)]);
            %set(inputSceneRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.inputRGBforRenderingDisplay);
        end
        
        
        % The luminance map of the reconstructed scene patch
        if (isempty(reconstructedSceneLuminanceMapPlot))
            xTicks = [sensorData.decodedImageSpatialSupportX(1) 0 sensorData.decodedImageSpatialSupportX(end)];
            yTicks = [];
            xlabelString = 'microns';
            ylabelString = 'reconstruction';
            titleString = ' ';
            colorbarStruct = struct(...
                'position', 'South', ...
                'ticks', luminanceRangeTicks, ...
                'tickLabels', luminanceRangeTickLabels, ...
                'orientation', 'horizontal', ...
                'title', '', ...
                'fontSize', 14, ...
                'fontName', 'Menlo', ...
                'color', [0 1 1]...
                );
            axesColor = [0 0 0];
            decodedRegionOutline = []; % theDecodedRegionOutline;
            identifyTargetDecoderPositions = false;
            reconstructedSceneLuminanceMapPlot = initializeDecodedImagePlot(...
                    axesDictionary('reconstructedSceneLuminanceMap'), titleString, ...
                    RGBsettingsAndLuminanceData.reconstructedLuminanceMap , luminanceRange,...
                    [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                    sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY,  decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                    xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);
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
            reconstructedSceneRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('reconstructedSceneRGBrendition'), titleString, ...
                  RGBsettingsAndLuminanceData.reconstructedRGBforRenderingDisplay , [0 1],...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);
        else
            set(reconstructedSceneRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.reconstructedRGBforRenderingDisplay);
        end
        
        % The instantaneous photocurrent of the @os mosaic 
        if (isempty(instantaneousSensorXYactivationPlot))
            xTicks = [sensorData.spatialSupportX(1) 0 sensorData.spatialSupportX(end)];
            yTicks = [];
            xlabelString = 'microns';
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
            axesColor = [1 0 0];
            decodedRegionOutline = theDecodedRegionOutline;
            instantaneousSensorXYactivationPlot = initializeDecodedImagePlot(...
                  axesDictionary('instantaneousSensorXYactivation'), titleString, ...
                  squeeze(responseSequence(:,:,tBin)), outerSegmentResponseRange,...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.spatialSupportX, sensorData.spatialSupportY,  decodedRegionOutline, identifyTargetDecoderPositions, sensorData, ...
                  xTicks, yTicks, xlabelString, ylabelString, axesColor, colorbarStruct);
        else
            set(instantaneousSensorXYactivationPlot, 'CData', squeeze(responseSequence(:,:,tBin)));
            title(axesDictionary('instantaneousSensorXYactivation'),  sprintf('photocurrent map\n%s, t: %2.2f sec', expParams.outerSegmentParams.type, timeAxis(tBin)/1000));
        end
        
       
        % The photocurrent traces for the target Lcone
        traces = squeeze(responseSequence(sensorData.targetLCone.rowcolCoord(1), sensorData.targetLCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetLcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = ''; yLabelString = ''; xTickLabels = {}; yTickLabels = {};
            titleString  = ''; 
            addScaleBars = true; backgroundColor = [1 1 1];
            sensorXTtracesForTargetLcontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetLcontrastDecoder'), titleString, ...
                recentTime, traces, [1 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
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
                recentTime, traces, [1 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetMcontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The photocurrent traces for the target Scone
        traces = squeeze(responseSequence(sensorData.targetSCone.rowcolCoord(1), sensorData.targetSCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetScontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = ''; yLabelString = ''; xTickLabels = {}; yTickLabels = sprintf('%+2.0f\n', yTicks);
            titleString  = '';
            addScaleBars = false; backgroundColor = [1 1 1];
            sensorXTtracesForTargetScontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetScontrastDecoder'), titleString, ...
                recentTime, traces, [1 0 0], backgroundColor, addScaleBars, recentTimeRange, outerSegmentResponseRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetScontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The decoded Lcone contrast for the target L-cone decoder
        recentReconstructedContrastTrace = squeeze(LMScontrastReconstruction(sensorData.targetLCone.nearestDecoderRowColCoord(1), sensorData.targetLCone.nearestDecoderRowColCoord(2), 1, recentTbins));
        recentInputContrastTrace = squeeze(LMScontrastInput(sensorData.targetLCone.nearestDecoderRowColCoord(1), sensorData.targetLCone.nearestDecoderRowColCoord(2), 1, recentTbins));
        if (isempty(comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot))
            xTicks = recentTimeRange(1):100:recentTimeRange(end); xTickLabels = {};
            yTicks = -1:1:4; yTickLabels = {};
            xLabelString = ''; yLabelString = '';
            inputColor = LconeContrastColor;
            reconstructionColor = [0 0 0];
            titleString  = '';
            backgroundColor = [1 1 1];
            comboInputAndReconstructionTracesForTargetLcontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetLcontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, recentTimeRange, coneContrastRange, ...
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
            comboInputAndReconstructionTracesForTargetMcontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetMcontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, recentTimeRange, coneContrastRange, ...
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
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            xLabelString = ''; yLabelString = '';
            inputColor = SconeContrastColor;
            reconstructionColor = [0 0 0];
            titleString  = '';
            backgroundColor = [1 1 1];
            comboInputAndReconstructionTracesForTargetScontrastDecoderPlot = initializeComboInputReconstructionTracesPlot(...
                axesDictionary('inputAndReconstructionTracesForTargetScontrastDecoder'), titleString, ...
                recentTime, recentInputContrastTrace, recentReconstructedContrastTrace, ...
                inputColor, reconstructionColor, backgroundColor, recentTimeRange, coneContrastRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(comboInputAndReconstructionTracesForTargetScontrastDecoderPlot.input, 'YData', recentInputContrastTrace);
            set(comboInputAndReconstructionTracesForTargetScontrastDecoderPlot.reconstruction, 'YData', recentReconstructedContrastTrace);
        end
        
        
        inputConeContrasts = squeeze(LMScontrastInput(:,:,1,tBin));
        reconstructedConeContrasts = squeeze(LMScontrastReconstruction(:,:,1,tBin));
        if (isempty(reconstructedVSinputLcontrastPlot))
            titleString = '';
            xLabelString = '';
            yLabelString = '';
            xTicks = -1:1:4; xTickLabels = sprintf('%+2.0f\n', yTicks);
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            markerColor = LconeContrastColor;
            reconstructedVSinputLcontrastPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputLcontrast'), titleString, ...
                inputConeContrasts(:), reconstructedConeContrasts(:), ...
                coneContrastRange, markerColor, xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(reconstructedVSinputLcontrastPlot, 'XData', inputConeContrasts(:), 'YData', reconstructedConeContrasts(:));
        end
        
        
        inputConeContrasts = squeeze(LMScontrastInput(:,:,2,tBin));
        reconstructedConeContrasts = squeeze(LMScontrastReconstruction(:,:,2,tBin));
        if (isempty(reconstructedVSinputMcontrastPlot))
            titleString = '';
            xLabelString = '';
            yLabelString = '';
            xTicks = -1:1:4; xTickLabels = sprintf('%+2.0f\n', yTicks);
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            markerColor = MconeContrastColor;
            reconstructedVSinputMcontrastPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputMcontrast'), titleString, ...
                inputConeContrasts(:), reconstructedConeContrasts(:), ...
                coneContrastRange, markerColor, xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(reconstructedVSinputMcontrastPlot, 'XData', inputConeContrasts(:), 'YData', reconstructedConeContrasts(:));
        end
        

        inputConeContrasts = squeeze(LMScontrastInput(:,:,3,tBin));
        reconstructedConeContrasts = squeeze(LMScontrastReconstruction(:,:,3,tBin));
        if (isempty(reconstructedVSinputScontrastPlot))
            titleString = '';
            xLabelString = '';
            yLabelString = '';
            xTicks = -1:1:4; xTickLabels = sprintf('%+2.0f\n', yTicks);
            yTicks = -1:1:4; yTickLabels = sprintf('%+2.0f\n', yTicks);
            markerColor = SconeContrastColor;
            reconstructedVSinputScontrastPlot = initializeContrastScatterPlot(...
                axesDictionary('reconstructedVSinputScontrast'), titleString, ...
                inputConeContrasts(:), reconstructedConeContrasts(:), ...
                coneContrastRange, markerColor, xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString);
        else
            set(reconstructedVSinputScontrastPlot, 'XData', inputConeContrasts(:), 'YData', reconstructedConeContrasts(:));
        end

        
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
     end % tBin  
     
     videoOBJ.close();
end


function contrastScatterPlot = initializeContrastScatterPlot(theAxes, titleString, inputContrasts, reconstructedContrasts, coneContrastRange, markerColor, ...
    xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString)

    plot(theAxes, [0 0], [coneContrastRange(1) coneContrastRange(end)], 'k-', 'LineWidth', 1.5);
    hold(theAxes, 'on');
    plot(theAxes, [coneContrastRange(1) coneContrastRange(end)], [0 0], 'k-', 'LineWidth', 1.5); 
    plot(theAxes, [coneContrastRange(1) coneContrastRange(end)], [coneContrastRange(1) coneContrastRange(end)], 'k-', 'LineWidth', 1.5);
    contrastScatterPlot = plot(theAxes,inputContrasts(:), reconstructedContrasts(:), ...
        'ko', 'MarkerFaceColor', markerColor, 'MarkerEdgeColor', markerColor/2, 'MarkerSize', 8);
    hold(theAxes, 'off');
    set(theAxes, 'XLim', coneContrastRange, 'YLim', coneContrastRange);
    set(theAxes, 'XTick', xTicks, 'XTickLabel', xTickLabels, 'YTick', yTicks, 'YTickLabel', yTickLabels);
    set(theAxes, 'FontSize', 16, 'FontName', 'Menlo', 'LineWidth', 1.5);
    axis(theAxes, 'square');
    box(theAxes, 'off'); grid(theAxes, 'off');
end


function comboContrastPlot = initializeComboInputReconstructionTracesPlot(theAxes, titleString, recentTime, inputContrastTrace, reconstructedContrastTrace, ...
                theInputColor, theReconstructionColor, backgroundColor, theXDataRange, theYDataRange, ...
                xTicks, yTicks, xTickLabels, yTickLabels, xLabelString, yLabelString)
            
    comboContrastPlot.input = area(theAxes, recentTime, inputContrastTrace, 'EdgeColor', theInputColor/3, 'FaceColor', theInputColor, 'LineWidth', 1.5, 'BaseValue', 0, 'parent', theAxes);
    hold(theAxes, 'on');
    comboContrastPlot.reconstruction = plot(theAxes, recentTime, reconstructedContrastTrace, '-', 'Color', theReconstructionColor, 'LineWidth', 3);
    % Plot the baseline
    plot(theAxes, recentTime, recentTime*0, 'k-', 'Color', 1-backgroundColor, 'LineWidth', 1.5);
    hold(theAxes, 'off');
    set(theAxes, 'XLim', theXDataRange, 'YLim', [theYDataRange(1) theYDataRange(2)], ...
                 'XTick', xTicks, 'XTickLabel', xTickLabels, ...
                 'YTick', yTicks, 'YTickLabel', yTickLabels, ...
                 'XColor', [0.0 0.0 0.0], 'YColor', [0.0 0.0 0.0], ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);
    %hL = legend({'input', 'reconstruction'}, 'Parent', theAxes);
   % set(hL, 'FontName', 'Menlo', 'FontSize', 16, 'Location', 'SouthWest')
    box(theAxes, 'off'); grid(theAxes, 'off');
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    set(theAxes,'yAxisLocation','right');
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
    box(theAxes, 'off'); grid(theAxes, 'off');
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    set(theAxes,'yAxisLocation','right');
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold');   
end


function decodedImagePlot = initializeDecodedImagePlot(theAxes, titleString, theCData, theCDataRange, theXDataRange, theYDataRange, spatialSupportX, spatialSupportY, decodedRegionOutline, identifyTargetDecoderPositions, sensorData, xTicks, yTicks, xLabelString, yLabelString, axesColor, cbarStruct)

    decodedImagePlot = imagesc(spatialSupportX, spatialSupportY, theCData, 'parent', theAxes);
    
    hold(theAxes, 'on');
    if (~isempty(decodedRegionOutline))
        plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
    end

    if (identifyTargetDecoderPositions)
        % Identify the target decoder locations
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetLCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetLCone.nearestDecoderRowColCoord(1)), ...
             'r+', 'LineWidth', 2.0, 'MarkerSize', 14, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', [1 0 0]);
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetMCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetMCone.nearestDecoderRowColCoord(1)), ...
             'r+', 'LineWidth', 2.0, 'MarkerSize', 14, 'MarkerFaceColor', [0 1 0], 'MarkerEdgeColor', [0 1 0]);
        plot(theAxes, ...
             sensorData.decodedImageSpatialSupportX(sensorData.targetSCone.nearestDecoderRowColCoord(2)), ...
             sensorData.decodedImageSpatialSupportY(sensorData.targetSCone.nearestDecoderRowColCoord(1)), ...
             'b+', 'LineWidth', 2.0,  'MarkerSize', 14, 'MarkerFaceColor', [0 1 1], 'MarkerEdgeColor', [0 1 1]);
    end
    hold(theAxes, 'off');  
    
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    dx = spatialSupportX(2)-spatialSupportX(1);
    dy = spatialSupportY(2)-spatialSupportY(1);
    set(theAxes, 'XLim', [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], ...
                 'YLim', [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'YTick', yTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
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


function updateFullScenePlot(theAxes, fullSceneSensorOutlinePlot, sensorOutline, spatialSupportX, spatialSupportY)
    
    dx = max(sensorOutline.x) - min(sensorOutline.x);
    dy = max(sensorOutline.y) - min(sensorOutline.y);
    xo = min(sensorOutline.x) + dx/2;
    yo = min(sensorOutline.y) + dy/2;
    windowWidth = 4*dx;
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
    
end

function fullScenePlotSensorOutlinePlot = initializeFullScenePlot(theAxes, sceneData, sensorOutline)

    imagesc(sceneData.fullSceneSpatialSupportX, sceneData.fullSceneSpatialSupportY, sceneData.RGBforRenderingDisplay, 'parent', theAxes);
    hold(theAxes, 'on');
    fullScenePlotSensorOutlinePlot = plot(theAxes, sensorOutline.x, sensorOutline.y, 'r-', 'LineWidth', 2.0);
    hold(theAxes, 'off');
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, 'XTick', [], 'YTick', []);
end


function [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows)

    hFig = figure(1); clf; 
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1], 'MenuBar', 'none');
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', slideRows, ...
               'colsNum', slideCols, ...
               'heightMargin',   0.02, ...
               'widthMargin',    0.01, ...
               'leftMargin',     0.015, ...
               'rightMargin',    0.010, ...
               'bottomMargin',   0.025, ...
               'topMargin',      0.02);
           
    axesDictionary = containers.Map();
    
    % The full input scene
    pos = subplotPosVectors(1,1).v;
    axesDictionary('fullInputScene') = axes('parent', hFig, 'unit', 'normalized', 'position', [pos(1)+0.002 pos(2)+0.02 pos(3)*2.02 pos(4)]);
    
    % The left 2 columns with luminance maps and RGB renditions
    axesDictionary('inputSceneLuminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,1).v);
    axesDictionary('inputSceneRGBrendition') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,2).v);
    axesDictionary('inputOpticalImageIlluminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,1).v);
    axesDictionary('inputOpticalImageRGBrendition')   = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,2).v);
    axesDictionary('reconstructedSceneLuminanceMap')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,1).v);
    axesDictionary('reconstructedSceneRGBrendition')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,2).v);
    
    % The middle: sensor activation
    axesDictionary('instantaneousSensorXYactivation') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,3).v);
    
    % The right side: 
    % First row: L,M,S contrast decoder filters at 3 select spatial positions
    axesDictionary('targetLcontastDecoderFilter')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,4).v);
    axesDictionary('targetMcontastDecoderFilter') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,5).v);
    axesDictionary('targetScontastDecoderFilter') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,6).v);
    
    % Second row: outer-segment traces, weighted by the above L,M,S decoder spatial profiles
    axesDictionary('sensorXTtracesForTargetLcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,4).v);
    axesDictionary('sensorXTtracesForTargetMcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,5).v);
    axesDictionary('sensorXTtracesForTargetScontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,6).v);
    
    % Third row: input and reconstructed L,M,S cone contrasts at the 3 chosen decoded locations
    axesDictionary('inputAndReconstructionTracesForTargetLcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,4).v);
    axesDictionary('inputAndReconstructionTracesForTargetMcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,5).v);
    axesDictionary('inputAndReconstructionTracesForTargetScontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,6).v);
    
    % Fourth row: instaneous scatter of reconstructed vs. input L,M,S cone contrasts at all decoded locations
    axesDictionary('reconstructedVSinputLcontrast') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,4).v);
    axesDictionary('reconstructedVSinputMcontrast') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,5).v);
    axesDictionary('reconstructedVSinputScontrast') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,6).v);
end

function videoOBJ = generateVideoObject(videoFilename)
    fprintf('Will export video to %s\n', videoFilename);
    videoOBJ = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    videoOBJ.FrameRate = 15; 
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



    
function [sceneData, oiData, sensorData] = retrieveComputedDataForCurrentScene(sceneSetName, resultsDir, sceneIndex, renderingDisplay, boostFactorForOpticalImage, displayGamma, targetLdecoderXYcoords, targetMdecoderXYcoords, targetSdecoderXYcoords)
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
    
    % Sensor data    
    sensorData.spatialSupportX = scanData{1}.sensorRetinalXaxis;
    sensorData.spatialSupportY = scanData{1}.sensorRetinalYaxis;
    sensorData.spatialOutlineX = [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end) sensorData.spatialSupportX(end) sensorData.spatialSupportX(1)   sensorData.spatialSupportX(1)];
    sensorData.spatialOutlineY = [sensorData.spatialSupportY(1) sensorData.spatialSupportY(1)   sensorData.spatialSupportY(end) sensorData.spatialSupportY(end) sensorData.spatialSupportY(1)];
    sensorData.decodedImageSpatialSupportX = scanData{1}.sensorFOVxaxis;
    sensorData.decodedImageSpatialSupportY = scanData{1}.sensorFOVyaxis;
    dx = (sensorData.decodedImageSpatialSupportX(2)-sensorData.decodedImageSpatialSupportX(1))/2;
    dy = (sensorData.decodedImageSpatialSupportY(2)-sensorData.decodedImageSpatialSupportY(1))/2;
    sensorData.decodedImageOutlineX = [sensorData.decodedImageSpatialSupportX(1)-dx sensorData.decodedImageSpatialSupportX(1)-dx   sensorData.decodedImageSpatialSupportX(end)+dx sensorData.decodedImageSpatialSupportX(end)+dx sensorData.decodedImageSpatialSupportX(1)-dx];
    sensorData.decodedImageOutlineY = [sensorData.decodedImageSpatialSupportY(1)-dy sensorData.decodedImageSpatialSupportY(end)+dy sensorData.decodedImageSpatialSupportY(end)+dy sensorData.decodedImageSpatialSupportY(1)-dy   sensorData.decodedImageSpatialSupportY(1)-dy];
        
    % returm other useful info: coords for the most central L,M, and S-cone
    conePositions = sensorGet(scanData{1}.scanSensor, 'xy');
    coneTypes = sensorGet(scanData{1}.scanSensor, 'cone type');
    sensorData.targetLCone  = getTargetConeCoords(sensorData, conePositions, targetLdecoderXYcoords, find(coneTypes == 2));
    sensorData.targetMCone  = getTargetConeCoords(sensorData, conePositions, targetMdecoderXYcoords, find(coneTypes == 3));
    sensorData.targetSCone  = getTargetConeCoords(sensorData, conePositions, targetSdecoderXYcoords, find(coneTypes == 4));

    
    function s = getTargetConeCoords(sensorData, conePositions, targetDecoderPosition, coneIndices)
        if isempty(coneIndices)
            s = [];
            return;
        end
        conePositionsDistanceToTarget = bsxfun(@minus, conePositions(coneIndices,:), targetDecoderPosition);
        coneDistances = sqrt(sum(conePositionsDistanceToTarget.^2, 2));
        [~, theIndex] = min(coneDistances(:));
        closestConeOfSelectedType = coneIndices(theIndex);
        [r,c] = ind2sub([numel(sensorData.spatialSupportY) numel(sensorData.spatialSupportX)], closestConeOfSelectedType);
        
        [X,Y] = meshgrid(sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY);
        d = sqrt((X-conePositions(closestConeOfSelectedType, 1)).^2 + (Y-conePositions(closestConeOfSelectedType, 2)).^2);
        [~,indexOfClosestDecoder] = min(d(:));
        [dr, rc] = ind2sub(size(X), indexOfClosestDecoder);
        s = struct(...
            'rowcolCoord', [r c], ...
            'xyCoord', conePositions(closestConeOfSelectedType,:), ...
            'nearestDecoderRowColCoord', [dr rc]);
    end

end


function [timeAxis, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
          sceneBackgroundExcitation,  opticalImageBackgroundExcitation, sceneIndexSequence, sensorPositionSequence, ...
          responseSequence, expParams, videoPostfix] = ...
          retrieveReconstructionData(sceneSetName, decodingDataDir, InSampleOrOutOfSample, computeSVDbasedLowRankFiltersAndPredictions)
    
    if (strcmp(InSampleOrOutOfSample, 'InSample'))
        
        fprintf('Loading design matrix to reconstruct the original responses ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
        load(fileName, 'Xtrain', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'expParams');
        responseSequence = decoder.reformatDesignMatrixToOriginalResponse(Xtrain, rawTrainingResponsePreprocessing, expParams);
        
        fprintf('\nLoading in-sample prediction data ...');
        fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
        load(fileName, 'Ctrain', 'CtrainPrediction', 'oiCtrain', ...
                       'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', ...
                       'trainingTimeAxis', 'originalTrainingStimulusSize', ...
                       'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'expParams');
        videoPostfix = sprintf('PINVbased');

        if (computeSVDbasedLowRankFiltersAndPredictions)
            load(fileName, 'CtrainPredictionSVDbased', 'SVDbasedLowRankFilterVariancesExplained');
            svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            if (numel(svdIndex)>1)
                return;
            end
            videoPostfix = sprintf('SVD_%2.3f%%VarianceExplained',SVDbasedLowRankFilterVariancesExplained(svdIndex));
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