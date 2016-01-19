% Method to generate custom sensor and compute isomerizations rates
% for a bunch of images, each scanned by eye movements 
function computeIsomerizations

    % reset
    %ieInit; close all;
    
    addNeddedToolboxesToPath();
    
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    
    % Spacify images
    imageSources = {...
        {'manchester_database', 'scene1'} ...
        {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
        {'manchester_database', 'scene4'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    % Get directory location where optical images are to be saved
    getpref('HyperSpectralImageIsetbioComputations','opticalImagesCacheDir');
    
    % simulation time step. same for eye movements and for sensor, outersegment
    timeStepInMilliseconds = 0.1;
    fixationOverlapFactor = 1.0;           % overlapFactor of 1, results in sensor positions that just abut each other, 2 more dense 0.5 less dense
    saccadesPerScan = 10;                   % parse the eye movement data into scans, each scan having this many saccades
    saccadicScanMode = 'sequential';        % 'randomized' or 'sequential', to visit eye position grid sequentially
    debug = true;                          % set to true, to see the eye scanning and the responses
    
    
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        % custom cone aperture
        'LMSdensities', [0.6 0.4 0.1], ...       % custom percentages of L,M and S cones
        'spatialGrid', [20 30], ...              % generate mosaic of 20 x 20 cones
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
        'integrationTimeInMilliseconds', 50, ...
        'randomSeed', 1552784, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', 300, ...
            'fixationOverlapFactor', fixationOverlapFactor, ...     
            'saccadicScanMode',  saccadicScanMode ...
        ) ...
    );
    
    for imageIndex = 1:numel(imageSources)
        % retrieve scene
        fprintf('Fetching data. Please wait ...\n');
        imsource = imageSources{imageIndex};
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
        
        % Set mean luminance of all scenes to 400 cd/m2
        scene = sceneAdjustLuminance(scene, 200);
        
        % Show scene
        vcAddAndSelectObject(scene); sceneWindow;
       
        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);
        
        % Retrieve retinal microns&degrees per pixel
        retinalMicronsPerPixel = oiGet(oi, 'wres','microns');
        retinalDegreesPerPixel = oiGet(oi, 'angularresolution');
        retinalMicronsPerDegreeX = retinalMicronsPerPixel / retinalDegreesPerPixel(1);
        retinalMicronsPerDegreeY = retinalMicronsPerPixel / retinalDegreesPerPixel(2);
    
        % Show optical image
        vcAddAndSelectObject(oi); oiWindow;
        
        % create custom human sensor
        sensor = sensorCreate('human');
        sensor = customizeSensor(sensor, sensorParams, oi);
        

        % compute isomerization rage for all positions
        sensor = coneAbsorptions(sensor, oi);
        
        % extract the full isomerization rate sequence across all positions
        isomerizationRate = sensorGet(sensor, 'photon rate');
        sensorPositions   = sensorGet(sensor,'positions');
        
        % extract the LMS cone stimulus sequence encoded by sensor at all visited positions
        LMSstimulusSequence = computeLMSstimulusSequence(sensor, scene, [retinalMicronsPerDegreeX retinalMicronsPerDegreeY]);
        if (~debug)
            % we do not need the scene any more so clear it
            clear 'scene'
        end
        
        % parse the data into scans, each scan having saccadesPerScansaccades
        positionsPerFixation = round(sensorParams.eyeMovementScanningParams.fixationDurationInMilliseconds / sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds); 
        fixationsNum = size(sensorGet(sensor,'positions'),1) / positionsPerFixation;
        scansNum = floor(fixationsNum/saccadesPerScan);
        fprintf('Data sets generated for this image: %d\n', scansNum);
        
        % reset sensor positions and isomerization rate
        sensor = sensorSet(sensor, 'photon rate', []);
        sensor = sensorSet(sensor, 'positions', []);
        
        for scanIndex = 1:scansNum    
            % define a new sequence of saccades
            startingSaccade = 1+(scanIndex-1)*10;
            endingSaccade = startingSaccade + 9;
            positionIndices = 1 + ((startingSaccade-1)*positionsPerFixation : endingSaccade*positionsPerFixation-1);
            fprintf('Analyzed positions: %d-%4d\n', positionIndices(1), positionIndices(end));
            
            % generate new sensor with given sub-sequence
            scanSensor = sensor;
            scanSensor = sensorSet(scanSensor, 'photon rate', isomerizationRate(:,:,positionIndices));
            scanSensor = sensorSet(scanSensor, 'positions',   sensorPositions(positionIndices,:));
            
            % save the scanSensor
            fileName = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            save(fileName, 'scanSensor', 'startingSaccade', 'endingSaccade');
            
            if (debug)
                osB = osBioPhys();
                osB.osSet('noiseFlag', 1);
                osB.osCompute(scanSensor);
                figNum = 200+scanIndex;
                osWindow(figNum, 'biophys-based outer segment', osB, scanSensor, oi, scene);
                pause
            end
        end
        
        % save the optical image and the number of data sets
        fileName = sprintf('%s_%s_opticalImage.mat', imsource{1}, imsource{2});
        save(fileName, 'oi', 'scansNum');
    end % imageIndex
