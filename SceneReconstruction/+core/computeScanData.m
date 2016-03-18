function scanData = computeScanData(scene,  oi,  sensor, outerSegmentParams, ...
    sceneFixationTimes, adaptingFieldFixationTimes, ...
    fixationsPerScan, consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
    decodedSceneSpatialSampleSizeInRetinalMicrons, decodedSceneExtraMicronsAroundSensorBorder, decodedSceneTemporalSampling)

    % Compute the scene's retinal projection, x- & y- spatial supports
    [sceneResampledToDecoderResolution, sceneRetinalProjectionXData, sceneRetinalProjectionYData] = ...
        computeResampledRetinalScene(scene, oi, decodedSceneSpatialSampleSizeInRetinalMicrons);
    
    % Compute sensor positions in microns - also force sensor to be within scene's retinal projection limits
    [sensorPositionsInMicrons, sensorFOVHalfWidthInMicrons, sensorFOVHalfHeightInMicrons] = retrieveSensorPositionsAndSizeInMicrons(sensor, sceneRetinalProjectionXData, sceneRetinalProjectionYData, decodedSceneExtraMicronsAroundSensorBorder);

    % Resample the optical image to decoder resolution
    oiResampledToDecoderResolution = oiSpatialResample(oi, decodedSceneSpatialSampleSizeInRetinalMicrons,'um', 'linear', false);
    oiSupportInMicrons = oiGet(oiResampledToDecoderResolution,'spatial support','microns');
    opticalImageXData = squeeze(oiSupportInMicrons(1,:,1));
    opticalImageYData = squeeze(oiSupportInMicrons(:,1,2));
    
    % Compute StockmanSharpe 2 deg LMS excitations for scene and optical image (stimulus + adaptingField)
    sceneLMS = core.imageFromSceneOrOpticalImage(sceneResampledToDecoderResolution, 'LMS');
    oiLMS    = core.imageFromSceneOrOpticalImage(oiResampledToDecoderResolution, 'LMS');

    % compute sensor extent in pixels and microns
    sensorFOVHalfCols = round(sensorFOVHalfWidthInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVHalfRows = round(sensorFOVHalfHeightInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVRowRange = (-sensorFOVHalfRows : 1 : sensorFOVHalfRows);
    sensorFOVColRange = (-sensorFOVHalfCols : 1 : sensorFOVHalfCols);
    sensorFOVxaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVColRange;
    sensorFOVyaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVRowRange;
    
    % Compute isomerizations for the total sensor time (this includes the adapting field fixations)
    sensor = coneAbsorptions(sensor, oi);
    isomerizationRate = sensorGet(sensor, 'photon rate');

    % Generate scan data for all scans
    adaptingFieldFixationsNum = numel(adaptingFieldFixationTimes.onsetBins);
    adaptingFieldFixationIndex = 0;
    
    scansNum = 1; % floor(numel(sceneFixationTimes.onsetBins)/fixationsPerScan);
    for scanIndex = 1:scansNum
        
        tic
        % Assemble eye movement path for this scan
        scanPathEyePositionIndices = [];
        
        % Two adaptation saccades before we start this scan
        for k = 1:2
            % add eye position indices
            adaptingFieldFixationIndex = mod(adaptingFieldFixationIndex, adaptingFieldFixationsNum) + 1;
            
            timeIndices = single(adaptingFieldFixationTimes.onsetBins(adaptingFieldFixationIndex):adaptingFieldFixationTimes.offsetBins(adaptingFieldFixationIndex));
            if (isempty(scanPathEyePositionIndices))
                scanPathEyePositionIndices = timeIndices;
            else
                scanPathEyePositionIndices = cat(2, scanPathEyePositionIndices, timeIndices);
            end
        end
        
        % The starting and ending saccade for this scan
        startingSaccade = 1+(scanIndex-1)*fixationsPerScan;
        endingSaccade   = startingSaccade + (fixationsPerScan-1);
        
        for sceneSaccadeIndex = startingSaccade:endingSaccade   
            % Add scene saccade
            timeIndices = single(sceneFixationTimes.onsetBins(sceneSaccadeIndex):sceneFixationTimes.offsetBins(sceneSaccadeIndex));
            if (isempty(scanPathEyePositionIndices))
                scanPathEyePositionIndices = timeIndices;
            else
                scanPathEyePositionIndices = cat(2, scanPathEyePositionIndices, timeIndices);
            end
            
            % Add adaptation saccade (if needed based on viewing mode)
            if (mod(sceneSaccadeIndex-startingSaccade+1, consecutiveSceneFixationsBetweenAdaptingFieldPresentation) == 0)
                adaptingFieldFixationIndex = mod(adaptingFieldFixationIndex, adaptingFieldFixationsNum) + 1;
                timeIndices = single(adaptingFieldFixationTimes.onsetBins(adaptingFieldFixationIndex):adaptingFieldFixationTimes.offsetBins(adaptingFieldFixationIndex));
                if (isempty(scanPathEyePositionIndices))
                    scanPathEyePositionIndices = timeIndices;
                else
                    scanPathEyePositionIndices = cat(2, scanPathEyePositionIndices, timeIndices);
                end
            end
        end
        
        % Another two adaptation saccades at the end
        for k = 1:2
            % add eye position indices
            adaptingFieldFixationIndex = mod(adaptingFieldFixationIndex, adaptingFieldFixationsNum) + 1;
            
            timeIndices = single(adaptingFieldFixationTimes.onsetBins(adaptingFieldFixationIndex):adaptingFieldFixationTimes.offsetBins(adaptingFieldFixationIndex));
            if (isempty(scanPathEyePositionIndices))
                scanPathEyePositionIndices = timeIndices;
            else
                scanPathEyePositionIndices = cat(2, scanPathEyePositionIndices, timeIndices);
            end
        end
        
        % Define sensor positions for this scanpath
        sensorPositionSequence = sensorPositionsInMicrons(scanPathEyePositionIndices,:);
        
        % Assemble the isomerization sequences for this scanpath
        isomerizationRateSequence = isomerizationRate(:,:,scanPathEyePositionIndices);
        
        % Generate new sensor and inject to it the isomerization rates and eye movements for the computed scan path
        scanSensor = sensor;
        scanSensor = sensorSet(scanSensor, 'photon rate', isomerizationRateSequence);
        sensorSampleSeparationInMicrons = sensorGet(scanSensor,'pixel size','um');
        scanSensor = sensorSet(scanSensor, 'positions',   sensorPositionSequence/sensorSampleSeparationInMicrons(1));
        timeIntervalInMilliseconds = sensorGet(scanSensor, 'time interval')*1000
        
      
        
        
        % Compute the outersegment sequences for this scanpath
        % Create outer segment
        if (strcmp(outerSegmentParams.type, '@osBiophys'))
            osOBJ = osBioPhys();
        elseif (strcmp(outerSegmentParams.type, '@osLinear'))
            osOBJ = osLinear();
        else
            error('Unknown outer segment type: ''%s'' \n', expParams.outerSegmentParams.type);
        end
        
        if (outerSegmentParams.addNoise)
            osOBJ.osSet('noiseFlag', 1);
        else
            osOBJ.osSet('noiseFlag', 0);
        end
        
        osOBJ.osCompute(scanSensor);
        photoCurrentSequence = osGet(osOBJ, 'ConeCurrentSignal');
        
        [min(isomerizationRateSequence(:)) max(isomerizationRateSequence(:))]
         [min(photoCurrentSequence(:)) max(photoCurrentSequence(:))]
        pause
        
        % Assemble the LMS excitation sequence for this scanpath (both at the scene level and the optical image level) 
        scanPathLength = numel(scanPathEyePositionIndices);
        scanTimeAxis   = (0:1:(scanPathLength-1))*sensorGet(sensor, 'time interval')*1000;
        sceneLMSexcitationSequence = zeros(scanPathLength, numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, 'single');
        oiLMSexcitationSequence    = zeros(scanPathLength, numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, 'single');
        
        for kPosIndex = 1:scanPathLength
            eyePositionIndex = scanPathEyePositionIndices(kPosIndex);
            sensorXpos = sensorPositionsInMicrons(eyePositionIndex,1);
            sensorYpos = sensorPositionsInMicrons(eyePositionIndex,2);

            [~,centerCol] = min(abs(sceneRetinalProjectionXData-sensorXpos));
            [~,centerRow] = min(abs(sceneRetinalProjectionYData-sensorYpos));
            sceneLMSexcitationSequence(kPosIndex,:,:,:) = single(sceneLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :));

            [~,centerCol] = min(abs(opticalImageXData-sensorXpos));
            [~,centerRow] = min(abs(opticalImageYData-sensorYpos));
            oiLMSexcitationSequence(kPosIndex,:,:,:) = single(oiLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :)); 
        end % kPosIndex
        
        % Reshape to common format (time dimension = 1)
        isomerizationRateSequence = permute(isomerizationRateSequence, [3 1 2]);
        photoCurrentSequence = permute(photoCurrentSequence, [3 1 2]);
        
        size(isomerizationRateSequence)
        size(photoCurrentSequence)
        size(sensorPositionSequence)
        size(sceneLMSexcitationSequence)
        pause
        
        % All done. Last step: subsample all the sequences temporally according to decodedSceneTemporalSampling
