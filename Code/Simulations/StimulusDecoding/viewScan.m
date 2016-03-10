function viewScan(configuration)

    % cd to here
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    [trainingImageSet, ~, ~, ~, ~] = configureExperiment(configuration);
    % select an image
    imageIndex = input(sprintf('Enter image index [1 - %d]: ', numel(trainingImageSet)));
    imsource = trainingImageSet{imageIndex};
    
    % See how many scan files there are for this image
    scanFilename = sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2});
    load(scanFilename, 'scansNum');
    
    scanIndex = input(sprintf('Enter scan index [1 - %d]: ', scansNum));
    scanFilename = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
    
    % This is useful for debugging
    showSensorWindow = true;
    if (showSensorWindow)
        loadSceneAndDispleySensorWindow(imsource, scanFilename, scanIndex);
    end

    % view the selected scan
    viewSelectedScan(scanFilename, scanIndex);
end

function [scene, oi] = loadSceneAndDispleySensorWindow(imsource, scanFilename, scanIndex)
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    client.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
    [artifactData, artifactInfo] = client.readArtifact(imsource{2}, 'type', 'mat');
    if ismember('scene', fieldnames(artifactData))
        fprintf('Fetched scene contains uncompressed scene data.\n');
        scene = artifactData.scene;
    else
        fprintf('Fetched scene contains compressed scene data.\n');
        %scene = sceneFromBasis(artifactData);
        scene = uncompressScene(artifactData);
    end
    fprintf('Done fetching data.\n');

    % Load scan sensor and forcedScene mean luminance
    load(scanFilename, 'forcedSceneMeanLuminance', 'scanSensor');
    
    % Set mean luminance of all scenes to same value
    scene = sceneAdjustLuminance(scene, forcedSceneMeanLuminance);

    % Compute optical image with human optics
    oi = oiCreate('human');
    oi = oiCompute(oi, scene);
    
    figNum = 200+scanIndex;
    osB = osBioPhys();
    osB.osSet('noiseFlag', 1);
    fprintf(2,'Computed outersegment response (for visualization) using time step: %2.2f msec.\nThis may be different from the time step used in the actual computation.\n', sensorGet(scanSensor, 'time interval')*1000);
    osB.osCompute(scanSensor);
    osWindow(figNum, 'biophys-based outer segment', 'horizontalLayout', osB, scanSensor, oi, scene);

    % clear what we do not need
    varList = {'osB', 'oi', 'scene'};
    clear(varList{:});
end


