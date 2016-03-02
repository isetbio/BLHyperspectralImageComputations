% Method to generate custom sensor and compute isomerizations rates
% for a bunch of images, each scanned by eye movements 
function computeOuterSegmentResponsesToStimulusSet(rootPath, osType, adaptingFieldType, configuration)

    minargs = 4;
    maxargs = 4;
    narginchk(minargs, maxargs);
    
    % reset
    ieInit;
    

    % configure experiment
    [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureExperiment(configuration);
    pause
    
    % Set up remote data toolbox client
    remoteDataToolboxClient = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig')); 
    
    % Fetch the scene dataset
    for imageIndex = 1:numel(trainingImageSet)
        % Retrieve scene
        imsource = trainingImageSet{imageIndex};
        fprintf('Fetching data for ''%s'' / ''%s''. Please wait ...\n', imsource{1}, imsource{2});
        remoteDataToolboxClient.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
        [artifactData{imageIndex}, artifactInfo] = remoteDataToolboxClient.readArtifact(imsource{2}, 'type', 'mat');
        fprintf('Done fetching scene data.\n');
    end
    
    debug = false;
    showRenderingOfSceneAndAdaptationField = true;
    useParallelEngine = true;
    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    
    for imageIndex = 1:numel(trainingImageSet)
        computeOuterSegmentResponsesForImage(scansDir, osType, useParallelEngine, showRenderingOfSceneAndAdaptationField, trainingImageSet{imageIndex}, artifactData{imageIndex}, forcedSceneMeanLuminance, adaptingFieldType, saccadesPerScan, sensorParams, sensorAdaptationFieldParams, debug);
    end

end

function computeOuterSegmentResponsesForImage(scansDir, osType, useParallelEngine, showRenderingOfSceneAndAdaptationField, imsource, artifactData, forcedSceneMeanLuminance, adaptingFieldType, saccadesPerScan, sensorParams, sensorAdaptationFieldParams, debug)

    workerID = 1;
  
    % Extract scene
    if ismember('scene', fieldnames(artifactData))
        fprintf('[Worker %d]: Fetched scene contains uncompressed scene data.\n', workerID);
        scene = artifactData.scene;
    else
        fprintf('[Worker %d]: Fetched scene contains compressed scene data.\n', workerID);
        %scene = sceneFromBasis(artifactData);
        scene = uncompressScene(artifactData);
    end

    % Set mean luminance of all scenes to same value
    scene = sceneAdjustLuminance(scene, forcedSceneMeanLuminance);

    % Generate uniform-field adapting scene with equal size as test scene
    if strcmp(adaptingFieldType, 'MacBethGrayD65MatchSceneLuminance')
        % Reflectance that of a gray MacBeth chip with a reflectance = 0.6, illuminated by D65 illuminant and 
        % a mean luminance adjusted to match that of the test scene.
        adaptingFieldIlluminant = 'D65';         % either 'from scene', or the name of a known illuminant, such as 'D65', 'illuminant c'
        adaptingFieldLuminance = sceneGet(scene, 'mean luminance');
        adaptingFieldReflectance = 0.7;
        sceneAdaptationField = makeMacBethWhiteChipAdaptingScene(scene, adaptingFieldReflectance, adaptingFieldLuminance, adaptingFieldIlluminant);
        fprintf('[Worker %d]: Adapting scene  mean luminance: %2.2f cd/m2\n', workerID, sceneGet(sceneAdaptationField, 'mean luminance'));
        fprintf('[Worker %d]: Testing  scene mean luminance: %2.2f cd/m2\n',  workerID, sceneGet(scene, 'mean luminance'));
        
    elseif strcmp(adaptingFieldType, 'MatchSpatiallyAveragedPhotonSPD')
        
        % Compute the spatially-averaged median photon SPD of the test scene
        photons = sceneGet(scene, 'photons');
        spatiallyAveragedPhotonSPD = zeros(1, size(photons,3));
        %  percentileToInclude: when set to 50,  we compute the median of the photons, 
        %                       when set to 100: we compute the mean of the photons
        percentileToInclude = 100;
        percentileToInclude = min([100 max([50.001 percentileToInclude])]);
        for wavebandIndex = 1:size(photons,3)
            wavebandPhotons = squeeze(photons(:,:,wavebandIndex));
            wavebandPhotons = wavebandPhotons(:);
            p = prctile(wavebandPhotons, [100-percentileToInclude percentileToInclude]);
            indices = find((wavebandPhotons >= p(1)) & (wavebandPhotons <= p(2)));
            spatiallyAveragedPhotonSPD(wavebandIndex) = mean(wavebandPhotons(indices));
        end

        % make adaptation field scene
        sceneAdaptationField = scene;
        % set a different name
        sceneAdaptationField = sceneSet(sceneAdaptationField, 'name', sprintf('%s - adaptation field', sceneGet(scene, 'name')));
        % set photons to the spatially-averaged median photon SPD of the test scene
        sceneAdaptationField = sceneSet(sceneAdaptationField, 'photons', bsxfun(@times, ones(size(photons)), reshape(spatiallyAveragedPhotonSPD, [1 1 numel(spatiallyAveragedPhotonSPD)])));
        % when setting the photons of a scene, isetbio clears the scene luminance, so let's refill the luminance slot
        [lum, meanL] = sceneCalculateLuminance(sceneAdaptationField);
        sceneAdaptationField = sceneSet(sceneAdaptationField,'luminance',lum);
    end
    

    % compute Stockman LMS excitations for both scenes
    sceneLMS = sceneGet(scene, 'lms');
    sceneAdaptationFieldLMS = sceneGet(sceneAdaptationField, 'lms');
    
    if (showRenderingOfSceneAndAdaptationField)
        sceneXYZ = sceneGet(scene, 'xyz');
        sceneAdaptationFieldXYZ = sceneGet(sceneAdaptationField, 'xyz');

        [tmp, nCols, mRows] = ImageToCalFormat(sceneXYZ);
        tmp = XYZToSRGBPrimary(tmp);
        sceneRGB = CalFormatToImage(tmp, nCols, mRows);
        [tmp, nCols, mRows] = ImageToCalFormat(sceneAdaptationFieldXYZ);
        tmp = XYZToSRGBPrimary(tmp);
        sceneAdaptationFieldRGB = CalFormatToImage(tmp, nCols, mRows);
        boost = 2.0;
        maxAll = 1.0/boost*max([max(sceneRGB(:)) max(sceneAdaptationFieldRGB(:))]);
        sceneRGB = sceneRGB  / maxAll;
        sceneAdaptationFieldRGB =  sceneAdaptationFieldRGB / maxAll;
        sceneRGB(sceneRGB>1) = 1;
        sceneRGB(sceneRGB<0) = 0;
        sceneAdaptationFieldRGB(sceneAdaptationFieldRGB>1) = 1;
        sceneAdaptationFieldRGB(sceneAdaptationFieldRGB<0) = 0;
        hfig = figure(123); clf; set(hfig, 'Position', [10 10 650 960]);
        subplot('Position', [0.01 0.5 0.99 0.46]); imshow(sceneRGB.^0.5); title('scene');
        subplot('Position', [0.01 0.01 0.99 0.46]); imshow(sceneAdaptationFieldRGB.^0.5); title('adaptation field');
        drawnow;
    end

    
    % print the mean LMS excitations
    computeSceneMeanAndMedianLMSexcitations(sceneLMS, sprintf('%s / %s', imsource{1}, imsource{2}));
    computeSceneMeanAndMedianLMSexcitations(sceneAdaptationFieldLMS, sprintf('%s / %s - adaptation field', imsource{1}, imsource{2}));
        
    % Show scene and adaptationField scene
    if (debug)
        vcAddAndSelectObject(scene); sceneWindow;
        vcAddAndSelectObject(sceneAdaptationField); sceneWindow;
    end
    
    fprintf('[Worker %d]: Computing optical images.\n', workerID);
    % Compute optical image with human optics
    oi = oiCreate('human');
    oi = oiCompute(oi, scene);

    % Compute optical image of adapting scene
    oiAdaptationField = oiCreate('human');
    oiAdaptationField = oiCompute(oiAdaptationField, sceneAdaptationField);

    % Show optical images
    if (debug)
        vcAddAndSelectObject(oi); oiWindow;
        vcAddAndSelectObject(oiAdaptationField); oiWindow;
    end
    
    % create custom human sensor
    sensor = sensorCreate('human');
    sensor = customizeSensor(sensor, sensorParams, oi);

    % create custom human sensor
    sensorAdaptationField = sensorCreate('human');
    sensorAdaptationField = customizeSensor(sensorAdaptationField, sensorAdaptationFieldParams, oiAdaptationField);

    % compute isomerization rate for all positions
    fprintf('[Worker %d]: Computing isomerization rates.\n', workerID);
    sensor = coneAbsorptions(sensor, oi);
    sensorAdaptationField = coneAbsorptions(sensorAdaptationField, oiAdaptationField);

    % extract the full isomerization rate sequence across all positions
    isomerizationRate = sensorGet(sensor, 'photon rate');
    sensorPositions   = sensorGet(sensor, 'positions');

    % extract the adaptationField data
    isomerizationRateAdaptationField = sensorGet(sensorAdaptationField, 'photon rate');
    sensorPositionsAdaptationField   = sensorGet(sensorAdaptationField, 'positions');
    
    % Retrieve retinal microns/degree
    retinalMicronsPerDegree = oiGet(oi, 'wres','microns') ./ oiGet(oi, 'angular resolution');

    % compute the LMS sequence for the adaptation field scene
    [LMSAdaptionFieldSequence,  ~, ~] = ...
        computeSceneLMSstimulusSequenceGeneratedBySensorMovements(sensorAdaptationFieldParams.sceneResamplingResolutionInRetinalMicrons, sceneAdaptationField, sensorAdaptationField, sensorPositionsAdaptationField, sceneAdaptationFieldLMS, retinalMicronsPerDegree, []);

    % parse the data into scans, each scan having saccadesPerScansaccades
    positionsPerFixation = round(sensorParams.eyeMovementScanningParams.fixationDurationInMilliseconds / sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds);
    positionsPerFixationAdaptationField = round(sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds / sensorAdaptationFieldParams.eyeMovementScanningParams.samplingIntervalInMilliseconds); 

    fixationsNum = size(sensorGet(sensor,'positions'),1) / positionsPerFixation;
    scansNum = floor(fixationsNum/saccadesPerScan);
    fprintf('[Worker %d]: Number of scan files generated for image %s: %d\n', workerID, imsource{2}, scansNum);

    % reset sensor positions and isomerization rate
    sensor = sensorSet(sensor, 'photon rate', zeros(size(isomerizationRate,1), size(isomerizationRate,2), 1));
    sensor = sensorSet(sensor, 'positions', zeros(1,2));
    
    for scanIndex = 1:scansNum   
        % select a subsequence of saccades (a scan)
        startingSaccade = 1+(scanIndex-1)*saccadesPerScan;
        endingSaccade = startingSaccade + (saccadesPerScan-1);
        positionIndices = 1 + (((startingSaccade-1)*positionsPerFixation : endingSaccade*positionsPerFixation-1));
        fprintf('\t[Worker %d]: Analyzing scan %d of %d (positions: %d-%4d)\n', workerID, scanIndex, scansNum  , positionIndices(1), positionIndices(end));

        % Extract the LMS cone stimulus sequence encoded by sensor at all visited positions
        fprintf('\t[Worker %d]: Computing Stockman LMS excitation sequence.\n', workerID);
        [scanLMSexcitationSequence, LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons] = ...
             computeSceneLMSstimulusSequenceGeneratedBySensorMovements(sensorParams.sceneResamplingResolutionInRetinalMicrons, scene, sensor, sensorPositions, sceneLMS, retinalMicronsPerDegree, positionIndices);

        scanLMSAdaptionFieldSequence = LMSAdaptionFieldSequence;
        scanIsomerizationRates       = isomerizationRate(:,:,positionIndices);
        scanPositions                = sensorPositions(positionIndices,:);

        % preallocate memory
        timeBinsNum = saccadesPerScan*(positionsPerFixation+positionsPerFixationAdaptationField)+positionsPerFixationAdaptationField;
        scanPlusAdaptationFieldIsomerizationRates    = zeros(size(isomerizationRate,1), size(isomerizationRate, 2), timeBinsNum);
        scanPlusAdaptationFieldPositions             = zeros(timeBinsNum,2);
        scanPlusAdaptationFieldLMSexcitationSequence = zeros(timeBinsNum, size(LMSAdaptionFieldSequence,2), size(LMSAdaptionFieldSequence,3), size(LMSAdaptionFieldSequence,4), 'single');

        % Insert adaptation field isomerizations between saccades to allow
        % for the outer segment to return to its baseline response
        for saccadeIndex = 1:saccadesPerScan
            timeBins1 = (saccadeIndex-1)*positionsPerFixation;
            timeBins2 = (saccadeIndex-1)*(positionsPerFixation+positionsPerFixationAdaptationField);

            % part1: response data from  adaptationField
            binIndices2 = (1+timeBins2):(timeBins2+positionsPerFixationAdaptationField);
            scanPlusAdaptationFieldIsomerizationRates(:,:,binIndices2) = isomerizationRateAdaptationField;
            scanPlusAdaptationFieldPositions(binIndices2,:)            = sensorPositionsAdaptationField;
            scanPlusAdaptationFieldLMSexcitationSequence(binIndices2,:,:,:) = scanLMSAdaptionFieldSequence;

            % part2: response data from current saccade
            binIndices1 = (1+timeBins1):(timeBins1+positionsPerFixation);
            binIndices2 = binIndices2(end) + (1:positionsPerFixation);
            scanPlusAdaptationFieldIsomerizationRates(:,:,binIndices2) = scanIsomerizationRates(:,:, binIndices1);
            scanPlusAdaptationFieldPositions(binIndices2, :)           = scanPositions(binIndices1,:);
            scanPlusAdaptationFieldLMSexcitationSequence(binIndices2, :,:,:) = scanLMSexcitationSequence(binIndices1,:,:,:);
        end

        % add trailing response data from adaptationField
        timeBins2 = saccadesPerScan*(positionsPerFixation+positionsPerFixationAdaptationField);
        binIndices2 = (1+timeBins2): (timeBins2 + positionsPerFixationAdaptationField);
        scanPlusAdaptationFieldIsomerizationRates(:,:,binIndices2) = isomerizationRateAdaptationField;
        scanPlusAdaptationFieldPositions(binIndices2,:)            = sensorPositionsAdaptationField;
        scanPlusAdaptationFieldLMSexcitationSequence(binIndices2,:,:,:) = LMSAdaptionFieldSequence;
        
        % add one more trailing response data from adaptationField
        binIndices2 = binIndices2 + positionsPerFixationAdaptationField;
        scanPlusAdaptationFieldIsomerizationRates(:,:,binIndices2) = isomerizationRateAdaptationField;
        scanPlusAdaptationFieldPositions(binIndices2,:)            = sensorPositionsAdaptationField;
        scanPlusAdaptationFieldLMSexcitationSequence(binIndices2,:,:,:) = LMSAdaptionFieldSequence;
        
        
        % generate new sensor with given sub-sequence of saccades with injected adaptationField isomerization rates
        scanSensor = sensor;
        scanSensor = sensorSet(scanSensor, 'photon rate', scanPlusAdaptationFieldIsomerizationRates);
        scanSensor = sensorSet(scanSensor, 'positions',   scanPlusAdaptationFieldPositions);
        
        % Compute outer-segment response
        fprintf('\t[Worker %d]: Computing outer segment response\n', workerID);
        
        if (strcmp(osType, 'biophysics-based'))
            osOBJ = osBioPhys();
        else
            osOBJ = osLinear();
        end
        
        osOBJ.osSet('noiseFlag', 1);
        osOBJ.osCompute(scanSensor);
        photoCurrents = osGet(osOBJ, 'ConeCurrentSignal');

        % Lowpass and downsample all time series to a resolution of 1 millisecond to save space and make decoding faster
        newTimeStepInMilliseconds = 1.0;
        fprintf('\t[Worker %d]: Downsampling to a resolution of %2.2f milliseconds\n', workerID, newTimeStepInMilliseconds);
        [scanPlusAdaptationFieldLMSexcitationSequence, photoCurrents, scanSensor] = ...
            subSampleSequences(scanPlusAdaptationFieldLMSexcitationSequence, photoCurrents, scanSensor, newTimeStepInMilliseconds/1000.0);
       
        % Also update the sensorParams and the sensorAdaptationFieldParams structs
        sensorParams.samplingIntervalInMilliseconds = newTimeStepInMilliseconds;
        sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds = newTimeStepInMilliseconds;
        sensorAdaptationFieldParams.samplingIntervalInMilliseconds = newTimeStepInMilliseconds;
        sensorAdaptationFieldParams.eyeMovementScanningParams.samplingIntervalInMilliseconds = newTimeStepInMilliseconds;

        % Save data
        fileName = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex));
        fprintf('\t[Worker %d]: Saving data for scan %d in %s\n', workerID, scanIndex, fileName);
        save(fileName, 'scansNum', 'scanSensor', 'photoCurrents', 'scanPlusAdaptationFieldLMSexcitationSequence', ...
                'LMSexcitationXdataInRetinalMicrons', 'LMSexcitationYdataInRetinalMicrons', ...
                'sensorParams', 'sensorAdaptationFieldParams', ...
                'startingSaccade', 'endingSaccade', 'forcedSceneMeanLuminance', '-v7.3');

        if (debug)
            figNum = 100*workerID+scanIndex;
            osWindow(figNum, 'biophys-based outer segment', osB, scanSensor, oi, scene);
        end
    end