%         timeDimensionIndex = 1;
%         lowPassSignal = false;
%          [sensorPositionSequence,   ~] = core.subsampleTemporally(sensorPositionSequence,   scanTimeAxis, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
%         
%          lowPassSignal = true;
%          [sceneLMSexcitationSequence, ~] = core.subsampleTemporally(sceneLMSexcitationSequence, scanTimeAxis, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
%         [oiLMSexcitationSequence,    ~] = core.subsampleTemporally(oiLMSexcitationSequence,    scanTimeAxis, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
%         [isomerizationRateSequence,  ~] = core.subsampleTemporally(isomerizationRateSequence,  scanTimeAxis, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
%         [photoCurrentSequence, scanTimeAxis] = core.subsampleTemporally(photoCurrentSequence,  scanTimeAxis, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
%         
        % Save scanData for this scan
        scanData{scanIndex} = struct(...
            'sensorPositionSequence',       sensorPositionSequence, ...
            'sceneLMSexcitationSequence',   sceneLMSexcitationSequence, ...
            'oiLMSexcitationSequence',      oiLMSexcitationSequence, ...
            'isomerizationRateSequence',    isomerizationRateSequence, ...
            'photoCurrentSequence',         photoCurrentSequence, ...
            'sensorFOVxaxis',               sensorFOVxaxis, ...
            'sensorFOVyaxis',               sensorFOVyaxis, ...
            'timeAxis',                     scanTimeAxis...
        );
    fprintf('Computing data for scan %d/%d took %2.2f seconds\n', scanIndex, scansNum, toc);
    end % scanIndex
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