end


function LMSstimulusSequence = computeLMSstimulusSequence(sensor, scene, retinalMicronsPerDegree)
    LMSstimulusSequence = [];
    
    % compute sensor positions (due to eye movements) in microns
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    pos = sensorGet(sensor,'positions');
    isomerizationRate = sensorGet(sensor, 'photon rate');
    
    sensorPositionsInMicrons = pos * 0;
    sensorPositionsInMicrons(:,1) = -pos(:,1)*sensorSampleSeparationInMicrons(1);
    sensorPositionsInMicrons(:,2) =  pos(:,2)*sensorSampleSeparationInMicrons(2);

    % compute sensor cone sampling grid
    sensorRowsCols = sensorGet(sensor, 'size');
    dx = sensorRowsCols(2) * sensorSampleSeparationInMicrons(2);
    dy = sensorRowsCols(1) * sensorSampleSeparationInMicrons(1);
    sensorSizeInMicrons = [dx dy];
    [R,C] = meshgrid(1:sensorRowsCols(1), 1:sensorRowsCols(2));
    R = R'; C = C';
    sensorXsamplingGrid = (C(:)-0.5) * sensorSampleSeparationInMicrons(1);
    sensorYsamplingGrid = (R(:)-0.5) * sensorSampleSeparationInMicrons(2);
    
    % get cone types
    coneTypes = sensorGet(sensor, 'cone type')-1;
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    
    % Create the scene XY grid in retinal microns, (not scene microns), because the sensor is specified in retinal microns
    sceneSpatialSupportInMicrons = sceneGet(scene,'spatial support','microns');
    degreesPerSample = sceneGet(scene,'deg per samp');
    micronsPerSample = sceneGet(scene,'distPerSamp','microns');
    sceneSpatialSupportInDegrees(:,:,1) = sceneSpatialSupportInMicrons(:,:,1) / micronsPerSample(1) * degreesPerSample;
    sceneSpatialSupportInDegrees(:,:,2) = sceneSpatialSupportInMicrons(:,:,2) / micronsPerSample(2) * degreesPerSample;

    % Spatial support in retinal microns
    sceneSpatialSupportInRetinalMicrons(:,:,1) = sceneSpatialSupportInDegrees(:,:,1) * retinalMicronsPerDegree(1);
    sceneSpatialSupportInRetinalMicrons(:,:,2) = sceneSpatialSupportInDegrees(:,:,2) * retinalMicronsPerDegree(2);

    sceneXgrid = squeeze(sceneSpatialSupportInRetinalMicrons(:,:,1)); 
    sceneYgrid = squeeze(sceneSpatialSupportInRetinalMicrons(:,:,2));
    sceneXdata = squeeze(sceneXgrid(1,:));  % x-positions from 1st row in retinal microns
    sceneYdata = squeeze(sceneYgrid(:,1));  % y-positions from 1st col in retinal microns
            
    % Obtain the scene Stockman LMS excitation values
    sceneStockmanLMSexitations = sceneGet(scene, 'lms');
    sceneRGB =  sceneGet(scene, 'rgb image');
    ClimRange = [min(sceneStockmanLMSexitations(:)) max(sceneStockmanLMSexitations(:))];
    
    photonRange = [min(isomerizationRate(:)) max(isomerizationRate(:))];

    for posIndex = 1:3000:size(sensorPositionsInMicrons,1)
        currentSensorPosition = sensorPositionsInMicrons(posIndex,:);
        sensorActivation = squeeze(isomerizationRate(:,:,posIndex));
        
        % determine scene portion under sensor at each sensor position
        % find scene pixels falling within the sensor outline
        pixelIndices = find(...
            (sceneXgrid >= currentSensorPosition(1) - sensorSizeInMicrons(1)*0.6) & ...
            (sceneXgrid <= currentSensorPosition(1) + sensorSizeInMicrons(1)*0.6) & ...
            (sceneYgrid >= currentSensorPosition(2) - sensorSizeInMicrons(2)*0.6) & ...
            (sceneYgrid <= currentSensorPosition(2) + sensorSizeInMicrons(2)*0.6) );
        [rows, cols] = ind2sub(size(sceneXgrid), pixelIndices);
            
        rowRange = min(rows):1:max(rows);
        colRange = min(cols):1:max(cols);
        
        sensorViewStockmanLMSexcitations = sceneStockmanLMSexitations(rowRange,colRange,:);
        xGridSubset = sceneXgrid(rowRange, colRange);
        yGridSubset = sceneYgrid(rowRange, colRange);
        sensorViewXdata = squeeze(xGridSubset(1,:));
        sensorViewYdata = squeeze(yGridSubset(:,1));
        
        h = figure(11);
        clf;
        set(h, 'Name', sprintf('pos: %d / %d', posIndex,size(sensorPositionsInMicrons,1)));
        subplot(4,2,[1 2]);
        image(sensorViewXdata, sensorViewYdata, sceneRGB(rowRange, colRange,:));
        hold on;

        coneXpos = currentSensorPosition(1) -sensorSizeInMicrons(1)/2 +  sensorXsamplingGrid;
        coneYpos = currentSensorPosition(2) -sensorSizeInMicrons(2)/2 +  sensorYsamplingGrid;
        coneApertureInMicrons = 3;
        th = [0:10:360]/360*2*pi;
        xc = cos(th)*coneApertureInMicrons/2;
        yc = sin(th)*coneApertureInMicrons/2;
        for coneRow = 1:sensorRowsCols(1)
            for coneCol = 1:sensorRowsCols(2)
               coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
               plot(coneXpos(coneIndex)+xc, coneYpos(coneIndex)+yc, '-', 'Color', squeeze(coneColors(coneTypes(coneIndex),:)));
            end
        end
        
        hold off;
        set(gca, 'CLim', [0 1]);
        axis 'image'
        title('scene');
        
        subplot(4,2,3);
        targetCone = 1;
        imagesc(sensorViewXdata, sensorViewYdata, squeeze(sensorViewStockmanLMSexcitations(:,:,1)));
        hold on;
        for coneRow = 1:sensorRowsCols(1)
            for coneCol = 1:sensorRowsCols(2)
               coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
               if (coneTypes(coneIndex) == targetCone)
                    plot(coneXpos(coneIndex)+xc, coneYpos(coneIndex)+yc, '-', 'Color', squeeze(coneColors(targetCone,:)));
               end
            end
        end
        hold off;
        set(gca, 'CLim', ClimRange);
        axis 'image'
        title('L cone excitation (scene)');
        
        
        subplot(4,2,4)
        [mosaicActivationImageXdata, mosaicActivationImageYdata, LconeMosaicActivation] = generateMosaicActivationImage(sensorActivation, sensorRowsCols, coneTypes, targetCone);
        imagesc(mosaicActivationImageXdata, mosaicActivationImageYdata, LconeMosaicActivation);
        set(gca, 'CLim', photonRange);
        axis 'image'
        title('L cone excitation (mosaic)');
        
        subplot(4,2,5);
        targetCone = 2;
        imagesc(sensorViewXdata, sensorViewYdata, squeeze(sensorViewStockmanLMSexcitations(:,:,2)));
        hold on;
        for coneRow = 1:sensorRowsCols(1)
            for coneCol = 1:sensorRowsCols(2)
               coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
               if (coneTypes(coneIndex) == targetCone)
                    plot(coneXpos(coneIndex)+xc, coneYpos(coneIndex)+yc, '-', 'Color', squeeze(coneColors(targetCone,:)));
               end
            end
        end
        hold off;
        set(gca, 'CLim', ClimRange);
        axis 'image'
        title('M cone excitation (scene)');
        
        subplot(4,2,6)
        [mosaicActivationImageXdata, mosaicActivationImageYdata, MconeMosaicActivation] = generateMosaicActivationImage(sensorActivation, sensorRowsCols, coneTypes, targetCone);
        imagesc(mosaicActivationImageXdata, mosaicActivationImageYdata, MconeMosaicActivation);
        set(gca, 'CLim',  photonRange);
        axis 'image'
        title('M cone excitation (mosaic)');
        
        subplot(4,2,7);
        targetCone = 3;
        imagesc(sensorViewXdata, sensorViewYdata, squeeze(sensorViewStockmanLMSexcitations(:,:,3)));
        hold on;
        for coneRow = 1:sensorRowsCols(1)
            for coneCol = 1:sensorRowsCols(2)
               coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
               if (coneTypes(coneIndex) == targetCone)
                    plot(coneXpos(coneIndex)+xc, coneYpos(coneIndex)+yc, '-', 'Color', squeeze(coneColors(targetCone,:)));
               end
            end
        end
        hold off;
        axis 'image'
        set(gca, 'CLim', ClimRange);
        title('S cone excitation (scene)');
        colormap(gray);
        
        subplot(4,2,8);
        [mosaicActivationImageXdata, mosaicActivationImageYdata, SconeMosaicActivation] = generateMosaicActivationImage(sensorActivation, sensorRowsCols, coneTypes, targetCone);
        imagesc(mosaicActivationImageXdata, mosaicActivationImageYdata, SconeMosaicActivation);
        set(gca, 'CLim',  photonRange/20);
        axis 'image'
        title('S cone excitation (mosaic, x20)');
        
        drawnow;
    end         