end


function [LMSexcitationSequenceSubSampled, photoCurrentsSubSampled, sensorSubSampled] = ...
                subSampleSequences(LMSexcitationSequence, photoCurrents, sensor, newSensorTimeInterval)
       
    % Before downsampling, convolve with a Gaussian kernel
    originalTimeInterval = sensorGet(sensor, 'time interval');
    decimationFactor = round(newSensorTimeInterval/originalTimeInterval);
    tauInSamples = sqrt((decimationFactor^2-1)/12);
    filterTime = -round(3*tauInSamples):1:round(3*tauInSamples);
    kernel = exp(-0.5*(filterTime/tauInSamples).^2);
    kernel = kernel / sum(kernel);
    

    % Compute subsampling sample indices
    originalTimePoints = round(sensorGet(sensor, 'total time')/originalTimeInterval);
    [~,tOffset] = max(kernel);
    subSampledIndices = tOffset + 0:decimationFactor:originalTimePoints;
    subSampledIndices = subSampledIndices(subSampledIndices>0);
     
    fprintf('\tLowpassing signals with a filter with %2.2f msec time constant and subsampling with a resolution of %2.2f msec.\n', tauInSamples*originalTimeInterval*1000, newSensorTimeInterval*1000);

    % LMS excitation sequence
    LMSexcitationSequenceSubSampled = zeros(numel(subSampledIndices), size(LMSexcitationSequence,2), size(LMSexcitationSequence,3), size(LMSexcitationSequence,4), 'single');
    for i = 1:size(LMSexcitationSequence,2)
         for j = 1:size(LMSexcitationSequence, 3)
             for k = 1:size(LMSexcitationSequence, 4)
                 tmp = conv(squeeze(LMSexcitationSequence(:,i, j, k)), kernel, 'same');
                 LMSexcitationSequenceSubSampled(:, i, j, k) = single(tmp(subSampledIndices));
             end
         end
    end
     
    % Sensor positions
    originalPositions = sensorGet(sensor, 'positions');
    subSampledPositions = zeros(numel(subSampledIndices), size(originalPositions,2), 'single');
    for i = 1:size(originalPositions,2)
        % we do not low pass the positions
        subSampledPositions(:,i) = single(squeeze(originalPositions(subSampledIndices,i)));
    end
    
    % Photon rate
    originalIsomerizations = sensorGet(sensor, 'photon rate');
    subSampledIsomerizations = zeros(size(originalIsomerizations,1), size(originalIsomerizations,2), numel(subSampledIndices), 'single');
    for i = 1:size(originalIsomerizations,1)
         for j = 1:size(originalIsomerizations, 2)
             tmp = conv(squeeze(originalIsomerizations(i, j, :)), kernel, 'same');
             subSampledIsomerizations(i,j,:) = single(tmp(subSampledIndices));
         end
    end
    
    % Photocurrents
    photoCurrentsSubSampled = zeros(size(photoCurrents,1), size(photoCurrents,2), numel(subSampledIndices), 'single');
    for i = 1:size(photoCurrents,1)
        for j = 1:size(photoCurrents,2)
             tmp = conv(squeeze(photoCurrents(i,j,:)), kernel, 'same');
             photoCurrentsSubSampled(i,j,:) = single(tmp(subSampledIndices));
        end
    end
    
    % Update sensor struct for consistency with new time sampling
    sensorSubSampled = sensor;
    sensorSubSampled = sensorSet(sensorSubSampled, 'time interval', newSensorTimeInterval);
    sensorSubSampled = sensorSet(sensorSubSampled, 'photon rate',  subSampledIsomerizations);
    sensorSubSampled = sensorSet(sensorSubSampled, 'positions',   subSampledPositions);
