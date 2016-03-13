function generateArtificialScanDataFromExistingScanData(rootPath, osType, adaptingFieldType)
    
    
    adaptiveOpticsConfiguration = 'adaptiveOpticsStimulation';
    adaptiveOpticsImSource = {'ao_database', 'condition1'};
    
    % adaptive optics beam position
    aoBeam = struct(...
        'positionsInRetinalMicrons', [], ...
    	'spatialSpreadInRetinalMicrons', 1.0, ...
    	'photonRateInIsomerizationsPerConePerSecond', 100000, ...
    	'durationInMilliseconds', 100 ...
        );
    
    originalConfiguration = 'manchester';
    scansDir = getScansDir(rootPath, originalConfiguration, adaptingFieldType, osType);
    
    scanIndex = 1;
    imsource = {'manchester_database', 'scene1'};
    
    fileName = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex));
    load(fileName, 'scansNum', 'scanSensor', 'photoCurrents', 'scanPlusAdaptationFieldLMSexcitationSequence', ...
                'LMSexcitationXdataInRetinalMicrons', 'LMSexcitationYdataInRetinalMicrons', ...
                'sensorParams', 'sensorAdaptationFieldParams', ...
                'startingSaccade', 'endingSaccade', 'forcedSceneMeanLuminance');

    totalTime = sensorGet(scanSensor, 'total time');
    timeStep  = sensorGet(scanSensor, 'time interval');
    timeBins  = round(totalTime/timeStep);
    timeAxis  = (0:(timeBins-1))*timeStep;

    isomerizationRate = sensorGet(scanSensor, 'photon rate');
    backgroundPhotonRate = isomerizationRate(1);
    
    trace = squeeze(isomerizationRate(10,10,:));
    
    if strcmp(adaptingFieldType, 'NoAdaptationField')
        stimOnsetBins = 400:200:numel(timeAxis)-1000;
    else
        stimOnsetBins = 400:600:numel(timeAxis)-1000;
    end
    
    % Pick every other to space trials apart
    stimOnsetBins = stimOnsetBins(1:3:end);
    
    stimOffsetBins = stimOnsetBins+aoBeam.durationInMilliseconds;
    stimOnsetTimes = timeAxis(stimOnsetBins);
    stimOffsetTimes = timeAxis(stimOffsetBins);
    
    
    figure(1); clf
    subplot(2,1,1);
    plot(timeAxis, squeeze(photoCurrents(10,10,:)), 'k-');
    subplot(2,1,2);
    plot(timeAxis, trace, 'k-');
    hold on
    for k = 1:numel(stimOnsetBins)
        plot(timeAxis(stimOnsetBins(k))*[1 1], [0 50000], 'r-');
        plot(timeAxis(stimOffsetBins(k))*[1 1], [50000 100000], 'b-');
    end
    set(gca, 'YTick', [1:10]*1e4);
    

    % Generate new sensor describing the adaptive optics conditions
    beforeStimulusTime = 1.0; % 1 second
    afterStimulusTime = 1.0; % 1 second
    stimOnsetTimes = stimOnsetTimes + beforeStimulusTime;
    stimOffsetTimes = stimOffsetTimes + beforeStimulusTime;
    newScanSensor = scanSensor;
    simulationTimeIntervalInSeconds = 0.1/1000;
    newTimeAxisBins = round((totalTime+beforeStimulusTime+afterStimulusTime)/simulationTimeIntervalInSeconds);
    newTimeAxis = (0:(newTimeAxisBins-1))*simulationTimeIntervalInSeconds;
    newScanSensor = sensorSet(newScanSensor, 'time interval', simulationTimeIntervalInSeconds);
    newScanSensor = sensorSet(newScanSensor, 'total time', newTimeAxisBins*simulationTimeIntervalInSeconds);
    
    figure(2);
    clf;
    colormap(bone(1024));
    
    coneTypes = sensorGet(newScanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);

    
    coneXYpositions = sensorGet(newScanSensor, 'xy');
    
    % Create timseries of adaptive optics photon rates

    
    singleConePhotonRate = aoBeam.photonRateInIsomerizationsPerConePerSecond;

    targetLconePos = [-7.5 -1.5];   % [4.5 -4.5];
    targetMconePos = [ -13.5 -10.5]; % [-13.5 19.5];
    
    maxActivatedConesNum = 30;
    for conditionIndex = 1:numel(stimOnsetTimes)
        
        switch conditionIndex
            case 1
                aoBeam.positionsInRetinalMicrons = targetLconePos;
                aoBeam.photonRateInIsomerizationsPerConePerSecond = singleConePhotonRate;
                
            case 2
                Ro = 10;
                lconePositions = coneXYpositions(lConeIndices,:);
                distances = sqrt(sum((bsxfun(@minus, lconePositions, targetLconePos)).^2, 2));
                stimulatedConeIndices = lConeIndices(find(distances < Ro));
                aoBeam.positionsInRetinalMicrons = coneXYpositions(stimulatedConeIndices,:);      
                
            case 3
                Ro = 20;
                lconePositions = coneXYpositions(lConeIndices,:);
                distances = sqrt(sum((bsxfun(@minus, lconePositions, targetLconePos)).^2, 2));
                stimulatedConeIndices = lConeIndices(find(distances < Ro));
                aoBeam.positionsInRetinalMicrons = coneXYpositions(stimulatedConeIndices,:);     
                
            case 4
                aoBeam.positionsInRetinalMicrons = targetMconePos;
                aoBeam.photonRateInIsomerizationsPerConePerSecond = singleConePhotonRate;
            
            case 5
                Ro = 10;
                mconePositions = coneXYpositions(mConeIndices,:);
                distances = sqrt(sum((bsxfun(@minus, mconePositions, targetMconePos)).^2, 2));
                stimulatedConeIndices = mConeIndices(find(distances < Ro));
                aoBeam.positionsInRetinalMicrons = coneXYpositions(stimulatedConeIndices,:); 
            case 6
                Ro = 20;
                mconePositions = coneXYpositions(mConeIndices,:);
                distances = sqrt(sum((bsxfun(@minus, mconePositions, targetMconePos)).^2, 2));
                stimulatedConeIndices = mConeIndices(find(distances < Ro));
                aoBeam.positionsInRetinalMicrons = coneXYpositions(stimulatedConeIndices,:); 
                
            case 7
                Ro = 5;
                R1 = 12;
                R2 = 20;
                lconePositions = coneXYpositions(lConeIndices,:);
                distances = sqrt(sum((bsxfun(@minus, lconePositions, targetLconePos)).^2, 2));
                stimulatedConeIndices = lConeIndices(find((distances < Ro) | ((distances > R1) & (distances < R2))));
                aoBeam.positionsInRetinalMicrons = coneXYpositions(stimulatedConeIndices,:);
        end
            
        aoBeam.photonRateInIsomerizationsPerConePerSecond = singleConePhotonRate/sqrt(size(aoBeam.positionsInRetinalMicrons,1));
        size(aoBeam.positionsInRetinalMicrons,1)
        [coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons, photonRateSpatialProfile(conditionIndex,:,:)] = createSpatialProfile(newScanSensor, aoBeam);
        
        if (conditionIndex == 1)
            stimulusPhotonRate = ones(size(photonRateSpatialProfile,2), size(photonRateSpatialProfile,3), newTimeAxisBins)*backgroundPhotonRate;
        end
        
        [~, bin1] = min(abs(newTimeAxis-stimOnsetTimes(conditionIndex)));
        [~, bin2] = min(abs(newTimeAxis-stimOffsetTimes(conditionIndex)));
        stimulusPhotonRate(:,:, bin1:bin2) = stimulusPhotonRate(:,:, bin1:bin2) + ...
            repmat(squeeze(photonRateSpatialProfile(conditionIndex,:,:)), [1 1 bin2-bin1+1]);
        
        subplot(5,4,conditionIndex);
        imagesc(coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons, squeeze(photonRateSpatialProfile(conditionIndex,:,:)));
        hold on;
        for coneIndex = 1:numel(coneTypes)
            if ismember(coneIndex, lConeIndices)
                RGBcolor = [1 0 0 ];
            elseif ismember(coneIndex, mConeIndices)
                RGBcolor = [0 1 0 ];
            elseif ismember(coneIndex, sConeIndices)
                RGBcolor = [0 0 1];
            end
            plot(coneXYpositions(coneIndex,1), coneXYpositions(coneIndex,2), 'ko', 'MarkerEdgeColor', RGBcolor);
        end
        
        hold off;
        set(gca, 'CLim', [0 50000])
        axis 'xy';
        axis 'image'
        axis 'square'
        drawnow;
    end
   
    newScanSensor = sensorSet(newScanSensor, 'photon rate', stimulusPhotonRate);
    
    % Compute outer segment responses
    if (strcmp(osType, 'biophysics-based'))
        osOBJ = osBioPhys();
    else
        osOBJ = osLinear();
    end
        
    osOBJ.osSet('noiseFlag', 1);
    osOBJ.osCompute(newScanSensor);
    photoCurrents = osGet(osOBJ, 'ConeCurrentSignal');

    
    % do the sub-sampling as we do with the hyperspectral responses
    % there is no LMS sequence in adaptive optics, so set it to background
    backgroundLMS = squeeze(scanPlusAdaptationFieldLMSexcitationSequence(1,1,1,:));
    scanPlusAdaptationFieldLMSexcitationSequence = repmat(reshape(backgroundLMS, [1 1 1 3]), ...
        [newTimeAxisBins size(scanPlusAdaptationFieldLMSexcitationSequence,2) size(scanPlusAdaptationFieldLMSexcitationSequence,3) 1]);
    
    newTimeStepInMilliseconds = 1.0;
    fprintf('\tDownsampling to a resolution of %2.2f milliseconds\n', newTimeStepInMilliseconds);
    [scanPlusAdaptationFieldLMSexcitationSequence, photoCurrents, newScanSensor] = ...
            subSampleSequences(scanPlusAdaptationFieldLMSexcitationSequence, photoCurrents, newScanSensor, newTimeStepInMilliseconds/1000.0);

       
    
    
    % Save everything
    scanSensor = newScanSensor;
    scansDir = getScansDir(rootPath, adaptiveOpticsConfiguration, adaptingFieldType, osType);
    scanIndex = 1;
    

    
    
    fileName = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', adaptiveOpticsImSource{1}, adaptiveOpticsImSource{2}, scanIndex));
    save(fileName, 'scansNum', 'scanSensor', 'photoCurrents', 'scanPlusAdaptationFieldLMSexcitationSequence', ...
                'LMSexcitationXdataInRetinalMicrons', 'LMSexcitationYdataInRetinalMicrons', ...
                'sensorParams', 'sensorAdaptationFieldParams', ...
                'startingSaccade', 'endingSaccade', 'forcedSceneMeanLuminance', '-v7.3');
            

    totalTime = sensorGet(scanSensor, 'total time');
    timeStep  = sensorGet(scanSensor, 'time interval');
    timeBins  = round(totalTime/timeStep);
    timeAxis  = (0:(timeBins-1))*timeStep;
    
     figure(3);
     clf;
     size(photoCurrents)
     subplot(2,1,1)
     imagesc(timeAxis, [1:400], reshape(stimulusPhotonRate, [size(stimulusPhotonRate,1)*size(stimulusPhotonRate,2) size(stimulusPhotonRate,3)]));
     subplot(2,1,2)
     plot(timeAxis, reshape(photoCurrents, [size(photoCurrents,1)*size(photoCurrents,2) size(photoCurrents,3)]), 'k-');
     drawnow
        
end

function [coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons, photonRateSpatialProfile] = createSpatialProfile(scanSensor, aoBeam)

    coneXYpositions = sensorGet(scanSensor, 'xy');
    coneMosaicSpatialXdataInRetinalMicrons = sort(unique(coneXYpositions(:,1)));
    coneMosaicSpatialYdataInRetinalMicrons = sort(unique(coneXYpositions(:,2)));
    
    [X,Y] = meshgrid(coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons);
    photonRateSpatialProfile = zeros(size(X));
    
    for beamPointIndex = 1:size(aoBeam.positionsInRetinalMicrons,1)
        xo = aoBeam.positionsInRetinalMicrons(beamPointIndex,1);
        yo = aoBeam.positionsInRetinalMicrons(beamPointIndex,2);
        sigma = aoBeam.spatialSpreadInRetinalMicrons;
        gain  = aoBeam.photonRateInIsomerizationsPerConePerSecond;
        photonRateSpatialProfile = photonRateSpatialProfile + gain * exp(-0.5*(((X-xo)/sigma).^2)) .* exp(-0.5*(((Y-yo)/sigma).^2));
    end
    

end