end

function [mosaicActivationImageXdata, mosaicActivationImageYdata, mosaicActivationImage] = generateMosaicActivationImage(sensorActivation, sensorRowsCols, coneTypes, targetCone)

    upSampleFactor = 7;
    zeroPadRows = 2;
    zeroPadCols = 2;
    
    mosaicActivationImage = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor);
    for coneRow = 1:sensorRowsCols(1)
        for coneCol = 1:sensorRowsCols(2)
           coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
           if (coneTypes(coneIndex) == targetCone)
                mosaicActivationImage((coneRow+zeroPadRows)*upSampleFactor+(upSampleFactor-1)/2, (coneCol+zeroPadCols)*upSampleFactor+(upSampleFactor-1)/2) = sensorActivation(coneRow, coneCol);
           end
        end
    end
    
    x = -(upSampleFactor-1)/2:(upSampleFactor-1)/2;
    [X,Y] = meshgrid(x,x);
    sigma = upSampleFactor/2.5;
    gaussianKernel = exp(-0.5*(X/sigma).^2).*exp(-0.5*(Y/sigma).^2);
    gaussianKernel = gaussianKernel / max(gaussianKernel(:));
    mosaicActivationImageXdata = size(mosaicActivationImage,2)-round(0.5*size(mosaicActivationImage,2));
    mosaicActivationImageYdata = size(mosaicActivationImage,1)-round(0.5*size(mosaicActivationImage,1));
    mosaicActivationImage = conv2(mosaicActivationImage, gaussianKernel, 'same');  
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
    pixel  = pixelSet(pixel, 'size', [1.0 1.0]*sensorParams.coneApertureInMicrons*1e-6);  % specified in meters);
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
    xNodes = floor(0.35*oiGet(opticalImage, 'width',  'microns')/sensorGet(sensor, 'width', 'microns')*eyeMovementScanningParams.fixationOverlapFactor);
    yNodes = floor(0.35*oiGet(opticalImage, 'height', 'microns')/sensorGet(sensor, 'height', 'microns')*eyeMovementScanningParams.fixationOverlapFactor);
    fx = round(sensorParams.spatialGrid(1)/eyeMovementScanningParams.fixationOverlapFactor);
    saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, sensorParams.eyeMovementScanningParams.saccadicScanMode);
    
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

function saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, saccadicScanMode)
    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(saccadicScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(saccadicScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', saccadicScanMode);
    end
    
    saccadicTargetPos(:,1) = gridXX(indices)*fx; 
    saccadicTargetPos(:,2) = gridYY(indices)*fx;
    
    %saccadicTargetPos(:,1) = -850/3;
    %saccadicTargetPos(:,2) = -390/3;
    
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
    
function addNeddedToolboxesToPath()
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    addpath(genpath(pwd));
    cd ..
    cd ..
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
end

