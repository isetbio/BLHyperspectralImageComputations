function visualizeDecodingFilters(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)

    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);

    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    
    decodingFiltersVarList = {...
        'wVector', ...
        'filterSpatialXdataInRetinalMicrons', ...
        'filterSpatialYdataInRetinalMicrons'...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingFiltersFileName);
    for k = 1:numel(decodingFiltersVarList)
        load(decodingFiltersFileName, decodingFiltersVarList{k});
    end
    
    decodingDataFileName = fullfile(decodingDirectory, sprintf('DecodingData.mat'));
    testingVarList = {...
        'scanSensor', ...
        'keptLconeIndices', 'keptMconeIndices', 'keptSconeIndices', ...
        'designMatrix', ...
        };
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(testingVarList)
        load(decodingDataFileName, testingVarList{k});
    end
    
    
    neuralFeaturesNum = size(wVector,1)
    stimulusTotalFeatures = size(wVector,2)
    stimulusSpatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons)
    

    decodingFilter.conesNum    = designMatrix.n;
    decodingFilter.latencyBins = designMatrix.lat;
    decodingFilter.memoryBins  = designMatrix.m;
    decodingFilter.timeAxis    = (designMatrix.lat + (0:(designMatrix.m-1)))*designMatrix.binWidth;

    % Normalize wVector for plotting in [-1 1]
    wVectorNormalized = wVector / max(abs(wVector(:)));
    
    figNo = 11;
    visualizeTemporalFilterDynamics(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter);
    
    
    figNo = 10;
    visualizeSpatialFilterDynamics(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter);
    
    
    
    if (1==2)
        % display decoding filter
        fprintf('Displaying DC component of the decoding filter.\n');
        % First display the spatial maps of DC decoding coefficients for L-, M-, and S-cone contrast
        figNo = 1;
        generatePlotOfDCdecodingCoeffs(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices);
    end
    
end


