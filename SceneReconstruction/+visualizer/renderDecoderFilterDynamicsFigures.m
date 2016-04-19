function renderDecoderFilterDynamicsFigures(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions)
 
    fprintf('\nLoading decoder filter ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector',  'spatioTemporalSupport', 'coneTypes', 'expParams');
    fprintf('Done.\n');
    
    componentString = 'PINVbased';
    generateAllFigures(decodingDataDir, componentString, wVector, spatioTemporalSupport, coneTypes, expParams)

    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'wVectorSVDbased', 'SVDbasedLowRankFilterVariancesExplained');%, 'Utrain', 'Strain', 'Vtrain');
        for kIndex = 1:numel(SVDbasedLowRankFilterVariancesExplained)
            wVectorSVD = squeeze(wVectorSVDbased(kIndex,:,:));
            componentString = sprintf('SVD_%2.3f%%VarianceExplained', SVDbasedLowRankFilterVariancesExplained(kIndex));
            generateAllFigures(decodingDataDir, componentString, wVectorSVD, spatioTemporalSupport, coneTypes, expParams)
        end
    end
end

function generateAllFigures(decodingDataDir, componentString, wVector, spatioTemporalSupport, coneTypes, expParams)
    
    dcTerm = 1;
    % Normalize wVector for plotting in [-1 1]
    wVector = wVector / max(max(abs(wVector(dcTerm+1:size(wVector,1),:))));
    weightsRange = 0.5*[-1 1];
    
    % Allocate memory for unpacked stimDecoder
    sensorRows      = numel(spatioTemporalSupport.sensorRetinalYaxis);
    sensorCols      = numel(spatioTemporalSupport.sensorRetinalXaxis);
    xSpatialBinsNum = numel(spatioTemporalSupport.sensorFOVxaxis);                   % spatial support of decoded scene
    ySpatialBinsNum = numel(spatioTemporalSupport.sensorFOVyaxis);
    timeAxis        = spatioTemporalSupport.timeAxis;
    timeBinsNum     = numel(timeAxis);
    stimDecoder = zeros(3, ySpatialBinsNum, xSpatialBinsNum, sensorRows, sensorCols, timeBinsNum);
    
    % Unpack the wVector into the stimDecoder
    dcTerm = 1;
    for stimConeContrastIndex = 1:3
        for ySpatialBin = 1:ySpatialBinsNum
        for xSpatialBin = 1:xSpatialBinsNum
            stimulusDimension = sub2ind([ySpatialBinsNum xSpatialBinsNum 3], ySpatialBin, xSpatialBin, stimConeContrastIndex);
            for coneRow = 1:sensorRows
            for coneCol = 1:sensorCols
                coneIndex = sub2ind([sensorRows sensorCols], coneRow, coneCol);
                neuralResponseFeatureIndices = (coneIndex-1)*timeBinsNum + (1:timeBinsNum);
                stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, coneRow, coneCol, :) = ...
                    squeeze(wVector(dcTerm + neuralResponseFeatureIndices, stimulusDimension));       
            end % coneRow
            end % coneCol
        end % xSpatialBin
        end % ySpatialBin
    end % coneContrastIndex
    
    % Generate spatial pooling filters figure (at select stimulus locations)
    generateSpatialPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, expParams, decodingDataDir, componentString);
    
    % Generate temporal pooling filters figure (at one stimulus location and at a local mosaic neighborhood)
    stimulusLocation.x = round(xSpatialBinsNum/2);
    stimulusLocation.y = round(ySpatialBinsNum/2);
    coneNeighborhood.center.x = stimulusLocation.x-2;
    coneNeighborhood.center.y = stimulusLocation.y+2;
    coneNeighborhood.extent.x = -3:3;
    coneNeighborhood.extent.y = -2:2;
    generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, decodingDataDir, componentString);
    
    generateSubMosaicSamplingFigures(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation,expParams, decodingDataDir, componentString);
    
end

