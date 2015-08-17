function runSimulation

    startup();
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
    
    conesAcross = 10;
    if (conesAcross == 10)
        eyeMovementOverlapFactor = 0.6;
    elseif (conesAcross == 20)
        eyeMovementOverlapFactor = 0.9;
    end
    
    % Specify major simulations params
    % Sensor params
    sensorParamsStruct = struct(...
            'name', 'humanLMS', ...
            'conesAcross', conesAcross, ...
            'coneAperture', 3*1e-6, ... % specified in meters
            'LMSdensities', [0.6 0.3 0.1], ...
            'heightToWidthRatio', 1.0, ...
            'coneIntegrationTime', 0.050, ...
            'noiseFlag', 0 ...
    );

    % Eye movement params
    eyeMovementParamsStruct = struct(...
        'name', 'fixationalEyeMovements', ...
        'samplesPerFixation', 10, ...% 80, ...
        'sampleTime', 0.01, ...  % 10 milliseconds
        'tremorAmplitude', 0.0073*2, ...  % double the default value
        'overlapFactor', eyeMovementOverlapFactor ...  % 50 % overlap
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
           % all scenes available
           sceneNames = {...
               'img1', 'img2', 'img3', 'img4', 'img5', 'img6', ...
               'imga1', 'imga2', 'imga3', 'imga4', 'imga5', 'imga6', 'imga7', 'imga8'...
               'imgb1', 'imgb2', 'imgb3', 'imgb4', 'imgb5', 'imgb6', 'imgb7', 'imgb8', ...
               'imgc1', 'imgc2', 'imgc3', 'imgc4', 'imgc5', 'imgc6', 'imgc7', 'imgc8', 'imgc9', ...
               'imgd0', 'imgd1', 'imgd2', 'imgd3', 'imgd4', 'imgd5', 'imgd6', 'imgd7', 'imgd8', 'imgd9', ...
               'imge0', 'imge1', 'imge2', 'imge3', 'imge4', 'imge5', 'imge6', 'imge7', ...
               'imgf1', 'imgf2', 'imgf3', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
               'imgg0', 'imgg1', 'imgg2', 'imgg3', 'imgg4', 'imgg5', 'imgg6', 'imgg7', 'imgg8', 'imgg9', ...
               'imgh0', 'imgh1', 'imgh2', 'imgh3', 'imgh4', 'imgh5', 'imgh6', 'imgh7' ...
               };
           % scene names with no blacked-out regions
           sceneNames = {...
               'img1', 'img2', 'img3', 'img4', 'img6', ...
               'imga1', 'imga2', 'imga4', 'imga5', 'imga6', 'imga7', 'imga8'...
               'imgb1', 'imgb2', 'imgb3', 'imgb5', 'imgb6', 'imgb7', 'imgb8', ...
               'imgc1', 'imgc2', 'imgc3', 'imgc4', 'imgc5', 'imgc6', 'imgc7', 'imgc8', 'imgc9', ...
               'imgd0', 'imgd1', 'imgd2', 'imgd3', 'imgd4', 'imgd5', 'imgd6', 'imgd7', 'imgd8', 'imgd9', ...
               'imge0', 'imge1', 'imge2', 'imge3', 'imge4', 'imge5', 'imge6', 'imge7', ...
               'imgf1', 'imgf2', 'imgf3', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
               'imgg0', 'imgg2', 'imgg5', 'imgg8', 'imgg9', ...
               'imgh0', 'imgh1', 'imgh2', 'imgh3' ...
               };
        end
       
        for sceneIndex = 1:numel(sceneNames)
            
            sceneName = sceneNames{sceneIndex};
            fprintf('\nProcessing scene %s\n', sceneName);
        
            % Instantiate a new sceneProcessor
            verbosity = 10;
            sceneProcessor = ISETbioSceneProcessor(databaseName, sceneName, verbosity);
            
            % Compute optical image (if necessary)
            sceneProcessor.computeOpticalImage(...
                'forceRecompute', false, ...
                'visualizeResultsAsIsetbioWindows', false, ...
                'visualizeResultsAsImages', false ...
            );
    
            acceptScene = 'y'; %input('Is this scene acceptable ? [y/n] ', 's');
            
            if (strcmp(acceptScene, 'y')) 
                
                currentSceneIndex = currentSceneIndex + 1;
                allSceneNames{currentSceneIndex} = sceneName;
                
                randomSeedForSensor = 42385654;
                
                % Compute the time-varying activation of the sensor mosaic
                XTresponse = sceneProcessor.computeSensorActivation(...
                    'forceRecompute', true, ...
                    'randomSeed',  randomSeedForSensor, ...   % pass empty to generate new sensor or some seed to generate same sensor
                    'sensorParams', sensorParamsStruct , ...
                    'eyeMovementParams', eyeMovementParamsStruct, ...
                    'visualizeResultsAsIsetbioWindows', visualizeResultsAsIsetbioWindows, ...
                    'visualizeResultsAsImages', visualizeResultsAsImages, ...
                    'generateVideo', generateVideo, ...
                    'saveSensorToFile', false ...
                ); 
                
                % save XT responses and eye movements for each scene
                XTresponses{currentSceneIndex}  = single(XTresponse);
                eyeMovements{currentSceneIndex} = single(sensorGet(sceneProcessor.sensor,'positions'));
                 
                % extract other information for saving
                opticalImageRGBrendering{currentSceneIndex} = oiGet(sceneProcessor.opticalImage, 'rgb image');
                opticalSampleSeparation{currentSceneIndex}  = oiGet(sceneProcessor.opticalImage, 'distPerSamp','microns');
                
                sensorSampleSeparation = sensorGet(sceneProcessor.sensor,'pixel size','um');
                sensorRowsCols         = sensorGet(sceneProcessor.sensor, 'size');
                trueConeXYLocations    = sensorGet(sceneProcessor.sensor, 'xy');
                trueConeTypes          = sensorGet(sceneProcessor.sensor, 'cone type');
                
                % information for computing linear cone adaptation signal
                sensorConversionGain = pixelGet(sensorGet(sceneProcessor.sensor,'pixel'),'conversionGain');
                sensorExposureTime   = sensorGet(sceneProcessor.sensor,'exposure time');   
                sensorTimeInterval   = sensorGet(sceneProcessor.sensor, 'time interval');
        
            else
               fprintf('Skipping scene ''%s''\n', sceneName); 
            end
            
            % clear current sceneProcessor
            varlist = {'sceneProcessor'};
            clear(varlist{:});
        end % sceneIndex
    end % dataBaseIndex
       
    % save all params
    save(sprintf('results_%dx%d.mat', sensorParamsStruct.conesAcross,sensorParamsStruct.conesAcross),...
        'allSceneNames', 'XTresponses', 'eyeMovements', ...
        'opticalImageRGBrendering', 'opticalSampleSeparation', ...
        'trueConeXYLocations', 'trueConeTypes', 'sensorRowsCols','sensorSampleSeparation', ...
        'sensorConversionGain', 'sensorExposureTime', 'sensorTimeInterval', ...
        'randomSeedForSensor',  'sensorParamsStruct', 'eyeMovementParamsStruct', ...
        '-v7.3');
end        
        



function PLotMDSprojection(MDSprojection, trueConeXYLocations, trueConeTypes)
    indices1 = find(trueConeTypes == 2);
    indices2 = find(trueConeTypes == 3);
    indices3 = find(trueConeTypes == 4);
    
    h = figure(999);
    set(h, 'Position', [10 10 1520 1100]);
    clf;
    subplot(2,2,1); hold on
    scatter3(MDSprojection(indices1,1), ...
            MDSprojection(indices1,2), ...
            MDSprojection(indices1,3), ...
            'filled', 'MarkerFaceColor',[1 0 0]);
    scatter3(MDSprojection(indices2,1), ...
            MDSprojection(indices2,2), ...
            MDSprojection(indices2,3), ...
            'filled', 'MarkerFaceColor',[0 1 0]);   
    scatter3(MDSprojection(indices3,1), ...
            MDSprojection(indices3,2), ...
            MDSprojection(indices3,3), ...
            'filled', 'MarkerFaceColor', [0 0 1]);
    
    xlabel('dim-1'); ylabel('dim-2'); zlabel('dim-3');
    box on; grid on; view([-170 50]);
    
    subplot(2,2,3);
    hold on;
    plot(MDSprojection(indices1,1), MDSprojection(indices1,2), 'ko', 'MarkerFaceColor',[1 0 0]);
    plot(MDSprojection(indices2,1), MDSprojection(indices2,2), 'ko', 'MarkerFaceColor',[0 1 0]);
    plot(MDSprojection(indices3,1), MDSprojection(indices3,2), 'ko', 'MarkerFaceColor',[0 0 1]);
    xlabel('dim-1'); ylabel('dim-2');
    box on; grid on;
    
    subplot(2,2,2);
    hold on;
    plot(MDSprojection(indices1,1), MDSprojection(indices1,3), 'ko', 'MarkerFaceColor',[1 0 0]);
    plot(MDSprojection(indices2,1), MDSprojection(indices2,3), 'ko', 'MarkerFaceColor',[0 1 0]);
    plot(MDSprojection(indices3,1), MDSprojection(indices3,3), 'ko', 'MarkerFaceColor',[0 0 1]);
    xlabel('dim-1'); ylabel('dim-3');
    box on; grid on;
    
    
    subplot(2,2,4);
    hold on;
    plot(MDSprojection(indices1,2), MDSprojection(indices1,3), 'ko', 'MarkerFaceColor',[1 0 0]);
    plot(MDSprojection(indices2,2), MDSprojection(indices2,3), 'ko', 'MarkerFaceColor',[0 1 0]);
    plot(MDSprojection(indices3,2), MDSprojection(indices3,3), 'ko', 'MarkerFaceColor',[0 0 1]);
    xlabel('dim-2'); ylabel('dim-3');
    box on; grid on;
    
    drawnow;
    pause(2.0)
end

