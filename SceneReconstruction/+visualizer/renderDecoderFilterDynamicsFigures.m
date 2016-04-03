function renderDecoderFilterDynamicsFigures(sceneSetName, descriptionString)
 
    fprintf('\nLoading decoder filter ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', 'expParams');
    fprintf('Done.\n');

    
    % Normalize wVector for plotting in [-1 1]
    wVector = wVector / max(abs(wVector(:)));
    weightsRange = 0.6*[-1 1];
    
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
    
    
    % Generate spatial pooling filters (at select stimulus locations)
    % generateSpatialPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, expParams, descriptionString);
    
    
    stimulusLocation.x = round(xSpatialBinsNum/2);
    stimulusLocation.y = round(SpatialBinsNum/2);
    coneNeighborhood.center.x = 4; %round(sensorCols/2);
    coneNeighborhood.center.y = 4; %round(sensorRows/2);
    coneNeighborhood.extent.x = -3:3;
    coneNeighborhood.extent.y = -2:2;
    generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, descriptionString)
    return;
    
   
    if (ySpatialBinsNum > 12)
        rowsToPlot = 3:6:ySpatialBinsNum
        fprintf('Stimulus y-positions are more than 12 will only show every 6th row\n');
    end
    
    if (xSpatialBinsNum > 12)
        colsToPlot = 3:6:xSpatialBinsNum
        fprintf('Stimulus y-positions are more than 12 will only show every 6th col\n');
    end
    
    
    coneString = {'LconeContrast', 'MconeContrast', 'SconeContrast'};
    if (expParams.outerSegmentParams.addNoise)
        outerSegmentNoiseString = 'Noise';
    else
        outerSegmentNoiseString = 'NoNoise';
    end
    
    
    if (1==1)  
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', numel(rowsToPlot), ...
               'colsNum', numel(colsToPlot), ...
               'heightMargin',   0.005, ...
               'widthMargin',    0.005, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.01, ...
               'topMargin',      0.00);
          
    
    imageFileName1 = fullfile(core.getDecodingDataDir(descriptionString), sprintf('DecoderSpatialFilters%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
    imageFileName2 = fullfile(core.getDecodingDataDir(descriptionString), sprintf('DecoderTemporalFilters%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
    
    
    for stimConeContrastIndex = 1:3
        hFig1 = figure(1+(stimConeContrastIndex-1)*10); clf; colormap(niceCmap(end:-1:1,:)); set(hFig1, 'position', [10 10 1024 468], 'Color', [1 1 1]);
        hFig2 = figure(2+(stimConeContrastIndex-1)*10); clf; colormap(niceCmap(end:-1:1,:)); set(hFig2, 'position', [700 10 1024 468], 'Color', [1 1 1]);

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
        
        figure(hFig1);
        NicePlot.exportFigToPNG(sprintf('%s%s.png', imageFileName1, coneString{stimConeContrastIndex}), hFig1, 300);
        
        figure(hFig2);
        NicePlot.exportFigToPNG(sprintf('%s%s.png', imageFileName2, coneString{stimConeContrastIndex}), hFig2, 300);
        
    end
    
    
    
    colormap(niceCmap(end:-1:1,:));
    
    % Now render temporal filter dynamics for one spatial location
    ySpatialLoc = round(ySpatialBinsNum/2);
    xSpatialLoc = round(xSpatialBinsNum/2);
    

    
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 7, ...
               'colsNum', 8, ...
               'heightMargin',   0.014, ...
               'widthMargin',    0.014, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.01, ...
               'topMargin',      0.00);
           
           
    for stimConeContrastIndex = 1:3
        imageFileName3 = fullfile(core.getDecodingDataDir(descriptionString), sprintf('DecoderTemporalFiltersInNeighborhood%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
   
        hFig3 = figure(10+(stimConeContrastIndex-1)*10); 
        clf;  set(hFig3, 'position', [10 10 1400 840], 'Color', [1 1 1]);
        colormap(niceCmap(end:-1:1,:)); 
        
        spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, ySpatialLoc, xSpatialLoc, :,:,:));
        
        if (stimConeContrastIndex == 1)
            % determine the visualized cone neighborhood based on the
            % L-cone decoder filter
            indicesForPeakResponseEstimation = find(timeAxis < 300);
            restrictedTimeAxis = timeAxis(indicesForPeakResponseEstimation(1):indicesForPeakResponseEstimation(end));

            tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
            [~, idx] = max(abs(tmp(:)));
            [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
            [~,peakTimeBin] = min(abs(timeAxis - restrictedTimeAxis(idx)));

            fprintf('filter at (%d,%d) peaks at %2.0f msec\n', xSpatialBin, ySpatialBin, timeAxis(peakTimeBin));
            nearbyConesXLocs = peakConeCol -2 + (-3:1:3)*1;
            nearbyConesYLocs = peakConeRow + 3 + (-3:1:3)*1;
        end
        
        subplot('position',subplotPosVectors(4, 1).v);
        imagesc((1:xSpatialBinsNum)-0.5, (1:ySpatialBinsNum)-0.5, squeeze(spatioTemporalFilter(:,:, peakTimeBin)));
        hold on;
        outlineY = [min(nearbyConesYLocs)-0.5 min(nearbyConesYLocs)-0.5 max(nearbyConesYLocs)+1 max(nearbyConesYLocs)+1 min(nearbyConesYLocs)-0.5];
        outlineX = [min(nearbyConesXLocs)-0.5 max(nearbyConesXLocs)+0.5 max(nearbyConesXLocs)+0.5 min(nearbyConesXLocs)-0.5 min(nearbyConesXLocs)-0.5];
        plot(outlineX, outlineY, 'k-', 'LineWidth', 2.0);
        hold off;
        box on
        set(gca, 'XTick', [], 'YTick', [], 'CLim', weightRange, 'XLim', [0 xSpatialBinsNum], 'YLim', [0 ySpatialBinsNum]);
        axis 'image'; axis 'xy'; 


        for iRow = 1:numel(nearbyConesXLocs)
            for iCol = 1:numel(nearbyConesYLocs)
                coneColPos = nearbyConesXLocs(iCol);
                coneRowPos = nearbyConesYLocs(iRow);
                subplot('position',subplotPosVectors((numel(nearbyConesYLocs)-iRow+1),iCol+1).v);
                temporalFilter = squeeze(spatioTemporalFilter(coneRowPos, coneColPos,:));
                coneIndex = sub2ind([sensorRows sensorCols], coneRowPos, coneColPos);
                if ismember(coneIndex, lConeIndices)
                    RGBcolor = [1 0.2 0.5];
                elseif ismember(coneIndex, mConeIndices)
                    RGBcolor = [0.2 0.8 0.2];
                elseif ismember(coneIndex, sConeIndices)
                    RGBcolor = [0.5 0.2 1];
                end
                
                plot(spatioTemporalSupport.timeAxis,  temporalFilter*0, 'k-', 'LineWidth', 1.0);
                hold on;
                plot([0 0],  [-1 1], 'k-', 'LineWidth', 1.0);
                plot(spatioTemporalSupport.timeAxis,  temporalFilter, '-', 'LineWidth', 2.0, 'Color', RGBcolor);
                hold off;
                box off;
                axis 'off'
                set(gca, 'XLim', [spatioTemporalSupport.timeAxis(1) spatioTemporalSupport.timeAxis(end)]);
                set(gca, 'YLim', [-0.2 0.7], 'XTickLabel', {}, 'YTickLabel', {});
            end
        end
        
        NicePlot.exportFigToPNG(sprintf('%s.png', imageFileName), hFig, 300);
    end
    
    end
    
    
    % Now render temporal filter dynamics for one spatial location
    ySpatialLoc = round(ySpatialBinsNum/2);
    xSpatialLoc = round(xSpatialBinsNum/2);
    
    
    % Finally render the spatial pooling profiles across sub-mosaics
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 3, ...
               'heightMargin',   0.014, ...
               'widthMargin',    0.014, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.01, ...
               'topMargin',      0.00);
           
           
           
           imageFileName4 = fullfile(core.getDecodingDataDir(descriptionString), sprintf('DecoderConeSubMosaicSpatialPooling%s%sOverlap%2.1fMeanLum%d', expParams.outerSegmentParams.type, outerSegmentNoiseString, expParams.sensorParams.eyeMovementScanningParams.fixationOverlapFactor,expParams.viewModeParams.forcedSceneMeanLuminance));
   
        hFig4 = figure(10); 
        clf; 
        set(hFig4, 'position', [10 10 1400 840], 'Color', [1 1 1]);
        colormap(niceCmap(end:-1:1,:)); 
        
    decoderWeightRange = [-1 1]/3;
    for stimulusTestYpos = ySpatialLoc+(-5:5)
    for stimulusTestXpos = xSpatialLoc+(-5:5)
        
        
        
        for stimConeContrastIndex = 1:3
            spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, stimulusTestYpos, stimulusTestXpos, :,:,:));
        
            %if (stimConeContrastIndex == 1)
                % determine the visualized cone neighborhood based on the
                % L-cone decoder filter
                indicesForPeakResponseEstimation = find(timeAxis < 300);
                restrictedTimeAxis = timeAxis(indicesForPeakResponseEstimation(1):indicesForPeakResponseEstimation(end));

                tmp = squeeze(spatioTemporalFilter(:,:,indicesForPeakResponseEstimation));
                [~, idx] = max(abs(tmp(:)));
                [peakConeRow, peakConeCol, peakTimeBinIndex] = ind2sub(size(tmp), idx);
                [~,peakTimeBin] = min(abs(timeAxis - restrictedTimeAxis(peakTimeBinIndex)));

               % fprintf('filter at (%d,%d) peaks at %2.0f msec\n', xSpatialBin, ySpatialBin, timeAxis(peakTimeBin));
            %end
        
            allConesKernel = squeeze(spatioTemporalFilter(:,:,peakTimeBinIndex));
            lConePts = [];
            mConePts = [];
            sConePts = [];
            allConePts = [];
            
            for coneRowPos = 1:size(allConesKernel,1)
                for coneColPos = 1:size(allConesKernel,2)
            
                    coneIndex = sub2ind([sensorRows sensorCols], coneRowPos, coneColPos);
                    xyWdata = [spatioTemporalSupport.sensorRetinalXaxis(coneColPos) spatioTemporalSupport.sensorRetinalYaxis(coneRowPos) allConesKernel(coneRowPos, coneColPos)];
                    
                    if ismember(coneIndex, lConeIndices)
                        lConePts(size(lConePts,1)+1,:) = xyWdata;
                        allConePts(size(allConePts,1)+1,:) = xyWdata;
                    elseif ismember(coneIndex, mConeIndices)
                        mConePts(size(mConePts,1)+1,:) = xyWdata;
                        allConePts(size(allConePts,1)+1,:) = xyWdata;
                    elseif ismember(coneIndex, sConeIndices)
                        sConePts(size(sConePts,1)+1,:) = xyWdata;
                        allConePts(size(allConePts,1)+1,:) = xyWdata;
                    end
                end
            end
                
            dx = spatioTemporalSupport.sensorRetinalXaxis(2)-spatioTemporalSupport.sensorRetinalXaxis(1);
            x = spatioTemporalSupport.sensorRetinalXaxis(1)-dx:1:spatioTemporalSupport.sensorRetinalXaxis(end)+dx;
            y = spatioTemporalSupport.sensorRetinalYaxis(1)-dx:1:spatioTemporalSupport.sensorRetinalYaxis(end)+dx;
            [xx, yy] = meshgrid(x,y); 
            lConeSpatialWeightingKernel = griddata(lConePts(:,1), lConePts(:,2), lConePts(:,3), xx, yy, 'cubic');
            mConeSpatialWeightingKernel = griddata(mConePts(:,1), mConePts(:,2), mConePts(:,3), xx, yy, 'cubic');
            sConeSpatialWeightingKernel = griddata(sConePts(:,1), sConePts(:,2), sConePts(:,3), xx, yy, 'cubic');
            lmConePts = [lConePts; mConePts];
            lmConeSpatialWeightingKernel = griddata(lmConePts(:,1), lmConePts(:,2), lmConePts(:,3), xx, yy, 'cubic');
            
            max(max(abs(sConePts(:,3))))
            
            subplot('position',subplotPosVectors(1,stimConeContrastIndex ).v);
            contourLineColor = [0.4 0.4 0.4];
            if (stimConeContrastIndex == 1)
                %maxForThisCone = max(abs(lConeSpatialWeightingKernel(:)));
                maxForThisCone = decoderWeightRange(2);
                minForThisCone = decoderWeightRange(1);
                dStep = maxForThisCone/16;
                [C,h] = contourf(xx,yy, lConeSpatialWeightingKernel, (minForThisCone:dStep:-dStep));
                h.LineWidth = 1;
                h.LineStyle = '--';
                h.LineColor = contourLineColor ;
                [C,h] = contourf(xx,yy, lConeSpatialWeightingKernel, (dStep:dStep:maxForThisCone));
                h.LineWidth = 1;
                h.LineStyle = '-';
               h.LineColor = contourLineColor ;
            elseif (stimConeContrastIndex == 2)
                %maxForThisCone = max(abs(mConeSpatialWeightingKernel(:)));
                maxForThisCone = decoderWeightRange(2);
                minForThisCone = decoderWeightRange(1);
                dStep = maxForThisCone/16;
                [C,h] = contourf(xx,yy, mConeSpatialWeightingKernel, (minForThisCone:dStep:-dStep));
                h.LineWidth = 1;
                h.LineStyle = '--';
               h.LineColor = contourLineColor ;
                [C,h] = contourf(xx,yy, mConeSpatialWeightingKernel, (dStep:dStep:maxForThisCone));
                h.LineWidth = 1;
                h.LineStyle = '-';
               h.LineColor = contourLineColor ;
            elseif (stimConeContrastIndex == 3)
                %maxForThisCone = max(abs(sConeSpatialWeightingKernel(:)));
                maxForThisCone = decoderWeightRange(2);
                minForThisCone = decoderWeightRange(1);
                dStep = maxForThisCone/16;
                [C,h] = contourf(xx,yy, sConeSpatialWeightingKernel, (minForThisCone :dStep:-dStep));
                h.LineWidth = 1;
                h.LineStyle = '--';
               h.LineColor = contourLineColor ;
                [C,h] = contourf(xx,yy, sConeSpatialWeightingKernel, (dStep:dStep:maxForThisCone));
                h.LineWidth = 1;
                h.LineStyle = '-';
               h.LineColor = contourLineColor ;
            end
            
            set(gca, 'CLim', decoderWeightRange);
        end % stimConeContrast
        
        drawnow;
        
    end % stimulusTestYpos
    end % stimulusTestXpos
    
end


function generateTemporalPoolingFiltersFigure(stimDecoder, weightsRange, spatioTemporalSupport, coneTypes, stimulusLocation, coneNeighborhood, expParams, descriptionString)
    
    % Load grayRed colormap
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'grayRedLUT');
    whos('-file', fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'));
    
    nearbyConeColumns = coneNeighborhood.center.x + coneNeighborhood.extent.x;
    nearbyConeRows    = coneNeighborhood.center.y + coneNeighborhood.extent.y;
    nearbyConeColumns = nearbyConeColumns(nearbyConeColumns >= 1);
    nearbyConeRows    = nearbyConeColumns(nearbyConeRows >= 1);
    nearbyConeColumns = nearbyConeColumns(nearbyConeColumns <= size(stimDecoder, 5));
    nearbyConeRows    = nearbyConeRows(nearbyConeRows <= size(stimDecoder, 4));
    
    nearbyConeRows
    nearbyConeColumns
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
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
        outlineY = spatioTemporalSupport.sensorRetinalXaxis([min(nearbyConeRows) min(nearbyConeRows) max(nearbyConeRows) max(nearbyConeRows) min(nearbyConeRows)]);
        outlineX = spatioTemporalSupport.sensorRetinalXaxis([min(nearbyConeColumns) max(nearbyConeColumns) max(nearbyConeColumns) min(nearbyConeColumns) min(nearbyConeColumns)]);
        plot(outlineX, outlineY, 'k-', 'LineWidth', 2.0);
        hold off;
        axis 'image'; axis 'xy'; 
        set(gca, 'XTick', (-150:15:150), 'YTick', (-150:15:150), ... %'XTickLabel', {}, 'YTickLabel', {}, ...
                 'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1) spatioTemporalSupport.sensorRetinalXaxis(end)], ...
                 'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1) spatioTemporalSupport.sensorRetinalYaxis(end)], 'CLim', weightsRange);
      
             
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
                     'XLim', [spatioTemporalSupport.sensorRetinalXaxis(1) spatioTemporalSupport.sensorRetinalXaxis(end)], ...
                     'YLim', [spatioTemporalSupport.sensorRetinalYaxis(1) spatioTemporalSupport.sensorRetinalYaxis(end)], 'CLim', weightsRange);
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