function generateSubMosaicSamplingFigures(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, expParams, decodingDataDir, componentString)
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    
    dX = spatioTemporalSupport.sensorRetinalXaxis(2)-spatioTemporalSupport.sensorRetinalXaxis(1);
    dY = spatioTemporalSupport.sensorRetinalYaxis(2)-spatioTemporalSupport.sensorRetinalYaxis(1);
    x = spatioTemporalSupport.sensorRetinalXaxis(1)-dX:1:spatioTemporalSupport.sensorRetinalXaxis(end)+dX;
    y = spatioTemporalSupport.sensorRetinalYaxis(1)-dY:1:spatioTemporalSupport.sensorRetinalYaxis(end)+dY;
    [xx, yy] = meshgrid(x,y); 
            
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 3, ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.005, ...
               'rightMargin',    0.005, ...
               'bottomMargin',   0.01, ...
               'topMargin',      0.04);
           
    prefix = sprintf('SubMosaicSampling%s', componentString);
    imageFileName = composeImageFilename(expParams, decodingDataDir, prefix, ''); 
    hFig = figure(10); 
    clf; set(hFig, 'position', [700 10 1024 750], 'Color', [1 1 1], 'Name', imageFileName);
    colormap(grayRedLUT);        
    
    % Outline of the decoded position
    decodedPosOutline.x = spatioTemporalSupport.sensorFOVxaxis(stimulusLocation.x) + ([-0.5 -0.5 0.5 0.5 -0.5])*(spatioTemporalSupport.sensorFOVxaxis(2)-spatioTemporalSupport.sensorFOVxaxis(1));
    decodedPosOutline.y = spatioTemporalSupport.sensorFOVyaxis(stimulusLocation.y) + ([-0.5 0.5 0.5 -0.5 -0.5])*(spatioTemporalSupport.sensorFOVyaxis(2)-spatioTemporalSupport.sensorFOVyaxis(1));
    
    coneString = {'Lcone contrast', 'Mcone contrast', 'Scone contrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        
        % determine coords of peak response
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusLocation.y, stimulusLocation.x, :,:,:));
        indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 30);
        tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
        [~, idx] = max(abs(tmp(:)));
        [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
        peakTimeBin = indicesForPeakResponseEstimation(idx);
        
        allConesSpatialPooling = squeeze(spatioTemporalFilter(:,:,peakTimeBin));
        % Plot the spatial pooling filter (across all cone types) at the top
        subplot('position',subplotPosVectors(1, stimConeContrastIndex).v);
        imagesc(spatioTemporalSupport.sensorRetinalXaxis, spatioTemporalSupport.sensorRetinalYaxis, allConesSpatialPooling);
        hold on;
        plot(decodedPosOutline.x, decodedPosOutline.y, 'g-', 'LineWidth', 2.0);
        hold off;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), 'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
        title(sprintf('%s decoder at (%2.1f,%2.1f)um \nspatial pooling across all cones', coneString{stimConeContrastIndex}, spatioTemporalSupport.sensorFOVxaxis(stimulusLocation.x), spatioTemporalSupport.sensorFOVyaxis(stimulusLocation.y)), 'FontSize', 14);
        
        lConeWeights = [];
        mConeWeights = [];
        sConeWeights = [];
        lConeCoords = [];
        mConeCoords = [];
        sConeCoords = [];
        
        for iRow = 1:size(spatioTemporalFilter,1)
            for iCol = 1:size(spatioTemporalFilter,2) 
                coneLocation = [spatioTemporalSupport.sensorRetinalXaxis(iCol) spatioTemporalSupport.sensorRetinalYaxis(iRow)];
                xyWeight = [coneLocation(1) coneLocation(2) allConesSpatialPooling(iRow, iCol)];
                coneIndex = sub2ind([size(spatioTemporalFilter,1) size(spatioTemporalFilter,2)], iRow, iCol);
                
                if ismember(coneIndex, lConeIndices)
                    lConeCoords(size(lConeCoords,1)+1,:) = coneLocation';
                    lConeWeights(size(lConeWeights,1)+1,:) = xyWeight;
                elseif ismember(coneIndex, mConeIndices)
                    mConeCoords(size(mConeCoords,1)+1,:) = coneLocation';
                    mConeWeights(size(mConeWeights,1)+1,:) = xyWeight;
                elseif ismember(coneIndex, sConeIndices)
                    sConeCoords(size(sConeCoords,1)+1,:) = coneLocation';
                    sConeWeights(size(sConeWeights,1)+1,:) = xyWeight;
                end       
            end
        end
        

        lConeSpatialWeightingKernel = griddata(lConeWeights(:,1), lConeWeights(:,2), lConeWeights(:,3), xx, yy, 'cubic');
        mConeSpatialWeightingKernel = griddata(mConeWeights(:,1), mConeWeights(:,2), mConeWeights(:,3), xx, yy, 'cubic');
        sConeSpatialWeightingKernel = griddata(sConeWeights(:,1), sConeWeights(:,2), sConeWeights(:,3), xx, yy, 'cubic');
        lmConeWeights = [lConeWeights; mConeWeights];
        lmConeSpatialWeightingKernel = griddata(lmConeWeights(:,1), lmConeWeights(:,2), lmConeWeights(:,3), xx, yy, 'cubic');
            
        if (stimConeContrastIndex == 1)
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            generateContourPlot(lConeSpatialWeightingKernel, weightsRange, lConeCoords, [1 0.5 0.7], [],[]); 
            title(sprintf('spatial pooling across L-cone submosaic'), 'FontSize', 14);
            
            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(mConeSpatialWeightingKernel, weightsRange, mConeCoords, [0.5 0.9 0.7], [],[]);
            title(sprintf('spatial pooling across M-cone  submosaic'), 'FontSize', 14);
            
        elseif (stimConeContrastIndex == 2)
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            generateContourPlot(mConeSpatialWeightingKernel, weightsRange, mConeCoords, [0.5 0.9 0.7], [], []);
            title(sprintf('spatial pooling across M-cone  submosaic'), 'FontSize', 14);
            
            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(lConeSpatialWeightingKernel, weightsRange, lConeCoords, [1 0.5 0.7], [],[]);
            title(sprintf('spatial pooling across L-cone  submosaic'), 'FontSize', 14);
            
        elseif (stimConeContrastIndex == 3)
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            generateContourPlot(sConeSpatialWeightingKernel, weightsRange, sConeCoords, [0.7 0.5 1], [],[]);
            title(sprintf('spatial pooling across S-cone  submosaic'), 'FontSize', 14);
            
            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(lmConeSpatialWeightingKernel, weightsRange, lConeCoords, [1 0.5 0.7], mConeCoords, [0.5 0.9 0.7]);
            title(sprintf('spatial pooling across L/M-cone  submosaics'), 'FontSize', 14);
        end    
    end % stimConeContrastIndex
    drawnow;
    NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
     
    % Helper drawing function
    function generateContourPlot(spatialWeightingKernel, weightsRange, coneCoordsSubmosaic1, RGBColor1, coneCoordsSubmosaic2,  RGBColor2)
        
        contourLineColor = [0.4 0.4 0.4];
        cStep = max(weightsRange)/12;
        % negative contours
        hold on
        [C,H] = contourf(xx,yy, spatialWeightingKernel, (weightsRange(1):cStep:-cStep));
        H.LineWidth = 1;
        H.LineStyle = '--';
        H.LineColor = contourLineColor;
        
        % positive contours
        [C,H] = contourf(xx,yy, spatialWeightingKernel, (cStep:cStep:weightsRange(2)));
        H.LineWidth = 1;
        H.LineStyle = '-';
        H.LineColor = contourLineColor;
        
        
        % Plot the cones
        markerSize = 60;
        scatter(squeeze(coneCoordsSubmosaic1(:,1)), squeeze(coneCoordsSubmosaic1(:,2)), markerSize,  RGBColor1, 'filled');
          
        if (~isempty(coneCoordsSubmosaic2))
            scatter(squeeze(coneCoordsSubmosaic2(:,1)), squeeze(coneCoordsSubmosaic2(:,2)), markerSize,  RGBColor2, 'filled');
        end
        
        hold off;
        box on;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), 'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
        set(gca, 'CLim', weightsRange);
    end

