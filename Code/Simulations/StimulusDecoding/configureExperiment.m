function [trainingImageSet, forcedSceneMeanLuminance, saccadesPerScan, sensorParams, sensorAdaptationFieldParams] = configureExperiment(configuration)

    if (strcmp(configuration, 'large'))
        
        fprintf('\nUsing LARGE configuration set with the following images: \n');
        trainingImageSet = {...
            {'manchester_database', 'scene1'} ...
            {'manchester_database', 'scene2'} ...
            {'manchester_database', 'scene3'} ...
            {'manchester_database', 'scene4'} ...
            {'manchester_database', 'scene6'} ...
            {'manchester_database', 'scene7'} ...
            {'manchester_database', 'scene8'} ...
            {'stanford_database', 'StanfordMemorial'} ...
        };
        for k = 1:numel(trainingImageSet)
           imsource = trainingImageSet{1};
           fprintf('%2d. ''%s'' / ''%s''\n', k, imsource{1}, imsource{2}); 
        end
        fprintf('\n');
        
        % parse the eye movement data into scans, each scan having this many saccades
        saccadesPerScan = 20;    
        
        % the higher the overlapFactor the more dense the saccades sample the scene
        % 1 results in sensor positions that just abut each other, 2 more dense, 0.5 less dense
        fixationOverlapFactor = 1.0;               
      
        % 'randomized' or 'sequential', to visit eye position grid sequentially
        saccadicScanMode = 'randomized';  
        
    elseif (strcmp(configuration, 'small'))
        
        fprintf('\nUsing SMALL configuration set with the following images: \n');
        % images used to train the decoder
        trainingImageSet = {...
            {'manchester_database', 'scene1'} ...
        };
        for k = 1:numel(trainingImageSet)
           imsource = trainingImageSet{1};
           fprintf('%2d. ''%s'' / ''%s''\n', k, imsource{1}, imsource{2}); 
        end
        fprintf('\n');
        
        % parse the eye movement data into scans, each scan having this many saccades
        saccadesPerScan = 5;  
    
        % the higher the overlapFactor the more dense the saccades sample the scene
        % 1 results in sensor positions that just abut each other, 2 more dense, 0.5 less dense
        fixationOverlapFactor = 0.5;   
        
        % 'randomized' or 'sequential', to visit eye position grid sequentially
        saccadicScanMode = 'sequential';
    else
        error('Unknown configuration. Must be either ''small'', or ''large''\n');
    end
    
    % force all scenes to have this mean luminance
    forcedSceneMeanLuminance = 200;             
     
    % sampling of LMS fundamentals maps
    sceneResamplingResolutionInRetinalMicrons = 1.0;
        
    % mosaic configuration
    coneCols = 20;
    coneRows = 20;
    coneApertureInMicrons = 3.0;                % custom cone aperture
    LMSdensities = [0.6 0.3 0.1];               % custom percentages of L,M and S cones
    integrationTimeInMilliseconds = 50;
    
    % time step for simulation,  eye movements, outersegment computations
    timeStepInMilliseconds = 0.1;               % (0.1 millisecond or smaller)
    
    % eye movement params
    fixationDurationInMilliseconds = 100;       % 100 millisecond fixations - stimulus duration
    
    % fix this to ensure repeatable results
    randomSeed = 1552784;
    
    % mparams for the sensor that will compute excitations to the different scenes
    sensorParams = struct(...
        'coneApertureInMicrons', coneApertureInMicrons, ...        
        'LMSdensities', LMSdensities, ...        
        'spatialGrid', [coneRows coneCols], ...  
        'sceneResamplingResolutionInRetinalMicrons', sceneResamplingResolutionInRetinalMicrons, ...
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