function viewSelectedScan(scanFilename, scanIndex)
  
    % Reset all fields
    scanSensor = [];
    scanPlusAdaptationFieldLMSexcitationSequence = [];
    LMSexcitationXdataInRetinalMicrons = [];
    LMSexcitationYdataInRetinalMicrons = [];
    sensorAdaptationFieldParams = [];
    photoCurrents = [];
    
    % load scan data
    load(scanFilename, ...
        'scanSensor', ...
        'photoCurrents', ...
        'scanPlusAdaptationFieldLMSexcitationSequence', ...
        'LMSexcitationXdataInRetinalMicrons', ...
        'LMSexcitationYdataInRetinalMicrons', ...
        'sensorAdaptationFieldParams');
      
    timeStep = sensorGet(scanSensor, 'time interval');
    scanPlusAdaptationFieldTimeAxis = (0:(round(sensorGet(scanSensor, 'total time')/timeStep)-1))*timeStep;
    
    % Compute baseline estimation bins (determined by the last points in the photocurrent time series)
    referenceBin = round(0.50*sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds/1000/timeStep);
    baselineEstimationBins = size(photoCurrents,3)-referenceBin+(-round(referenceBin/2):round(referenceBin/2));
    fprintf('Offsetting photocurrents by their baseline levels (estimated in [%2.2f - %2.2f] seconds.\n', baselineEstimationBins(1)*timeStep, baselineEstimationBins(end)*timeStep);
    
    % substract baseline from photocurrents
    photoCurrents = bsxfun(@minus, photoCurrents, mean(photoCurrents(:,:, baselineEstimationBins),3));

    % substract baseline from isomerization rates
    isomerizationRates = sensorGet(scanSensor, 'photon rate');
    % isomerizationRates = bsxfun(@minus, isomerizationRates, mean(isomerizationRates(:,:, baselineEstimationBins),3));
    
    %scanPlusAdaptationFieldLMSexcitationSequence = bsxfun(@minus, scanPlusAdaptationFieldLMSexcitationSequence, mean(scanPlusAdaptationFieldLMSexcitationSequence(baselineEstimationBins,:,:,:),1));
    
    % Compute upsampled photocurrent maps for visualization
    fprintf('Upsampling photocurrent maps.\n');
    [LconePhotocurrentMap, MconePhotocurrentMap, SconePhotocurrentMap, photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, ...
        LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateUpsampledSpatialMaps(scanSensor, photoCurrents);

    % Compute upsampled isomerization maps for visualization
    fprintf('Upsampling isomerization maps.\n');
    
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
        
    % Compute coords of cone aperture outline
    thetas = [0:10:360]/360*2*pi;
    coneApertureInMicrons = pixelGet(sensorGet(scanSensor, 'pixel'), 'size')/1e-6;
    coneApertureXcoords = cos(thetas)*coneApertureInMicrons(1)/2;
    coneApertureYcoords = sin(thetas)*coneApertureInMicrons(2)/2;
    
    % determine the (rows,cols) in excitation map that are within a distance < coneAperture/2 
    % from the position of the target cones
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

    
    hFig = figure(1000+scanIndex);
    clf; set(hFig, 'Color', [0 0 0 ], 'Position', [60 100 1880 1100]);
    colormap(bone(512));
        
    ConeColors = [1 0 0; 0 1 0; 0 0 1];
    % Initial visualization time
    currentTime = 0.2;
    
    binIndex = round(currentTime/timeStep);

    % Generate the time series plots
    for targetCone = 1:3
        subplot('position', [0.02 0.7-(targetCone-1)*0.325 0.6 0.275]);
        hold on;

        if (targetCone == 1)
            targetConeRowsInExcitationMap = targetLconeRowsInExcitationMap;
            targetConeColsInExcitationMap = targetLconeColsInExcitationMap;
            targetConePhotoCurrent = squeeze(LconePhotocurrentMap(LconeRows(targetLconeIndex), LconeCols(targetLconeIndex), :));
            targetConeIsomerizationRate = squeeze(LconeIsomerizationMap(LconeRows(targetLconeIndex), LconeCols(targetLconeIndex), :));
            legend4label = 'L-cone isomerization rate';
            legend5label = 'L-cone photocurrent';
            plotTitle = sprintf('XYpos = [%2.2f, %2.2f] (L-cone)', LMSexcitationXdataInRetinalMicrons(targetLconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetLconeRowsInExcitationMap(2)));
        elseif (targetCone == 2)
            targetConeRowsInExcitationMap = targetMconeRowsInExcitationMap;
            targetConeColsInExcitationMap = targetMconeColsInExcitationMap;
            targetConePhotoCurrent = squeeze(MconePhotocurrentMap(MconeRows(targetMconeIndex), MconeCols(targetMconeIndex), :));
            targetConeIsomerizationRate = squeeze(MconeIsomerizationMap(MconeRows(targetMconeIndex), MconeCols(targetMconeIndex), :));
            legend4label = 'M-cone isomerization rate';
            legend5label = 'M-cone photocurrent';
            plotTitle = sprintf('XYpos = [%2.2f, %2.2f] (M-cone)', LMSexcitationXdataInRetinalMicrons(targetMconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetMconeRowsInExcitationMap(2)));
        elseif (targetCone == 3)
            targetConeRowsInExcitationMap = targetSconeRowsInExcitationMap;
            targetConeColsInExcitationMap = targetSconeColsInExcitationMap;
            targetConePhotoCurrent = squeeze(SconePhotocurrentMap(SconeRows(targetSconeIndex), SconeCols(targetSconeIndex), :));
            targetConeIsomerizationRate = squeeze(SconeIsomerizationMap(SconeRows(targetSconeIndex), SconeCols(targetSconeIndex), :));
            legend4label = 'S-cone isomerization rate';
            legend5label = 'S-cone photocurrent';
            plotTitle = sprintf('XYpos = [%2.2f, %2.2f] (S-cone)', LMSexcitationXdataInRetinalMicrons(targetSconeColsInExcitationMap(2)), LMSexcitationYdataInRetinalMicrons(targetSconeRowsInExcitationMap(2)));
        end

        % First the locally-averaged L,M,S - fundamental (Stockman) excitations
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

        % Then the isomerization rate for the target cone
        plot(scanPlusAdaptationFieldTimeAxis, targetConeIsomerizationRate/isomerizationRange(2), '-', 'Color', [1.0 1.0 1.0], 'LineWidth', 2.0);

        % Then the photocurrent for the current cone
        plot(scanPlusAdaptationFieldTimeAxis, targetConePhotoCurrent/abs(photocurrentRange(2)), '-', 'Color', [0.3 0.7 0.7], 'LineWidth', 1.0);

        % Finally, the limits for computing the baseline correction
        plot(scanPlusAdaptationFieldTimeAxis(baselineEstimationBins(1))*[1 1], [-1 1], '-', 'Color', [0.5 0.5 1.0]);
        plot(scanPlusAdaptationFieldTimeAxis(baselineEstimationBins(end))*[1 1], [-1 1], '-', 'Color', [0.5 0.5 1.0]);
        currentTimePlotHandles(targetCone) = plot(currentTime*[1 1], [-1 1], 'y--');
        hold off;
        box on

        h1 = legend('local L-fund excitation (Stockman)', 'local M-fund excitation (Stockman)', 'local S-fund excitation (Stockman)', legend4label, legend5label);
        set(h1, 'Location', 'SouthWest', 'FontSize', 12, 'Color', [0.2 0.2 0.2], 'TextColor', [0.8 0.8 0.8]);
        set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'FontSize', 12, 'XLim', [scanPlusAdaptationFieldTimeAxis(1) scanPlusAdaptationFieldTimeAxis(end)], 'YLim', [-1 1]);

        if (targetCone == 3)
            xlabel('time (sec)');
        end

        title(plotTitle, 'Color', squeeze(ConeColors(targetCone,:)));
    end % targetCone


    % The cone excitation spatial maps
    for targetCone = 1:3
        subplot('position', [0.64 0.7-(targetCone-1)*0.325 0.11 0.27]);

        % Draw spatial maps
        if (targetCone == 1)
            coneExcitationMapHandles(targetCone) = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
            colorbarLabel = 'L-fundamental excitation (Stockman)';
        elseif (targetCone == 2)
            coneExcitationMapHandles(targetCone) = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
            colorbarLabel = 'M-fundamental excitation (Stockman)';
        elseif (targetCone == 3)
            coneExcitationMapHandles(targetCone)= imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));
            colorbarLabel = 'S-fundamental excitation (Stockman)';
        end

        % Superimpose aperture for this target cone
        hold on;
        if (targetCone == 1)
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
        end
        if (targetCone == 2)
             plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
        end
        if (targetCone == 3)
             plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
        end
        hold off;

        axis 'ij'; axis 'image';
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
            coneIsomerizationMapHandles(targetCone) = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(LconeIsomerizationMap(:,:,binIndex)));
            colorbarLabel = 'L mosaic isom. rate (R*/sec)';
        elseif (targetCone == 2)
            coneIsomerizationMapHandles(targetCone) = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(MconeIsomerizationMap(:,:,binIndex)));
            colorbarLabel = 'M mosaic isom. rate (R*/sec)';
        elseif (targetCone == 3)
            coneIsomerizationMapHandles(targetCone) = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(SconeIsomerizationMap(:,:,binIndex)));
            colorbarLabel = 'S mosaic isom. rate (R*/sec)';
        end

        % Superimpose aperture for this cone
        hold on;
        if (targetCone == 1)
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
        end
        if (targetCone == 2)
             plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
        end
        if (targetCone == 3)
             plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
        end
        hold off;

        axis 'ij'; axis 'image';
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
            conePhotocurrentMapHandles(targetCone) = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(LconePhotocurrentMap(:,:,binIndex)));
            colorbarLabel = 'L mosaic photocurrent (pA)';
        elseif (targetCone == 2)
            conePhotocurrentMapHandles(targetCone) = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(MconePhotocurrentMap(:,:,binIndex)));
            colorbarLabel = 'M mosaic photocurrent (pA)';
        elseif (targetCone == 3)
            conePhotocurrentMapHandles(targetCone) = imagesc(photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, squeeze(SconePhotocurrentMap(:,:,binIndex)));
            colorbarLabel = 'S mosaic photocurrent (pA)';
        end

        % Superimpose aperture for this cone
        hold on;
        if (targetCone == 1)
            plot(LMSexcitationXdataInRetinalMicrons(targetLconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetLconeCenterRowInExcitationMap)+coneApertureYcoords, 'r-', 'LineWidth', 2.0);
        end
        if (targetCone == 2)
             plot(LMSexcitationXdataInRetinalMicrons(targetMconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetMconeCenterRowInExcitationMap)+coneApertureYcoords, 'g-', 'LineWidth', 2.0);
        end
        if (targetCone == 3)
             plot(LMSexcitationXdataInRetinalMicrons(targetSconeCenterColInExcitationMap)+coneApertureXcoords, LMSexcitationYdataInRetinalMicrons(targetSconeCenterRowInExcitationMap)+coneApertureYcoords, 'b-', 'LineWidth', 2.0);
        end
        hold off;

        axis 'ij'; axis 'image';
        cbarHandle = colorbar(gca, 'northoutside');
        set(cbarHandle, 'Color', [0.7 0.7 0.7], 'FontSize', 12);
        ylabel(cbarHandle, colorbarLabel);

        set(gca, 'Color', [0.2 0.2 0.2], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []);
        set(gca, 'CLim', photocurrentRange);
        box on;
    end

    % Render fingure
    drawnow;
    
    
    
    % Add a time slider at the bottom and its callback function
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
               @(hFigure,eventdata) timeSliderCallback(timeSlider,eventdata, currentTimePlotHandles, coneExcitationMapHandles, coneIsomerizationMapHandles, conePhotocurrentMapHandles));


    % Callback for the time slider
    function timeSliderCallback(hObject, eventdata, currentTimePlotHandles, coneExcitationMapHandles, coneIsomerizationMapHandles, conePhotocurrentMapHandles)
        currentTime = get(hObject,'Value');
        binIndex = round(currentTime/timeStep);
        set(currentTimePlotHandles(1), 'XData', currentTime*[1 1]);
        set(currentTimePlotHandles(2), 'XData', currentTime*[1 1]);
        set(currentTimePlotHandles(3), 'XData', currentTime*[1 1]);

        % Update the Stockman excitation maps
        set(coneExcitationMapHandles(1), 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
        set(coneExcitationMapHandles(2), 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
        set(coneExcitationMapHandles(3), 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));

        % Update the isomerization maps
        set(coneIsomerizationMapHandles(1), 'CData', squeeze(LconeIsomerizationMap(:,:,binIndex)));
        set(coneIsomerizationMapHandles(2), 'CData', squeeze(MconeIsomerizationMap(:,:,binIndex)));
        set(coneIsomerizationMapHandles(3), 'CData', squeeze(SconeIsomerizationMap(:,:,binIndex)));

        % Update the photocurrent maps
        set(conePhotocurrentMapHandles(1), 'CData', squeeze(LconePhotocurrentMap(:,:,binIndex)));
        set(conePhotocurrentMapHandles(2), 'CData', squeeze(MconePhotocurrentMap(:,:,binIndex)));
        set(conePhotocurrentMapHandles(3), 'CData', squeeze(SconePhotocurrentMap(:,:,binIndex)));
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
       mapRow = (coneRow+zeroPadRows)*upSampleFactor - (upSampleFactor-1)/2-1;
       mapCol = (coneCol+zeroPadCols)*upSampleFactor - (upSampleFactor-1)/2-1;     
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

function scene = uncompressScene(artifactData)
    basis      = artifactData.basis;
    comment    = artifactData.comment;
    illuminant = artifactData.illuminant;
    mcCOEF     = artifactData.mcCOEF;
    save('tmp.mat', 'basis', 'comment', 'illuminant', 'mcCOEF');
    wList = 380:5:780;
    scene = sceneFromFile('tmp.mat', 'multispectral', [],[],wList);
    scene = sceneSet(scene, 'distance', artifactData.dist);
    scene = sceneSet(scene, 'wangular', artifactData.fov);
    delete('tmp.mat');
end