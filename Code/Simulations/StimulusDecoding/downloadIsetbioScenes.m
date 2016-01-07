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
    timeStepInMilliseconds = 0.5;
    
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ... 
        'LMSdensities', [0.6 0.4 0.1], ...
        'spatialGrid', [15 15], ...  
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
        'fixationalEyeMovementParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'durationInMilliseconds', 200 ...
            ) ...
        );
    
    for imageIndex = 1:numel(imageSources)
        % retrieve scene
        imsource = imageSources{imageIndex};
        client.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
        [artifactData, artifactInfo] = client.readArtifact(imsource{2}, 'type', 'mat');
        if ismember('scene', fieldnames(artifactData))
            fprintf('Fethed scene contains uncompressed scene data.\n');
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
        randomSeed = 3242984;
        sensor = customizeSensor(sensor, sensorParams, oi, randomSeed);
        
        % compute rate of isomerized photons
        sensor = coneAbsorptions(sensor, oi);
         
        photonIsomerizationRate = sensorGet(sensor,'photon rate');
        photonIsomerizationRateXT = reshape(photonIsomerizationRate, [size(photonIsomerizationRate,1)*size(photonIsomerizationRate,2), size(photonIsomerizationRate,3)]);
        
        % compute adapted photo-current
        %adaptedOS = osLinear(); 
        adaptedOS = osBioPhys();
        adaptedOS = osSet(adaptedOS, 'noiseFlag', 1);
        adaptedOS = osCompute(adaptedOS, sensor);
        osAdaptedCur = osGet(adaptedOS, 'ConeCurrentSignal');
        osAdaptedCurXT = reshape(osAdaptedCur, [size(osAdaptedCur,1)*size(osAdaptedCur,2), size(osAdaptedCur,3)]);
        
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
    
    fixationalEyeMovementParams = sensorParams.fixationalEyeMovementParams;
    
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
    
    % custom eye movement
    eyeMovement = emCreate();
    
    % custom sample time
    eyeMovement  = emSet(eyeMovement, 'sample time', fixationalEyeMovementParams.samplingIntervalInMilliseconds/1000.0);        
    
    % attach eyeMovement to the sensor
    sensor = sensorSet(sensor,'eyemove', eyeMovement);
            
    % generate the fixation eye movement sequence
    eyeMovementsNum = round(fixationalEyeMovementParams.durationInMilliseconds / fixationalEyeMovementParams.samplingIntervalInMilliseconds);
    eyeMovementPositions = zeros(eyeMovementsNum,2);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    sensor = emGenSequence(sensor);
    
    % saccade 300 cones leftward and 100 cones upwards
    eyeMovementPositions = bsxfun(@plus, sensorGet(sensor,'positions'), [58 10]);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    
    % Integration time. This will determine signal amplitude !!!
    fprintf('Sensor has default integration time:  %2.2f milliseconds\n', 1000.0*sensorGet(sensor, 'integrationTime'));
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