function visualizeTemporalFilterDynamics(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVector, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
    % Retrieve the (row,col) positions of the cones included in the decoder
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    coneMosaicRows = sensorGet(scanSensor, 'row');
    coneMosaicCols = sensorGet(scanSensor, 'col');
    coneRowPos = zeros(1, decodingFilter.conesNum);
    coneColPos = zeros(1, decodingFilter.conesNum);
    for coneIndex = 1:decodingFilter.conesNum
        [coneRowPos(coneIndex), coneColPos(coneIndex)] = ind2sub([coneMosaicRows coneMosaicCols], filterConeIDs(coneIndex));
    end
    
    
    % Compute the stimDecoder(coneContrastIndex, stimYps, stimXpos) filters
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons);
    dcTerm = 1;
    timeBins = 1:decodingFilter.memoryBins;
    
    
    
           
    for stimConeContrastIndex = 1:3
        if (spatialFeaturesNum == 1)
            stimDimIndices = stimConeContrastIndex;
        else
            stimDimIndices = (stimConeContrastIndex-1)*spatialFeaturesNum + (1:spatialFeaturesNum);
        end
        for spatialDimIndex = 1:numel(stimDimIndices)
            
            [spatialYDimIndex, spatialXDimIndex] = ind2sub([ numel(filterSpatialYdataInRetinalMicrons)  numel(filterSpatialXdataInRetinalMicrons)], spatialDimIndex);
            for coneIndex = 1:decodingFilter.conesNum  
                % get slice
                temporalDecodingFilter = wVector(dcTerm + (coneIndex-1)*numel(timeBins) + timeBins, stimDimIndices(spatialDimIndex));
                
                if (spatialDimIndex == 1) && (coneIndex == 1) && (stimConeContrastIndex==1)
                    % preallocate memory
                    a.filter = zeros(sensorGet(scanSensor, 'row'), sensorGet(scanSensor, 'col'), numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(stimConeContrastIndex, spatialYDimIndex, spatialXDimIndex).filter(coneRowPos(coneIndex), coneColPos(coneIndex), :) = temporalDecodingFilter;
            end % coneIndex
        end % stimDimIndex
    end  % stimConeContrastIndex
    
    
    decoderWeightRange = max(wVector(:))*[-0.45 0.45]; % [min(wVector(:)) max(wVector(:))*0.5]
    
    mConeFreePosXcoord = 10;
    mConeFreePosYcoord = 6;
   
    mConeRichPosXcoord = 7;
    mConeRichPosYcoord = 8;
    
    stimulusXpositionsToExamine = mConeRichPosXcoord;
    stimulusYpositionsToExamine = mConeRichPosYcoord;
    
    %stimulusXpositionsToExamine = 4:numel(filterSpatialXdataInRetinalMicrons)-3;
    %stimulusYpositionsToExamine = 4:numel(filterSpatialYdataInRetinalMicrons)-3
    

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', coneMosaicRows, ...
               'colsNum', coneMosaicCols, ...
               'heightMargin',   0.002, ...
               'widthMargin',    0.002, ...
               'leftMargin',     0.002, ...
               'rightMargin',    0.002, ...
               'bottomMargin',   0.002, ...
               'topMargin',      0.002);
           
    for stimulusTestYpos = stimulusYpositionsToExamine
    for stimulusTestXpos = stimulusXpositionsToExamine
        for stimConeContrastIndex = 1:3
            
            spatiotemporalKernel = stimDecoder(stimConeContrastIndex, stimulusTestYpos, stimulusTestXpos).filter;
            
            hFig = figure(stimConeContrastIndex); clf;
            set(hFig, 'Color', [1 1 1], 'Position', [10 10 1350 1290]);
            
            for coneIndex = 1:numel(filterConeIDs)
                
                coneRow = coneRowPos(coneIndex);
                coneCol = coneColPos(coneIndex);
                
                % figure out the color of the filter entry
                if ismember(filterConeIDs(coneIndex), lConeIndices)
                    RGBcolor = [1 0.2 0.5];
                elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                    RGBcolor = [0.2 1 0.5];
                elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                    RGBcolor = [0.5 0.2 1];
                end
                
                subplot('position',subplotPosVectors(coneMosaicRows-coneRow+1,coneCol).v);
                plot(decodingFilter.timeAxis, squeeze(spatiotemporalKernel(coneRow,coneCol,:)), 'k-', 'Color', RGBcolor, 'LineWidth', 2);
                hold on;
                plot([0 0], decoderWeightRange, 'k-');
                plot([decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)], 0*decoderWeightRange, 'k-');
                hold off
                set(gca, 'XColor', 'none', 'YColor', 'none', 'Color', 'none', 'XTick', [], 'YTick', [], 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)], 'YLim', decoderWeightRange);
                axis 'square'
 
            end % coneIndex
            drawnow;
            
            if (stimConeContrastIndex == 1)
                figName = sprintf('%s/LcontrastDecoderTemporalSampling.png', decodingDirectory);
            elseif (stimConeContrastIndex == 2)
                figName = sprintf('%s/McontrastDecoderTemporalSampling.png', decodingDirectory);
            elseif (stimConeContrastIndex == 3)
                figName = sprintf('%s/ScontrastDecoderTemporalSampling.png', decodingDirectory);
            end
            fprintf('Will export temporal profiles %s\n', figName);
            NicePlot.exportFigToPNG(figName, hFig, 300);
            
        end % stimConeContrastIndex = 1:3
    end % stimulusTestXpos
    end % stimulusTestYpos
    
end

