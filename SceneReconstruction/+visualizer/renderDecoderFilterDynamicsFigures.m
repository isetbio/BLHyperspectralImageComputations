function renderDecoderFilterDynamicsFigures(sceneSetName, descriptionString)

    
    fprintf('\nLoading decoder filter ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector', 'spatioTemporalSupport');
    fprintf('Done.\n');
    
    sensorRows      = numel(spatioTemporalSupport.sensorRowAxis);
    sensorCols      = numel(spatioTemporalSupport.sensorColAxis);
    xSpatialBinsNum = numel(spatioTemporalSupport.sensorFOVxaxis);                   % spatial support of decoded scene
    ySpatialBinsNum = numel(spatioTemporalSupport.sensorFOVyaxis);
    spatialDimsNum  = xSpatialBinsNum * ySpatialBinsNum;
    timeAxis        = spatioTemporalSupport.timeAxis;
    timeBinsNum     = numel(timeAxis);

    % Normalize wVector for plotting in [-1 1]
    wVector = wVector / max(abs(wVector(:)));
    weightRange = max(abs(wVector(:)))*[-1.0 1.0];
    
    % Allocate memory for unpacked stimDecoder
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
    
    
    
    %niceCmap = cbrewer('div', 'Spectral', 1024);
    %niceCmap = cbrewer('seq', 'PuBu', 1024);
    
    niceCmap = cbrewer('div', 'RdGy', 1024);
    
    if (ySpatialBinsNum > 12)
        rowsToPlot = round(ySpatialBinsNum/2) + (-3:3);
        fprintf('Stimulus y-positions are more than 12 will only show central %d\n', rowsToPlot);
    end
    
    if (xSpatialBinsNum > 12)
        colsToPlot = round(xSpatialBinsNum/2) + (-3:3);
        fprintf('Stimulus x-positions are more than 12 will only show central %d\n', colsToPlot);
    end
    
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(rowsToPlot), ...
               'heightMargin',   0.005, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.005, ...
               'rightMargin',    0.005, ...
               'bottomMargin',   0.005, ...
               'topMargin',      0.01);
           
    for stimConeContrastIndex = 1:3
        hFig1 = figure(1+(stimConeContrastIndex-1)*10); clf; colormap(niceCmap(end:-1:1,:)); set(hFig1, 'position', [10 10 950 930]);
        hFig2 = figure(2+(stimConeContrastIndex-1)*10); clf; colormap(niceCmap(end:-1:1,:)); set(hFig2, 'position', [700 10 950 930]);

        for iRow = 1:numel(rowsToPlot)
        for iCol = 1:numel(colsToPlot)
            ySpatialBin = rowsToPlot(iRow);
            xSpatialBin = colsToPlot(iCol);
            
            spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, :,:,:));
            
            indicesForPeakResponseEstimation = find(timeAxis < 300);
            restrictedTimeAxis = timeAxis(indicesForPeakResponseEstimation(1):indicesForPeakResponseEstimation(end));
            
            tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
            [~, idx] = max(abs(tmp(:)));
            [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
            [~,peakTimeBin] = min(abs(timeAxis - restrictedTimeAxis(idx)));
            fprintf('filter at (%d,%d) peaks at %2.0f msec\n', xSpatialBin, ySpatialBin, timeAxis(peakTimeBin));

            figure(hFig1)
            subplot('position',subplotPosVectors(numel(rowsToPlot)-iRow+1,iCol).v);
            imagesc(squeeze(spatioTemporalFilter(:,:, peakTimeBin)));
            set(gca, 'XTick', [], 'YTick', [], 'CLim', weightRange);
            axis 'image'; axis 'xy'; 
            drawnow
            
            figure(hFig2)
            subplot('position',subplotPosVectors(numel(rowsToPlot)-iRow+1,iCol).v);
            plot(timeAxis, squeeze(spatioTemporalFilter(peakConeRow, peakConeCol, :)), 'k.-');
            hold on;
            plot([0 0], [-1 1], 'r-');
            plot([timeAxis(1) timeAxis(end)], [0 0], 'r-');
            hold off
            axis 'square';
            set(gca, 'XTick', [], 'YTick', [], 'XLim', [timeAxis(1) timeAxis(end)], 'YLim', weightRange);
            drawnow
        end
        
        end
    end

end