end


function [LMSexcitationSequence, sceneSensorViewXdataInRetinalMicrons, sceneSensorViewYdataInRetinalMicrons] = ...
    computeSceneLMSstimulusSequenceGeneratedBySensorMovements(sceneResamplingResolutionInRetinalMicrons, scene, sensor, sensorPositions, sceneLMS, retinalMicronsPerDegree, positionIndices)
    
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



function [resampledScene, resampledSceneXgrid,  resampledSceneYgrid] = resampleScene(sceneData, sceneXdata, sceneYdata, sceneResamplingInterval)  
    resampledColsNum = (round((sceneXdata(end)-sceneXdata(1))/sceneResamplingInterval)/2)*2;
    resampledRowsNum = (round((sceneYdata(end)-sceneYdata(1))/sceneResamplingInterval)/2)*2;
    
    resampledSceneXdata = (-resampledColsNum/2:resampledColsNum/2-1)*sceneResamplingInterval + sceneResamplingInterval/2;
    resampledSceneYdata = (-resampledRowsNum/2:resampledRowsNum/2-1)*sceneResamplingInterval + sceneResamplingInterval/2;
    
    [X,Y] = meshgrid(sceneXdata, sceneYdata);
    [resampledSceneXgrid, resampledSceneYgrid] = meshgrid(resampledSceneXdata, resampledSceneYdata);
   
    % preallocate memory
    sceneChannels = size(sceneData,3);
    resampledScene = zeros(numel(resampledSceneYdata), numel(resampledSceneXdata), sceneChannels);
    
    for channelIndex = 1:sceneChannels
        singleChannelData = squeeze(sceneData(:,:,channelIndex));
        resampledScene(:,:, channelIndex) = interp2(X,Y, singleChannelData, resampledSceneXgrid, resampledSceneYgrid, 'linear');
    end 
