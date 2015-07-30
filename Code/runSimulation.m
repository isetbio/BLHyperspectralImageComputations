function runSimulation

    startup();
    
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
    
    databaseName = 'manchester_database';
    sceneName = 'scene3';
    
   % databaseName = 'harvard_database';
   % sceneName = 'imgb6';
    
    
    verbosity = 10;
    
    % Instantiate a new sceneProcessor
    sceneProcessor = ISETbioSceneProcessor(databaseName, sceneName, verbosity);
    
    % Compute optical image
    % We may specify custom optics params
%     opticsParamsStruct = struct('name', 'human', ...);
%     sceneProcessor.computeOpticalImage(...
%         'opticsParams', opticsParamsStruct, ...
%         'forceRecompute', true ...
%         'visualizeResults', true
%     );


    % or use default optics
    sceneProcessor.computeOpticalImage(...
        'forceRecompute', false, ...
        'visualizeResultsAsIsetbioWindows', false, ...
        'visualizeResultsAsImages', false ...
    );

    % We may specify custon sensor params
    sensorParamsStruct = struct(...
        'name', 'humanLMS', ...
        'conesAcross', 8, ...
        'coneAperture', 5*1e-6, ... % specified in meters
        'heightToWidthRatio', 1.0, ...
        'coneIntegrationTime', 0.050 ...
    );

    % ... and custom eye movement params
    eyeMovementParamsStruct = struct(...
        'name', 'fixationalEyeMovements', ...
        'samplesPerFixation', 20, ...% 80, ...
        'overlapFactor', 3.0 ...  % 50 % overlap
    );

    intermediateVisualization = false;
    
    if (intermediateVisualization)
        visualizeResultsAsIsetbioWindows = false;
        visualizeResultsAsImages = true;
        generateVideo = false;
    else
        visualizeResultsAsIsetbioWindows = false;
        visualizeResultsAsImages = false;
        generateVideo = false;
    end
    
    % Compute the time-varying activation of the sensor mosaic
    sceneProcessor.computeSensorActivation(...
        'forceRecompute', false, ...
        'randomSeed',  12385654, ...   % pass empty to generate new sensor or some seed to generate same sensor
        'sensorParams', sensorParamsStruct , ...
        'eyeMovementParams', eyeMovementParamsStruct, ...
        'visualizeResultsAsIsetbioWindows', visualizeResultsAsIsetbioWindows, ...
        'visualizeResultsAsImages', visualizeResultsAsImages, ...
        'generateVideo', generateVideo ...
    );

    if (~intermediateVisualization)
        MDSprojection = sceneProcessor.estimateReceptorIdentities('demoMode', false, 'selectTimeBins', []);
        sensor = sceneProcessor.sensor;
        save(sprintf('%s_results.mat',sceneName) ,'MDSprojection', 'sensor');
    end
   
    estimateClusters();
end

