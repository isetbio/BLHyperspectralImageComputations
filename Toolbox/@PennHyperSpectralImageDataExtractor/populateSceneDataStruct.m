% Penn database - specific method to populate the sceneDataStruct
function populateSceneDataStruct(obj)
    fprintf('In Penn  DataBase populateSceneDataStruct.\n');
 
    obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForPennScenes(obj);
    obj.sceneData.knownReflectionData           = generateKnownReflectionDataStructForPennScenes(obj);
    obj.sceneData.reflectanceDataFileName       = obj.sceneData.name;
    obj.sceneData.spectralRadianceDataFileName  = '';
            
end

function knownReflectionData = generateKnownReflectionDataStructForPennScenes(obj)
	knownReflectionData = [];
end

    
% Method to generate a reference object data struct
function referenceObjectData = generateReferenceObjectDataStructForPennScenes(obj)

    switch (obj.sceneData.name)
       case 'BearFruitGrayB'
           sceneInfo = 'Bear and fruit scene under blue illumination. Spatial and illuminant data available. For more information, please visit http://color.psych.upenn.edu/hyperspectral/bearfruitgray/bearfruitgray.html';
            
       case 'BearFruitGrayR'
           sceneInfo = 'Bear and fruit scene under red illumination. Spatial and illuminant data available. For more information, please visit http://color.psych.upenn.edu/hyperspectral/bearfruitgray/bearfruitgray.html';
            
       case 'BearFruitGrayY'
           sceneInfo = 'Bear and fruit scene under yellow illumination. Spatial and illuminant data available. For more information, please visit http://color.psych.upenn.edu/hyperspectral/bearfruitgray/bearfruitgray.html';
            
       otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', obj.sceneData.name, obj.sceneData.database);  
    end
    
    distanceToCamera = 2;
    sensorSizeInPixels = 2020; 
    cameraResolutionInPixelsPerDegree = 102.4;
    
    referenceObjectShape = 'computed from first principles';
    horizFOV = sensorSizeInPixels/cameraResolutionInPixelsPerDegree;
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
