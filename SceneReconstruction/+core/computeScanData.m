function computeScanData(scene,  oi,  sensor, sensorFixationTimes, ...
    sceneAdaptingField, oiAdaptingField, sensorAdaptingField, sensorAdaptingFieldFixationTimes, ...
    fixationsPerScan, consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
    decodedSceneSpatialSampleSizeInRetinalMicrons, extraMicronsAroundSensorBorder)

    % Compute the scene's retinal projection, x- & y- spatial supports
    [sceneResampledToDecoderResolution, sceneRetinalProjectionXData, sceneRetinalProjectionYData] = ...
        computeResampledRetinalScene(scene, oi, decodedSceneSpatialSampleSizeInRetinalMicrons);
    
    [sceneAdaptingFieldResampledToDecoderResolution, ~, ~] = ...
        computeResampledRetinalScene(sceneAdaptingField, oiAdaptingField, decodedSceneSpatialSampleSizeInRetinalMicrons);
    
    % Compute sensor positions in microns - also force sensor to be within scene's retinal projection limits
    [sensorPositionsInMicrons, sensorFOVHalfWidthInMicrons, sensorFOVHalfHeightInMicrons] = retrieveSensorPositionsAndSizeInMicrons(sensor, sceneRetinalProjectionXData, sceneRetinalProjectionYData, extraMicronsAroundSensorBorder);

    % resample the optical images to decoder resolution
    oiResampledToDecoderResolution = oiSpatialResample(oi, decodedSceneSpatialSampleSizeInRetinalMicrons,'um', 'linear', false);
    oiAdaptingFieldResampledToDecoderResolution = oiSpatialResample(oiAdaptingField, decodedSceneSpatialSampleSizeInRetinalMicrons,'um', 'linear', false);
    
    % Retrieve oi spatial support
    oiSupportInMicrons = oiGet(oiResampledToDecoderResolution,'spatial support','microns');
    opticalImageXData = squeeze(oiSupportInMicrons(1,:,1));
    opticalImageYData = squeeze(oiSupportInMicrons(:,1,2));
    
    % Compute StockmanSharpe 2 deg LMS excitations for scene and optical image (stimulus + adaptingField)
    sceneLMS              = core.imageFromSceneOrOpticalImage(sceneResampledToDecoderResolution, 'LMS');
    oiLMS                 = core.imageFromSceneOrOpticalImage(oiResampledToDecoderResolution, 'LMS');
    sceneAdaptingFieldLMS = core.imageFromSceneOrOpticalImage(sceneAdaptingFieldResampledToDecoderResolution, 'LMS');
    oiAdaptingFielLdMS    = core.imageFromSceneOrOpticalImage(oiAdaptingFieldResampledToDecoderResolution, 'LMS');
    
    % compute sensor extent in pixels and microns
    sensorFOVHalfCols = round(sensorFOVHalfWidthInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVHalfRows = round(sensorFOVHalfHeightInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVRowRange = (-sensorFOVHalfRows : 1 : sensorFOVHalfRows);
    sensorFOVColRange = (-sensorFOVHalfCols : 1 : sensorFOVHalfCols);
    sensorFOVxaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVColRange;
    sensorFOVyaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVRowRange;
    
    % Get isomerizations
    isomerizationRate                = sensorGet(sensor, 'photon rate');
    isomerizationRateAdaptingField   = sensorGet(sensorAdaptingField, 'photon rate');
    
    % Preallocate memory for scanData
    scansNum = floor(numel(sensorFixationTimes.onsetBins)/fixationsPerScan);
    for scanIndex = 1:scansNum
        
        startingSaccade = 1+(scanIndex-1)*fixationsPerScan;
        endingSaccade   = startingSaccade + (fixationsPerScan-1);
        
        scanEyePositionIndicesNum = 0;
        for saccadeIndex = startingSaccade:endingSaccade
            timeIndices = (sensorFixationTimes.onsetBins(saccadeIndex):sensorFixationTimes.offsetBins(saccadeIndex));
            eyePositionIndices.d{saccadeIndex-startingSaccade+1}.timeIndices = single(timeIndices);
            scanEyePositionIndicesNum  = scanEyePositionIndicesNum  + numel(timeIndices);
        end
        
        scanData{scanIndex} = struct(...
            'sceneLMSexcitationSequence',   zeros(scanEyePositionIndicesNum , numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, 'single'), ...
            'oiLMSexcitationSequence',      zeros(scanEyePositionIndicesNum , numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, 'single'), ...
            'eyePositionIndices',           eyePositionIndices, ...
            'isomerizationRateSequence',    zeros(scanEyePositionIndicesNum , size(isomerizationRate,1), size(isomerizationRate,2)), ...
            'sensorFOVxaxis', sensorFOVxaxis, ...
            'sensorFOVyaxis', sensorFOVyaxis ...
        );
    end
    
    % Retrieve isomerization sequences
    fprintf('Assembling isomerization sequences for %d scans.\n',scansNum);
    for scanIndex = 1:scansNum  
        
        isomerizationRateSequence = scanData{scanIndex}.isomerizationRateSequence;
        kPosCounter = 0; 
        
        for saccadeIndex = 1:numel(scanData{scanIndex}.eyePositionIndices.d) 
  
            % Get eye positions indices for this saccade
            eyePositionIndices = scanData{scanIndex}.eyePositionIndices.d{saccadeIndex}.timeIndices;
            
            % Get the isomerization rate sequence for this saccade
            kk = kPosCounter + (1:numel(eyePositionIndices));
            isomerizationRateSequence(kk,:,:) = reshape(squeeze(isomerizationRate(:,:,eyePositionIndices)), [numel(eyePositionIndices) size(isomerizationRate,1) size(isomerizationRate,2) ]);
        
        end  
        
        scanData{scanIndex}.isomerizationRateSequence = isomerizationRateSequence;  
    end
    
    useParFor = false;
    if (useParFor)
        poolOBJ = gcp('nocreate');
        if (isempty(poolOBJ))
            parpool()
        else
            delete(poolOBJ)
            parpool()
        end
    end
    
    
    %parfor scanIndex = 1:scansNum
    for scanIndex = 1:scansNum
        
        if (useParFor)
            t = getCurrentTask(); workerID = t.ID;
            fprintf('[worker #%d]: Computing LMS sequence for scan %d/%d\n', workerID, scanIndex, scansNum);
        else
             fprintf('Assembling LMS sequence for scan %d/%d\n', scanIndex, scansNum);
        end
        
        sceneLMSexcitationSequence = scanData{scanIndex}.sceneLMSexcitationSequence;
        oiLMSexcitationSequence    = scanData{scanIndex}.oiLMSexcitationSequence;

        startingSaccade = 1+(scanIndex-1)*fixationsPerScan;
        endingSaccade   = startingSaccade+(fixationsPerScan-1);
        
        fprintf('size before');
        size(sceneLMSexcitationSequence)
        
        kPosCounter = 0;
        for saccadeIndex = 1:numel(scanData{scanIndex}.eyePositionIndices.d)
            % Get eye positions indices for this saccade
            eyePositionIndices = scanData{scanIndex}.eyePositionIndices.d{saccadeIndex}.timeIndices;
            
            % Get the isomerization rate sequence for this saccade
            eyePositionIndicesNum = numel(eyePositionIndices);
             
            % Get the LMS sequences for this saccade
            for k = 1:eyePositionIndicesNum 
                kPosCounter = kPosCounter + 1;
                
                sensorXpos = sensorPositionsInMicrons(eyePositionIndices(k),1);
                sensorYpos = sensorPositionsInMicrons(eyePositionIndices(k),2);
            
                [~,centerCol] = min(abs(sceneRetinalProjectionXData-sensorXpos));
                [~,centerRow] = min(abs(sceneRetinalProjectionYData-sensorYpos));
               
                sceneLMSexcitationSequence(kPosCounter,:,:,:) = single(sceneLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :));
            
                [~,centerCol] = min(abs(opticalImageXData-sensorXpos));
                [~,centerRow] = min(abs(opticalImageYData-sensorYpos));
                oiLMSexcitationSequence(kPosCounter,:,:,:) = single(oiLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :));
            end % for k
            
        end % saccadeIndex
        
        scanData{scanIndex}.sceneLMSexcitationSequence = sceneLMSexcitationSequence;
        scanData{scanIndex}.oiLMSexcitationSequence = oiLMSexcitationSequence; 
        
        fprintf('size after');
        size(sceneLMSexcitationSequence)
        
        showResults = true;
        if (showResults)
        for k = 1:2:size(scanData{scanIndex}.sceneLMSexcitationSequence,1)
            scenelContrastFrame = squeeze(scanData{scanIndex}.sceneLMSexcitationSequence(k,:,:,1));
            oiContrastFrame     = squeeze(scanData{scanIndex}.oiLMSexcitationSequence(k,:,:,1));
            isomerizationFrame  = squeeze(scanData{scanIndex}.isomerizationRateSequence(k,:,:));

            if (k == 1)
                subplot(1,3,1);
                p1 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, scenelContrastFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                hold off
                set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                axis 'xy';
                axis 'image'
                subplot(1,3,2);
                p2 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, oiContrastFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                hold off
                set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                axis 'xy';
                axis 'image'
                subplot(1,3,3)
                p3 = imagesc(1:size(isomerizationFrame,2)*3-30, 1:size(isomerizationFrame,1)*3-30, isomerizationFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                hold off
                set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                axis 'xy';
                axis 'image'
                colormap(gray(1024));
            else
                set(p1, 'CData', scenelContrastFrame);
                set(p2, 'CData', oiContrastFrame);
                set(p3, 'CData', isomerizationFrame);
            end
            drawnow;
        end
        end % showResults
        
    end % parfor scanIndex
        

  

end

    
function [sensorPositionsInMicrons, sensorFOVHalfWidthInMicrons, sensorFOVHalfHeightInMicrons] = retrieveSensorPositionsAndSizeInMicrons(sensor, sceneRetinalProjectionXData, sceneRetinalProjectionYData, extraMicronsAroundSensorBorder)
    sensorPositionsInConeSeparations = sensorGet(sensor, 'positions');
    coneSeparationInMicrons    = sensorGet(sensor,'pixel size','um');
    sensorPositionsInMicrons   = bsxfun(@times, sensorPositionsInConeSeparations, [-coneSeparationInMicrons(1) coneSeparationInMicrons(2)]);

    sensorRowsCols = sensorGet(sensor, 'size');
    sensorHeightInMicrons = sensorRowsCols(1) * coneSeparationInMicrons(1);
    sensorWidthInMicrons  = sensorRowsCols(2) * coneSeparationInMicrons(2);
    
    sensorFOVHalfHeightInMicrons = round(sensorHeightInMicrons/2 + extraMicronsAroundSensorBorder);
    sensorFOVHalfWidthInMicrons  = round(sensorWidthInMicrons/2  + extraMicronsAroundSensorBorder);
    
    % force the sensor position to be within the limits of the retinal projection of the scene
	% first the x-coords
    x = sensorPositionsInMicrons(:,1);
    indices = find(x <= min(sceneRetinalProjectionXData) + sensorFOVHalfWidthInMicrons);
    x(indices) = floor(min(sceneRetinalProjectionXData)) + sensorFOVHalfWidthInMicrons;
    indices = find(x >= max(sceneRetinalProjectionXData) - sensorFOVHalfWidthInMicrons);
    x(indices) = floor(max(sceneRetinalProjectionXData)) - sensorFOVHalfWidthInMicrons;
    sensorPositionsInMicrons(:,1) = x;
    
    % then the y-coords
    y = sensorPositionsInMicrons(:,2);
    indices = find(y <= min(sceneRetinalProjectionYData) + sensorFOVHalfHeightInMicrons);
    y(indices) = floor(min(sceneRetinalProjectionYData)) + sensorFOVHalfHeightInMicrons;
    indices = find(y >= max(sceneRetinalProjectionYData) - sensorFOVHalfHeightInMicrons);
    y(indices) = floor(max(sceneRetinalProjectionYData)) - sensorFOVHalfHeightInMicrons;
    sensorPositionsInMicrons(:,2) = y;
end

function [sceneResampled, sceneRetinalProjectionXData, sceneRetinalProjectionYData] = ...
    computeResampledRetinalScene(scene, oi, decodedSceneSpatialSampleSizeInRetinalMicrons)

    % Retrieve scene spatial support (here, in scene microns)
    sceneSpatialSupportInMicrons = sceneGet(scene,'spatial support','microns');
    
    % Convert from scene microns to retinal microns
    micronsPerSample = sceneGet(scene,'distPerSamp','microns');
    degreesPerSample = sceneGet(scene,'deg per samp');
    oiWres =  oiGet(oi, 'wres','microns') ;
    oiAngRes = oiGet(oi, 'angular resolution');
    retinalMicronsPerDegree =  oiWres(1) ./ oiAngRes(1);
    sceneRetinalProjectionXData = squeeze(sceneSpatialSupportInMicrons(1,:,1)) / micronsPerSample(1) * degreesPerSample(1) * retinalMicronsPerDegree(1);
   
    
    % Resample scene so as to achieve desired retinal sampling
    currentSceneSpatialSampleSizeInRetinalMicrons = sceneRetinalProjectionXData(2)-sceneRetinalProjectionXData(1);
    resizeFactor = decodedSceneSpatialSampleSizeInRetinalMicrons / currentSceneSpatialSampleSizeInRetinalMicrons;
    desiredSceneSamplingInMeters = sceneGet(scene,'distPerSamp','m') * resizeFactor;
    sceneResampled = sceneSpatialResample(scene, desiredSceneSamplingInMeters, 'm', 'linear', false);
    
    sceneSpatialSupportInMicrons = sceneGet(sceneResampled,'spatial support','microns');
    micronsPerSample = sceneGet(sceneResampled,'distPerSamp','microns');
    degreesPerSample = sceneGet(sceneResampled,'deg per samp');
    sceneRetinalProjectionXData = squeeze(sceneSpatialSupportInMicrons(1,:,1)) / micronsPerSample(1) * degreesPerSample(1) * retinalMicronsPerDegree(1);
    sceneRetinalProjectionYData = squeeze(sceneSpatialSupportInMicrons(:,1,2)) / micronsPerSample(1) * degreesPerSample(1) * retinalMicronsPerDegree(1);

end

function scanLMSexcitationSequence = retrieveScanLMSexcitationSequence(sceneLMS, sensor, eyePositionIndices)
    if (~isempty(positionIndices))
        sensorPositions = sensorPositions(positionIndices,:);
    end
    positionsNum = size(sensorPositions,1);
    fprintf('\tAnalyzing scan %d of %d (positions: %d-%4d)\n', scanIndex, scansNum, eyePositionIndices(1), eyePositionIndices(end));
end


    
    
function [LMSexcitationSequence, sceneSensorViewXdataInRetinalMicrons, sceneSensorViewYdataInRetinalMicrons] = ...
    computeSceneLMSstimulusSequenceGeneratedBySensorMovementsOLD(sceneResamplingResolutionInRetinalMicrons, scene, sensor, sensorPositions, sceneLMS, retinalMicronsPerDegree, positionIndices)
    
    if (~isempty(positionIndices))
        sensorPositions = sensorPositions(positionIndices,:);
    end
    positionsNum = size(sensorPositions,1);
    
    % Convert to units of retinal microns
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    sensorPositionsInRetinalMicrons(:,1) = -sensorPositions(:,1)*sensorSampleSeparationInMicrons(1);
    sensorPositionsInRetinalMicrons(:,2) =  sensorPositions(:,2)*sensorSampleSeparationInMicrons(2);
    
    % Compute sensor size in retinal microns
    sensorRowsCols = sensorGet(sensor, 'size');
    sensorWidthInMicrons = sensorRowsCols(2) * sensorSampleSeparationInMicrons(2);
    sensorHeightInMicrons = sensorRowsCols(1) * sensorSampleSeparationInMicrons(1);
    
    % Retrieve scene spatial support (here, in scene microns)
    sceneSpatialSupportInMicrons = sceneGet(scene,'spatial support','microns');
    
    % Convert from scene microns to degrees of visual angle
    micronsPerSample = sceneGet(scene,'distPerSamp','microns');
    degreesPerSample = sceneGet(scene,'deg per samp');
    sceneSpatialSupportInDegrees(:,:,1) = sceneSpatialSupportInMicrons(:,:,1) / micronsPerSample(1) * degreesPerSample;
    sceneSpatialSupportInDegrees(:,:,2) = sceneSpatialSupportInMicrons(:,:,2) / micronsPerSample(2) * degreesPerSample;
    
    % Convert from degrees of visual angle to retinal microns
    sceneSpatialSupportInRetinalMicrons(:,:,1) = sceneSpatialSupportInDegrees(:,:,1) * retinalMicronsPerDegree(1);
    sceneSpatialSupportInRetinalMicrons(:,:,2) = sceneSpatialSupportInDegrees(:,:,2) * retinalMicronsPerDegree(2);
    
    % Obtain the scene's Stockman LMS excitation maps with a spatial resolution = 0.5 microns
    sceneXdataInRetinalMicrons = squeeze(sceneSpatialSupportInRetinalMicrons(1,:,1));
    sceneYdataInRetinalMicrons = squeeze(sceneSpatialSupportInRetinalMicrons(:,1,2));

    [sceneLMSexitations, sceneXgridInRetinalMicrons, sceneYgridInRetinalMicrons] = ...
        resampleScene(sceneLMS, sceneXdataInRetinalMicrons, sceneYdataInRetinalMicrons, sceneResamplingResolutionInRetinalMicrons);

    sceneXdataInRetinalMicrons = single(squeeze(sceneXgridInRetinalMicrons(1,:)));
    sceneYdataInRetinalMicrons = single(squeeze(sceneYgridInRetinalMicrons(:,1)));

    sensorHalfWidth  = round(sensorWidthInMicrons/2  + sensorSampleSeparationInMicrons(2));
    sensorHalfHeight = round(sensorHeightInMicrons/2 + sensorSampleSeparationInMicrons(1));
    
    % Compute the sequence of scene LMS excitation (Stockman) excitations generated by the sensor's eye movements.
    % 1. Begin by preallocating memory to hold the generated sequence
    posIndex = 1;
    currentSensorPositionInRetinalMicrons = sensorPositionsInRetinalMicrons(posIndex,:);
    forceSensorPositionToBoundaries();
        
    % Determine the scene row range and col range that define the scene area that is 
    % under the sensor's current position (we add one extra cone on each side)
    [rows, cols] = determineSceneRowsColsWithinSensor();
    rowRange = min(rows):max(rows);
    colRange = min(cols):max(cols);  
    
    % compute spatial support for the sensor's view of the scene
    sceneSensorViewXdataInRetinalMicrons = sceneXdataInRetinalMicrons(1,colRange(1):colRange(end));
    sceneSensorViewYdataInRetinalMicrons = sceneYdataInRetinalMicrons(rowRange(1):rowRange(end));
    sceneSensorViewXdataInRetinalMicrons = sceneSensorViewXdataInRetinalMicrons - mean(sceneSensorViewXdataInRetinalMicrons(:));
    sceneSensorViewYdataInRetinalMicrons = sceneSensorViewYdataInRetinalMicrons - mean(sceneSensorViewYdataInRetinalMicrons(:));
    
    fprintf('Will generate array of dimensions: %d x %d x %d x %d\n', positionsNum, numel(rowRange), numel(colRange), 3);
    pause(0.1);
    LMSexcitationSequence = zeros(positionsNum, numel(rowRange), numel(colRange), 3, 'single');

    for posIndex = 1:positionsNum
        % Retrieve sensor current position
        currentSensorPositionInRetinalMicrons = sensorPositionsInRetinalMicrons(posIndex,:);
        forceSensorPositionToBoundaries();
        
        % Determine the scene row range and col range that define the scene area that is 
        % under the sensor's current position (we add one extra cone on each side)
        [rows, cols] = determineSceneRowsColsWithinSensor();
        
        % Retrieve LMS excitations for current position
        currentRowRange = min(rows) + (0:numel(rowRange)-1);
        currentColRange = min(cols) + (0:numel(colRange)-1);
        LMSexcitationSequence(posIndex,:,:,:) = sceneLMSexitations(currentRowRange,currentColRange,:);
    end % posIndex
    
    function [rows, cols] = determineSceneRowsColsWithinSensor()
        pixelIndices = find(...
            (abs(floor(sceneXgridInRetinalMicrons)-currentSensorPositionInRetinalMicrons(1)) <= sensorHalfWidth) & ...
            (abs(floor(sceneYgridInRetinalMicrons)-currentSensorPositionInRetinalMicrons(2)) <= sensorHalfHeight));
        [rows, cols] = ind2sub(size(sceneXgridInRetinalMicrons), pixelIndices);
    end

    function forceSensorPositionToBoundaries()
        % force currentSensorPosition to boundaries
        if (currentSensorPositionInRetinalMicrons(1)-sensorHalfWidth <= sceneXgridInRetinalMicrons(1))
            currentSensorPositionInRetinalMicrons(1) = floor(sceneXgridInRetinalMicrons(1)) + sensorHalfWidth + sensorSampleSeparationInMicrons(2);
        end
        if (currentSensorPositionInRetinalMicrons(1)+sensorHalfWidth >= sceneXgridInRetinalMicrons(end))
            currentSensorPositionInRetinalMicrons(1) = floor(sceneXgridInRetinalMicrons(end)) - sensorHalfWidth - sensorSampleSeparationInMicrons(2);
        end

        if (currentSensorPositionInRetinalMicrons(2)-sensorHalfHeight <= sceneYgridInRetinalMicrons(1))
            currentSensorPositionInRetinalMicrons(2) = round(sceneYgridInRetinalMicrons(1)) + sensorHalfHeight + sensorSampleSeparationInMicrons(1);
        end
        if (currentSensorPositionInRetinalMicrons(2)+sensorHalfHeight >= sceneYgridInRetinalMicrons(end))
            currentSensorPositionInRetinalMicrons(2) = round(sceneYgridInRetinalMicrons(end)) - sensorHalfHeight - sensorSampleSeparationInMicrons(1);
        end
    end

end



