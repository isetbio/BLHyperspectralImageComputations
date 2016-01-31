function [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureExperiment(configuration)

    if (configuration == 1)
        [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureSmallImageTrainingSet();
    else
        [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureLargeImageTrainingSet();
    end
    
end


function [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureLargeImageTrainingSet()

    fprintf('\nUsing LARGE configuration set\n');
    trainingImageSet = {...
        {'manchester_database', 'scene1'} ...
        {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
        {'manchester_database', 'scene4'} ...
        {'manchester_database', 'scene6'} ...
        {'manchester_database', 'scene7'} ...
        {'manchester_database', 'scene8'} ...
        {'stanford_database', 'StanfordMemorial'} ...
    }
    
    % force all scenes to have this mean luminance
    forcedSceneMeanLuminance = 200;             
     
    % parse the eye movement data into scans, each scan having this many saccades
    saccadesPerScan = 20;                        
    
    % smosaic configuration
    coneCols = 16;
    coneRows = 16;
    coneApertureInMicrons = 3.0;                % custom cone aperture
    LMSdensities = [0.6 0.3 0.1];               % custom percentages of L,M and S cones
    integrationTimeInMilliseconds = 50;
    
    % time step for simulation,  eye movements, outersegment computations
    timeStepInMilliseconds = 0.1;               % (0.1 millisecond or smaller)
    
    % eye movement params
    fixationDurationInMilliseconds = 100;       % 100 millisecond fixations - stimulus duration
    fixationOverlapFactor = 1.0;                % overlapFactor of 1 results in sensor positions that just abut each other, 2 more dense, 0.5 less dense
    saccadicScanMode = 'randomized';            % 'randomized' or 'sequential', to visit eye position grid sequentially
    
    % fix this to ensure repeatable results
    randomSeed = 1552784;
    
    % mparams for the sensor that will compute excitations to the different scenes
    sensorParams = struct(...
        'coneApertureInMicrons', coneApertureInMicrons, ...        
        'LMSdensities', LMSdensities, ...        
        'spatialGrid', [coneRows coneCols], ...  
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed', randomSeed, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', fixationDurationInMilliseconds, ...
            'fixationOverlapFactor', fixationOverlapFactor, ...     
            'saccadicScanMode',  saccadicScanMode ...
        ) ...
    );

    % params for the sensor that will compute excitations to the adapting scene
    sensorAdaptationFieldParams = sensorParams;
    sensorAdaptationFieldParams.eyeMovementScanningParams.fixationOverlapFactor = 0.0;
    % Allow 400 msec inter-stimulus interval (stimulus = adaptation field) for the outer segment response to return to baseline
    sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds = 400;  
    
end

function [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureSmallImageTrainingSet()
    
    fprintf('\nUsing LARGE configuration set\n');

    % images used to train the decoder
    trainingImageSet = {...
        {'manchester_database', 'scene1'} ...
%        {'manchester_database', 'scene2'} ...
        }
    % force all scenes to have this mean luminance
    forcedSceneMeanLuminance = 200;             
     
    % parse the eye movement data into scans, each scan having this many saccades
    saccadesPerScan = 5;                        
    
    % smosaic configuration
    coneCols = 16;
    coneRows = 16;
    coneApertureInMicrons = 3.0;                % custom cone aperture
    LMSdensities = [0.6 0.3 0.1];               % custom percentages of L,M and S cones
    integrationTimeInMilliseconds = 50;
    
    % time step for simulation,  eye movements, outersegment computations
    timeStepInMilliseconds = 0.1;               % (0.1 millisecond or smaller)
    
    % eye movement params
    fixationDurationInMilliseconds = 100;       % 100 millisecond fixations - stimulus duration
    fixationOverlapFactor = 0.25;                % overlapFactor of 1 results in sensor positions that just abut each other, 2 more dense, 0.5 less dense
    saccadicScanMode = 'sequential';            % 'randomized' or 'sequential', to visit eye position grid sequentially
    
    % fix this to ensure repeatable results
    randomSeed = 1552784;
    
    % mparams for the sensor that will compute excitations to the different scenes
    sensorParams = struct(...
        'coneApertureInMicrons', coneApertureInMicrons, ...        
        'LMSdensities', LMSdensities, ...        
        'spatialGrid', [coneRows coneCols], ...  
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed', randomSeed, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', fixationDurationInMilliseconds, ...
            'fixationOverlapFactor', fixationOverlapFactor, ...     
            'saccadicScanMode',  saccadicScanMode ...
        ) ...
    );

    % params for the sensor that will compute excitations to the adapting scene
    sensorAdaptationFieldParams = sensorParams;
    sensorAdaptationFieldParams.eyeMovementScanningParams.fixationOverlapFactor = 0.0;
    % Allow 400 msec inter-stimulus interval (stimulus = adaptation field) for the outer segment response to return to baseline
    sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds = 400;  
end