end

function sensor = customizeSensor(sensor, sensorParams, opticalImage)
    
    if (isempty(sensorParams.randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(sensorParams.randomSeed);
    end
    
    eyeMovementScanningParams = sensorParams.eyeMovementScanningParams;
    
    % custom aperture
    pixel  = sensorGet(sensor,'pixel');
    pixel  = pixelSet(pixel, 'size', [1.0 1.0]*sensorParams.coneApertureInMicrons*1e-6);  % specified in meters;
    sensor = sensorSet(sensor, 'pixel', pixel);
    
    % custom LMS densities
    coneMosaic = coneCreate();
    coneMosaic = coneSet(coneMosaic, ...
        'spatial density', [0.0 ...
                           sensorParams.LMSdensities(1) ...
                           sensorParams.LMSdensities(2) ...
                           sensorParams.LMSdensities(3)] );
    sensor = sensorCreateConeMosaic(sensor,coneMosaic);
        
    % sensor wavelength sampling must match that of opticalimage
    sensor = sensorSet(sensor, 'wavelength', oiGet(opticalImage, 'wavelength'));
     
    % no noise on sensor
    sensor = sensorSet(sensor,'noise flag', 0);
    
    % custom size
    sensor = sensorSet(sensor, 'size', sensorParams.spatialGrid);

    % custom time interval
    sensor = sensorSet(sensor, 'time interval', sensorParams.samplingIntervalInMilliseconds/1000.0);
    
    % custom integration time
    sensor = sensorSet(sensor, 'integration time', sensorParams.integrationTimeInMilliseconds/1000.0);
    
    % custom eye movement
    eyeMovement = emCreate();
    
    % custom sample time
    eyeMovement  = emSet(eyeMovement, 'sample time', eyeMovementScanningParams.samplingIntervalInMilliseconds/1000.0);        
    
    % attach eyeMovement to the sensor
    sensor = sensorSet(sensor,'eyemove', eyeMovement);
            
    % generate the fixation eye movement sequence
    if (eyeMovementScanningParams.fixationOverlapFactor == 0)
        xNodes = 0;
        yNodes = 0;
        fx = 1.0;
    else
        xNodes = (round(0.35*oiGet(opticalImage, 'width',  'microns')/sensorGet(sensor, 'width', 'microns')*eyeMovementScanningParams.fixationOverlapFactor));
        yNodes = (round(0.35*oiGet(opticalImage, 'height', 'microns')/sensorGet(sensor, 'height', 'microns')*eyeMovementScanningParams.fixationOverlapFactor));
        if ((xNodes == 0) || (yNodes == 0))
            error(sprintf('\nZero saccadic eye nodes were generated. Consider increasing the fixationOverlapFactor (currently set to: %2.4f)\n', eyeMovementScanningParams.fixationOverlapFactor));
        end
        fx = max(sensorParams.spatialGrid) * sensorParams.coneApertureInMicrons / eyeMovementScanningParams.fixationOverlapFactor;  
    end
    
    fprintf('Saccadic grid: %d x %d\n', 2*xNodes+1, 2*yNodes+1);
    
    saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, sensorParams.coneApertureInMicrons, sensorParams.eyeMovementScanningParams.saccadicScanMode,  oiGet(opticalImage, 'width',  'microns'), oiGet(opticalImage, 'height',  'microns'));
    eyeMovementsNum = size(saccadicTargetPos,1) * round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds);
    eyeMovementPositions = zeros(eyeMovementsNum,2);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    sensor = emGenSequence(sensor);

    % add saccadic targets
    eyeMovementPositions = sensorGet(sensor,'positions');
    
    for eyeMovementIndex = 1:eyeMovementsNum
        kk = 1+floor((eyeMovementIndex-1)/round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds));
        eyeMovementPositions(eyeMovementIndex,:) = eyeMovementPositions(eyeMovementIndex,:) + saccadicTargetPos(kk,:);
    end
    
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
end

function saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, coneApertureInMicrons, saccadicScanMode, opticalImageWidthInMicrons, opticalImageHeightInMicrons)
    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(saccadicScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(saccadicScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', saccadicScanMode);
    end

    % these are in units of cone separations
    saccadicTargetPos(:,1) = round(gridXX(indices)*fx/coneApertureInMicrons);
    saccadicTargetPos(:,2) = round(gridYY(indices)*fx/coneApertureInMicrons);
    
    if (any(abs(saccadicTargetPos(:,1)*coneApertureInMicrons) > opticalImageWidthInMicrons/2))
       [max(abs(squeeze(saccadicTargetPos(:,1))*coneApertureInMicrons)) opticalImageWidthInMicrons/2]
       error('saccadic position (x) outside of optical image size'); 
    end
    if (any(abs(saccadicTargetPos(:,2)*coneApertureInMicrons) > opticalImageHeightInMicrons/2))
        [max(abs(squeeze(saccadicTargetPos(:,2))*coneApertureInMicrons)) opticalImageHeightInMicrons/2]
        error('saccadic position (y) outside of optical image size');
    end
    
    debug = false;
    if (debug)
        % for calibration purposes only
        desiredXposInMicrons = 828.8;
        desiredYposInMicrons = 603.0;
        % transform to units of cone separations
        saccadicTargetPos(:,1) = -round(desiredXposInMicrons/coneApertureInMicrons);
        saccadicTargetPos(:,2) =  round(desiredYposInMicrons/coneApertureInMicrons);
    end
end

function computeSceneMeanAndMedianLMSexcitations(sceneLMS, sceneName)
    meanLMSexcitations = zeros(1,3);
    medianLMSexcitations = zeros(1,3);
    for coneIndex = 1:3
        sceneExcitationSingleCone = squeeze(sceneLMS(:,:,coneIndex));
        meanLMSexcitations(coneIndex) = mean(sceneExcitationSingleCone(:));
        medianLMSexcitations(coneIndex) = median(sceneExcitationSingleCone(:));
    end
    fprintf('%60s: %8s LMS excitations = < %2.3f, %2.3f, %2.3f >\n', sceneName, 'mean',   meanLMSexcitations(1),   meanLMSexcitations(2),   meanLMSexcitations(3));
    fprintf('%60s: %8s LMS excitations = < %2.3f, %2.3f, %2.3f >\n', sceneName, 'median', medianLMSexcitations(1), medianLMSexcitations(2), medianLMSexcitations(3));
end

function scene = makeMacBethWhiteChipAdaptingScene(originalScene, adaptingFieldReflectance, adaptingFieldLuminance, adaptingFieldIlluminant)

    scene = originalScene;
    scene = sceneSet(scene, 'name', sprintf('%s - adaptation field', sceneGet(originalScene, 'name')));
    
    % Retrieve scene wavelength sampling 
    wavelengthSampling = sceneGet(scene,'wave');
    
    % Get the reflectance of the white patch in the MacBeth chart
    fName = fullfile(isetRootPath,'data','surfaces','macbethChart.mat');
    macbethChart = ieReadSpectra(fName, wavelengthSampling);
    
    patchNo = 12;  % scale the 3rd (middle) gray patch
    macbethGrayPatchMeanReflectanceCurve = squeeze(macbethChart(:,patchNo));
    macbethGrayPatchMeanReflectance = mean(macbethGrayPatchMeanReflectanceCurve);
    matchingMacbethReflectance = macbethGrayPatchMeanReflectanceCurve / macbethGrayPatchMeanReflectance * adaptingFieldReflectance;
    
    % choose an illuminant: either the scene's or D65
    if (strcmp(adaptingFieldIlluminant, 'from scene'))
        illuminantToUse = sceneGet(scene, 'illuminant');
    else
        illuminantToUse = illuminantCreate(adaptingFieldIlluminant,wavelengthSampling);
    end
    
    % if an adapting field luminance is passed, set the illuminant to this luminance
    if (~isempty(adaptingFieldLuminance))
        illuminantPhotons = illuminantGet(illuminantToUse, 'photons');
        luminance = ieLuminanceFromPhotons(illuminantPhotons, wavelengthSampling);
        illuminantPhotons = illuminantPhotons / luminance * adaptingFieldLuminance;
        illuminantToUse = illuminantSet(illuminantToUse, 'photons', illuminantPhotons);
        luminanceAfter = ieLuminanceFromPhotons(illuminantPhotons, wavelengthSampling);
    end
    
    % Illuminate scene with chosen illuminant
    adaptationPhotonRate = matchingMacbethReflectance .* reshape(illuminantGet(illuminantToUse, 'photons'), size(matchingMacbethReflectance));
    
    % Hack. Set the scene photons directly, i.e., without going through isetbio.
    scene.data.photons = ...
            repmat(reshape(adaptationPhotonRate, [1 1 numel(adaptationPhotonRate)]), [sceneGet(scene, 'rows') sceneGet(scene, 'cols') 1]);
        
    % Finally set the scene illuminant
    sceneSet(scene, 'illuminant', illuminantToUse);
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