function visualizeSpatialFilterDynamics(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVector, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
    % Retrieve the types of all cones
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    % Retrieve the positions of all the cones
    coneXYpositions = sensorGet(scanSensor, 'xy');
    coneMosaicSpatialXdataInRetinalMicrons = sort(unique(coneXYpositions(:,1)));
    coneMosaicSpatialYdataInRetinalMicrons = sort(unique(coneXYpositions(:,2)));
    
    % Retrieve the (row,col) positions of the cones included in the decoder
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    coneMosaicRows = sensorGet(scanSensor, 'row');
    coneMosaicCols = sensorGet(scanSensor, 'col');
    coneRowPos = zeros(1, decodingFilter.conesNum);
    coneColPos = zeros(1, decodingFilter.conesNum);
    
    for coneIndex = 1:decodingFilter.conesNum
        [coneRowPos(coneIndex), coneColPos(coneIndex)] = ind2sub([coneMosaicRows coneMosaicCols], filterConeIDs(coneIndex));
    end
    
    
    % Compute the stimDecoder(coneContrastIndex, stimYps, stimXpos) filters
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons);
    dcTerm = 1;
    timeBins = 1:decodingFilter.memoryBins;
    
    
    for stimConeContrastIndex = 1:3
        if (spatialFeaturesNum == 1)
            stimDimIndices = stimConeContrastIndex;
        else
            stimDimIndices = (stimConeContrastIndex-1)*spatialFeaturesNum + (1:spatialFeaturesNum);
        end
        for spatialDimIndex = 1:numel(stimDimIndices)
            
            [spatialYDimIndex, spatialXDimIndex] = ind2sub([ numel(filterSpatialYdataInRetinalMicrons)  numel(filterSpatialXdataInRetinalMicrons)], spatialDimIndex);
            for coneIndex = 1:decodingFilter.conesNum  
                % get slice
                temporalDecodingFilter = wVector(dcTerm + (coneIndex-1)*numel(timeBins) + timeBins, stimDimIndices(spatialDimIndex));
                
                if (spatialDimIndex == 1) && (coneIndex == 1) && (stimConeContrastIndex==1)
                    % preallocate memory
                    a.filter = zeros(sensorGet(scanSensor, 'row'), sensorGet(scanSensor, 'col'), numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(stimConeContrastIndex, spatialYDimIndex, spatialXDimIndex).filter(coneRowPos(coneIndex), coneColPos(coneIndex), :) = temporalDecodingFilter;
            end % coneIndex
        end % stimDimIndex
    end  % stimConeContrastIndex
    
    
    hFig = figure(figNo); clf;
    set(hFig, 'Position', [10 10 875 1060], 'Color', [1 1 1]);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 3, ...
               'heightMargin',   0.08, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.045, ...
               'rightMargin',    0.001, ...
               'bottomMargin',   0.05, ...
               'topMargin',      0.03);
           
    %colormap(jet(1024));
    
    niceCmap = cbrewer('div', 'Spectral', 1024);
    %niceCmap = cbrewer('seq', 'PuBu', 1024);
    niceCmap = cbrewer('div', 'RdGy', 1024);
    colormap(niceCmap(end:-1:1,:));
    
