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
    wVectorNormalized = 1.3 * wVector / max(abs(wVector(:)));
    if (1==2)
        % display decoding filter
        fprintf('Displaying DC component of the decoding filter.\n');
        % First display the spatial maps of DC decoding coefficients for L-, M-, and S-cone contrast
        figNo = 1;
        generatePlotOfDCdecodingCoeffs(figNo, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices);
    end
    

    % Then display the spatial map of the coefficients for each 
    fprintf('Displaying the spatiotemporal L-, M- and S-contrast decoder for scene position (1,1)\n');
    figNo = 2;
    generatePlotsOfDecodingMaps(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVectorNormalized, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
end


function generatePlotsOfDecodingMaps(figNo, decodingDirectory, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, wVector, scanSensor, keptLconeIndices, keptMconeIndices, keptSconeIndices, decodingFilter)
    
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons);
    
    dcTerm = 1;
    timeBins = 1:decodingFilter.memoryBins;
    
    % Retrieve cone positions in microns and in (row,col) units
    coneMosaicRows = sensorGet(scanSensor, 'row');
    coneMosaicCols = sensorGet(scanSensor, 'col');
    coneRowPos = zeros(1, decodingFilter.conesNum);
    coneColPos = zeros(1, decodingFilter.conesNum);
    for coneIndex = 1:decodingFilter.conesNum
        [coneRowPos(coneIndex), coneColPos(coneIndex)] = ind2sub([coneMosaicRows coneMosaicCols], filterConeIDs(coneIndex));
    end
    coneXYpositions = sensorGet(scanSensor, 'xy');
    coneXpositions = sort(unique(coneXYpositions(:,1)));
    coneYpositions = sort(unique(coneXYpositions(:,2)));
    
    % Retrieve the cone types
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    coneName = {'L', 'M', 'S'};
    
    % Compute the stimDecoder(coneContrastIndex, stimYps, stimXpos) filters
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
    
    
    
    satExponent = 1.0;
    satGain = 1.0;

    % Compute stimulus X- and Y- spatial extents for plotting
    dx = 0.0*(filterSpatialXdataInRetinalMicrons(2)-filterSpatialXdataInRetinalMicrons(1));
    dy = 0.0*(filterSpatialYdataInRetinalMicrons(2)-filterSpatialYdataInRetinalMicrons(1));
    dx = 0.5*(coneXpositions(2)-coneXpositions(1));
    dy = 0.5*(coneYpositions(2)-coneYpositions(1));
    XLims = [coneXpositions(1)-dx coneXpositions(end)+dx]; % [filterSpatialXdataInRetinalMicrons(1)-dx filterSpatialXdataInRetinalMicrons(end)+dx];
    YLims = [coneYpositions(1)-dx coneYpositions(end)+dx]; % [filterSpatialYdataInRetinalMicrons(1)-dy filterSpatialYdataInRetinalMicrons(end)+dy];
   
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 4, ...
               'heightMargin',   0.08, ...
               'widthMargin',    0.03, ...
               'leftMargin',     0.04, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.06, ...
               'topMargin',      0.03);
           
    videoFilename = sprintf('%s/DecodingFilterAnimation.m4v', decodingDirectory);
    fprintf('Will export video to %s\n', videoFilename);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    

    for sceneYpos = 2 : 1 : numel(filterSpatialYdataInRetinalMicrons)-1
        for sceneXpos = 2 : 1 : numel(filterSpatialXdataInRetinalMicrons)-1
            
            % compute the outline of the decoded region
            stimSizeX = (filterSpatialXdataInRetinalMicrons(end)-filterSpatialXdataInRetinalMicrons(1))/numel(filterSpatialXdataInRetinalMicrons);
            stimSizeY = (filterSpatialYdataInRetinalMicrons(end)-filterSpatialYdataInRetinalMicrons(1))/numel(filterSpatialYdataInRetinalMicrons);
            stimOutlineX = filterSpatialXdataInRetinalMicrons(sceneXpos) + 0.5*[-1 -1 1 1 -1]*stimSizeX;
            stimOutlineY = filterSpatialYdataInRetinalMicrons(sceneYpos) + 0.5*[-1 1 1 -1 -1]*stimSizeY;
            stimOutlineCenter = [filterSpatialXdataInRetinalMicrons(sceneXpos) filterSpatialYdataInRetinalMicrons(sceneYpos)];
            crossHairX(1,:) = stimOutlineCenter(1)*[1 1];
            crossHairY(1,:) = max(stimOutlineY)+[0 5];
            crossHairX(2,:) = stimOutlineCenter(1)*[1 1];
            crossHairY(2,:) = min(stimOutlineY)-[0 5];
            crossHairX(3,:) = max(stimOutlineX)+[0 5];
            crossHairY(3,:) = stimOutlineCenter(2)*[1 1];
            crossHairX(4,:) = min(stimOutlineX)-[0 5];
            crossHairY(4,:) = stimOutlineCenter(2)*[1 1];
            
            % clear figure and generate axes
            hFig = figure(figNo); clf;
            set(hFig, 'Position', [10 10 1775 940]);
            stimulusPositionAxes = axes('parent', hFig, 'unit','normalized','position',[subplotPosVectors(1,1).v(1) 0.5*(subplotPosVectors(1,1).v(2) + subplotPosVectors(2,1).v(2)) subplotPosVectors(1,1).v(3) subplotPosVectors(1,1).v(4)]);
            temporalProfileLconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,2).v, 'Color', [0 0 0].^(1/satExponent));
            spatialProfileLconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,2).v, 'Color', [0.5 0.5 0.5].^(1/satExponent));
            temporalProfileMconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,3).v, 'Color', [0 0 0].^(1/satExponent));
            spatialProfileMconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,3).v, 'Color', [0.5 0.5 0.5].^(1/satExponent));
            temporalProfileSconeDecoderAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,4).v, 'Color', [0 0 0].^(1/satExponent));
            spatialProfileSconeDecoderAxes  = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,4).v, 'Color', [0.5 0.5 0.5].^(1/satExponent));
            
            axis(stimulusPositionAxes, 'square');
            axis(temporalProfileLconeDecoderAxes, 'square');
            axis(spatialProfileLconeDecoderAxes, 'square');
            axis(temporalProfileMconeDecoderAxes, 'square');
            axis(spatialProfileMconeDecoderAxes, 'square');
            axis(temporalProfileSconeDecoderAxes, 'square');
            axis(spatialProfileSconeDecoderAxes, 'square');
            
            % Initialize the spatial profile density plots
            axesToDrawOn = {spatialProfileLconeDecoderAxes, spatialProfileMconeDecoderAxes, spatialProfileSconeDecoderAxes};
            for coneContrastIndex = 1:numel(axesToDrawOn)
                axisToDrawOn = axesToDrawOn{coneContrastIndex};
                
                grayImage = 0.5*ones(numel(coneYpositions), numel(coneXpositions),3);
                densityPlot(coneContrastIndex) = imagesc(coneXpositions, coneYpositions, grayImage.^(1/satExponent), 'parent', axisToDrawOn);
                
                % The cross-hairs
                hold(axisToDrawOn, 'on');
                stimulusOutlinePlot1(coneContrastIndex) = plot(axisToDrawOn, stimOutlineX, stimOutlineY, 'k-', 'LineWidth', 2.0);
                stimulusOutlinePlot2(coneContrastIndex) = plot(axisToDrawOn, stimOutlineX, stimOutlineY, 'k-', 'LineWidth', 2.0);
                stimulusOutlinePlot3(coneContrastIndex) = plot(axisToDrawOn, squeeze(crossHairX(1,:)), squeeze(crossHairY(1,:)), 'k-', 'LineWidth', 2.0);
                stimulusOutlinePlot4(coneContrastIndex) = plot(axisToDrawOn, squeeze(crossHairX(2,:)), squeeze(crossHairY(2,:)), 'k-', 'LineWidth', 2.0);
                stimulusOutlinePlot5(coneContrastIndex) = plot(axisToDrawOn, squeeze(crossHairX(3,:)), squeeze(crossHairY(3,:)), 'k-', 'LineWidth', 2.0);
                stimulusOutlinePlot6(coneContrastIndex) = plot(axisToDrawOn, squeeze(crossHairX(4,:)), squeeze(crossHairY(4,:)), 'k-', 'LineWidth', 2.0);
                hold(axisToDrawOn, 'off');
                        
                axis(axisToDrawOn, 'xy')
                axis(axisToDrawOn, 'image');
                set(axisToDrawOn, 'CLim', [0 1],'XLim', XLims, 'YLim', YLims, 'FontSize', 12);
                set(axisToDrawOn, 'XTick', filterSpatialXdataInRetinalMicrons, 'YTick', filterSpatialYdataInRetinalMicrons);
                set(axisToDrawOn, 'XTickLabel', sprintf('%2.0f\n', filterSpatialXdataInRetinalMicrons), 'YTickLabel', sprintf('%2.0f\n', filterSpatialYdataInRetinalMicrons));
                xlabel(axisToDrawOn, 'microns', 'FontSize', 14);
                if (coneContrastIndex == 1)
                    ylabel(axisToDrawOn, 'microns', 'FontSize', 14);
                else
                    set(axisToDrawOn, 'YTickLabel', {});
                end
                grid(axisToDrawOn, 'on');
                drawnow;
            end
            
            % Initialize the temporal profile plots
            axesToDrawOn = {temporalProfileLconeDecoderAxes, temporalProfileMconeDecoderAxes, temporalProfileSconeDecoderAxes};
            for coneContrastIndex = 1:numel(axesToDrawOn)
                axisToDrawOn = axesToDrawOn{coneContrastIndex};
                if (coneContrastIndex == 1)
                   ylabel(axisToDrawOn, 'decoding coefficient', 'FontSize', 12);
                else
                   set(axisToDrawOn, 'YTickLabel', {});
                end
                        
                xlabel(axisToDrawOn, 'time (msec)', 'FontSize', 12);
                set(axisToDrawOn, 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)], 'YLim', [-1 1], 'FontSize', 12);
            end
            

            % Go through each cone contrast
            for coneContrastIndex = 1:3
                
                % Generate and display the stimulus position density plot
                stimulusPosition = 0.5*ones(numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
                if (coneContrastIndex == 1)
                    RGBval = [1 0.2 0.5];
                elseif (coneContrastIndex == 2)
                    RGBval = [0.2 1 0.5];
                else
                    RGBval = [0.5 0.2 1];
                end
                stimulusPosition(sceneYpos, sceneXpos, :) = reshape(RGBval, [1 1 3]);

                imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, stimulusPosition.^(1/satExponent), 'parent', stimulusPositionAxes);
                axis(stimulusPositionAxes, 'xy');
                axis(stimulusPositionAxes, 'image');
                set(stimulusPositionAxes, 'XLim', XLims, 'YLim', YLims, 'FontSize', 12);
                set(stimulusPositionAxes, 'XTick', filterSpatialXdataInRetinalMicrons, 'YTick', filterSpatialYdataInRetinalMicrons);
                set(stimulusPositionAxes, 'XTickLabel', sprintf('%2.0f\n', filterSpatialXdataInRetinalMicrons), 'YTickLabel', sprintf('%2.0f\n', filterSpatialYdataInRetinalMicrons));
                xlabel(stimulusPositionAxes, 'microns', 'FontSize', 14);
                ylabel(stimulusPositionAxes, 'microns', 'FontSize', 14);
                grid(stimulusPositionAxes, 'on');
                title(stimulusPositionAxes, sprintf('decoded position, %s-cone contrast', coneName{coneContrastIndex}), 'FontSize', 14);
                RGBval = zeros(decodingFilter.conesNum,3);
                
                % Now go through each time bin and plot the spatial profile
                % density plot at that time bin as well as the temporal
                % profile up to that time bin
                maxConeDecodingWeight = 0;
                for timeBin = 1:numel(timeBins)
                
                    set(hFig, 'Name', sprintf('time = %d ms', decodingFilter.timeAxis(timeBin)));
                    
                    coneWeightsXYTMap = squeeze(stimDecoder(coneContrastIndex, sceneYpos, sceneXpos).filter(:, :, :));
                    coneWeightsXYMap = squeeze(coneWeightsXYTMap(:,:,timeBin));
                    coneDecodingMapRGBrepresentation = nan(coneMosaicRows, coneMosaicCols,3);
                    
                    if (max(abs(coneWeightsXYMap(:))) > maxConeDecodingWeight)
                        maxConeDecodingWeight = max(abs(coneWeightsXYMap(:)));
                        timeBinForFinalDisplay = timeBin;
                    end
                    
                    if (timeBin == numel(timeBins))
                        coneWeightsXYMap = squeeze(coneWeightsXYTMap(:,:,timeBinForFinalDisplay));
                    end
                    
                    for coneIndex = 1:decodingFilter.conesNum
                        if ismember(filterConeIDs(coneIndex), lConeIndices)
                            RGBval(coneIndex,:) = [1 -1 0.2];
                        elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                            RGBval(coneIndex,:) = [-1 1 0.2];
                        elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                            RGBval(coneIndex,:) = [-0.5 -0.5 1];
                        else
                            error('No such cone type')
                        end
                        coneDecodingMapRGBrepresentation(coneRowPos(coneIndex), coneColPos(coneIndex), :) = reshape([0.5 0.5 0.5] + 0.5*satGain*squeeze(RGBval(coneIndex,:)) * coneWeightsXYMap(coneRowPos(coneIndex), coneColPos(coneIndex)), [1 1 3]);
                    end % coneIndex
            
                    % avoid out of gamut
                    coneDecodingMapRGBrepresentation(coneDecodingMapRGBrepresentation(:)> 1) = 1;
                    coneDecodingMapRGBrepresentation(coneDecodingMapRGBrepresentation(:)< 0) = 0;
                    
                    if (coneContrastIndex == 1)
                        axisToDrawOn = spatialProfileLconeDecoderAxes;
                    elseif (coneContrastIndex == 2)
                        axisToDrawOn = spatialProfileMconeDecoderAxes;
                    elseif (coneContrastIndex == 3)
                        axisToDrawOn = spatialProfileSconeDecoderAxes;
                    end
                    
                    % Update the spatial profiles
                    set(densityPlot(coneContrastIndex), 'CData', coneDecodingMapRGBrepresentation.^(1/satExponent));
                    set(stimulusOutlinePlot1(coneContrastIndex), 'XData', stimOutlineX, 'YData', stimOutlineY);
                    set(stimulusOutlinePlot2(coneContrastIndex), 'XData', stimOutlineX, 'YData', stimOutlineY);
                    set(stimulusOutlinePlot3(coneContrastIndex), 'XData', squeeze(crossHairX(1,:)), 'YData', squeeze(crossHairY(1,:)));
                    set(stimulusOutlinePlot4(coneContrastIndex), 'XData', squeeze(crossHairX(2,:)), 'YData', squeeze(crossHairY(2,:)));
                    set(stimulusOutlinePlot5(coneContrastIndex), 'XData', squeeze(crossHairX(3,:)), 'YData', squeeze(crossHairY(3,:)));
                    set(stimulusOutlinePlot6(coneContrastIndex), 'XData', squeeze(crossHairX(4,:)), 'YData', squeeze(crossHairY(4,:)));
                     
                    
                    % Now update the the temporal profiles
                    if (coneContrastIndex == 1)
                        axisToDrawOn = temporalProfileLconeDecoderAxes;
                    elseif (coneContrastIndex == 2)
                        axisToDrawOn = temporalProfileMconeDecoderAxes;
                    elseif (coneContrastIndex == 3)
                        axisToDrawOn = temporalProfileSconeDecoderAxes;
                    end
                    
                    if (timeBin == 1)
                        for coneIndex = 1:decodingFilter.conesNum
                            lineColor = [0.5 0.5 0.5] + 0.5*satGain*squeeze(RGBval(coneIndex,:));
                            lineColor(lineColor<0) = 0;
                            lineColor(lineColor>1) = 1;
                            coneData = squeeze(coneWeightsXYTMap(coneRowPos(coneIndex), coneColPos(coneIndex), 1:timeBin));
                            hT(coneIndex) = line(decodingFilter.timeAxis(1:timeBin), coneData, ...
                                'Color', lineColor, 'LineWidth', 1.0, 'parent', axisToDrawOn);
                            if (coneIndex == 1)
                                hold(axisToDrawOn, 'on');
                            end
                        end
                        hold(axisToDrawOn, 'off');
                        box(axisToDrawOn, 'on');
                        if (coneContrastIndex == 1)
                            ylabel(axisToDrawOn, 'decoding coefficient', 'FontSize', 12);
                        else
                            set(axisToDrawOn, 'YTickLabel', {});
                        end
                        
                        xlabel(axisToDrawOn, 'time (msec)', 'FontSize', 12);
                        set(axisToDrawOn, 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)], 'YLim', [-0.5 1], 'FontSize', 12);
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
                    writerObj.writeVideo(getframe(hFig));
                end  %timeBin
                
                title(spatialProfileAxis, sprintf('max response latency: %d ms', decodingFilter.timeAxis(timeBinForFinalDisplay)), 'FontSize', 14);
                
            end % coneContrastIndex
            pause(1.0);
        end % sceneXpos
    end % sceneYpos

    writerObj.close();
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

