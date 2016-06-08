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
    recentTbinsNum = 100;
    
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
    
    
    previousSceneIndex = 0;
    for tBin = recentTbinsNum+1:numel(timeAxis)
        
        recentTbins = tBin-recentTbinsNum:1:tBin;
        
        % Get the current scene data
        if (sceneIndexSequence(tBin) ~= previousSceneIndex)
            fprintf('Retrieving new scene data at time bin: %d\n', tBin);
            [sceneData, oiData, sensorData] = retrieveComputedDataForCurrentScene(expParams.sceneSetName, expParams.resultsDir, sceneIndexSequence(tBin), renderingDisplay, boostFactorForOpticalImage, displayGamma);
            previousSceneIndex = sceneIndexSequence(tBin);
            
            % The full input scene
            %imagesc(sceneData.RGBforRenderingDisplay); axis image;
            % The full optical image
            %imagesc(oiData.fullOpticalImageSpatialSupportX, oiData.fullOpticalImageSpatialSupportY, oiData.RGBforRenderingDisplay); axis 'image'
            % overlay sensor position on optical image
            %hold on;
            %sensorPositionOnOpticalImagePlot = plot(sensorData.spatialOutlineX + sensorPositionSequence(tBin,1), sensorData.spatialOutlineY + sensorPositionSequence(tBin,2), 'w-', 'LineWidth', 2.0);
            % the full illuminance map
            %imagesc(oiData.LuminanceMap); axis 'image';
        end
        
        % Update sensor position in optical image
        %set(sensorPositionOnOpticalImagePlot, 'XData', sensorData.spatialOutlineX + sensorPositionSequence(tBin,1), 'YData', sensorData.spatialOutlineY + sensorPositionSequence(tBin,2));
        
        
        % Convert the various LMS contrasts to RGB settings and luminances for the rendering display
        RGBsettingsAndLuminanceData = LMScontrastsToRGBsettingsAndLuminanceforRenderingDisplay(tBin, LMScontrastInput, LMScontrastReconstruction, oiLMScontrastInput, ...
                        sceneBackgroundExcitation,  opticalImageBackgroundExcitation, renderingDisplay, boostFactorForOpticalImage, displayGamma);
        
        % The luminance map of the input scene patch
        if (isempty(inputSceneLuminanceMapPlot))
            xTicks = []; yTicks = [];
            xlabelString = ''; ylabelString = 'input scene';
            titleString = 'luminance map'; colorbarStruct = [];
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            inputSceneLuminanceMapPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneLuminanceMap'), titleString, ...
                  RGBsettingsAndLuminanceData.inputLuminanceMap, luminanceRange,...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);  
        else
            set(inputSceneLuminanceMapPlot, 'CData', RGBsettingsAndLuminanceData.inputLuminanceMap);
        end
        
        % The RGB rendition of the input scene patch
        if (isempty(inputSceneRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = 'RGB rendition';
            colorbarStruct = [];
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            inputSceneRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputSceneRGBrendition'), titleString, ...
                  RGBsettingsAndLuminanceData.inputRGBforRenderingDisplay, [0 1],...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);  
        else
            set(inputSceneRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.inputRGBforRenderingDisplay);
        end
        
        % The luminance map of the input optical image patch
        if (isempty(inputOpticalImageLuminanceMapPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = 'optical image';
            titleString = ' ';
            colorbarStruct = [];
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            inputOpticalImageLuminanceMapPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageIlluminanceMap'), titleString, ...
                  RGBsettingsAndLuminanceData.inputOpticalImageLuminanceMap, luminanceRange,...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY,imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);  
        else
            set(inputOpticalImageLuminanceMapPlot, 'CData', RGBsettingsAndLuminanceData.inputOpticalImageLuminanceMap);
        end
        
        % The RGB rendition  of the input optical image patch
        if (isempty(inputOpticalImageRGBrenditionPlot))
            xTicks = [];
            yTicks = [];
            xlabelString = '';
            ylabelString = '';
            titleString = ' ';
            colorbarStruct = [];
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            inputOpticalImageRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('inputOpticalImageRGBrendition'), titleString, ...
                  RGBsettingsAndLuminanceData.inputOpticalImageRGBforRenderingDisplay, [0 1],...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);  
        else
            set(inputOpticalImageRGBrenditionPlot, 'CData', RGBsettingsAndLuminanceData.inputOpticalImageRGBforRenderingDisplay);
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
                'color', [0 1 0]...
                );
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            reconstructedSceneLuminanceMapPlot = initializeDecodedImagePlot(...
                    axesDictionary('reconstructedSceneLuminanceMap'), titleString, ...
                    RGBsettingsAndLuminanceData.reconstructedLuminanceMap , luminanceRange,...
                    [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                    sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, imageOutline, ...
                    xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);
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
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            reconstructedSceneRGBrenditionPlot = initializeDecodedImagePlot(...
                  axesDictionary('reconstructedSceneRGBrendition'), titleString, ...
                  RGBsettingsAndLuminanceData.reconstructedRGBforRenderingDisplay , [0 1],...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY, imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);
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
                'title', 'pAmps', ...
                'fontSize', 14, ...
                'fontName', 'Menlo', ...
                'color', [0 0 0]...
                );
            imageOutline = struct('x', sensorData.decodedImageOutlineX, 'y', sensorData.decodedImageOutlineY, 'color', [0 1 0]);
            instantaneousSensorXYactivationPlot = initializeDecodedImagePlot(...
                  axesDictionary('instantaneousSensorXYactivation'), titleString, ...
                  squeeze(responseSequence(:,:,tBin)), outerSegmentResponseRange,...
                  [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                  sensorData.spatialSupportX, sensorData.spatialSupportY, imageOutline, ...
                  xTicks, yTicks, xlabelString, ylabelString, colorbarStruct);
        else
            set(instantaneousSensorXYactivationPlot, 'CData', squeeze(responseSequence(:,:,tBin)));
            title(axesDictionary('instantaneousSensorXYactivation'),  sprintf('photocurrent map\n%s, t: %2.2f sec', expParams.outerSegmentParams.type, timeAxis(tBin)/1000));
        end
        
       
        
        % The photocurrent traces for the target Lcone
        traces = squeeze(responseSequence(sensorData.targetLCone.rowcolCoord(1), sensorData.targetLCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetLcontrastDecoderPlot))
            recentTime = timeAxis(recentTbins)-timeAxis(recentTbins(end));
            xRange = [recentTime(1) recentTime(end)];
            yRange = outerSegmentResponseRange;
            xTicks = xRange(1):100:xRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = '';
            yLabelString = '';
            titleString  = ''; % sprintf('Lcone @xyPos: (%2.1fum, %2.1fum)', sensorData.targetLCone.xyCoord(1), sensorData.targetLCone.xyCoord(2));
            addScaleBars = true;
            backgroundColor = [0 0 0];
            sensorXTtracesForTargetLcontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetLcontrastDecoder'), titleString, ...
                recentTime, traces, LconeContrastColor.^2.0, backgroundColor, addScaleBars, xRange, yRange, xTicks, yTicks, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetLcontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The photocurrent traces for the target Mcone
        traces = squeeze(responseSequence(sensorData.targetMCone.rowcolCoord(1), sensorData.targetMCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetMcontrastDecoderPlot))
            recentTime = timeAxis(recentTbins)-timeAxis(recentTbins(end));
            xRange = [recentTime(1) recentTime(end)];
            yRange = outerSegmentResponseRange;
            xTicks = xRange(1):100:xRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = '';
            yLabelString = '';
            titleString  = ''; % sprintf('Lcone @xyPos: (%2.1fum, %2.1fum)', sensorData.targetLCone.xyCoord(1), sensorData.targetLCone.xyCoord(2));
            addScaleBars = false;
            backgroundColor = [0 0 0];
            sensorXTtracesForTargetMcontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetMcontrastDecoder'), titleString, ...
                recentTime, traces, MconeContrastColor.^2.0, backgroundColor, addScaleBars, xRange, yRange, xTicks, yTicks, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetMcontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The photocurrent traces for the target Scone
        traces = squeeze(responseSequence(sensorData.targetSCone.rowcolCoord(1), sensorData.targetSCone.rowcolCoord(2), recentTbins));
        if (isempty(sensorXTtracesForTargetScontrastDecoderPlot))
            recentTime = timeAxis(recentTbins)-timeAxis(recentTbins(end));
            xRange = [recentTime(1) recentTime(end)];
            yRange = outerSegmentResponseRange;
            xTicks = xRange(1):100:xRange(end);
            yTicks = outerSegmentResponseRange(1):20:outerSegmentResponseRange(end);
            xLabelString = '';
            yLabelString = '';
            titleString  = ''; % sprintf('Lcone @xyPos: (%2.1fum, %2.1fum)', sensorData.targetLCone.xyCoord(1), sensorData.targetLCone.xyCoord(2));
            addScaleBars = false;
            backgroundColor = [0 0 0];
            sensorXTtracesForTargetScontrastDecoderPlot = initializeSensorTracesPlot(...
                axesDictionary('sensorXTtracesForTargetScontrastDecoder'), titleString, ...
                recentTime, traces, SconeContrastColor.^2.0, backgroundColor, addScaleBars, xRange, yRange, xTicks, yTicks, xLabelString, yLabelString);
        else
            set(sensorXTtracesForTargetScontrastDecoderPlot, 'YData', traces);
        end
        
        
        % The decoded Lcone contrast for the target L-cone decoder
        recentLconeContrastReconstruction = squeeze(LMScontrastReconstruction(sensorData.targetLCone.nearestDecodedPosition(1), sensorData.targetLCone.nearestDecodedPosition(2), 1, recentTbins));
        
        
        
        if (1==2)
 
        subplot(3,3,8);
        responseXYactivation = responseSequence(:,:,tBin);
        imagesc(sensorData.spatialSupportX, sensorData.spatialSupportY, responseXYactivation); axis 'image'
        hold on;
        % indentify tracked cones
        plot(sensorData.centralMostLCone.xyCoord(1), sensorData.centralMostLCone.xyCoord(2), 'rx');
        plot(sensorData.centralMostMCone.xyCoord(1), sensorData.centralMostMCone.xyCoord(2), 'gx');
        plot(sensorData.centralMostSCone.xyCoord(1), sensorData.centralMostSCone.xyCoord(2), 'bx');
        plot(sensorData.decodedImageOutlineX, sensorData.decodedImageOutlineY, 'g-', 'LineWidth', 2.0);
        hold off;
        
        set(gca, 'XLim', [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end)], ...
                 'YLim', [sensorData.spatialSupportY(1) sensorData.spatialSupportY(end)], ...
                 'CLim', outerSegmentResponseRange);
        % Add colorbar inside the density plot at the bottom
        hCbar = colorbar('south', 'peer', gca, 'Ticks', outerSegmentResponseTicks, 'TickLabels', sprintf('%2.0f\n',outerSegmentResponseTicks));
        hCBar.Orientation = 'horizontal'; hCbar.Label.String = ''; hCbar.FontSize = 12; hCbar.FontName = 'Menlo'; hCbar.Color = [0 1 0];
        title('outer segment mosaic activation')
        
        
        
        subplot(3,3,6);
        recentLconeContrastReconstruction = squeeze(LMScontrastReconstruction(sensorData.centralMostLCone.nearestDecodedPosition(1), sensorData.centralMostLCone.nearestDecodedPosition(2), 1, recentTbins));
        recentMconeContrastReconstruction = squeeze(LMScontrastReconstruction(sensorData.centralMostMCone.nearestDecodedPosition(1), sensorData.centralMostMCone.nearestDecodedPosition(2), 2, recentTbins));
        recentSconeContrastReconstruction = squeeze(LMScontrastReconstruction(sensorData.centralMostSCone.nearestDecodedPosition(1), sensorData.centralMostSCone.nearestDecodedPosition(2), 3, recentTbins));
        plot([recentTime(1) recentTime(end)], [0 0], 'k-'); hold on
        plot(recentTime, recentLconeContrastReconstruction, 'k-', 'Color', LconeContrastColor, 'LineWidth', 2.0);
        plot(recentTime, recentMconeContrastReconstruction, 'k-', 'Color', MconeContrastColor, 'LineWidth', 2.0);
        plot(recentTime, recentSconeContrastReconstruction, 'k-', 'Color', SconeContrastColor, 'LineWidth', 2.0);
        hold off
        box off; grid on
        set(gca, 'YLim', [-2 5], 'YTick', (-2:0:10));
        
        
