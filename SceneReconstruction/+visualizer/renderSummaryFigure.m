function renderSummaryFigure(sceneSetName, resultsDir, decodingDataDir)


    
    % Get luminance colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    
    
    % Generate colors for L,M,S contrast traces
    LconeContrastColor = [255 170 190]/255;
    MconeContrastColor = [120 255 224]/255;
    SconeContrastColor = [170 180 255]/255;
    
    
    % Whether to use the SVD-based filters/predictions
    computeSVDbasedLowRankFiltersAndPredictions = true;  % SVD based
    % computeSVDbasedLowRankFiltersAndPredictions = false;  % PINV based
  
    % Get performance data
    [trainInputC, trainReconstructedC, testInputC, testReconstructedC, SVDvarianceExplained, svdIndex] = ...
        visualizer.retrievePerformanceData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions);
    
    
    % Get the decoder filters
    [decoder.filters, decoder.peakTimeBins, decoder.spatioTemporalSupport, decoder.coneTypes] = visualizer.retrieveDecoderData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, svdIndex);
    spatialSupportX = decoder.spatioTemporalSupport.sensorRetinalXaxis;
    spatialSupportY = decoder.spatioTemporalSupport.sensorRetinalYaxis;
    timeAxis        = decoder.spatioTemporalSupport.timeAxis;
    decoder.filters = decoder.filters / max(abs(decoder.filters(:)));
    
    % Get sensor data
    %targetLdecoderXYcoords = [7 10];
    %targetMdecoderXYcoords = [14 -6];
    %targetSdecoderXYcoords = [0 0];
    
    targetLdecoderXYcoords = [6-6];
    targetMdecoderXYcoords = [6 -6];
    targetSdecoderXYcoords = [6 -6];
    
    sensorData = visualizer.retrieveSensorData(sceneSetName, resultsDir, decoder, targetLdecoderXYcoords, targetMdecoderXYcoords, targetSdecoderXYcoords);
    decodedRegionOutline.x = sensorData.decodedImageOutlineX;
    decodedRegionOutline.y = sensorData.decodedImageOutlineY;
    decodedRegionOutline = [];
    targetCone = sensorData.targetLCone;
    
    % Locations (relative to the target cone) for which to display temporal filters
    conesStride = 2;
    visualizedYcoords = targetCone.rowcolCoord(1) + (-1:1) * conesStride;
    visualizedXcoords = targetCone.rowcolCoord(2) + (-2:3) * conesStride;
        
    
    
    slideSize = [1920 1080]; slideCols = 6; slideRows = 4;
    
    for decodedContrastIndex = 1:3
        
        figureNo = 10 + decodedContrastIndex;
        [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows, figureNo);
        colormap(grayRedLUT); 
        
        switch decodedContrastIndex
            case 1
                    %targetCone = sensorData.targetLCone;
                    titleString = 'L-contrast decoder';
                    inputContrast         = squeeze(testInputC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 1,:));
                    reconstructedContrast  = squeeze(testReconstructedC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 1,:));
                    dotColor = LconeContrastColor*0.8;
            case 2
                    %targetCone = sensorData.targetMCone;
                    titleString = 'M-contrast decoder';
                    inputContrast         = squeeze(testInputC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 2,:));
                    reconstructedContrast  = squeeze(testReconstructedC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 2,:));
                    dotColor = MconeContrastColor*0.8;
            case 3
                    %targetCone = sensorData.targetSCone;
                    titleString = 'S-contrast decoder';
                    inputContrast         = squeeze(testInputC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 3,:));
                    reconstructedContrast  = squeeze(testReconstructedC(targetCone.nearestDecoderRowColCoord(2),targetCone.nearestDecoderRowColCoord(1), 3,:));
                    dotColor = SconeContrastColor*0.8;
        end
        
        % Render the out-of-sample performance of the visualized decoder
        axesColor = [0 0 0]; backgroundColor = [1 1 1]; 
        renderPerformancePlot(axesDictionary('performancePlot'), inputContrast, reconstructedContrast, dotColor, axesColor, backgroundColor, titleString);
        
        
        decoderLocation.x = sensorData.decodedImageSpatialSupportX(targetCone.nearestDecoderRowColCoord(2));
        decoderLocation.y = sensorData.decodedImageSpatialSupportY(targetCone.nearestDecoderRowColCoord(1));
        decoderLocation = []; % do not show it
        
        
        lConeIndices = find(sensorData.coneTypes(:) == 2);
        mConeIndices = find(sensorData.coneTypes(:) == 3);
        sConeIndices = find(sensorData.coneTypes(:) == 4);
        contourLevels = [-0.95 -0.8 -0.6 -0.4 -0.2 0.2 0.4 0.6 0.8 0.95];
        
        spatialFilter = squeeze(decoder.filters(decodedContrastIndex, targetCone.nearestDecoderRowColCoord(1), targetCone.nearestDecoderRowColCoord(2),:,:, decoder.peakTimeBins(decodedContrastIndex)));       
        contourStruct = visualizer.computeContourData(spatialFilter, contourLevels, spatialSupportX, spatialSupportY, lConeIndices, mConeIndices, sConeIndices);

        for mosaicType = 1:3
            switch mosaicType
                case 1
                        theAxes = axesDictionary('AllMosaicsSpatialFilter');
                        yLabelString = '';
                        xTicks = [spatialSupportX(1) 0 spatialSupportX(end)];
                        yTicks = [spatialSupportY(1) 0 spatialSupportY(end)];
                        
                        xLabelString = '';
                        titleString = 'all mosaics pooling'; 
                case 2
                        theAxes = axesDictionary('PrincipalMosaicPooling');
                        if (decodedContrastIndex == 1) || (decodedContrastIndex == 2)
                            contourData = contourStruct.LconeMosaicSamplingContours;
                            titleString = 'L-mosaic pooling';
                        else
                            contourData = contourStruct.SconeMosaicSamplingContours;
                            titleString = 'S-mosaic pooling';
                        end
                        xTicks = [];
                        yTicks = []; % [spatialSupportY(1) 0 spatialSupportY(end)];
                        xLabelString = '';
                        yLabelString = '';
                case 3
                        theAxes = axesDictionary('SecondaryMosaicPooling');
                        if (decodedContrastIndex == 1) || (decodedContrastIndex == 2)
                            contourData = contourStruct.MconeMosaicSamplingContours;
                            titleString = 'M-mosaic pooling';
                        else
                            contourData = contourStruct.LMconeMosaicSamplingContours;
                            titleString = 'LM-mosaic pooling';
                        end
                        
                        xTicks = []; % [spatialSupportX(1) 0 spatialSupportX(end)];
                        yTicks = []; % [spatialSupportY(1) 0 spatialSupportY(end)];
                        xLabelString = '';
                        yLabelString = '';
                        
            end

            labelMosaicCenterUsingCrossHairs = true;
            if (mosaicType == 1)
                noContourData = [];
                renderSpatialFilter(theAxes, spatialFilter, noContourData, spatialSupportX, spatialSupportY, ...
                    visualizedXcoords, visualizedYcoords, ...
                    decodedRegionOutline, labelMosaicCenterUsingCrossHairs, decoderLocation, ...
                    xTicks, yTicks, xLabelString, yLabelString, titleString);
            else
                backgroundColor = [0.3 0.3 0.3];
                contourColor = [1 1 1];
                renderConeMosaicPlot(theAxes, contourData, contourColor, sensorData, spatialSupportX, spatialSupportY, ...
                    LconeContrastColor, MconeContrastColor, SconeContrastColor, labelMosaicCenterUsingCrossHairs, ...
                    xTicks, yTicks, axesColor, backgroundColor, xLabelString, yLabelString, titleString);  
            end
        end   % mosaicIndex 

        
        

        xLabelString = '';
        yLabelString = '';
        
        backgroundColor = [1 1 1];
        for yPosIndex = 1:numel(visualizedYcoords)
            coneRow = visualizedYcoords(yPosIndex);
            if (yPosIndex == numel(visualizedYcoords))
                xTicks = [-100 0 100 200 300];
            else
                xTicks = [];
            end
            for xPosIndex = 1:numel(visualizedXcoords)
                coneCol = visualizedXcoords(xPosIndex);
                if  (sensorData.coneTypes(coneRow, coneCol) == 2)
                    lineColor = LconeContrastColor;
                elseif (sensorData.coneTypes(coneRow, coneCol) == 3)
                    lineColor = MconeContrastColor;
                elseif (sensorData.coneTypes(coneRow, coneCol) == 4)
                    lineColor = SconeContrastColor;
                end
                if (xPosIndex == numel(visualizedXcoords)) && (yPosIndex == numel(visualizedYcoords))
                    addScaleBars = false;
                else
                    addScaleBars = false;
                end
                if (xPosIndex == 1) && (yPosIndex == numel(visualizedYcoords))
                    axesColor = [0 0 0];
                    yTicks = -1:0.5:1;
                    xLabelString = 'time (ms)';
                else
                    axesColor = [1 1 1];
                    yTicks = [];
                    xLabelString = '';
                end
                temporalFilter = squeeze(decoder.filters(decodedContrastIndex, targetCone.nearestDecoderRowColCoord(1), targetCone.nearestDecoderRowColCoord(2), coneRow, coneCol, :));  
                renderTemporalFilter(axesDictionary(sprintf('temporalFilter_%d%d', yPosIndex,xPosIndex)), temporalFilter, timeAxis, ...
                    xTicks, yTicks, xLabelString, yLabelString, axesColor, backgroundColor, lineColor, addScaleBars);
            end
        end % temporalFilterLocation
        
        
        drawnow;
    end % decodedContrast
