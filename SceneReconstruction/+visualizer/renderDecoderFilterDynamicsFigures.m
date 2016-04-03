function renderDecoderFilterDynamicsFigures(sceneSetName, descriptionString)
 
    fprintf('\nLoading decoder filter ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', 'expParams');
    fprintf('Done.\n');

    
    % Normalize wVector for plotting in [-1 1]
    wVector = wVector / max(abs(wVector(:)));
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
    % generateSpatialPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, expParams, descriptionString);
    
    % Generate temporal pooling filters figure (at one stimulus location and at a local mosaic neighborhood)
    stimulusLocation.x = round(xSpatialBinsNum/4);
    stimulusLocation.y = round(ySpatialBinsNum/3);
    coneNeighborhood.center.x = round(sensorCols/2)-2;
    coneNeighborhood.center.y = round(sensorRows/2)+2;
    coneNeighborhood.extent.x = -3:3;
    coneNeighborhood.extent.y = -2:2;
    generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, descriptionString);
    
    generateSubMosaicSamplingFigures(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation,expParams, descriptionString);
    
end

function generateSubMosaicSamplingFigures(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, expParams, descriptionString)
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    whos('-file', fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'));
    
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
               'heightMargin',   0.005, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.015, ...
               'topMargin',      0.00);
           
    prefix = 'SubMosaicSampling';
    imageFileName = composeImageFilename(expParams, descriptionString, prefix, ''); 
    hFig = figure(10); 
    clf; set(hFig, 'position', [700 10 1024 800], 'Color', [1 1 1], 'Name', imageFileName);
    colormap(grayRedLUT);        
    
    
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        
        % determine coords of peak response
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusLocation.y, stimulusLocation.x, :,:,:));
        indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 100);
        tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
        [~, idx] = max(abs(tmp(:)));
        [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
        peakTimeBin = indicesForPeakResponseEstimation(idx);
        
        allConesSpatialPooling = squeeze(spatioTemporalFilter(:,:,peakTimeBin));
        % Plot the spatial pooling filter (across all cone types) at the top
        subplot('position',subplotPosVectors(1, stimConeContrastIndex).v);
        imagesc(spatioTemporalSupport.sensorRetinalXaxis, spatioTemporalSupport.sensorRetinalYaxis, allConesSpatialPooling);
%         hold on;
%         plot(outlineX, outlineY, 'k-', 'LineWidth', 2.0);
%         hold off;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), 'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
      
        lConeWeights = [];
        mConeWeights = [];
        sConeWeights = [];
    
        for iRow = 1:size(spatioTemporalFilter,1)
          for iCol = 1:size(spatioTemporalFilter,2) 
                xyWeight = [spatioTemporalSupport.sensorRetinalXaxis(iCol) spatioTemporalSupport.sensorRetinalYaxis(iRow) allConesSpatialPooling(iRow, iCol)];
                coneIndex = sub2ind([size(spatioTemporalFilter,1) :size(spatioTemporalFilter,2)], iRow, iCol);
                if ismember(coneIndex, lConeIndices)
                    RGBcolor = [1 0.2 0.5];
                    lConeWeights(size(lConeWeights,1)+1,:) = xyWeight;
                elseif ismember(coneIndex, mConeIndices)
                    RGBcolor = [0.2 0.8 0.2];
                    mConeWeights(size(mConeWeights,1)+1,:) = xyWeight;
                elseif ismember(coneIndex, sConeIndices)
                    RGBcolor = [0.5 0.2 1];
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
            generateContourPlot(lConeSpatialWeightingKernel, weightsRange);
          
            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(mConeSpatialWeightingKernel, weightsRange);
            
        elseif (stimConeContrastIndex == 2)
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            generateContourPlot(mConeSpatialWeightingKernel, weightsRange);

            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(lConeSpatialWeightingKernel, weightsRange);

        elseif (stimConeContrastIndex == 3)
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            generateContourPlot(sConeSpatialWeightingKernel, weightsRange);

            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            generateContourPlot(lmConeSpatialWeightingKernel, weightsRange);
        end    
    end % stimConeContrastIndex
    drawnow;
    
    NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
     
    
    function generateContourPlot(spatialWeightingKernel, weightsRange)
        contourLineColor = [0.4 0.4 0.4];
        cStep = max(weightsRange)/12;
        % negative contours
        [C,H] = contourf(xx,yy, spatialWeightingKernel, (weightsRange(1):cStep:-cStep));
        H.LineWidth = 1;
        H.LineStyle = '--';
        H.LineColor = contourLineColor;
        % positive contours
        [C,H] = contourf(xx,yy, spatialWeightingKernel, (cStep:cStep:weightsRange(2)));
        H.LineWidth = 1;
        H.LineStyle = '-';
        H.LineColor = contourLineColor;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), 'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1)-dX/2 spatioTemporalSupport.sensorRetinalXaxis(end)+dX/2], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1)-dY/2 spatioTemporalSupport.sensorRetinalYaxis(end)+dY/2], 'CLim', weightsRange);
        set(gca, 'CLim', weightsRange);
    end

end


function generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, descriptionString)
    
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    whos('-file', fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'));
    
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
    
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        prefix = 'TemporalPooling';
        imageFileName = composeImageFilename(expParams, descriptionString, prefix, coneString{stimConeContrastIndex}); 
        hFig = figure(1000+(stimConeContrastIndex-1)*10); 
        clf; set(hFig, 'position', [700 10 1024 800], 'Color', [1 1 1], 'Name', imageFileName);
        colormap(grayRedLUT); 
        
        % determine coords of peak response
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusLocation.y, stimulusLocation.x, :,:,:));
        indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 100);
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


function generateSpatialPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, expParams, descriptionString)
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    whos('-file', fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'));
    
    dX = spatioTemporalSupport.sensorRetinalXaxis(2)-spatioTemporalSupport.sensorRetinalXaxis(1);
    dY = spatioTemporalSupport.sensorRetinalYaxis(2)-spatioTemporalSupport.sensorRetinalYaxis(1);
    xSpatialBinsNum = numel(spatioTemporalSupport.sensorFOVxaxis);                   % spatial support of decoded scene
    ySpatialBinsNum = numel(spatioTemporalSupport.sensorFOVyaxis);
 
    if (ySpatialBinsNum > 12)
        rowsToPlot = 3:6:ySpatialBinsNum;
        fprintf('Stimulus y-positions are more than 12 will only show every 6th row\n');
    end
    
    if (xSpatialBinsNum > 12)
        colsToPlot = 3:6:xSpatialBinsNum;
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
           
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    for stimConeContrastIndex = 1:numel(coneString)
        prefix = 'SpatialPooling';
        imageFileName = composeImageFilename(expParams, descriptionString, prefix, coneString{stimConeContrastIndex}); 
        hFig = figure(100+(stimConeContrastIndex-1)*10); 
        clf; set(hFig, 'position', [700 10 1024 468], 'Color', [1 1 1], 'Name', imageFileName);
        colormap(grayRedLUT); 
        
        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            ySpatialBin = rowsToPlot(iRow);
            xSpatialBin = colsToPlot(iCol);
            spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, :,:,:));
            
            % determine coords of peak response
            indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) < 100);
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
        end
        end
        % Export figure
        NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
    end
end


function imageFileName = composeImageFilename(expParams, descriptionString, prefix, postfix)
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end 
    imageFileName = fullfile(core.getDecodingDataDir(descriptionString), sprintf('%s%s%sOverlap%2.1fMeanLum%d%s', prefix, expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance, postfix));    
end
