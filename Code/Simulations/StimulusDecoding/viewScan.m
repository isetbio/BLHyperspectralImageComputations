function viewScan

    % Spacify images
    imageSources = {...
    %    {'manchester_database', 'scene1'} ...
    %    {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
    %    {'manchester_database', 'scene4'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    for imageIndex = 1:numel(imageSources)
        imsource = imageSources{imageIndex};
        scanSensor = [];
        scanPlusAdaptationFieldTimeAxis = [];
        scanPlusAdaptationFieldLMSexcitationSequence = [];
        LMSexcitationXdataInRetinalMicrons = [];
        LMSexcitationYdataInRetinalMicrons = [];
        sensorAdaptationFieldParams = [];
        
        
         scanIndex = 5;
            scanFilename = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            whos('-file', scanFilename)
            load(scanFilename, ...
                'oi', 'scene', ...
                'scanSensor', ...
                'photoCurrents', ...
                'scanPlusAdaptationFieldTimeAxis', ...
                'scanPlusAdaptationFieldLMSexcitationSequence', ...
                'LMSexcitationXdataInRetinalMicrons', ...
                'LMSexcitationYdataInRetinalMicrons', ...
                'sensorAdaptationFieldParams');
        
        debug = true;
        if (debug)
            figNum = 200+scanIndex;
            osB = osBioPhys();
            osB.osSet('noiseFlag', 1);
            osB.osCompute(scanSensor);
            osWindow(figNum, 'biophys-based outer segment', osB, scanSensor, oi, scene);
        end
                
        % Substract baseline (determined by the last point in the photocurrent time series)
        referenceBin = round(0.25*sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds/1000/sensorGet(scanSensor, 'time interval'));
        
        photoCurrentBaselineEstimationBins = size(photoCurrents,3)-referenceBin+(-round(referenceBin/2):round(referenceBin/2));
        photoCurrents = bsxfun(@minus, photoCurrents, mean(photoCurrents(:,:, photoCurrentBaselineEstimationBins),3));
        
        % Compute upsampled photocurrent maps for visualization
        fprintf('Upsampling photocurrent maps.\n');
        [LconePhotocurrentMap, MconePhotocurrentMap, SconePhotocurrentMap, photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, ...
            LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateUpsampledSpatialMaps(scanSensor, photoCurrents);

        
        % Compute upsampled isomerization maps for visualization
        fprintf('Upsampling isomerization maps.\n');
        isomerizationRates = sensorGet(scanSensor, 'photon rate');
        [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap, isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, ...
            LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateUpsampledSpatialMaps(scanSensor, isomerizationRates);


        % Displayed range of LMS cone photocurrents (computed from the outer segments)
        photocurrentRange = [...
            min([min(LconePhotocurrentMap(:)) min(MconePhotocurrentMap(:)) min(SconePhotocurrentMap(:))]) ...
            max([max(LconePhotocurrentMap(:)) max(MconePhotocurrentMap(:)) max(SconePhotocurrentMap(:))])...
            ];
        
        % Displayed range of LMS cone excitations (computed from the scene data using Stockman fundamentals)
        coneExcitationRange = [0 max(abs(scanPlusAdaptationFieldLMSexcitationSequence(:)))];
        
        % Displayed range of LMS isomerizations (computed from the sensor)
        isomerizationRange = [0 max([max(LconeIsomerizationMap(:)) max(MconeIsomerizationMap(:)) max(SconeIsomerizationMap(:))])];

        
        % Select last row, first col for each cone for plotting the time-series data
        [~,targetLconeIndex] = max(LconeRows);
        [~,targetMconeIndex] = max(MconeRows);
        [~,targetSconeIndex] = max(SconeRows);
        
        % Determine the equivalent position in the excitation map
        targetLconeXpos = isomerizationMapXdataInRetinalMicrons(LconeCols(targetLconeIndex));
        targetLconeYpos = isomerizationMapYdataInRetinalMicrons(LconeRows(targetLconeIndex));
        targetMconeXpos = isomerizationMapXdataInRetinalMicrons(MconeCols(targetMconeIndex));
        targetMconeYpos = isomerizationMapYdataInRetinalMicrons(MconeRows(targetMconeIndex));
        targetSconeXpos = isomerizationMapXdataInRetinalMicrons(SconeCols(targetSconeIndex));
        targetSconeYpos = isomerizationMapYdataInRetinalMicrons(SconeRows(targetSconeIndex));
        
        % determine the (rows,cols) in excitation map that are within a distance < coneAperture/2 
        % from the position of the target cones
        coneApertureInMicrons = pixelGet(sensorGet(scanSensor, 'pixel'), 'size')/1e-6;
        
        % for target L cone
        [~,targetLconeCenterColInExcitationMap] = min(abs(LMSexcitationXdataInRetinalMicrons - targetLconeXpos));
        [~,targetLconeCenterRowInExcitationMap] = min(abs(LMSexcitationYdataInRetinalMicrons - targetLconeYpos));
        targetLconeColsInExcitationMap = find(abs(LMSexcitationXdataInRetinalMicrons - targetLconeXpos) < 0.5*coneApertureInMicrons(1));
        targetLconeRowsInExcitationMap = find(abs(LMSexcitationYdataInRetinalMicrons - targetLconeYpos) < 0.5*coneApertureInMicrons(2));
        % for target M cone
        [~,targetMconeCenterColInExcitationMap] = min(abs(LMSexcitationXdataInRetinalMicrons - targetMconeXpos));
        [~,targetMconeCenterRowInExcitationMap] = min(abs(LMSexcitationYdataInRetinalMicrons - targetMconeYpos));
        targetMconeColsInExcitationMap = find(abs(LMSexcitationXdataInRetinalMicrons - targetMconeXpos) < 0.5*coneApertureInMicrons(1));
        targetMconeRowsInExcitationMap = find(abs(LMSexcitationYdataInRetinalMicrons - targetMconeYpos) < 0.5*coneApertureInMicrons(2));
        % for target S cone
        [~,targetSconeCenterColInExcitationMap] = min(abs(LMSexcitationXdataInRetinalMicrons - targetSconeXpos));
        [~,targetSconeCenterRowInExcitationMap] = min(abs(LMSexcitationYdataInRetinalMicrons - targetSconeYpos));
        targetSconeColsInExcitationMap = find(abs(LMSexcitationXdataInRetinalMicrons - targetSconeXpos) < 0.5*coneApertureInMicrons(1));
        targetSconeRowsInExcitationMap = find(abs(LMSexcitationYdataInRetinalMicrons - targetSconeYpos) < 0.5*coneApertureInMicrons(2));
  
        % Compute coords of cone aperture outline
        th = [0:10:360]/360*2*pi;
        coneApertureXcoords = cos(th)*coneApertureInMicrons(1)/2;
        coneApertureYcoords = sin(th)*coneApertureInMicrons(2)/2;
        
        
        hFig = figure(1);
        clf;
        set(hFig, 'Color', [0 0 0 ], 'Position', [60 100 2100 1230]);
        colormap(bone(512));
        
        ConeColors = [1 0 0; 0 1 0; 0 0 1];
        currentTime = 0.2;
        timeStep = sensorGet(scanSensor, 'time interval');
        binIndex = round(currentTime/timeStep);
        
        % The time series plots
        for targetCone = 1:3
            subplot('position', [0.02 0.7-(targetCone-1)*0.325 0.6 0.275]);
            hold on;
            
            if (targetCone == 1)
                targetConeRowsInExcitationMap = targetLconeRowsInExcitationMap;
                targetConeColsInExcitationMap = targetLconeColsInExcitationMap;
                targetConePhotoCurrent = squeeze(LconePhotocurrentMap(LconeRows(targetLconeIndex), LconeCols(targetLconeIndex), :));
                targetConeIsomerizationRate = squeeze(LconeIsomerizationMap(LconeRows(targetLconeIndex), LconeCols(targetLconeIndex), :));
                legend4label = 'Lcone isomerization rate';
                legend5label = 'Lcone photocurrent';
                plotTitle = sprintf('Lcone XYpos: (%2.2f, %2.2f)', LMSexcitationXdataInRetinalMicrons(targetLconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetLconeRowsInExcitationMap(2)));
            elseif (targetCone == 2)
                targetConeRowsInExcitationMap = targetMconeRowsInExcitationMap;
                targetConeColsInExcitationMap = targetMconeColsInExcitationMap;
                targetConePhotoCurrent = squeeze(MconePhotocurrentMap(MconeRows(targetMconeIndex), MconeCols(targetMconeIndex), :));
                targetConeIsomerizationRate = squeeze(MconeIsomerizationMap(MconeRows(targetMconeIndex), MconeCols(targetMconeIndex), :));
                legend4label = 'Mcone isomerization rate';
                legend5label = 'Mcone photocurrent';
                plotTitle = sprintf('Mcone XYpos: (%2.2f, %2.2f)', LMSexcitationXdataInRetinalMicrons(targetMconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetMconeRowsInExcitationMap(2)));
            elseif (targetCone == 3)
                targetConeRowsInExcitationMap = targetSconeRowsInExcitationMap;
                targetConeColsInExcitationMap = targetSconeColsInExcitationMap;
                targetConePhotoCurrent = squeeze(SconePhotocurrentMap(SconeRows(targetSconeIndex), SconeCols(targetSconeIndex), :));
                targetConeIsomerizationRate = squeeze(SconeIsomerizationMap(SconeRows(targetSconeIndex), SconeCols(targetSconeIndex), :));
                legend4label = 'Scone isomerization rate';
                legend5label = 'Scone photocurrent';
                plotTitle = sprintf('Scone XYpos: (%2.2f, %2.2f)', LMSexcitationXdataInRetinalMicrons(targetSconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetSconeRowsInExcitationMap(2)));
            end

            % First the Stockman excitations
            for coneIndex = 1:3
                % compute mean excitation in a region of 3x3 scene pixels
                meanConeExcitationInRegion = [];
                for i = 1:numel(targetConeRowsInExcitationMap)
                    for j = 1:numel(targetConeColsInExcitationMap)
                        if isempty(meanConeExcitationInRegion)
                            meanConeExcitationInRegion = squeeze(scanPlusAdaptationFieldLMSexcitationSequence(:, targetConeRowsInExcitationMap(i), targetConeColsInExcitationMap(j), coneIndex));
                        else
                            meanConeExcitationInRegion = meanConeExcitationInRegion + squeeze(scanPlusAdaptationFieldLMSexcitationSequence(:, targetConeRowsInExcitationMap(i), targetConeColsInExcitationMap(j), coneIndex));
                        end
                    end
                end
                meanConeExcitationInRegion = meanConeExcitationInRegion / (numel(targetConeRowsInExcitationMap)*numel(targetConeColsInExcitationMap));
                plot(scanPlusAdaptationFieldTimeAxis, meanConeExcitationInRegion/coneExcitationRange(2), '-', 'LineWidth', 1.0, 'Color', squeeze(ConeColors(coneIndex,:)));
            end % coneIndex
        
            % Then the isomerization rate
            plot(scanPlusAdaptationFieldTimeAxis, targetConeIsomerizationRate/isomerizationRange(2), '-', 'Color', [1.0 1.0 1.0], 'LineWidth', 2.0);

            % Then the photocurrent
            plot(scanPlusAdaptationFieldTimeAxis, targetConePhotoCurrent/abs(photocurrentRange(2)), '-', 'Color', [0.3 0.7 0.7], 'LineWidth', 1.0);

            % Finally, the analysis limits
            plot(scanPlusAdaptationFieldTimeAxis(photoCurrentBaselineEstimationBins(1))*[1 1], [-1 1], '-', 'Color', [0.5 0.5 1.0]);
            plot(scanPlusAdaptationFieldTimeAxis(photoCurrentBaselineEstimationBins(end))*[1 1], [-1 1], '-', 'Color', [0.5 0.5 1.0]);
            currentTimePlotHandles(targetCone) = plot(currentTime*[1 1], [-1 1], 'y--');
            
            title(plotTitle, 'Color', squeeze(ConeColors(targetCone,:)));
            hold off;
            box on
        
            h1 = legend('local Lcone excitation (Stockman)', 'local Mcone excitation (Stockman)', 'local Scone excitation (Stockman)', legend4label, legend5label, 'baselineT1', 'baselineT2', 'Location', 'NorthWest');
            set(h1, 'FontSize', 12, 'Color', [0.2 0.2 0.2], 'TextColor', [0.8 0.8 0.8]);
            set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'FontSize', 12, 'XLim', [scanPlusAdaptationFieldTimeAxis(1) scanPlusAdaptationFieldTimeAxis(end)], 'YLim', [-1 1]);
        
            if (targetCone == 3)
                xlabel('time (sec)');
            end
        end % targetCone
        

        % The cone excitation spatial maps
        for targetCone = 1:3
            subplot('position', [0.64 0.7-(targetCone-1)*0.325 0.11 0.27]);
            
             % Draw spatial maps
            if (targetCone == 1)
                hLconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
                colorbarLabel = 'Lcone excitation (Stockman)';
            elseif (targetCone == 2)
                hMconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
                colorbarLabel = 'Mcone excitation (Stockman)';
            elseif (targetCone == 3)
                hSconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));
                colorbarLabel = 'Scone excitation (Stockman)';
            end
            
            % Draw exemplar cone apertures
            hold on;
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
            hold off;
            
            axis 'ij'
            axis 'image'
            cbarHandle = colorbar(gca, 'northoutside');
            set(cbarHandle, 'Color', [0.7 0.7 0.7], 'FontSize', 12);
            ylabel(cbarHandle, colorbarLabel);
            
            set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []);
            set(gca, 'CLim', coneExcitationRange);
            box on;
        end % targetCone
        
        
        % The mosaic isomerization rate spatial maps
        for targetCone = 1:3
            subplot('position', [0.64+0.12 0.7-(targetCone-1)*0.325 0.11 0.27]);

             % Draw spatial maps
            if (targetCone == 1)
                hLconeIsomerizationMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(LconeIsomerizationMap(:,:,binIndex)));
                colorbarLabel = 'Lcone isomerization rate';
            elseif (targetCone == 2)
                hMconeIsomerizationMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(MconeIsomerizationMap(:,:,binIndex)));
                colorbarLabel = 'Mcone isomerization rate';
            elseif (targetCone == 3)
                hSconeIsomerizationMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(SconeIsomerizationMap(:,:,binIndex)));
                colorbarLabel = 'Scone isomerization rate';
            end
            
            hold on;
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
            hold off;
            
            axis 'ij'
            axis 'image'
            cbarHandle = colorbar(gca, 'northoutside');
            set(cbarHandle, 'Color', [0.7 0.7 0.7], 'FontSize', 12);
            ylabel(cbarHandle, colorbarLabel);
            
            set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []);
            set(gca, 'CLim', isomerizationRange);
            box on;
        end % targetCone
        
        % The mosaic photocurrent spatial maps
         for targetCone = 1:3
            subplot('position', [0.64+2*0.12 0.7-(targetCone-1)*0.325 0.11 0.27]);
            
            % Draw spatial maps
            if (targetCone == 1)
                hLconePhotocurrentMap = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(LconePhotocurrentMap(:,:,binIndex)));
                colorbarLabel = 'Lcone photocurrent';
            elseif (targetCone == 2)
                hMconePhotocurrentMap = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(MconePhotocurrentMap(:,:,binIndex)));
                colorbarLabel = 'Mcone photocurrent';
            elseif (targetCone == 3)
                hSconePhotocurrentMap = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(SconePhotocurrentMap(:,:,binIndex)));
                colorbarLabel = 'Scone photocurrent';
            end
            
            % Draw exemplar cone apertures
            hold on;
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
            plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
            hold off;
            
            axis 'ij'
            axis 'image'
            cbarHandle = colorbar(gca, 'northoutside');
            set(cbarHandle, 'Color', [0.7 0.7 0.7], 'FontSize', 12);
            ylabel(cbarHandle, colorbarLabel);
            
            set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []);
            set(gca, 'CLim', photocurrentRange);
            box on;
         end
         
        % The time slider
        positionVector = [0.005 0.002 0.99 0.02];
        timeSlider = uicontrol(...
                'Parent', hFig,...
                'Style', 'slider',...
                'BackgroundColor',  [0.6 0.6 0.6], ...
                'Min', scanPlusAdaptationFieldTimeAxis(1), 'Max', scanPlusAdaptationFieldTimeAxis(end), 'Value', currentTime,...
                'Units', 'normalized',...
                'Position', positionVector);   
        % set the slider's callback function
        addlistener(timeSlider,'ContinuousValueChange', ...
                   @(hFigure,eventdata) timeSliderCallback(timeSlider,eventdata, currentTimePlotHandles));
            
        drawnow
    end
    
    % Callback for the sensor view slider
    function timeSliderCallback(hObject,eventdata, currentTimePlotHandles)
        currentTime = get(hObject,'Value');
        binIndex = round(currentTime/timeStep);
        set(currentTimePlotHandles(1), 'XData', currentTime*[1 1]);
        set(currentTimePlotHandles(2), 'XData', currentTime*[1 1]);
        set(currentTimePlotHandles(3), 'XData', currentTime*[1 1]);
        
        % Update the Stockman excitation maps
        set(hLconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
        set(hMconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
        set(hSconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));
        
        % Update the isomerization maps
        set(hLconeIsomerizationMap, 'CData', squeeze(LconeIsomerizationMap(:,:,binIndex)));
        set(hMconeIsomerizationMap, 'CData', squeeze(MconeIsomerizationMap(:,:,binIndex)));
        set(hSconeIsomerizationMap, 'CData', squeeze(SconeIsomerizationMap(:,:,binIndex)));
        
        % Update the photocurrent maps
        set(hLconePhotocurrentMap, 'CData',squeeze(LconePhotocurrentMap(:,:,binIndex)));
        set(hMconePhotocurrentMap, 'CData',squeeze(MconePhotocurrentMap(:,:,binIndex)));
        set(hSconePhotocurrentMap, 'CData',squeeze(SconePhotocurrentMap(:,:,binIndex)));
        drawnow
    end

end




function [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap, isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, ...
    LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateUpsampledSpatialMaps(scanSensor, coneSignals)
    
    coneTypes          = sensorGet(scanSensor, 'cone type')-1;
    sensorRowsCols     = sensorGet(scanSensor, 'size');
    sensorSampleSeparationInMicrons = sensorGet(scanSensor,'pixel size','um');
    
    upSampleFactor = 7;  % must be odd
    zeroPadRows = 1; zeroPadCols = 1;
    
    LconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    MconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    SconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    
    LconeRows = [];
    LconeCols = [];
    MconeRows = [];
    MconeCols = [];
    SconeRows = [];
    SconeCols = [];
    
    for coneRow = 1:sensorRowsCols(1)
    for coneCol = 1:sensorRowsCols(2)
       mapRow = (coneRow+zeroPadRows)*upSampleFactor - (upSampleFactor-1)/2;
       mapCol = (coneCol+zeroPadCols)*upSampleFactor - (upSampleFactor-1)/2;     
       coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
       if (coneTypes(coneIndex) == 1)
           LconeRows = [LconeRows mapRow];
           LconeCols = [LconeCols mapCol];
           LconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       elseif (coneTypes(coneIndex) == 2)
           MconeRows = [MconeRows mapRow];
           MconeCols = [MconeCols mapCol];
           MconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       elseif (coneTypes(coneIndex) == 3)
           SconeRows = [SconeRows mapRow];
           SconeCols = [SconeCols mapCol];
           SconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       else
           error('Cone type must be 1, 2 or 3');
       end
    end
    end
    

    if (upSampleFactor > 1)
        % Generate Gaussian kernel
        x = -(upSampleFactor-1)/2:(upSampleFactor-1)/2;
        [X,Y] = meshgrid(x,x);
        sigma = upSampleFactor/3.3;
        gaussianKernel = exp(-0.5*(X/sigma).^2).*exp(-0.5*(Y/sigma).^2);
        gaussianKernel = gaussianKernel / max(gaussianKernel(:));

        for binIndex = 1:size(coneSignals,3)
            LconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(LconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
            MconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(MconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
            SconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(SconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
        end
    end
    
    isomerizationMapXdataInRetinalMicrons = (0:size(LconeIsomerizationMap,2)-1)/(size(LconeIsomerizationMap,2)-1) - 0.5;
    isomerizationMapXdataInRetinalMicrons = isomerizationMapXdataInRetinalMicrons * (sensorRowsCols(2)+zeroPadCols*2)*sensorSampleSeparationInMicrons(1);
    isomerizationMapYdataInRetinalMicrons = (0:size(LconeIsomerizationMap,1)-1)/(size(LconeIsomerizationMap,1)-1) - 0.5;
    isomerizationMapYdataInRetinalMicrons = isomerizationMapYdataInRetinalMicrons * (sensorRowsCols(1)+zeroPadRows*2)*sensorSampleSeparationInMicrons(2);
    
end

