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
    
    
    switch sceneName
        case 'scene1'
            referencePaintMaterialFileName              = fullfile(sourceDir, sceneName, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene1(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_crown3bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_crown3.mat';
            
        case 'scene2'
            referencePaintMaterialFileName              = fullfile(sourceDir, sceneName, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene2(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_ruivaes1bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_ruivaes1.mat';
            
        case 'scene3'
            referencePaintMaterialFileName              = fullfile(sourceDir, sceneName, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene3(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_mosteiro4bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_mosteiro4.mat';
            
        case 'scene4'
            referencePaintMaterialFileName              = fullfile(sourceDir, sceneName, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene4(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_cyflower1bb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_cyflower1.mat';
        otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', sceneName, databaseName);   
    end
    
end


function referenceObjectData = generateReferenceObjectDataStructForManchesterScene1(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.324, ...              % 
            'yChroma',      0.337, ...              %
            'Yluma',        1820,  ...              % cd/m2
            'CCT',          5875   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'rectangle', ...
            'distanceToCamera', 16.4, ...           % meters
            'sizeInMeters',     11.0/100.0, ...     % for this scene, the reported size is the plate's height
            'sizeInPixels',     81, ...             % estimated manually from the picture
            'roiXYpos',         [1339 851], ...     % pixels (center)
            'roiSize',          [0 20] ...          % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in the Sameiro area, Braga, Minho region, Portugal, on 12 July 2003 at 15:10'...
                  'under direct sunlight with clear sky. Ambient temperature was 32 ºC. Camera aperture was f/16, focus 9.0,'...
                  'and zoom set to maximum giving a focal length of 75 mm.'
                  ] ...
    );    
end


function referenceObjectData = generateReferenceObjectDataStructForManchesterScene2(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.321, ...              % 
            'yChroma',      0.338, ...              %
            'Yluma',        1187,  ...              % cd/m2
            'CCT',          6034   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'rectangle', ...
            'distanceToCamera', 13.4, ...           % meters
            'sizeInMeters',     11.0/100.0, ...     % for this scene, the reported size is the plate's height
            'sizeInPixels',     99, ...             % estimated manually from the picture
            'roiXYpos',         [1324 469], ...     % pixels (center)
            'roiSize',          [13 18] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in Ruivães, Vieira do MInho, Minho region, Portugal, on 4 July 2003 at 14:50 under overcast sky with'...
                  'occasional direct sunlight and a slight wind.  Ambient temperature was 28 ºC. Camera aperture was f/16, focus 12.5, and'...
                  'zoom set to maximum giving a focal length of 75 mm.'...
                  ] ...
    );    
end




function referenceObjectData = generateReferenceObjectDataStructForManchesterScene3(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.331, ...              % 
            'yChroma',      0.355, ...              %
            'Yluma',        405,  ...               % cd/m2
            'CCT',          5544   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'rectangle', ...
            'distanceToCamera', 33.1, ...           % meters
            'sizeInMeters',     9.0/100.0, ...     % for this scene, the reported size is the plate's height
            'sizeInPixels',     28, ...             % estimated manually from the picture
            'roiXYpos',         [1246 962], ...     % pixels (center)
            'roiSize',          [9 9] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in the Museum of the Monastery of S. Martinho de Tibães, Mire de Tibães, Minho region, Portugal,' ...
                  'on 2 July 2003 at 16:49 under overcast cloudy sky. Ambient temperature was 24 ºC. Camera aperture was f/16, focus 10,' ...
                  'and zoom set to maximum giving a focal length of 75 mm'...
                  ] ...
    );    
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
            'roiXYpos',         [83 981], ...       % pixels (center)
            'roiSize',          [10 10] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Recorded in the Gualtar campus of University of Minho, Portugal, on 31 July 2002 at 17:40' ...
                'under direct sunlight and blue sky. Ambient temperature: 29 C.' ...
                'Camera aperture: f/22, focus: 38, zoom set to maximum giving a focal length of 75 mm'] ...
    );    
end