%         LconeInputContrast = LMScontrastInput(:,:,1,tBin);
%         LconeReconstructedContrast = LMScontrastReconstruction(:,:,1,tBin);
%         plot(LconeInputContrast(:), LconeReconstructedContrast(:),  'k.');
%         set(gca, 'XLim', [-2 5], 'YLim', [-2 5]); axis 'square';
        
        end
        
        
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));
     end % tBin  
     
     videoOBJ.close();
end

function osTracePlot = initializeSensorTracesPlot(theAxes, titleString, recentTime, traces, theColor, backgroundColor, addScaleBars, theXDataRange, theYDataRange, xTicks, yTicks, xLabelString, yLabelString)

    osTracePlot = plot(theAxes, recentTime, traces, 'k-', 'Color', theColor, 'LineWidth', 4);
    hold(theAxes, 'on');
    % Plot the baseline
    plot(theAxes, recentTime, recentTime*0, 'k-', 'Color', 1-backgroundColor, 'LineWidth', 1.5);
    if (addScaleBars)
        dy = 15;
        dx = 70;
        plot(theAxes, [recentTime(1)+dx recentTime(1)+dx + 300], [theYDataRange(2)-dy theYDataRange(2)-dy], 'k-', 'Color', 1-backgroundColor, 'LineWidth', 2.0);
        plot(theAxes, [recentTime(1)+dx recentTime(1)+dx], [theYDataRange(2)-dy theYDataRange(2)-dy-50], 'k-', 'Color', 1-backgroundColor, 'LineWidth', 2.0);
        textXcoord = double(recentTime(1)+dx+20); textYcoord = double(theYDataRange(2)-dy+5);
        text(textXcoord, textYcoord, '300 msec', 'Parent', theAxes, 'Color', 1-backgroundColor, 'FontName', 'Menlo', 'FontSize', 16);
        textXcoord = double(recentTime(1)+dx-35); textYcoord = double(theYDataRange(2)-50);
        text(textXcoord, textYcoord, '50 pA', 'Parent', theAxes, 'Color', 1-backgroundColor, 'FontName', 'Menlo', 'FontSize', 16, 'Rotation', 90);
    end
    hold(theAxes, 'off');

    set(theAxes, 'XLim', theXDataRange, 'YLim', [theYDataRange(1) theYDataRange(2)], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'YTick', yTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'XColor', 'none', 'YColor', 'none', ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 2.0);
    box(theAxes, 'off'); grid(theAxes, 'off');
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold');   
end

