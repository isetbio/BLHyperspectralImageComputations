function runSimulation

    startup();
    
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
    
    verbosity = 10;
    
    
    
    
    % We may specify custon sensor params
        sensorParamsStruct = struct(...
            'name', 'humanLMS', ...
            'conesAcross', 10, ...
            'coneAperture', 4*1e-6, ... % specified in meters
            'heightToWidthRatio', 1.0, ...
            'coneIntegrationTime', 0.050 ...
        );

    % ... and custom eye movement params
    eyeMovementParamsStruct = struct(...
        'name', 'fixationalEyeMovements', ...
        'samplesPerFixation', 10, ...% 80, ...
        'tremorAmplitude', 0.0073*2, ...  % double the default value
        'overlapFactor', 0.5 ...  % 50 % overlap
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
    
   currentSceneIndex = 0;
   
   for databaseIndex = 1:2
       
       if (databaseIndex == 1)
           databaseName = 'manchester_database';
           sceneNames = {'scene1', 'scene2', 'scene3', 'scene4', 'scene6', 'scene7', 'scene8'};
       elseif (databaseIndex == 2)
           databaseName = 'harvard_database';
           sceneNames = {...
               'img1', 'img2', 'img3', 'img4', 'img5', 'img6', ...
               'imga1', 'imga2', 'imga3', 'imga4', 'imga5', 'imga5', 'imga7', 'imga8'...
               'imgb1', 'imgb2', 'imgb3', 'imgb4', 'imgb5', 'imgb6', 'imgb7', 'imgb8', ...
               'imgc1', 'imgc2', 'imgc3', 'imgc4', 'imgc5', 'imgc6', 'imgc7', 'imgc8', 'imgc9', ...
               'imgd0', 'imgd1', 'imgd2', 'imgd3', 'imgd4', 'imgd5', 'imgd6', 'imgd7', 'imgd8', 'imgd9', ...
               'imge0', 'imge1', 'imge2', 'imge3', 'imge4', 'imge5', 'imge6', 'imge7', ...
               'imgf1', 'imgf2', 'imgf3', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
               'imgg0', 'imgg1', 'imgg2', 'imgg3', 'imgg4', 'imgg5', 'imgg6', 'imgg7', 'imgg8', 'imgg9', ...
               'imgh0', 'imgh1', 'imgh2', 'imgh3', 'imgh4', 'imgh5', 'imgh6', 'imgh7' ...
               };
       end
       
   for sceneIndex = 1:numel(sceneNames)
        sceneName = sceneNames{sceneIndex};
        fprintf('\nProcessing scene %s\n', sceneName);
        
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
            'visualizeResultsAsImages', true ...
        );
    
        % Compute the time-varying activation of the sensor mosaic
        XTresponse = sceneProcessor.computeSensorActivation(...
            'forceRecompute', true, ...
            'randomSeed',  12385654, ...   % pass empty to generate new sensor or some seed to generate same sensor
            'sensorParams', sensorParamsStruct , ...
            'eyeMovementParams', eyeMovementParamsStruct, ...
            'visualizeResultsAsIsetbioWindows', visualizeResultsAsIsetbioWindows, ...
            'visualizeResultsAsImages', visualizeResultsAsImages, ...
            'generateVideo', generateVideo ...
        );
    
        
        currentSceneIndex = currentSceneIndex + 1;
        XTresponses{currentSceneIndex} = single(XTresponse);
        
        trueConeXYLocations = sensorGet(sceneProcessor.sensor, 'xy');
        trueConeTypes = sensorGet(sceneProcessor.sensor, 'cone type');
    
        
    
        varlist = {'sceneProcessor'};
        clear(varlist{:});
    end
   end
    
   numel(XTresponses)
    XTresponse = [];
    for sceneIndex = 1:numel(XTresponses)
        a = XTresponses{sceneIndex};
        XTresponse = [XTresponse a/max(abs(a(:)))];
        fprintf('new data size (%d) : %d %d\n', sceneIndex, size(a,1), size(a,2));
        fprintf('aggregate data size: %d %d\n', size(XTresponse,1), size(XTresponse,2));
    end
    
    
    
    MDSprojection = ISETbioSceneProcessor.estimateReceptorIdentities(XTresponse, 'demoMode', false, 'selectTimeBins', []);
    save('results.mat','XTresponse', 'MDSprojection', 'trueConeXYLocations', 'trueConeTypes', '-v7.3');

    %estimateClusters(MDSprojection, trueConeXYLocations, trueConeTypes);
end

