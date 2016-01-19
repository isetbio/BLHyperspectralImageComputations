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
    fixationOverlapFactor = 0.15;           % overlapFactor of 1, results in sensor positions that just abut each other, 2 more dense 0.5 less dense
    saccadesPerScan = 10;                   % parse the eye movement data into scans, each scan having this many saccades
    saccadicScanMode = 'randomized';        % 'randomized' or 'sequential', to visit eye position grid sequentially
    debug = true;                          % set to true, to see the eye scanning and the responses
    
    
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        % custom cone aperture
        'LMSdensities', [0.6 0.4 0.1], ...       % custom percentages of L,M and S cones
        'spatialGrid', [10 15], ...              % generate mosaic of 20 x 20 cones
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
        
        
        % Show optical image
        vcAddAndSelectObject(oi); oiWindow;
        
        % create custom human sensor
        sensor = sensorCreate('human');
        sensor = customizeSensor(sensor, sensorParams, oi);
        
        % extract the LMS cone stimulus sequence encoded by sensor at all visited positions
        LMSstimulusSequence = computeLMSstimulusSequence(sensor, scene);
        
        if (~debug)
            % we do not need the scene any more so clear it
            clear 'scene'
        end
        
        % compute isomerization rage for all positions
        sensor = coneAbsorptions(sensor, oi);
        
        % extract the full isomerization rate sequence across all positions
        isomerizationRate = sensorGet(sensor, 'photon rate');
        sensorPositions   = sensorGet(sensor,'positions');
        
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


function LMSstimulusSequence = computeLMSstimulusSequence(sensor, scene)
    LMSstimulusSequence = []
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

