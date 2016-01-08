function downloadIsetbioScenes
    clear all
    close all
    
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
        'coneApertureInMicrons', 3.0, ... 
        'LMSdensities', [0.6 0.4 0.1], ...
        'spatialGrid', [25 25], ...  
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
        'integrationTimeInMilliseconds', 50, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', 300, ...
            'numberOfFixations', 20 ...
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
        
        % Show scene
        %vcAddAndSelectObject(scene); sceneWindow;
       
        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);
        
        % Show optical image
        %vcAddAndSelectObject(oi); oiWindow;
        
        % create custom human sensor
        sensor = sensorCreate('human');
        randomSeed = 94586784;
        sensor = customizeSensor(sensor, sensorParams, oi, randomSeed);
        
        % compute rate of isomerized photons
        sensor = coneAbsorptions(sensor, oi);
         
        photonIsomerizationRate = sensorGet(sensor,'photon rate');
        eyeMovementPositions = sensorGet(sensor, 'positions');
        eyeMovementPositions(end,:)
        
        figure(1001);
        imagesc(squeeze(photonIsomerizationRate(:,:,end)));
        
        photonIsomerizationRateXT = reshape(photonIsomerizationRate, [size(photonIsomerizationRate,1)*size(photonIsomerizationRate,2), size(photonIsomerizationRate,3)]);
        
        % compute adapted photo-current
        %adaptedOS = osLinear(); 
        adaptedOS = osBioPhys();
        adaptedOS = osSet(adaptedOS, 'noiseFlag', 1);
        adaptedOS = osCompute(adaptedOS, sensor);

        osWindow(adaptedOS, sensor, oi);
        
        % plot results
        figure(10);
        clf;
        subplot(5,1,1);
        eyeMovementPositions = sensorGet(sensor, 'positions');
        timeAxis = (0:size(eyeMovementPositions,1)-1)/(size(eyeMovementPositions,1))*sensorGet(sensor, 'total time');
        stairs(timeAxis,eyeMovementPositions(:,1), 'r-');
        hold on;
        stairs(timeAxis,eyeMovementPositions(:,2), 'b-');
        ylabel('distance (cones)');
        title('eye movements');
        
        subplot(5,1,2);
        timeAxis = (0:size(photonIsomerizationRate,3)-1)/(size(photonIsomerizationRate,3))*sensorGet(sensor, 'total time');
        imagesc(timeAxis, (1:size(photonIsomerizationRate,1)*size(photonIsomerizationRate,2)), photonIsomerizationRateXT);
        ylabel('cone no');
        colorbar('northoutside');
        title('photoisomerization rates');
        
        subplot(5,1,3);
        plot(timeAxis, photonIsomerizationRateXT, 'k-');
        ylabel('isomerization rates (R*/sec)');
        
        subplot(5,1,4)
        timeAxis = (0:size(osAdaptedCur,3)-1)/(size(osAdaptedCur,3))*sensorGet(sensor, 'total time');
        imagesc(timeAxis, (1:size(osAdaptedCur,1)*size(osAdaptedCur,2)), osAdaptedCurXT);
        ylabel('cone no');
        xlabel('time (seconds)');
        title('photocurrent');
        colorbar('northoutside');
        
        subplot(5,1,5);
        plot(timeAxis, osAdaptedCurXT, 'k-');
        ylabel('photocurrents (R*/sec)');
        
    end
     
end

function sensor = customizeSensor(sensor, sensorParams, opticalImage, randomSeed)
    
    if (isempty(randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(randomSeed);
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
    eyeMovementsNum = eyeMovementScanningParams.numberOfFixations * round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds);
    eyeMovementPositions = zeros(eyeMovementsNum,2);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    sensor = emGenSequence(sensor);
    
    % add saccadic targets
    saccadicTargetPos = round(randn(eyeMovementScanningParams.numberOfFixations,2)*100);
    for k = 1:eyeMovementScanningParams.numberOfFixations
        if (mod(k-1,6) < 2)
            saccadicTargetPos(k,:) = [-850 -390]/3; % spot of light 
        elseif (mod(k-1,6) < 4)
            saccadicTargetPos(k,:) = [-170 515]/2;
        else
            saccadicTargetPos(k,:) = [-105 505]/3; % tree trunk
        end
    end
    eyeMovementPositions = sensorGet(sensor,'positions', eyeMovementPositions);
    for eyeMovementIndex = 1:eyeMovementsNum
        kk = 1+floor((eyeMovementIndex-1)/round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds));
        eyeMovementPositions(eyeMovementIndex,:) = eyeMovementPositions(eyeMovementIndex,:) + saccadicTargetPos(kk,:);
    end
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    
    eyeMovementPositions
    % Integration time. This will determine signal amplitude !!!
    fprintf('Sensor integration time:  %2.2f milliseconds\n', 1000.0*sensorGet(sensor, 'integrationTime'));
    fprintf('Sensor time interval:  %2.2f milliseconds\n', 1000.0*sensorGet(sensor, 'time interval'));
    fprintf('Sensor sampling total time:  %2.2f milliseconds\n', 1000.0*sensorGet(sensor, 'total time'));
    fprintf('eye movement time interval:  %2.2f milliseconds\n', 1000.0*emGet(eyeMovement, 'sample time'));
   
    
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