end

function renderConeMosaicPlot(theAxes, contourData, contourColor, sensorData, spatialSupportX, spatialSupportY, LconeContrastColor, MconeContrastColor, SconeContrastColor, labelMosaicCenterUsingCrossHairs, xTicks, yTicks, axesColor, backgroundColor, xLabelString, yLabelString, titleString)
    
    lConeIndices = find(sensorData.coneTypes == 2);
    mConeIndices = find(sensorData.coneTypes == 3);
    sConeIndices = find(sensorData.coneTypes == 4);
    
    dX = spatialSupportX(2)-spatialSupportX(1);
    dY = spatialSupportY(2)-spatialSupportY(1);
    
    markerSize = 130;
    markerSymbol = 's';
    scatter(theAxes, squeeze(sensorData.conePositions(lConeIndices,1)), squeeze(sensorData.conePositions(lConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', LconeContrastColor*0.8,  'MarkerEdgeColor', 'none');
    hold(theAxes, 'on');
    scatter(theAxes, squeeze(sensorData.conePositions(mConeIndices,1)), squeeze(sensorData.conePositions(mConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', MconeContrastColor*0.8,  'MarkerEdgeColor', 'none');
    scatter(theAxes, squeeze(sensorData.conePositions(sConeIndices,1)), squeeze(sensorData.conePositions(sConeIndices,2)), markerSize, markerSymbol, 'MarkerFaceColor', SconeContrastColor*0.8,  'MarkerEdgeColor', 'none');
    
    if (labelMosaicCenterUsingCrossHairs)
        plot(theAxes, [spatialSupportX(1) spatialSupportX(end)], [0 0 ], 'k-', 'LineWidth', 1.5);
        plot(theAxes, [0 0], [spatialSupportY(1) spatialSupportY(end)], 'k-', 'LineWidth', 1.5);
    end
    
    % Superimpose the (select) contours
    contourLengthThreshold = 10;
    for contourNo = 1:numel(contourData)
       fprintf('Contour %d/%d: level:%2.2f, length: %d. Will be plotted.\n', contourNo, numel(contourData), contourData(contourNo).level, contourData(contourNo).length);
       if ((abs(contourData(contourNo).level) <= 0.3) && contourData(contourNo).length < contourLengthThreshold )
           fprintf(2, 'Contour %d/%d: level:%f, length: %d. Will not be plotted.\n', contourNo, numel(contourData), contourData(contourNo).level, contourData(contourNo).length);
           continue;
       end
       plot(theAxes, contourData(contourNo).x, contourData(contourNo).y, '-', 'Color', contourColor, 'LineWidth', 3.0);
    end
    
    hold(theAxes, 'off');
    
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, 'XLim', [spatialSupportX(1)-dX/2 spatialSupportX(end)+dX/2], ...
                 'YLim', [spatialSupportY(1)-dY/2 spatialSupportY(end)+dY/2], ...
                 'XTick', xTicks, 'XTickLabel', sprintf('%+2.1f\n', xTicks), ...
                 'YTick', yTicks, 'YTickLabel', sprintf('%+2.1f\n', xTicks), ...
                 'XColor', axesColor, 'YColor', axesColor, ...
                 'FontSize', 16, 'FontName', 'Menlo', ...
                 'Color', backgroundColor, 'LineWidth', 1.5);   
    box(theAxes, 'on');
    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);  
    
end


function renderTemporalFilter(theAxes, temporalFilter, timeAxis, xTicks, yTicks, xLabelString, yLabelString, axesColor, backgroundColor, lineColor, addScaleBars)
    
    plot(theAxes, timeAxis, timeAxis*0, 'k-', 'LineWidth', 1.5);
    hold(theAxes, 'on');
    plot(theAxes, [0 0], [-1 1], 'k-', 'LineWidth', 1.5);
    plot(theAxes, timeAxis, temporalFilter, 'k-', 'LineWidth', 5.0, 'Color', lineColor/2);
    plot(theAxes, timeAxis, temporalFilter, 'k-', 'LineWidth', 3.0, 'Color', lineColor);
    
    if (addScaleBars)
        yo = 0.9;
        dy = 0.1;
        dx = -150;
        plot(theAxes, [timeAxis(end)+dx timeAxis(end)+dx + 100], yo*[1 1], 'k-', 'Color', 1-backgroundColor, 'LineWidth', 2.0);
        textXcoord = double(timeAxis(end)+dx+0); textYcoord = yo-dy;
        text(textXcoord, textYcoord, '100 msec', 'Parent', theAxes, 'Color', 1-backgroundColor, 'FontName', 'Menlo', 'FontSize', 16);
    end
    
    hold(theAxes, 'off');
    box(theAxes, 'off'); grid(theAxes, 'off');
    set(theAxes, ...
        'XLim', [timeAxis(1) timeAxis(end)], ...
        'YLim', [-1 1], ...
        'XTick', xTicks, 'XTickLabel', sprintf('%+2.0f\n', xTicks), ...
        'YTick', yTicks, 'YTickLabel', sprintf('%+2.1f\n', yTicks), ...
        'XColor', axesColor, 'YColor', axesColor, ...
        'CLim', [-1 1], 'FontSize', 16, 'FontName', 'Menlo', ...
        'Color', backgroundColor, 'LineWidth', 1.5, ...
        'YaxisLocation','left');

    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  '',  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);  
end

function renderSpatialFilter(theAxes, spatialFilter, contourData, spatialSupportX, spatialSupportY, visualizedXcoords, visualizedYcoords, decodedRegionOutline, labelMosaicCenterUsingCrossHairs, decoderLocation, xTicks, yTicks, xLabelString, yLabelString, titleString)
    
    dX = spatialSupportX(2)-spatialSupportX(1);
    dY = spatialSupportY(2)-spatialSupportY(1);
    
    axesColor = [0 0 0];
    backgroundColor = [1 1 1];
    
    imagesc(spatialSupportX, spatialSupportY, spatialFilter, 'parent', theAxes);
    hold(theAxes, 'on');
    
    if (~isempty(contourData))
        % Superimpose the (select) contours
        contourLengthThreshold = 10;
        for contourNo = 1:numel(contourData)
           fprintf('Contour %d/%d: level:%2.2f, length: %d. Will be plotted.\n', contourNo, numel(contourData), contourData(contourNo).level, contourData(contourNo).length);
           if ((abs(contourData(contourNo).level) <= 0.3) && contourData(contourNo).length < contourLengthThreshold )
               fprintf(2, 'Contour %d/%d: level:%f, length: %d. Will not be plotted.\n', contourNo, numel(contourData), contourData(contourNo).level, contourData(contourNo).length);
               continue;
           end
           plot(theAxes, contourData(contourNo).x, contourData(contourNo).y, 'k-', 'LineWidth', 2.0);
        end
    end
    
    % Identify locations for which we display temporal filters
    if ((~isempty(visualizedXcoords)) && (~isempty(visualizedYcoords))) 
        [x, y] = meshgrid(visualizedXcoords, visualizedYcoords);
        plot(theAxes, spatialSupportX(x(:)), spatialSupportY(y(:)), 'kx', 'MarkerSize', 14, 'LineWidth', 1.0);
    end
    
    % Superimpose the decoded region outline
    if (~isempty(decodedRegionOutline))
        plot(theAxes, decodedRegionOutline.x, decodedRegionOutline.y, '-', 'Color', decodedRegionOutline.color, 'LineWidth', 2.0);
    end
    
    if (labelMosaicCenterUsingCrossHairs)
        plot(theAxes, [spatialSupportX(1) spatialSupportX(end)], [0 0 ], 'k-', 'LineWidth', 1.5);
        plot(theAxes, [0 0], [spatialSupportY(1) spatialSupportY(end)], 'k-', 'LineWidth', 1.5);
    end
        
    if (~isempty(decoderLocation))
        % Identify the target decoder locations
        plot(theAxes, decoderLocation.x, decoderLocation.y, ...
             's', 'LineWidth', 2.0, 'MarkerSize', 20, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0 0 1]);
    end
    
    hold(theAxes, 'off');
       
    axis(theAxes, 'image'); axis(theAxes, 'ij');
    set(theAxes, ...
        'XLim', [spatialSupportX(1)-dX/2 spatialSupportX(end)+dX/2], ...
        'YLim', [spatialSupportY(1)-dY/2 spatialSupportY(end)+dY/2], ...
        'XTick', xTicks, 'XTickLabel', sprintf('%+2.1f\n', xTicks), ...
        'YTick', yTicks, 'YTickLabel', sprintf('%+2.1f\n', yTicks), ...
        'XColor', axesColor, 'YColor', axesColor, ...
        'CLim', [-1 1], 'FontSize', 16, 'FontName', 'Menlo', ...
        'Color', backgroundColor, 'LineWidth', 1.5);

    xlabel(theAxes, xLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, yLabelString, 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);  
end

function renderPerformancePlot(theAxes, inputC, reconstructedC, dotColor, axesColor, backgroundColor, titleString)
    xLims = [-2 5];
    yLims = [-2 5];
    xTicks = -1:1:5;
    yTicks = -1:1:5;
    plot(theAxes, [xLims(1) yLims(2)], [yLims(1) yLims(2)], 'k-', 'LineWidth', 1.5);
    hold(theAxes, 'on');
    plot(theAxes, [0 0], yLims, 'k-', 'LineWidth', 1.5);
    plot(theAxes, xLims, [0 0], 'k-', 'LineWidth', 1.5);
    plot(theAxes, inputC, reconstructedC, '.', 'MarkerEdgeColor', dotColor, 'MarkerSize', 16, 'MarkerFaceColor', dotColor);
    hold(theAxes, 'off');
    
    box(theAxes, 'off'); grid(theAxes, 'off');
    
    axis(theAxes, 'square')
    set(theAxes, ...
        'XLim', xLims, ...
        'YLim', yLims, ...
        'XTick', xTicks, 'XTickLabel', sprintf('%+2.0f\n', xTicks), ...
        'YTick', yTicks, 'YTickLabel', sprintf('%+2.0f\n', yTicks), ...
        'XColor', axesColor, 'YColor', axesColor, ...
         'FontSize', 16, 'FontName', 'Menlo', ...
        'Color', backgroundColor, 'LineWidth', 1.5);
    xlabel(theAxes, 'scene contrast', 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    ylabel(theAxes, 'reconstr. contrast', 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]);
    title(theAxes,  titleString,  'FontSize', 18, 'FontWeight', 'bold', 'Color', [0 0 0]); 
end



function [axesDictionary, hFig] = generateAxes(slideSize, slideCols, slideRows, figNo)

    hFig = figure(figNo); clf; 
    set(hFig, 'Position', [10 10 slideSize(1) slideSize(2)], 'Color', [1 1 1], 'MenuBar', 'none');
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', slideRows, ...
               'colsNum', slideCols, ...
               'heightMargin',   0.015, ...
               'widthMargin',    0.010, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.09, ...
               'topMargin',      0.015);
           
    axesDictionary = containers.Map();
    

    % first column
    axesDictionary('performancePlot')      = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,1).v+[0.06 0 0 0]);
    dy = 0.0;
    axesDictionary('AllMosaicsSpatialFilter') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,3).v+[-0.01 dy 0 0]);
    axesDictionary('PrincipalMosaicPooling') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,4).v+[0 dy 0 0]);
    axesDictionary('SecondaryMosaicPooling') = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,5).v+[0.01 dy 0 0]);
    
    dy = -0.04;
    dx = 0.00;
    % second colum
    for xPosIndex = 1:6
        for yPosIndex = 1:3
            axesDictionary(sprintf('temporalFilter_%d%d',yPosIndex,xPosIndex)) = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(yPosIndex+1,xPosIndex).v+[dx dy 0 0]);
        end
    end
    
end




