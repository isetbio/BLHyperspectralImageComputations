function scanData = computeScanData(scene,  oi,  sensor, osOBJ, ...
    sceneFixationTimes, adaptingFieldFixationTimes, ...
    fixationsPerScan, consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
    decodedSceneSpatialSampleSizeInRetinalMicrons, decodedSceneExtraMicronsAroundSensorBorder, decodedSceneTemporalSampling)
    
    % Compute the scene's retinal projection, x- & y- spatial supports in
    % the decoder's spatial resolution
    [sceneResampledToDecoderResolution, sceneRetinalProjectionXData, sceneRetinalProjectionYData] = ...
        computeResampledRetinalScene(scene, oi, decodedSceneSpatialSampleSizeInRetinalMicrons);
    clear 'scene'
    
    % Compute sensor positions in microns. Also force sensor positions to be withing the scene's retinal projection extent 
    [sensor, sensorPositionsInMicrons, sensorFOVxaxis, sensorFOVyaxis, sensorFOVColRange, sensorFOVRowRange] = ...
        retrieveSensorPositionsAndSizeInMicrons(sensor, sceneRetinalProjectionXData, sceneRetinalProjectionYData, decodedSceneSpatialSampleSizeInRetinalMicrons, decodedSceneExtraMicronsAroundSensorBorder);
    
    % Compute isomerizations for the total sensor time (this includes the adapting field fixations)
    % Note: For this computation, we use oi,  which is computed with a
    % spatial resolution of 1.0 microns, NOT oiResampledToDecoderResolution, 
    % whose spatial resolution could be really coarse, like 1x1.
    sensor = coneAbsorptions(sensor, oi);
    isomerizationRate = sensorGet(sensor, 'photon rate');
    
    % Resample the optical image in the decoder's spatial resolution
    [oiResampledToDecoderResolution, opticalImageXData, opticalImageYData] = ...
        computeResampledOpticalScene(oi, decodedSceneSpatialSampleSizeInRetinalMicrons);
    clear 'oi'
  
    % Compute StockmanSharpe 2 deg LMS excitation sequence for scene (stimulus + adaptingField)
    sceneLMS = core.imageFromSceneOrOpticalImage(sceneResampledToDecoderResolution, 'LMS');
    clear 'sceneResampledToDecoderResolution'
    
    % Compute StockmanSharpe 2 deg LMS excitation sequence for optical image (stimulus + adaptingField)
    oiLMS    = core.imageFromSceneOrOpticalImage(oiResampledToDecoderResolution, 'LMS');
    clear 'oiResampledToDecoderResolution'
    
    % Generate scan data for all scans
    adaptingFieldFixationIndex = 0;
    
    scansNum = floor(numel(sceneFixationTimes.onsetBins)/fixationsPerScan);
    for scanIndex = 1:scansNum
        
        fprintf('Computing data for scan %d/%d. Please wait ...', scanIndex, scansNum);
        tic
        % The starting and ending saccade for this scan
        startingSaccade = 1+(scanIndex-1)*fixationsPerScan;
        endingSaccade   = startingSaccade + (fixationsPerScan-1);
        
        % Generatescan path
        [scanPathEyePositionIndices, adaptingFieldFixationIndex, trailingAdaptationPeriodTimeBinsNum] = generateScanPath(...
            startingSaccade, endingSaccade, ...
            adaptingFieldFixationIndex, adaptingFieldFixationTimes, sceneFixationTimes, ...
            consecutiveSceneFixationsBetweenAdaptingFieldPresentation);
        
        % Define sensor positions for this scanpath
        sensorPositionSequence = sensorPositionsInMicrons(scanPathEyePositionIndices,:);
        
        % Assemble the isomerization sequences for this scanpath
        isomerizationRateSequence = isomerizationRate(:,:,scanPathEyePositionIndices);
        
        % Generate new sensor and inject to it the isomerization rates and eye movements for the computed scan path
        scanSensor = sensor;
        scanSensor = sensorSet(scanSensor, 'photon rate', isomerizationRateSequence);
        sensorSampleSeparationInMicrons = sensorGet(scanSensor,'pixel size','um');
        scanSensor = sensorSet(scanSensor, 'positions',   sensorPositionSequence/sensorSampleSeparationInMicrons(1));

        % Compute photocurrents for this scan path
        osOBJ.osCompute(scanSensor);
        photoCurrentSequence = osGet(osOBJ, 'ConeCurrentSignal');
        
        % Assemble the LMS excitation sequence for this scanpath (both at the scene level and the optical image level) 
        [sceneLMSexcitationSequence, oiLMSexcitationSequence] = generateLMSexcitationSequence(...
            scanPathEyePositionIndices, sensorPositionsInMicrons, sensorFOVRowRange, sensorFOVColRange,...
            sceneRetinalProjectionXData, sceneRetinalProjectionYData, opticalImageXData, opticalImageYData, sceneLMS, oiLMS);
        
        % Generate time axis for this scan path
        scanTimeAxis = (0:1:(numel(scanPathEyePositionIndices)-1))*sensorGet(sensor, 'time interval')*1000;
        
        % All done. Last step: subsample all the sequences temporally according to decodedSceneTemporalSampling
        initialTimePeriodExcuded = 400;   % do not include the initial 400 milliseconds of the response - avoid photocurrent transients
        timeDimensionIndex = 1; lowPassSignal = true;
        [sensorPositionSequence,  subSampledScanTimeAxis, ~, ~] = core.subsampleTemporally(sensorPositionSequence, scanTimeAxis, initialTimePeriodExcuded, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
        
        timeDimensionIndex = ndims(sceneLMSexcitationSequence); lowPassSignal = true;
        [sceneLMSexcitationSequence, ~, lowPassKernel, lowPassKernelTimeAxis] = core.subsampleTemporally(sceneLMSexcitationSequence, scanTimeAxis, initialTimePeriodExcuded, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
        
        timeDimensionIndex = ndims(oiLMSexcitationSequence); lowPassSignal = true;
        [oiLMSexcitationSequence, ~, ~, ~] = core.subsampleTemporally(oiLMSexcitationSequence, scanTimeAxis, initialTimePeriodExcuded, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
         
        timeDimensionIndex = ndims(isomerizationRateSequence); lowPassSignal = true;
        [isomerizationRateSequence,  ~, ~, ~] = core.subsampleTemporally(isomerizationRateSequence,  scanTimeAxis, initialTimePeriodExcuded, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
        
        timeDimensionIndex = ndims(photoCurrentSequence); lowPassSignal = true;
        [photoCurrentSequence, ~, ~, ~] = core.subsampleTemporally(photoCurrentSequence,  scanTimeAxis, initialTimePeriodExcuded, timeDimensionIndex, lowPassSignal, decodedSceneTemporalSampling);
        
        % transform LMS excitation sequence into Weber contrast
        trailingPeriodForEstimatingBackgroundExcitations = [scanTimeAxis(end-trailingAdaptationPeriodTimeBinsNum)+10 scanTimeAxis(end)-10];
        timeBinsForEstimatingMeanLMScontrast = find((subSampledScanTimeAxis+initialTimePeriodExcuded > trailingPeriodForEstimatingBackgroundExcitations(1)) & ...
                                                    (subSampledScanTimeAxis+initialTimePeriodExcuded < trailingPeriodForEstimatingBackgroundExcitations(2)));
        
        for k = 1:3
            sceneBackgroundExcitations(k) = mean(mean(mean(squeeze(sceneLMSexcitationSequence(:,:,k,timeBinsForEstimatingMeanLMScontrast)))));
            sceneLMSexcitationSequence(:,:,k,:) = sceneLMSexcitationSequence(:,:,k,:)/sceneBackgroundExcitations(k) - 1;
            oiBackgroundExcitations(k) = mean(mean(mean(squeeze(oiLMSexcitationSequence(:,:,k,timeBinsForEstimatingMeanLMScontrast)))));
            oiLMSexcitationSequence(:,:,k,:) = oiLMSexcitationSequence(:,:,k,:)/oiBackgroundExcitations(k) - 1;
        end
        
        
        fprintf('mean cone excitation estimated between %2.1f and %2.1f milliseconds\n', subSampledScanTimeAxis(timeBinsForEstimatingMeanLMScontrast(1)), subSampledScanTimeAxis(timeBinsForEstimatingMeanLMScontrast(end)));
        fprintf('scene: %2.3f %2.3f %2.3f\n', sceneBackgroundExcitations(1), sceneBackgroundExcitations(2), sceneBackgroundExcitations(3));
        fprintf('optim: %2.5f %2.5f %2.5f\n', oiBackgroundExcitations(1), oiBackgroundExcitations(2), oiBackgroundExcitations(3));
        
        % Save scanData for this scan
        scanData{scanIndex} = struct(...
            'scanSensor',                   scanSensor, ...
            'sensorPositionSequence',       sensorPositionSequence, ...
            'sceneLMScontrastSequence',     sceneLMSexcitationSequence, ...
            'oiLMScontrastSequence',        oiLMSexcitationSequence, ...
            'sceneBackgroundExcitations',   sceneBackgroundExcitations, ...
            'oiBackgroundExcitations',      oiBackgroundExcitations, ...
            'isomerizationRateSequence',    isomerizationRateSequence, ...
            'photoCurrentSequence',         photoCurrentSequence, ...
            'sensorFOVxaxis',               sensorFOVxaxis, ...
            'sensorFOVyaxis',               sensorFOVyaxis, ...
            'sceneRetinalProjectionXData',  sceneRetinalProjectionXData, ... 
            'sceneRetinalProjectionYData',  sceneRetinalProjectionYData, ...
            'opticalImageXData',            opticalImageXData, ...
            'opticalImageYData',            opticalImageYData, ...
            'timeAxis',                     subSampledScanTimeAxis...
        );
    fprintf('Completed in %2.2f seconds\n', toc);
    end % scanIndex
end


function [sceneLMSexcitationSequence, oiLMSexcitationSequence] = generateLMSexcitationSequence(...
        scanPathEyePositionIndices, sensorPositionsInMicrons, sensorFOVRowRange, sensorFOVColRange,...
        sceneRetinalProjectionXData, sceneRetinalProjectionYData, opticalImageXData, opticalImageYData, sceneLMS, oiLMS)
            
    scanPathLength = numel(scanPathEyePositionIndices);
    sceneLMSexcitationSequence = zeros(numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, scanPathLength,  'single');
    oiLMSexcitationSequence    = zeros(numel(sensorFOVRowRange), numel(sensorFOVColRange), 3, scanPathLength, 'single');

    for kPosIndex = 1:scanPathLength
        eyePositionIndex = scanPathEyePositionIndices(kPosIndex);
        sensorXpos = sensorPositionsInMicrons(eyePositionIndex,1);
        sensorYpos = sensorPositionsInMicrons(eyePositionIndex,2);

        [~,centerCol] = min(abs(sceneRetinalProjectionXData-sensorXpos));
        [~,centerRow] = min(abs(sceneRetinalProjectionYData-sensorYpos));
        sceneLMSexcitationSequence(:,:,:, kPosIndex) = single(sceneLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :));

        [~,centerCol] = min(abs(opticalImageXData-sensorXpos));
        [~,centerRow] = min(abs(opticalImageYData-sensorYpos));
        oiLMSexcitationSequence(:,:,:,kPosIndex) = single(oiLMS(centerRow+sensorFOVRowRange, centerCol+sensorFOVColRange, :)); 
    end % kPosIndex
end


function [scanPathEyePositionIndices, adaptingFieldFixationIndex, trailingAdaptationPeriodTimeBinsNum] = generateScanPath(startingSaccade, endingSaccade, ...
    adaptingFieldFixationIndex, adaptingFieldFixationTimes, sceneFixationTimes, consecutiveSceneFixationsBetweenAdaptingFieldPresentation)
    
    % Assemble eye movement path for this scan
    scanPathEyePositionIndices = [];
        
    adaptingFieldFixationsNum = numel(adaptingFieldFixationTimes.onsetBins);

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
    firstTimeBinOfTrailingAdaptationPeriod = size(scanPathEyePositionIndices,2)+1;
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
    
    trailingAdaptationPeriodTimeBinsNum = size(scanPathEyePositionIndices,2) - firstTimeBinOfTrailingAdaptationPeriod;
end

function [sensor, sensorPositionsInMicrons, sensorFOVxaxis, sensorFOVyaxis, sensorFOVColRange, sensorFOVRowRange] = retrieveSensorPositionsAndSizeInMicrons(sensor, sceneRetinalProjectionXData, sceneRetinalProjectionYData, decodedSceneSpatialSampleSizeInRetinalMicrons, extraMicronsAroundSensorBorder)
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
    
    % Force sensor positions to be within scene's retinal projection limits
    %sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    sensorPositionsInConeSeparations = bsxfun(@times, sensorPositionsInMicrons, 1./[-coneSeparationInMicrons(1) coneSeparationInMicrons(2)]);
    sensor = sensorSet(sensor, 'positions',   sensorPositionsInConeSeparations);
   
    
    % compute sensor extent in pixels and microns
    sensorFOVHalfCols = round(sensorFOVHalfWidthInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVHalfRows = round(sensorFOVHalfHeightInMicrons/decodedSceneSpatialSampleSizeInRetinalMicrons);
    sensorFOVRowRange = (-sensorFOVHalfRows : 1 : sensorFOVHalfRows);
    sensorFOVColRange = (-sensorFOVHalfCols : 1 : sensorFOVHalfCols);
    sensorFOVxaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVColRange;
    sensorFOVyaxis = decodedSceneSpatialSampleSizeInRetinalMicrons * sensorFOVRowRange;
    
end


function [oiResampledToDecoderResolution, opticalImageXData, opticalImageYData] = ...
        computeResampledOpticalScene(oi, decodedSceneSpatialSampleSizeInRetinalMicrons)
    
    oiResampledToDecoderResolution = oiSpatialResample(oi, decodedSceneSpatialSampleSizeInRetinalMicrons,'um', 'linear', false);
    oiSupportInMicrons = oiGet(oiResampledToDecoderResolution,'spatial support','microns');
    opticalImageXData = squeeze(oiSupportInMicrons(1,:,1));
    opticalImageYData = squeeze(oiSupportInMicrons(:,1,2));
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



