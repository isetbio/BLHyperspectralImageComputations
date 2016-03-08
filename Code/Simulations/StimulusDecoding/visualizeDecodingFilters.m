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
    
    
    designMatrix
    size(wVector)
    featuresNum = size(wVector,1)
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons)
    stimulusDimensions = size(wVector,2)
    
    
    
    % display decoding filter
    fprintf('Displaying DC component of the decoding filter.\n');
   
    decodingFilter.conesNum    = designMatrix.n;
    decodingFilter.latencyBins = designMatrix.lat;
    decodingFilter.memoryBins  = designMatrix.m;
    decodingFilter.timeAxis    = (designMatrix.lat + (0:(designMatrix.m-1)))*designMatrix.binWidth;
    
    % Normalize wVector for plotting in [-1 1]
    wVectorNormalized = wVector / max(abs(wVector(:)));
    
    % First display the spatial maps of DC decoding coefficients for L-, M-, and S-cone contrast
    figNo = 1;
    generatePlotOfDCdecodingCoeffs(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices);

    

    % Then display the spatial map of the coefficients for each 
    fprintf('Displaying the spatiotemporal L-, M- and S-contrast decoder for scene position (1,1)\n');
    figNo = 2;
    generatePlotsOfDecodingMaps(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
    
    
    pause


    
    
    
   
    
    
    figure(3); 
     
    for stimDimIndex = 1:stimulusDimensions
        
        if (spatialFeaturesNum > 1)
            coneContrastDimIndex = floor((stimDimIndex-1)/spatialFeaturesNum)+1;
            spatialDimIndex = mod(stimDimIndex-1, spatialFeaturesNum) + 1;
            [spatialYDimIndex, spatialXDimIndex] = ind2sub([ numel(filterSpatialYdataInRetinalMicrons)  numel(filterSpatialXdataInRetinalMicrons)], spatialDimIndex);
        elseif (spatialFeaturesNum == 1)
            coneContrastDimIndex = stimDimIndex; 
        end
        
        clf;
        for coneIndex = 1:decodingFilter.conesNum
            temporalDecodingFilter = wVectorNormalized(dcTerm + (coneIndex-1)*numel(timeBins) + timeBins, stimDimIndex);
            
            if (spatialFeaturesNum == 1)
                if (coneIndex == 1) && (stimDimIndex == 1)
                    a.filter = zeros(decodingFilter.conesNum, numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(coneContrastDimIndex).filter(coneIndex,:) = temporalDecodingFilter;
            else
                if (coneIndex == 1) && (stimDimIndex == 1)
                    a.filter = zeros(decodingFilter.conesNum, numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(coneContrastDimIndex, spatialYDimIndex, spatialXDimIndex).filter(coneIndex,:) = temporalDecodingFilter;
            end
            
            if ismember(filterConeIDs(coneIndex), lConeIndices)
                RGBval = [1 0. 0.];
            elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                RGBval = [0 1 0.0];
            elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                RGBval = [0.0 0 1];
            else
                error('No such cone type')
            end
            
            subplot(1,2,1);
            plot(decodingFilter.timeAxis, temporalDecodingFilter, 'k-', 'Color', RGBval);
            set(gca, 'YLim', [-1 1], 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)]);
            xlabel('msec');
            subplot(1,2,2);
            hold on;
            plot(decodingFilter.timeAxis, temporalDecodingFilter, 'k-', 'Color', RGBval);
            set(gca, 'YLim', [-1 1], 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)])
            xlabel('msec');
            drawnow;
        end % coneIndex
    end % stimIndex
    
        
    stimConeContrastIndex = 2; % s-cone decoding filter
    
    for timeBin = 1:numel(timeBins)
    h = figure(2); set(h, 'Name', sprintf('%d', timeBin));
    clf;
    kk = 0;
    for stimYindex = 1:numel(filterSpatialYdataInRetinalMicrons)
        for stimXindex = 1:numel(filterSpatialXdataInRetinalMicrons)
            kk = kk + 1;
            subplot(numel(filterSpatialYdataInRetinalMicrons),numel(filterSpatialXdataInRetinalMicrons),kk);

            coneRows = sensorGet(scanSensor, 'rows');
            coneCols = sensorGet(scanSensor, 'cols');
            filterMosaicLayoutRGBrepresentation = zeros(coneRows, coneCols, 3)+0.5;

            for coneIndex = 1:decodingFilter.conesNum
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
                % figure out the (row,col) position of the filter entry
                [row, col] = ind2sub([sensorGet(scanSensor, 'row') sensorGet(scanSensor, 'col')], filterConeIDs(coneIndex));

                filterMosaicLayoutRGBrepresentation(row, col, :) = [0.5 0.5 0.5] + RGBval * stimDecoder(stimConeContrastIndex, stimYindex, stimXindex).filter(coneIndex, timeBin);
            end
            image(filterMosaicLayoutRGBrepresentation);
            axis 'image'
            drawnow;
        end
    end
    
    
    end
