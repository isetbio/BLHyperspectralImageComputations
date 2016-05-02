function [sensor, fixationTimes, adaptingFieldFixationTimes] = customizeSensor(originalSensor, sensorParams, opticalImage, borderFraction)
    
    sensor = originalSensor;
    
    if (isempty(sensorParams.randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(sensorParams.randomSeed);
    end
    
    % custom lens optical density
    if (~isempty(sensorParams.lensOpticalDensity))   
       lens = sensorGet(sensor, 'human lens');
       lens = lensSet(lens, 'density', sensorParams.lensOpticalDensity);
       sensor = sensorSet(sensor, 'human lens', lens);
    end
    
    % custom macular optical density
    if (~isempty(sensorParams.macularOpticalDensity))
        macular = sensorGet(sensor, 'human macular');
        macular = macularSet(macular, 'density', sensorParams.macularOpticalDensity);
        sensor = sensorSet(sensor, 'human macular', macular);
    end
    
    % custom cone peak optical densities
    if (~isempty(sensorParams.conePeakOpticalDensities))
        humanCone = sensorGet(sensor, 'human cone');
        humanCone = coneSet(humanCone, 'pods', reshape(sensorParams.conePeakOpticalDensities, [3 1]));
        sensor = sensorSet(sensor, 'human cone', humanCone);
    end

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
    eyeMovement  = emSet(eyeMovement, 'sample time', sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds/1000.0);        
    
    % attach eyeMovement to the sensor
    sensor = sensorSet(sensor,'eyemove', eyeMovement);
    
    % generate the fixation eye movement sequence
    oiWidthInMicrons      = oiGet(opticalImage, 'width',  'microns');
    oiHeightInMicrons     = oiGet(opticalImage, 'height',  'microns');
    sensorWidthInMicrons  = sensorGet(sensor, 'width', 'microns');
    sensorHeightInMicrons = sensorGet(sensor, 'height', 'microns');
    
    if (sensorParams.eyeMovementScanningParams.fixationOverlapFactor == 0)
        xNodes = 0;
        yNodes = 0;
        fx = 1.0;
    else
        xNodesNeg = -(round(0.35 * oiWidthInMicrons/sensorWidthInMicrons * sensorParams.eyeMovementScanningParams.fixationOverlapFactor));
        xNodesPos =  (round(0.35*(1.0-2.2*borderFraction) * oiWidthInMicrons/sensorWidthInMicrons * sensorParams.eyeMovementScanningParams.fixationOverlapFactor));
        yNodes = (round(0.35 * oiHeightInMicrons/sensorHeightInMicrons * sensorParams.eyeMovementScanningParams.fixationOverlapFactor));
        if (yNodes == 0)
            error('\nZero saccadic eye nodes were generated. Consider increasing the fixationOverlapFactor (currently set to: %2.4f)\n', sensorParams.eyeMovementScanningParams.fixationOverlapFactor);
        end
        fx(1) = sensorWidthInMicrons / sensorParams.eyeMovementScanningParams.fixationOverlapFactor;  
        fx(2) = sensorHeightInMicrons / sensorParams.eyeMovementScanningParams.fixationOverlapFactor; 
    end
    
    fprintf('Saccadic grid: %d x %d\n', (xNodesPos-xNodesNeg+1), 2*yNodes+1);
    saccadicTargetPos = generateSaccadicTargets(xNodesNeg, xNodesPos, yNodes, fx, ...
        sensorParams.coneApertureInMicrons, sensorParams.eyeMovementScanningParams.saccadicScanMode,  ...
        oiWidthInMicrons, oiHeightInMicrons);
    
    % Generate a normal distribution of fixation durations
    mu = sensorParams.eyeMovementScanningParams.meanFixationDurationInMilliseconds;
    sigma = sensorParams.eyeMovementScanningParams.stDevFixationDurationInMilliseconds;
    
    % Vector of fixation durations
    fixationsNum = size(saccadicTargetPos,1);
    fixationDurationsInMilliseconds = round(mu + randn(1,fixationsNum)*sigma);
    fixationDurationsInTimeSteps = fixationDurationsInMilliseconds/sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds;
    eyeMovementsNum = sum(fixationDurationsInTimeSteps);
    
    
    % Generate saccadic targets to the adapting field
    saccadicAdaptingFieldTargetPos = generateAdaptingFieldSaccadicTargets(yNodes, fx, ...
        sensorParams.coneApertureInMicrons, sensorParams.eyeMovementScanningParams.saccadicScanMode,  ...
        oiWidthInMicrons, oiHeightInMicrons, borderFraction);
    
    
    % Generate a normal distribution of fixation durations
    mu = sensorParams.eyeMovementScanningParams.meanFixationDurationInMillisecondsForAdaptingField;
    sigma = sensorParams.eyeMovementScanningParams.stDevFixationDurationInMillisecondsForAdaptingField;
    
    % Vector of fixation durations
    adaptingFieldFixationsNum = size(saccadicAdaptingFieldTargetPos ,1);
    adaptingFieldFixationDurationsInMilliseconds = round(mu + randn(1,adaptingFieldFixationsNum)*sigma);
    adaptingFieldFixationDurationsInTimeSteps = adaptingFieldFixationDurationsInMilliseconds/sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds;
    eyeMovementsNum = eyeMovementsNum + sum(adaptingFieldFixationDurationsInTimeSteps);
    
    printEyeMovementStats = false;
    if (printEyeMovementStats)
        fprintf('number of total eye movements: %d\n', eyeMovementsNum);
        fprintf('mean fixation dur: %2.1f (std: %2.1f))\n', mean(fixationDurationsInMilliseconds), std(fixationDurationsInMilliseconds));
        fprintf('mean (adapting)fixation dur: %2.1f (std: %2.1f))\n', mean(adaptingFieldFixationDurationsInMilliseconds), std(adaptingFieldFixationDurationsInMilliseconds));
    end
    
    % generate all eye movements centered at (0,0)
    eyeMovementPositions = zeros(eyeMovementsNum,2);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    sensor = emGenSequence(sensor);

    fixationTimes.onsetBins = zeros(1, fixationsNum);
    fixationTimes.offsetBins = zeros(1, fixationsNum);
    
    adaptingFieldFixationTimes.onsetBins = zeros(1, adaptingFieldFixationsNum);
    adaptingFieldFixationTimes.offsetBins = zeros(1, adaptingFieldFixationsNum);
    
    % add saccadic targets to sensor
    eyeMovementPositions = sensorGet(sensor,'positions') * sensorParams.eyeMovementScanningParams.microFixationGain;
    lastPos = 0;
    for fixationIndex = 1:fixationsNum 
        saccadicPos = squeeze(saccadicTargetPos(fixationIndex,:));
        firstPos = lastPos + 1;
        lastPos  = lastPos + fixationDurationsInTimeSteps(fixationIndex);
        eyeMovementPositions(firstPos:lastPos,:) = bsxfun(@plus, eyeMovementPositions(firstPos:lastPos,:), saccadicPos);
        fixationTimes.onsetBins(fixationIndex)  = firstPos;
        fixationTimes.offsetBins(fixationIndex) = lastPos;
    end
    
    for fixationIndex = 1:adaptingFieldFixationsNum
        saccadicPos = squeeze(saccadicAdaptingFieldTargetPos(fixationIndex,:));
        firstPos = lastPos + 1;
        lastPos  = lastPos + adaptingFieldFixationDurationsInTimeSteps(fixationIndex);
        eyeMovementPositions(firstPos:lastPos,:) = bsxfun(@plus, eyeMovementPositions(firstPos:lastPos,:), saccadicPos);
        adaptingFieldFixationTimes.onsetBins(fixationIndex)  = firstPos;
        adaptingFieldFixationTimes.offsetBins(fixationIndex) = lastPos;
    end
   

    % attach the new positions to the sensor
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    
    % plotting at the end
    showEyeMovements = false;
    if (showEyeMovements) 
        totalTime = sensorGet(sensor, 'total time');
        timeAxisInMilliseconds = 1000.0*linspace(0, totalTime, size(eyeMovementPositions,1)); 
        
        timeBinsToView = 1:min([40000 size(eyeMovementPositions,1)]);
        
        h = figure(100); set(h, 'Position', [10 10 1561 1171]);
        subplot(2,1,1)
        plot(timeAxisInMilliseconds(timeBinsToView), eyeMovementPositions(timeBinsToView,1), 'r-');
        hold on;
        for fixationIndex = 1:fixationsNum
            saccadicPos = squeeze(saccadicTargetPos(fixationIndex,:));
            plot([fixationTimes.onsetBins(fixationIndex) fixationTimes.offsetBins(fixationIndex)]*sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds, saccadicPos(1)*[1 1], '--', 'LineWidth', 2.0);
        end
        ylabel('x-pos');
        set(gca, 'XLim', [timeAxisInMilliseconds(timeBinsToView(1)) timeAxisInMilliseconds(timeBinsToView(end))]);
        
        subplot(2,1,2)
        plot(timeAxisInMilliseconds(timeBinsToView), eyeMovementPositions(timeBinsToView,2), 'b-');
        hold on;
        for fixationIndex = 1:fixationsNum
            saccadicPos = squeeze(saccadicTargetPos(fixationIndex,:));
            plot([fixationTimes.onsetBins(fixationIndex) fixationTimes.offsetBins(fixationIndex)]*sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds, saccadicPos(2)*[1 1], '--', 'LineWidth', 2.0);
        end
        set(gca, 'XLim', [timeAxisInMilliseconds(timeBinsToView(1)) timeAxisInMilliseconds(timeBinsToView(end))]);
        ylabel('y-pos');
    end
end

function saccadicTargetPos = generateAdaptingFieldSaccadicTargets(yNodes, fx, coneApertureInMicrons, saccadicScanMode, opticalImageWidthInMicrons, opticalImageHeightInMicrons, borderFraction)
    
    [gridXX,gridYY] = meshgrid(1,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(saccadicScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(saccadicScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', saccadicScanMode);
    end

    % these are in units of cone separations
    saccadicTargetPos(:,2) = round(gridYY(indices)*fx(2)/coneApertureInMicrons);
    saccadicTargetPos(:,1) = (opticalImageWidthInMicrons)*(0.40-borderFraction/2)/coneApertureInMicrons;
    
    if (any(abs(saccadicTargetPos(:,1)*coneApertureInMicrons) > opticalImageWidthInMicrons/2))
        [max(abs(squeeze(saccadicTargetPos(:,1))*coneApertureInMicrons)) opticalImageWidthInMicrons/2]
        error('saccadic adapting position (x) outside of optical image size'); 
    end
    if (any(abs(saccadicTargetPos(:,2)*coneApertureInMicrons) > opticalImageHeightInMicrons/2))
        [max(abs(squeeze(saccadicTargetPos(:,2))*coneApertureInMicrons)) opticalImageHeightInMicrons/2]
        error('saccadic adapting position (y) outside of optical image size');
    end
    
end

function saccadicTargetPos = generateSaccadicTargets(xNodesNeg, xNodesPos, yNodes, fx, coneApertureInMicrons, saccadicScanMode, opticalImageWidthInMicrons, opticalImageHeightInMicrons)
    [gridXX,gridYY] = meshgrid(xNodesNeg:xNodesPos,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(saccadicScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(saccadicScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', saccadicScanMode);
    end
    
    % these are in units of cone separations
    saccadicTargetPos(:,1) = round(gridXX(indices)*fx(1)/coneApertureInMicrons);
    saccadicTargetPos(:,2) = round(gridYY(indices)*fx(2)/coneApertureInMicrons);
    
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