%     cmap = bone(1024);
%     colormap(cmap(end:-1:1,:))
%     colormap(cmap)
    
    decoderWeightRange = max(wVector(:))*[-0.45 0.45]; % [min(wVector(:)) max(wVector(:))*0.5]
    
    
    
    videoFilename = sprintf('%s/DecoderSpatialSamplingAnimation.m4v', decodingDirectory);
    pngFilename = sprintf('%s/DecoderSpatialSamplingLastFrame.png', decodingDirectory);
    fprintf('Will export video to %s\n', videoFilename);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    mConeFreePosXcoord = 10;
    mConeFreePosYcoord = 6;
   
    mConeRichPosXcoord = 7;
    mConeRichPosYcoord = 8;
    
    stimulusXpositionsToExamine = mConeRichPosXcoord;
    stimulusYpositionsToExamine = mConeRichPosYcoord;
    
   % stimulusXpositionsToExamine = 4:numel(filterSpatialXdataInRetinalMicrons)-3;
   % stimulusYpositionsToExamine = 4:numel(filterSpatialYdataInRetinalMicrons)-3
    
    for stimulusTestYpos = stimulusYpositionsToExamine
    for stimulusTestXpos = stimulusXpositionsToExamine
        
        clf(hFig);
        stimOutlineX = filterSpatialXdataInRetinalMicrons(stimulusTestXpos) + [-1 -1 1 1 -1 -1]*0.5*(filterSpatialXdataInRetinalMicrons(2)-filterSpatialXdataInRetinalMicrons(1));
        stimOutlineY = filterSpatialYdataInRetinalMicrons(stimulusTestYpos) + [-1 1 1 -1 -1  1]*0.5*(filterSpatialYdataInRetinalMicrons(2)-filterSpatialYdataInRetinalMicrons(1));

        for stimConeContrastIndex = 1:3
            decodingFilter.kernel = stimDecoder(stimConeContrastIndex, stimulusTestYpos, stimulusTestXpos).filter;
            [~,idx] = max(abs(decodingFilter.kernel(:)));
            [peakConeRowIndex, peakConeColIndex, peakTimeBinIndex] = ind2sub(size(decodingFilter.kernel), idx);
            fprintf('stimContrast: %d; weights peak at t= %d ms for cone at (row,col) = (%d,%d) \n', stimConeContrastIndex, decodingFilter.timeAxis(peakTimeBinIndex), peakConeRowIndex, peakConeColIndex);

            allConesKernel = squeeze(decodingFilter.kernel(:,:,peakTimeBinIndex));

            subplot('position',subplotPosVectors(1,stimConeContrastIndex).v);
            % plot filter
            imagesc(coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons, allConesKernel);
            hold on;

            plot(stimOutlineX, stimOutlineY, 'y-', 'LineWidth', 2.0);

            hold off
            axis 'xy'
            axis 'equal'
            set(gca, 'CLim', decoderWeightRange, 'XLim', [coneMosaicSpatialXdataInRetinalMicrons(1)-1.5  coneMosaicSpatialXdataInRetinalMicrons(end)+1.5 ], 'YLim', [coneMosaicSpatialYdataInRetinalMicrons(1)-1.5 coneMosaicSpatialYdataInRetinalMicrons(end)+1.5 ]);
            set(gca, 'XTick', [], 'YTick', [], 'FontSize', 16);
            if (stimConeContrastIndex==1)
                title(sprintf('L-contrast decoder\n(sampling across all cones)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==2)
                title(sprintf('M-contrast decoder\n(sampling across all cones)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==3)
                title(sprintf('S-contrast decoder\n(sampling across all cones)'), 'FontSize', 20)
            end

            if (stimConeContrastIndex==1)
                ylabel('microns', 'FontSize', 20);
            end
            
            subplot('position',subplotPosVectors(2,stimConeContrastIndex).v);
            hold on;

            % get the submosaics
            lConePts = [];
            mConePts = [];
            sConePts = [];
            allConePts = [];
            for coneIndex = 1:numel(filterConeIDs)
                coneRow = coneRowPos(coneIndex);
                coneCol = coneColPos(coneIndex);
                coneXpos = coneXYpositions(filterConeIDs(coneIndex),1);
                coneYpos = coneXYpositions(filterConeIDs(coneIndex),2);
                xyWdata = [coneXpos coneYpos allConesKernel(coneRow, coneCol)];
                % figure out the color of the filter entry
                if ismember(filterConeIDs(coneIndex), lConeIndices)
                    lConePts(size(lConePts,1)+1,:) = xyWdata;
                    allConePts(size(allConePts,1)+1,:) = xyWdata;

                elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                    mConePts(size(mConePts,1)+1,:) = xyWdata;
                    allConePts(size(allConePts,1)+1,:) = xyWdata;

                elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                    sConePts(size(sConePts,1)+1,:) = xyWdata;
                    allConePts(size(allConePts,1)+1,:) = xyWdata;
                else
                    error('No such cone type')
                end
            end


            x = coneMosaicSpatialXdataInRetinalMicrons(1)-3:1:coneMosaicSpatialXdataInRetinalMicrons(end)+3;
            y = coneMosaicSpatialYdataInRetinalMicrons(1)-3:1:coneMosaicSpatialYdataInRetinalMicrons(end)+3;

            [xx, yy] = meshgrid(x,y); 
            lConeSpatialWeightingKernel = griddata(lConePts(:,1), lConePts(:,2), lConePts(:,3), xx, yy, 'cubic');
            mConeSpatialWeightingKernel = griddata(mConePts(:,1), mConePts(:,2), mConePts(:,3), xx, yy, 'cubic');
            sConeSpatialWeightingKernel = griddata(sConePts(:,1), sConePts(:,2), sConePts(:,3), xx, yy, 'cubic');

            lmConePts = [lConePts; mConePts];
            lmConeSpatialWeightingKernel = griddata(lmConePts(:,1), lmConePts(:,2), lmConePts(:,3), xx, yy, 'cubic');

            % plot contour plot of the decoding filter

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

            
            for coneIndex = 1:numel(filterConeIDs)
                coneRow = coneRowPos(coneIndex);
                coneCol = coneColPos(coneIndex);
                coneXpos = coneXYpositions(filterConeIDs(coneIndex),1);
                coneYpos = coneXYpositions(filterConeIDs(coneIndex),2);
                xyWdata = [coneXpos coneYpos allConesKernel(coneRow, coneCol)];
                % figure out the color of the filter entry
                if ismember(filterConeIDs(coneIndex), lConeIndices)
                    RGBval = 0.5*([1 0.2 0.5]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 1)
                        % plot this cone only if this is an l-cone decoder
                        plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                    RGBval = 0.5*([0.2 1 0.5]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 2)
                        % plot this cone only if this is an m-cone decoder
                        plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                    RGBval = 0.5*([0.5 0.2 1]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 3)
                         % plot this cone only if this is an s-cone decoder
                        plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                else
                    error('No such cone type')
                end
            end
            
            
            % plot the stimulus
            plot(stimOutlineX, stimOutlineY, 'y-', 'LineWidth', 2.0);
            hold off
            axis 'xy'
            axis 'equal'
            box 'off'
            set(gca, 'CLim', decoderWeightRange, 'XLim', [coneMosaicSpatialXdataInRetinalMicrons(1)-1.5 coneMosaicSpatialXdataInRetinalMicrons(end)+1.5], 'YLim', [coneMosaicSpatialYdataInRetinalMicrons(1)-1.5 coneMosaicSpatialYdataInRetinalMicrons(end)+1.5]);
            set(gca, 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [-100:20:100], 'YTick', [-100:20:100], 'XTickLabel', {}, 'FontSize', 16);
            if (stimConeContrastIndex>1)
                set(gca,'YTickLabel', {});
            end

            if (stimConeContrastIndex==1)
                title(sprintf('L-contrast decoder\n(L mosaic sampling)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==2)
                title(sprintf('M-contrast decoder\n(M mosaic sampling)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==3)
                title(sprintf('S-contrast decoder\n(S mosaic sampling)'), 'FontSize', 20)
            end

            if (stimConeContrastIndex==1)
                ylabel('microns', 'FontSize', 20);
            end


            subplot('position',subplotPosVectors(3,stimConeContrastIndex).v);
            hold on;

            

            if (stimConeContrastIndex == 1)
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
            elseif (stimConeContrastIndex == 2)
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
            elseif (stimConeContrastIndex == 3)
                %maxForThisCone = max(abs(lmConeSpatialWeightingKernel(:)));
                maxForThisCone = decoderWeightRange(2);
                minForThisCone = decoderWeightRange(1);
                dStep = maxForThisCone/16;
                [C,h] = contourf(xx,yy, lmConeSpatialWeightingKernel, (minForThisCone:dStep:-dStep));
                h.LineWidth = 1;
                h.LineStyle = '--';
               h.LineColor = contourLineColor ;
                [C,h] = contourf(xx,yy, lmConeSpatialWeightingKernel, (dStep:dStep:maxForThisCone));
                h.LineWidth = 1;
                h.LineStyle = '-';
                h.LineColor = contourLineColor ;
            end


            % plot the (other mosaic)
            for coneIndex = 1:numel(filterConeIDs)
                coneRow = coneRowPos(coneIndex);
                coneCol = coneColPos(coneIndex);
                coneXpos = coneXYpositions(filterConeIDs(coneIndex),1);
                coneYpos = coneXYpositions(filterConeIDs(coneIndex),2);
                % figure out the color of the filter entry
                if ismember(filterConeIDs(coneIndex), lConeIndices)
                    RGBval = 0.5*([1 0.2 0.5]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 2) || (stimConeContrastIndex == 3)
                        % plot this cone only if this is an m-cone decoder or an s-cone decoder
                        plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                    RGBval = 0.5*([0.2 1 0.5]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 1) || (stimConeContrastIndex == 3)
                        % plot this cone only if this is an l-cone decoder or an s-cone decoder
                        plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                    RGBval = 0.5*([0.5 0.2 1]+[1 1 1]);
                    RGBval = 0.2*[1 1 1];
                    if (stimConeContrastIndex == 1) || (stimConeContrastIndex == 3)
                         % do not plot s cones
                        % plot(coneXYpositions(filterConeIDs(coneIndex), 1), coneXYpositions(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
                    end
                else
                    error('No such cone type')
                end
            end
            

            % plot the stimulus
            plot(stimOutlineX, stimOutlineY, 'y-', 'LineWidth', 2.0);
            hold off
            axis 'xy'
            axis 'equal'
            box 'off'
            set(gca, 'CLim', decoderWeightRange, 'XLim', [coneMosaicSpatialXdataInRetinalMicrons(1)-1.5 coneMosaicSpatialXdataInRetinalMicrons(end)+1.5], 'YLim', [coneMosaicSpatialYdataInRetinalMicrons(1)-1.5 coneMosaicSpatialYdataInRetinalMicrons(end)+1.5]);
            set(gca, 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [-100:20:100], 'YTick', [-100:20:100], 'FontSize', 16);

            if (stimConeContrastIndex>1)
                set(gca,'YTickLabel', {});
            end

            if (stimConeContrastIndex==1)
                title(sprintf('L-contrast decoder\n(M mosaic sampling)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==2)
                title(sprintf('M-contrast decoder\n(L mosaic sampling)'), 'FontSize', 20)
            elseif (stimConeContrastIndex==3)
                title(sprintf('S-contrast decoder\n(L/M mosaic sampling)'), 'FontSize', 20)
            end
            
            xlabel('microns', 'FontSize', 20);
            if (stimConeContrastIndex==1)
                ylabel('microns', 'FontSize', 20);
            end
            
        end % coneContrastIndex
            
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    end

    writerObj.close();
    
    
    NicePlot.exportFigToPNG(pngFilename, hFig, 300);
    
    
end

function generatePlotOfDCdecodingCoeffs(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVector, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices)
    
    dcTerm = 1; % the vector of DC terms is the first row of the decoding filter
    dcVector = reshape(squeeze(wVector(dcTerm,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
        
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 3, ...
       'heightMargin',   0.04, ...
       'widthMargin',    0.03, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.01, ...
       'bottomMargin',   0.06, ...
       'topMargin',      0.03);
   
    h = figure(figNo); clf; colormap(gray(512));
    set(h, 'Name', 'Decoding filter: DC coefficient for each spatial position of stimulus');
    set(h, 'Position', [10 10 1750 560]);
    subplot('Position', subplotPosVectors(1,1).v);
    makeStimConeComboPlot(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, squeeze(dcVector(:,:,1)), ...
        scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, 'Lcone decoding');
    
    subplot('Position', subplotPosVectors(1,2).v);
    makeStimConeComboPlot(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, squeeze(dcVector(:,:,2)), ...
        scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, 'Mcone decoding');
    
    subplot('Position', subplotPosVectors(1,3).v);
    makeStimConeComboPlot(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, squeeze(dcVector(:,:,3)), ...
        scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, 'Scone decoding');
    
    drawnow
end
    
    
function makeStimConeComboPlot(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, decodingFilter2Dmap, ...
        scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, titleString)
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    coneTypes = sensorGet(scanSensor, 'coneType');
    xyConePos = sensorGet(scanSensor, 'xy');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, decodingFilter2Dmap);
    hold on;
    
    for coneIndex = 1:numel(filterConeIDs)
        % figure out the color of the filter entry
        if ismember(filterConeIDs(coneIndex), lConeIndices)
            RGBval = [0.5 0. 0.];
        elseif ismember(filterConeIDs(coneIndex), mConeIndices)
            RGBval = [0 0.5 0.0];
        elseif ismember(filterConeIDs(coneIndex), sConeIndices)
            RGBval = [0.0 0 0.5];
        else
            error('No such cone type')
        end
        plot(xyConePos(filterConeIDs(coneIndex), 1), xyConePos(filterConeIDs(coneIndex), 2), 'ko', 'MarkerEdgeColor', RGBval, 'MarkerSize', 12);
    end
    xlabel('microns', 'FontSize', 14);
    ylabel('microns', 'FontSize', 14);
    hold off;
    axis 'xy'
    axis 'equal'
    colorbar
    set(gca, 'CLim', [-1 1]*0.05, 'XLim', [filterSpatialXdataInRetinalMicrons(1)-1.5 filterSpatialXdataInRetinalMicrons(end)+1.5], 'YLim', [filterSpatialYdataInRetinalMicrons(1)-1.5 filterSpatialYdataInRetinalMicrons(end)+1.5]);
    set(gca, 'FontSize', 12);
    title(titleString, 'FontSize', 14);
    
end