function decodedImagePlot = initializeDecodedImagePlot(theAxes, titleString, theCData, theCDataRange, theXDataRange, theYDataRange, spatialSupportX, spatialSupportY, imageOutline, xTicks, yTicks, xLabelString, yLabelString, cbarStruct)
    decodedImagePlot = imagesc(spatialSupportX, spatialSupportY, theCData, 'parent', theAxes);
    axis(theAxes, 'image');
    dx = spatialSupportX(2)-spatialSupportX(1);
    dy = spatialSupportY(2)-spatialSupportY(1);
    set(theAxes, 'XLim', [theXDataRange(1)-dx/2 theXDataRange(2)+dx/2], ...
                 'YLim', [theYDataRange(1)-dy/2 theYDataRange(2)+dy/2], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
                 'YTick', yTicks, 'XTickLabel', sprintf('%2.1f\n', xTicks), ...
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
    
    if (~isempty(imageOutline))
        hold(theAxes, 'on');
        plot(theAxes, imageOutline.x, imageOutline.y, '-', 'Color', imageOutline.color, 'LineWidth', 2.0);
        hold(theAxes, 'off');
    end
            
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold');
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold');   
end

function [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows)

    hFig = figure(1); clf; 
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1], 'MenuBar', 'none');
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', slideRows, ...
               'colsNum', slideCols, ...
               'heightMargin',   0.01, ...
               'widthMargin',    0.01, ...
               'leftMargin',     0.015, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.025, ...
               'topMargin',      0.02);
           
    axesDictionary = containers.Map();
    
    % The left 2 columns with luminance maps and RGB renditions
    axesDictionary('inputSceneLuminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,1).v);
    axesDictionary('inputSceneRGBrendition') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,2).v);
    axesDictionary('inputOpticalImageIlluminanceMap') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,1).v);
    axesDictionary('inputOpticalImageRGBrendition')   = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,2).v);
    axesDictionary('reconstructedSceneLuminanceMap')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,1).v);
    axesDictionary('reconstructedSceneRGBrendition')  = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,2).v);
    
    % The middle: sensor activation
    axesDictionary('instantaneousSensorXYactivation') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,3).v);
    
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
    axesDictionary('inputAndReconstructedLcontrastTracesForTargetLcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,4).v);
    axesDictionary('inputAndReconstructedMcontrastTracesForTargetMcontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,5).v);
    axesDictionary('inputAndReconstructedScontrastTracesForTargetScontrastDecoder') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(3,6).v);
    
    % Fourth row: instaneous scatter of reconstructed vs. input L,M,S cone contrasts at all decoded locations
    axesDictionary('reconstructedVSinputLcontrastAcrossAllDecoderPositions') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,4).v);
    axesDictionary('reconstructedVSinputMcontrastAcrossAllDecoderPositions') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,5).v);
    axesDictionary('reconstructedVSinputScontrastAcrossAllDecoderPositions') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(4,6).v);
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