end


function generatePlotsOfDecodingMaps(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVector, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons);
    
    dcTerm = 1;
    timeBins = 1:decodingFilter.memoryBins;
    
    coneMosaicRows = sensorGet(scanSensor, 'row');
    coneMosaicCols = sensorGet(scanSensor, 'col');
    coneRowPos = zeros(1, decodingFilter.conesNum);
    coneColPos = zeros(1, decodingFilter.conesNum);
    
    for coneIndex = 1:decodingFilter.conesNum
        [coneRowPos(coneIndex), coneColPos(coneIndex)] = ind2sub([coneMosaicRows coneMosaicCols], filterConeIDs(coneIndex));
    end
    
    for coneContrastIndex = 1:3
        if (spatialFeaturesNum == 1)
            stimDimIndices = coneContrastIndex;
        else
            stimDimIndices = (coneContrastIndex-1)*spatialFeaturesNum + (1:spatialFeaturesNum);
        end
        
        for spatialDimIndex = 1:numel(stimDimIndices)
            
            [spatialYDimIndex, spatialXDimIndex] = ind2sub([ numel(filterSpatialYdataInRetinalMicrons)  numel(filterSpatialXdataInRetinalMicrons)], spatialDimIndex);
            
            for coneIndex = 1:decodingFilter.conesNum  
                % get slice
                temporalDecodingFilter = wVector(dcTerm + (coneIndex-1)*numel(timeBins) + timeBins, stimDimIndices(spatialDimIndex));
                
                if (spatialDimIndex == 1) && (coneIndex == 1) && (coneContrastIndex==1)
                    % preallocate memory
                    a.filter = zeros(sensorGet(scanSensor, 'row'), sensorGet(scanSensor, 'col'), numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end

                stimDecoder(coneContrastIndex, spatialYDimIndex, spatialXDimIndex).filter(coneRowPos(coneIndex), coneColPos(coneIndex), :) = temporalDecodingFilter;
            end % coneIndex
        end % stimDimIndex
    end  % coneContrastIndex
    
    
    coneXYpositions = sensorGet(scanSensor, 'xy');
    coneXpositions = sort(unique(coneXYpositions(:,1)))
    pause
    
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
   
    for sceneYpos = 1: numel(filterSpatialYdataInRetinalMicrons)
        for sceneXpos = 1:numel(filterSpatialXdataInRetinalMicrons)
            
            hFig = figure(figNo); clf;
            subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 4, ...
               'heightMargin',   0.08, ...
               'widthMargin',    0.03, ...
               'leftMargin',     0.02, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.06, ...
               'topMargin',      0.03);
   
            stimulusPositionAxes = axes('parent', hFig, 'unit','normalized','position',[subplotPosVectors(1,1).v(1) 0.5*(subplotPosVectors(1,1).v(2) + subplotPosVectors(2,1).v(2)) subplotPosVectors(1,1).v(3) subplotPosVectors(1,1).v(4)]);
            temporalProfileLconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,2).v);
            spatialProfileLconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,2).v);
            temporalProfileMconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,3).v);
            spatialProfileMconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,3).v);
            temporalProfileSconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,4).v);
            spatialProfileSconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,4).v);
            
            
            
            for coneContrastIndex = 1:3
                
                stimulusPosition = 0.5*ones(numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
                if (coneContrastIndex == 1)
                    RGBval = [1 0. 0.];
                elseif (coneContrastIndex == 2)
                    RGBval = [0 1 0.];
                else
                    RGBval = [0 0 1];
                end
                stimulusPosition(sceneYpos, sceneXpos, :) = reshape(RGBval, [1 1 3]);

                imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, stimulusPosition, 'parent', stimulusPositionAxes);
                axis(stimulusPositionAxes, 'xy');
                axis(stimulusPositionAxes, 'image');
                set(stimulusPositionAxes, 'XTick', filterSpatialXdataInRetinalMicrons, 'YTick', filterSpatialYdataInRetinalMicrons);
                set(stimulusPositionAxes, 'XTickLabel', {}, 'YTickLabel', {});
                grid(stimulusPositionAxes, 'on');
                
                RGBval = zeros(decodingFilter.conesNum,3);
                
                maxConeDecodingWeight = 0;
                for timeBin = 1:numel(timeBins)
                
                    set(hFig, 'Name', sprintf('time = %d ms', decodingFilter.timeAxis(timeBin)));
                    
                    coneWeightsXYTMap = squeeze(stimDecoder(coneContrastIndex, sceneYpos, sceneXpos).filter(:, :, :));
                    coneWeightsXYMap = squeeze(coneWeightsXYTMap(:,:,timeBin));
                    coneDecodingMapRGBrepresentation = ones(coneMosaicRows, coneMosaicCols,3);
                    
                    if (max(abs(coneWeightsXYMap(:))) > maxConeDecodingWeight)
                        maxConeDecodingWeight = max(abs(coneWeightsXYMap(:)));
                        timeBinForFinalDisplay = timeBin;
                    end
                    
                    if (timeBin == numel(timeBins))
                        coneWeightsXYMap = squeeze(coneWeightsXYTMap(:,:,timeBinForFinalDisplay));
                    end
                    
                    for coneIndex = 1:decodingFilter.conesNum
                        if ismember(filterConeIDs(coneIndex), lConeIndices)
                            RGBval(coneIndex,:) = [1 0. 0.];
                        elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                            RGBval(coneIndex,:) = [0 1 0.0];
                        elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                            RGBval(coneIndex,:) = [0.0 0 1];
                        else
                            error('No such cone type')
                        end

                        coneDecodingMapRGBrepresentation(coneRowPos(coneIndex), coneColPos(coneIndex), :) = reshape([0.5 0.5 0.5] + 0.5*squeeze(RGBval(coneIndex,:)) * coneWeightsXYMap(coneRowPos(coneIndex), coneColPos(coneIndex)), [1 1 3]);
                    end % coneIndex
            
                    if (coneContrastIndex == 1)
                        axisToDrawOn = spatialProfileLconeDecoderAxes;
                    elseif (coneContrastIndex == 2)
                        axisToDrawOn = spatialProfileMconeDecoderAxes;
                    elseif (coneContrastIndex == 3)
                        axisToDrawOn = spatialProfileSconeDecoderAxes;
                    end
                    
                    
                    imagesc(1:coneMosaicCols, 1:coneMosaicRows, coneDecodingMapRGBrepresentation, 'parent', axisToDrawOn);
                    set(axisToDrawOn, 'CLim', [0 1]);
                    xlabel(axisToDrawOn, 'cone col');
                    ylabel(axisToDrawOn, 'cone row');
                    axis(axisToDrawOn, 'xy')
                    axis(axisToDrawOn, 'image')
                    box(axisToDrawOn, 'on');
     
                    if (coneContrastIndex == 1)
                        axisToDrawOn = temporalProfileLconeDecoderAxes;
                    elseif (coneContrastIndex == 2)
                        axisToDrawOn = temporalProfileMconeDecoderAxes;
                    elseif (coneContrastIndex == 3)
                        axisToDrawOn = temporalProfileSconeDecoderAxes;
                    end
                    
                    if (timeBin == 1)
                        hold(axisToDrawOn, 'on');
                        for coneIndex = 1:decodingFilter.conesNum
                            coneData = squeeze(coneWeightsXYTMap(coneRowPos(coneIndex), coneColPos(coneIndex), 1:timeBin));
                            hT(coneIndex) = line(decodingFilter.timeAxis(1:timeBin), coneData, ...
                                'Color', squeeze(RGBval(coneIndex,:)), 'parent', axisToDrawOn);
                        end
                        hold(axisToDrawOn, 'off');
                        box(axisToDrawOn, 'on');
                        xlabel(axisToDrawOn, 'time (msec)');
                        set(axisToDrawOn, 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)], 'YLim', [-1 1]);
                    else
                        for coneIndex = 1:decodingFilter.conesNum
                            coneData = squeeze(coneWeightsXYTMap(coneRowPos(coneIndex), coneColPos(coneIndex), 1:timeBin));
                            set(hT(coneIndex), 'XData', decodingFilter.timeAxis(1:timeBin), 'YData', coneData);
                        end
                    end
                    

                    if (coneContrastIndex == 1)
                       spatialProfileAxis = spatialProfileLconeDecoderAxes;
                       temporalProfileAxis = temporalProfileLconeDecoderAxes;
                       title(temporalProfileAxis, 'Lcone decoder', 'FontSize', 14);
                    elseif (coneContrastIndex == 2)
                       spatialProfileAxis = spatialProfileMconeDecoderAxes;
                       temporalProfileAxis = temporalProfileMconeDecoderAxes;
                       title(temporalProfileAxis, 'Mcone decoder', 'FontSize', 14);
                    elseif (coneContrastIndex == 3)
                       spatialProfileAxis = spatialProfileSconeDecoderAxes;
                       temporalProfileAxis = temporalProfileSconeDecoderAxes;
                       title(temporalProfileAxis, 'Scone decoder', 'FontSize', 14);
                    end
                    
                    drawnow;
                    
                end  %timeBin
                
                title(spatialProfileAxis, sprintf('t of max response: %d ms', decodingFilter.timeAxis(timeBinForFinalDisplay)), 'FontSize', 14);
                
            end % coneContrastIndex
            pause(1.0);
        end % sceneXpos
    end % sceneYpos

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

