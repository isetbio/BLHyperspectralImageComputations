% Harvard database - specific method to populate the sceneDataStruct
function populateSceneDataStruct(obj)
    fprintf('In Harvard DataBase populateSceneDataStruct.\n');
     
    % Assemble sourceDir
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    
    obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForHarvardScenes(obj);
    obj.sceneData.reflectanceDataFileName       = obj.sceneData.name;
    obj.sceneData.spectralRadianceDataFileName  = '';
            
end

% Method to generate a reference object data struct
function referenceObjectData = generateReferenceObjectDataStructForHarvardScenes(obj)

    % Enter custom geometry and illuminant settings as these images do not have such information.
    if (strcmp(obj.sceneData.subset, 'CZ_hsdb'))
        switch obj.sceneData.name 
            case 'img1'
                distanceToCamera = 30.0;                      % in meters
                referenceObjectShape = 'rail';
                referenceObjectSizeInMeters = 100/100;        % in meters
                referenceObjectSizeInPixels = 70;
                referenceObjectXYpos = [562 786];
                referenceObjectROI = [2 referenceObjectSizeInPixels/2];
                meanSceneLuminanceInCdPerM2 = 500;
            case 'img2'
                distanceToCamera = 30.0;                      % in meters
                referenceObjectShape = 'rail';
                referenceObjectSizeInMeters = 100/100;        % in meters
                referenceObjectSizeInPixels = 70;
                referenceObjectXYpos = [562 786];
                referenceObjectROI = [2 referenceObjectSizeInPixels/2];
                meanSceneLuminanceInCdPerM2 = 500;
        end
    else
        error('Unknown harvard database subset: ''%s''. ', obj.sceneData.subset);
    end
    
    
    % custom illuminant
    obj.sceneData.customIlluminant.name         = 'D65';
    obj.sceneData.customIlluminant.wave         = 420:10:720;
    obj.sceneData.customIlluminant.meanSceneLum = meanSceneLuminanceInCdPerM2;

    % custom clipping
    obj.sceneData.clippingRegion.x1 = 1;
    obj.sceneData.clippingRegion.x2 = Inf;
    obj.sceneData.clippingRegion.y1 = 1;
    obj.sceneData.clippingRegion.y2 = Inf;
   
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
            'roiXYpos',         referenceObjectXYpos, ...        % pixels (center)
            'roiSize',          referenceObjectROI ...           % pixels (halfwidth, halfheight)
         ), ...
         'info', [] ...
    ); 

end
