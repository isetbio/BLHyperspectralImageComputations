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
        case 'SanFrancisco'
           sceneInfo = 'View of San Francisco from Stanford''s dish.';
            
       case 'StanfordMemorial'
           sceneInfo = 'Stanford''s Memorial Church facade.';
            
       case 'HiResFemale12'
           sceneInfo = 'Female Stanford professor face.';
            
        otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', obj.sceneData.name, obj.sceneData.database);  
    end
    
            

    distanceToCamera = 100
    sizeInMeters = 1
    sizeInPixels = 100
    
    referenceObjectData = struct(...
         'spectroRadiometerReadings', struct(...
            'xChroma',      nan, ...              
            'yChroma',      nan, ...              
            'Yluma',        nan,  ...           
            'CCT',          nan   ... 
            ), ...
         'paintMaterial', struct(), ...  % No paint material available
         'geometry', struct( ...         % Geometry of the reference object
            'shape',            [], ...
            'distanceToCamera', distanceToCamera, ...            % meters
            'sizeInMeters',     sizeInMeters,...  % estimated manually from the picture
            'sizeInPixels',     sizeInPixels,...  % estimated manually from the picture
            'roiXYpos',         [], ...        % pixels (center)
            'roiSize',          [] ...           % pixels (halfwidth, halfheight)
         ), ...
         'info', sceneInfo ...
    ); 

end