end


function generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, decodingDataDir, componentString)
    
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    
    dX = spatioTemporalSupport.sensorRetinalXaxis(2)-spatioTemporalSupport.sensorRetinalXaxis(1);
    dY = spatioTemporalSupport.sensorRetinalYaxis(2)-spatioTemporalSupport.sensorRetinalYaxis(1);
    nearbyConeColumns = coneNeighborhood.center.x + coneNeighborhood.extent.x;
    nearbyConeRows    = coneNeighborhood.center.y + coneNeighborhood.extent.y;
    nearbyConeColumns = nearbyConeColumns(nearbyConeColumns >= 1);
    nearbyConeRows    = nearbyConeColumns(nearbyConeRows >= 1);
    nearbyConeColumns = nearbyConeColumns(nearbyConeColumns <= size(stimDecoder, 5));
    nearbyConeRows    = nearbyConeRows(nearbyConeRows <= size(stimDecoder, 4));
    
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    % Outline of sensor region over which we will display the temporal pooling functions
    outlineX = [ spatioTemporalSupport.sensorRetinalXaxis(min(nearbyConeColumns))-dX/2 ...
                 spatioTemporalSupport.sensorRetinalXaxis(max(nearbyConeColumns))+dX/2 ...
                 spatioTemporalSupport.sensorRetinalXaxis(max(nearbyConeColumns))+dX/2 ...
                 spatioTemporalSupport.sensorRetinalXaxis(min(nearbyConeColumns))-dX/2 ...
                 spatioTemporalSupport.sensorRetinalXaxis(min(nearbyConeColumns))-dX/2];
    outlineY = [ spatioTemporalSupport.sensorRetinalYaxis(min(nearbyConeRows))-dY/2 ...
                 spatioTemporalSupport.sensorRetinalYaxis(min(nearbyConeRows))-dY/2 ...
                 spatioTemporalSupport.sensorRetinalYaxis(max(nearbyConeRows))+dY/2 ...
                 spatioTemporalSupport.sensorRetinalYaxis(max(nearbyConeRows))+dY/2 ...
                 spatioTemporalSupport.sensorRetinalYaxis(min(nearbyConeRows))-dY/2];
   
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(nearbyConeRows)+1, ...
               'colsNum', numel(nearbyConeColumns), ...
               'heightMargin',   0.005, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.015, ...
               'topMargin',      0.00);
    
    coneString = {'Lcone contrast', 'Mcone contrast', 'Scone contrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        prefix = sprintf('TemporalPooling%s',componentString);
        imageFileName = composeImageFilename(expParams, decodingDataDir, prefix, coneString{stimConeContrastIndex}); 
        hFig = figure(1000+(stimConeContrastIndex-1)*10); 
        clf; set(hFig, 'position', [700 10 1024 800], 'Color', [1 1 1], 'Name', imageFileName);
        colormap(grayRedLUT); 
        
        % determine coords of peak response
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusLocation.y, stimulusLocation.x, :,:,:));
        indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 30);
        tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
        [~, idx] = max(abs(tmp(:)));
        [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
        peakTimeBin = indicesForPeakResponseEstimation(idx);
        
        % Plot the spatial pooling filter at the top
        subplot('position',subplotPosVectors(1, 1+round((numel(nearbyConeColumns)-1)/2)).v);
        imagesc(spatioTemporalSupport.sensorRetinalXaxis, spatioTemporalSupport.sensorRetinalYaxis, squeeze(spatioTemporalFilter(:,:,peakTimeBin)));
        hold on;
        plot(outlineX, outlineY, 'k-', 'LineWidth', 2.0);
        hold off;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), ... %'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
        title(sprintf('%s decoder at (%2.1f,%2.1f)um', coneString{stimConeContrastIndex}, spatioTemporalSupport.sensorFOVxaxis(stimulusLocation.x), spatioTemporalSupport.sensorFOVyaxis(stimulusLocation.y)), 'FontSize', 14);
        
             
        % Now plot the temporal pooling functions
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusLocation.y, stimulusLocation.x, nearbyConeRows, nearbyConeColumns,:));
        for iRow = 1:numel(nearbyConeRows)
          for iCol = 1:numel(nearbyConeColumns)
                
                coneColPos = nearbyConeColumns(iCol);
                coneRowPos = nearbyConeRows(iRow);
                coneIndex = sub2ind([size(stimDecoder,4) size(stimDecoder,5)], coneRowPos, coneColPos);
                if ismember(coneIndex, lConeIndices)
                    RGBcolor = [1 0.2 0.5];
                elseif ismember(coneIndex, mConeIndices)
                    RGBcolor = [0.2 0.8 0.2];
                elseif ismember(coneIndex, sConeIndices)
                    RGBcolor = [0.5 0.2 1];
                end
                
                subplot('position',subplotPosVectors(numel(nearbyConeRows)+2-iRow,iCol).v);
                plot(spatioTemporalSupport.timeAxis, squeeze(spatioTemporalFilter(iRow, iCol,:)), '-', 'Color', RGBcolor, 'LineWidth', 2.0);
                hold on;
                plot([0 0],  [-1 1], 'k-', 'LineWidth', 1.0);
                plot([spatioTemporalSupport.timeAxis(1) spatioTemporalSupport.timeAxis(end)],  [0 0], 'k-');
                hold off;
                box off;
                axis 'off'
                set(gca, 'XLim', [spatioTemporalSupport.timeAxis(1) spatioTemporalSupport.timeAxis(end)], 'YLim', weightsRange);
          end
        end
        NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
    end % stimConeContrastIndex
