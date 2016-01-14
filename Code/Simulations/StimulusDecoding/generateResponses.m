function generateResponses

    % reset
    ieInit; close all;
    
    addNeddedToolboxesToPath();
    
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    
    % Spacify images
    imageSources = {...
        {'manchester_database', 'scene1'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    % Get directory location where optical images are to be saved
    getpref('HyperSpectralImageIsetbioComputations','opticalImagesCacheDir');
    
    % simulation time step. same for eye movements and for sensor, outersegment
    timeStepInMilliseconds = 0.1;
    
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        % custom cone aperture
        'LMSdensities', [0.6 0.4 0.1], ...       % custom percentages of L,M and S cones
        'spatialGrid', [20 20], ...              % generate mosaic of 20 x 20 cones
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
        'integrationTimeInMilliseconds', 50, ...
        'randomSeed', 1552784, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', 300, ...
            'fixationOverlapFactor', 1.0, ...     % overlapFactor of 1, results in sensor positions that just abut each other
            'positionScanMode',  'randomized' ... % 'randomized' or 'sequential' to visit eye position grid sequentially
        ) ...
    );
    
    for imageIndex = 1:numel(imageSources)
        % retrieve scene
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
        
        positionsPerFixation = round(sensorParams.eyeMovementScanningParams.fixationDurationInMilliseconds / sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds); 
        fixationsNum = size(sensorGet(sensor,'positions'),1) / positionsPerFixation;
        
        % compute isomerization rage for all positions
        sensor = coneAbsorptions(sensor, oi);
        
        % save full isomerization rate and positions
        isomerizationRate = sensorGet(sensor, 'photon rate');
        sensorPositions   = sensorGet(sensor,'positions');
        
        % reset sensor positions and isomerization rate
        sensor = sensorSet(sensor, 'photon rate', []);
        sensor = sensorSet(sensor, 'positions', []);
        
        % compute currents for different fixation sub-sequences
        saccadicPosRanges = [ 1 10; ...                   % first group of 10 saccades
                             11 20; ...                   % second  group of 10 saccades
                             [-9 0] + fixationsNum ...    % last group of 10 saccades
                             ];
        
        for saccadeGroupIndex = 1:size(saccadicPosRanges,1)   
            saccadicPosRange = squeeze(saccadicPosRanges(saccadeGroupIndex,:));
            % find position indices
            positionIndices = 1 + ((saccadicPosRange(1)-1)*positionsPerFixation : (saccadicPosRange(2))*positionsPerFixation-1);
            fprintf('Analyzed positions: %d-%4d\n', positionIndices(1), positionIndices(end));
        
            % generate new sensor with given sub-sequence data
            newSensor = sensor;
            newSensor = sensorSet(newSensor, 'photon rate', isomerizationRate(:,:,positionIndices));
            newSensor = sensorSet(newSensor, 'positions',   sensorPositions(positionIndices,:));
            visualizeCurrent(newSensor, oi, 100+saccadeGroupIndex);
        end 
    end
end


function visualizeCurrent(sensor, oi, figNum)
    % compute photo-current
    osB = osBioPhys();
    osB = osSet(osB, 'noiseFlag', 1);
    osB = osCompute(osB, sensor);

    osWindow(figNum, 'biophys-based outer segment', osB, sensor, oi);
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
    saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, sensorParams.eyeMovementScanningParams.positionScanMode);
    
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

function saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, positionScanMode)
    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(positionScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(positionScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', positionScanMode);
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

