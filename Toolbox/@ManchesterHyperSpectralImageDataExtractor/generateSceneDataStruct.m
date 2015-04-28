function generateSceneDataStruct(obj,sceneName)

    databaseName = 'manchester_database';
    
    obj.sceneData = struct(...
        'database', databaseName, ...              % database directory
        'name',     sceneName, ...                 % scene name (also subdirectory)
        'referenceObjectData', struct(), ...       % struct with reference object data
        'reflectanceDataFileName', '', ...         % name of scene reflectance data file
        'spectralRadianceDataFileName', '' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
    );

    sourceDir = fullfile(getpref('HyperSpectralImageComputations', 'originalDataBaseDir'), databaseName);
    referencePaintMaterialFileName = fullfile(sourceDir, sceneName, 'ref_n7.mat');
    
    switch sceneName
        case 'scene4'
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene4(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_cyflower1bb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_cyflower1.mat';
        otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', sceneName, databaseName);   
    end
    
end


function referenceObjectData = generateReferenceObjectDataStructForManchesterScene4(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.351, ...              % 
            'yChroma',      0.363, ...              %
            'Yluma',        8751,  ...              % cd/m2
            'CCT',          4827   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'sphere', ...
            'distanceToCamera', 1.4, ...            % meters
            'sizeInMeters',     3.75/100.0, ...     % for this scene, the reported size is the ball diameter
            'sizeInPixels',     167, ...            % estimated manually from the picture
            'roiXYpos',         [83 981], ...       % pixels
            'roiSize',          [10 10] ...         % pixels
         ), ...
         'info', ['Recorded in the Gualtar campus of University of Minho, Portugal, on 31 July 2002 at 17:40, ' ...
                'under direct sunlight and blue sky. Ambient temperature: 29 C. ' ...
                'Camera aperture: f/22, focus: 38, zoom set to maximum giving a focal length of 75 mm'] ...
    );    
end