end


function generateSpatialPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, expParams, decodingDataDir, componentString)
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    whos('-file', fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'));
    
    dX = spatioTemporalSupport.sensorRetinalXaxis(2)-spatioTemporalSupport.sensorRetinalXaxis(1);
    dY = spatioTemporalSupport.sensorRetinalYaxis(2)-spatioTemporalSupport.sensorRetinalYaxis(1);
    xSpatialBinsNum = numel(spatioTemporalSupport.sensorFOVxaxis);                   % spatial support of decoded scene
    ySpatialBinsNum = numel(spatioTemporalSupport.sensorFOVyaxis);
 
    if (ySpatialBinsNum > 12)
        [~, idx] = min(abs(spatioTemporalSupport.sensorFOVyaxis));
        rowsToPlot = idx + (-300:6:300);
        rowsToPlot = rowsToPlot((rowsToPlot>=1) & (rowsToPlot<= numel(spatioTemporalSupport.sensorFOVyaxis)));
        fprintf('Stimulus y-positions are more than 12 will only show every 6th row\n');
    end
    
    if (xSpatialBinsNum > 12)
        [~, idx] = min(abs(spatioTemporalSupport.sensorFOVxaxis));
        colsToPlot = idx + (-300:6:300);
        colsToPlot = colsToPlot((colsToPlot>=1) & (colsToPlot<= numel(spatioTemporalSupport.sensorFOVxaxis)));
        fprintf('Stimulus y-positions are more than 12 will only show every 6th col\n');
    end
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(colsToPlot), ...
               'heightMargin',   0.005, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.015, ...
               'topMargin',      0.00);
           
    coneString = {'L cone contrast', 'Mcone contrast', 'Scone contrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        prefix = sprintf('SpatialPooling%s',componentString);
        imageFileName = composeImageFilename(expParams, decodingDataDir, prefix, coneString{stimConeContrastIndex}); 
        hFig = figure(100+(stimConeContrastIndex-1)*10); 
        clf; set(hFig, 'position', [700 10 1550 720], 'Color', [1 1 1], 'Name', imageFileName);
        colormap(grayRedLUT); 
        
        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            ySpatialBin = rowsToPlot(iRow);
            xSpatialBin = colsToPlot(iCol);
            spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, :,:,:));
            
            % determine coords of peak response
            indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 30);
            tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
            [~, idx] = max(abs(tmp(:)));
            [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
            peakTimeBin = indicesForPeakResponseEstimation(idx);
            fprintf('filter at (%d,%d) peaks at %2.0f msec\n', xSpatialBin, ySpatialBin, spatioTemporalSupport.timeAxis(peakTimeBin));

            subplot('position',subplotPosVectors(numel(rowsToPlot)-iRow+1,iCol).v);

            imagesc(spatioTemporalSupport.sensorRetinalXaxis, spatioTemporalSupport.sensorRetinalYaxis, squeeze(spatioTemporalFilter(:,:, peakTimeBin)));
            set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), ...
                     'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                     'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
            axis 'image'; axis 'xy'; 
            if (iRow > 1 || iCol > 1)
                set(gca, 'XTickLabel', {}, 'YTickLabel', {});
            end
            title(sprintf('%s decoder at (%2.1f,%2.1f)um', coneString{stimConeContrastIndex}, spatioTemporalSupport.sensorFOVxaxis(xSpatialBin), spatioTemporalSupport.sensorFOVyaxis(ySpatialBin)), 'FontSize', 14);
        end
        end
        % Export figure
        NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
    end
end


function imageFileName = composeImageFilename(expParams, decodingDataDir, prefix, postfix)
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end 
    imageFileName = fullfile(decodingDataDir, sprintf('%s%s%sOverlap%2.1fMeanLum%d%s', prefix, expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance, postfix));    
end
