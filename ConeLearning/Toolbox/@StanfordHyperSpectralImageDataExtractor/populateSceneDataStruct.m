% Stanford database - specific method to populate the sceneDataStruct
function populateSceneDataStruct(obj)
    fprintf('In Stanford DataBase populateSceneDataStruct.\n');
    
    obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForStanfordScenes(obj);
    obj.sceneData.knownReflectionData           = generateKnownReflectionDataStructForStanfordScenes(obj);
    obj.sceneData.reflectanceDataFileName       = obj.sceneData.name;
    obj.sceneData.spectralRadianceDataFileName  = '';
    
end

function knownReflectionData = generateKnownReflectionDataStructForStanfordScenes(obj)
	knownReflectionData = [];
end

% Method to generate a reference object data struct
function referenceObjectData = generateReferenceObjectDataStructForStanfordScenes(obj)

    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    load(fullfile(sourceDir, sprintf('%s.mat',obj.sceneData.name)), 'comment');
    sceneInfo = comment;
        
    switch (obj.sceneData.name)
        case 'SanFranciscoPFilter'
           sceneInfo = 'View of San Francisco from Stanford''s dish (with polarizer filter).';
           distanceToCamera = 500;
           
       case 'StanfordDishPFilter'
           sceneInfo = 'View of Stanford''s Dish (with polarizer filter).';
           distanceToCamera = 500;
           
       case 'StanfordTowerPFilter'
           sceneInfo = 'View of Stanford''s Tower (with polarizer filter).';
           distanceToCamera = 500;
           
       case 'StanfordMemorial'
           sceneInfo = 'Stanford''s Memorial Church facade.';
           distanceToCamera = 30;
           
       case 'HiResFemale1'
           sceneInfo = 'Female face #1.';
           distanceToCamera = 1;
           
       case 'HiResFemale2'
           sceneInfo = 'Female face #2.';
           distanceToCamera = 1;
           
       case 'HiResFemale3'
           sceneInfo = 'Female face #3.';
           distanceToCamera = 1;
           
       case 'HiResFemale6'
           sceneInfo = 'Female face #6.';
           distanceToCamera = 1;
           
       case 'HiResFemale8'
           sceneInfo = 'Female face #8.';
           distanceToCamera = 1;
           
       case 'HiResFemale9'
           sceneInfo = 'Female face #9.';
           distanceToCamera = 1;
           
       case 'HiResFemale12'
           sceneInfo = 'Female face #12.';
           distanceToCamera = 1;
           
       case 'HiResMale1'
           sceneInfo = 'Male face #1.';
           distanceToCamera = 1;
           
       case 'HiResMale2'
           sceneInfo = 'Male face #2.';
           distanceToCamera = 1;
           
       case 'HiResMale4'
           sceneInfo = 'Male face #4.';
           distanceToCamera = 1;
           
       case 'HiResMale5'
           sceneInfo = 'Male face #5.';
           distanceToCamera = 1;
           
       case 'HiResMale6'
           sceneInfo = 'Male face #6.';
           distanceToCamera = 1;
           
        case 'HiResMale9'
           sceneInfo = 'Male face #9.';
           distanceToCamera = 1;
          
        case 'HiResMale11'
           sceneInfo = 'Male face #11.';
           distanceToCamera = 1;
           
        case 'HiResMale12'
           sceneInfo = 'Male face #12.';
           distanceToCamera = 1;
           
        otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', obj.sceneData.name, obj.sceneData.database);  
    end
    
            
    sensorSizeInPixels = 1600;
    
    referenceObjectShape = 'computed from first principles';
    horizFOV = 17;
    referenceObjectSizeInMeters = 2.0*distanceToCamera * tan(horizFOV/2/180*pi);
    referenceObjectSizeInPixels = sensorSizeInPixels;
    
    referenceObjectData = struct(...
         'spectroRadiometerReadings', struct(...
            'xChroma',      nan, ...              
            'yChroma',      nan, ...              
            'Yluma',        nan,  ...           
            'CCT',          nan   ... 
            ), ...
         'paintMaterial', struct(), ...  % No paint material available
         'geometry', struct( ...         % Geometry of the reference object
            'shape',            referenceObjectShape, ...
            'distanceToCamera', distanceToCamera, ...            % meters
            'sizeInMeters',     referenceObjectSizeInMeters,...  % estimated manually from the picture
            'sizeInPixels',     referenceObjectSizeInPixels,...  % estimated manually from the picture
            'roiXYpos',         [], ...        % pixels (center)
            'roiSize',          [] ...           % pixels (halfwidth, halfheight)
         ), ...
         'info', sceneInfo ...
    ); 

end
