% Method to generate a reference object data struct for scenes with no
% reference objects, i.e., no size, viewing distance information
function referenceObjectData = generateGenericReferenceObjectDataStruct(obj, sceneCalibrationStruct)

    sceneAngularFOV = sceneCalibrationStruct.horizontalFieldOfViewInDegrees
    
    scenePixelRows = size(obj.reflectanceMap,1)
    scenePixelCols = size(obj.reflectanceMap,2)
    
    distanceToCamera = 5.0;                 % in meters
    referenceObjectSizeInMeters = 10/100; 
    referenceObjectSizeInPixels = 1
    
    referenceObjectData = struct(...
         'spectroRadiometerReadings', struct(...
            'xChroma',      nan, ...              
            'yChroma',      nan, ...              
            'Yluma',        nan,  ...           
            'CCT',          nan   ... 
            ), ...
         'paintMaterial', struct(), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            '', ...
            'distanceToCamera', distanceToCamera, ...           % meters
            'sizeInMeters',     11.0/100.0, ...     % for this scene, the reported size is the plate's height
            'sizeInPixels',     81, ...             % estimated manually from the picture
            'roiXYpos',         [], ...             % pixels (center)
            'roiSize',          [] ...              % pixels (halfwidth, halfheight)
         ), ...
         'info', [] ...
    );                    
            
end