function [sceneData, oiData, sensorData] = retrieveComputedDataForCurrentScene(sceneSetName, resultsDir, sceneIndex, renderingDisplay, boostFactorForOpticalImage, displayGamma)
    scanFileName = core.getScanFileName(sceneSetName, resultsDir, sceneIndex);
    load(scanFileName, 'scanData', 'scene', 'oi');
    
    % Get the LMS excitations
    [sceneLMSexcitations, ~] = core.imageFromSceneOrOpticalImage(scene, 'LMS');
    
    % Transform them to RGB
    beVerbose = true; 
    boostFactor = 1;
    [sceneData.RGBforRenderingDisplay, sceneData.RGBpixelsBelowGamut, sceneData.RGBpixelsAboveGamut, sceneData.LuminanceMap] = ...
        core.LMStoRGBforSpecificDisplay(sceneLMSexcitations, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get the LMS excitations of the optical image
    [opticalImageLMSexcitations, ~] = core.imageFromSceneOrOpticalImage(oi, 'LMS');
    boostFactor = boostFactorForOpticalImage;
    [oiData.RGBforRenderingDisplay, oiData.RGBpixelsBelowGamut, oiData.RGBpixelsAboveGamut, oiData.LuminanceMap] = ...
        core.LMStoRGBforSpecificDisplay(opticalImageLMSexcitations, renderingDisplay, boostFactor, displayGamma, beVerbose);
    
    % Get spatial support data
    oiData.sceneRetinalProjectionSpatialSupportX = scanData{1}.sceneRetinalProjectionXData;
    oiData.sceneRetinalProjectionSpatialSupportY = scanData{1}.sceneRetinalProjectionYData;
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
    sensorData.targetLCone  = getTargetConeCoords(sensorData, conePositions, [-20 -10], find(coneTypes == 2));
    sensorData.targetMCone  = getTargetConeCoords(sensorData, conePositions, [20 10], find(coneTypes == 3));
    sensorData.targetSCone  = getTargetConeCoords(sensorData, conePositions, [0 0], find(coneTypes == 4));
    
    
    function s = getTargetConeCoords(sensorData, conePositions, targetConePosition, coneIndices)
        if isempty(coneIndices)
            s = [];
            return;
        end
        conePositionsDistanceToTarget = bsxfun(@minus, conePositions, targetConePosition);
        coneDistances = sqrt(sum(conePositionsDistanceToTarget.^2, 2));
        [~, theIndex] = min(coneDistances(coneIndices));
        [r,c] = ind2sub([numel(sensorData.spatialSupportY) numel(sensorData.spatialSupportX)], coneIndices(theIndex));
        [X,Y] = meshgrid(sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY);
        d = sqrt((X-conePositions(coneIndices(theIndex), 1)).^2 + (Y-conePositions(coneIndices(theIndex), 2)).^2);
        [~,idx] = min(d);
        [dr, rc] = ind2sub(size(X), idx);
        s = struct(...
            'rowcolCoord', [r c], ...
            'xyCoord', conePositions(coneIndices(theIndex), :), ...
            'nearestDecodedPosition', [dr rc]);
        s
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


function tmp
    % Retrieve resources needed to convert LMS RGB for a hypothetical super display that can display the natural scenes
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 2; % 8;
    [coneFundamentals, displaySPDs, RGBtoXYZ, wave] = core.LMSRGBconversionData(displayName, gain);
    
    whichOne = input('In-sample (1) out-of-sample(2) , or both (3) data : ');
    
    slideSize = [2560 1440]/2;
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1]);
    
    computeSVDbasedLowRankFiltersAndPredictions = true;
    
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
            svdIndices = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            svdIndex = svdIndices(1);
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
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
            svdIndex = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            CtestPrediction = squeeze(CtestPredictionSVDbased(svdIndex,:, :));
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
            svdIndices = core.promptUserForChoiceFromSelectionOfChoices('Select desired variance explained for the reconstruction filters', SVDbasedLowRankFilterVariancesExplained);
            svdIndex = svdIndices(1);
            CtestPrediction = squeeze(CtestPredictionSVDbased(svdIndex,:, :));
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
            CtrainPrediction = squeeze(CtrainPredictionSVDbased(svdIndex,:, :));
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
