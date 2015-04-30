% Manchester database - specific method to populate the sceneDataStruct
function populateSceneDataStruct(obj)

    % Assemble sourceDir
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    
    switch obj.sceneData.name
        case 'scene1'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene1(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_crown3bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_crown3.mat';  % illuminant info
            
        case 'scene2'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene2(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_ruivaes1bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_ruivaes1.mat';  % illuminant info
            
        case 'scene3'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene3(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_mosteiro4bb_reg1_lax.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_mosteiro4.mat';  % illuminant info
            
        case 'scene4'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene4(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_cyflower1bb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_cyflower1.mat';  % illuminant info
            
        case 'scene5'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene5(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_cbrufefields1bb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_cbrufefields.mat'; % illuminant info
       
        case 'scene6'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene6(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_braga1bb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_braga1.mat';  % illuminant info
            
        case 'scene7'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene7(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_ribeira1bbb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_riebira1.mat';  % illuminant info
            
        case 'scene8'
            referencePaintMaterialFileName              = fullfile(sourceDir, obj.sceneData.name, 'ref_n7.mat');
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScene8(referencePaintMaterialFileName);
            obj.sceneData.reflectanceDataFileName       = 'ref_farme1bbbb_reg1.mat';
            obj.sceneData.spectralRadianceDataFileName  = 'radiance_by_reflectance_farme1.mat';  % illuminant info
            
            
        % Scenes 9-16 in the Mancester database have no geometric or
        % illuminant information. The generateReferenceObjectDataStructForManchesterScenes9Through16
        % adds that missing information based on personal (Nicolas') beliefs.
        case 'scene9'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene9.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
      
        case 'scene10'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene10.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
        case 'scene11'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene11.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
       case 'scene12'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene12.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
       case 'scene13'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene13.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
         
       case 'scene14'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene14.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
       case 'scene15'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene15.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
       case 'scene16'
            % generate custom referenceObjectData struct
            obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForManchesterScenes9Through16(obj);
            obj.sceneData.reflectanceDataFileName       = 'scene16.mat';
            obj.sceneData.spectralRadianceDataFileName  = '';
            
            
        otherwise
            error('Unknown scene name (''%s'') for database ''%s''. ', obj.sceneData.name, obj.sceneData.database);   
    end
    
end


% Method to generate a reference object data struct specific to scenes9-16
function referenceObjectData = generateReferenceObjectDataStructForManchesterScenes9Through16(obj)

    % Enter custom geometry and illuminant settings as these images do not have such information.
    switch obj.sceneData.name
        case 'scene9'
            % custom spatial calibration information  (pedal)
            distanceToCamera = 2.0;                      % in meters
            referenceObjectShape = 'flower pedal';
            referenceObjectSizeInMeters = 2.5/100;         % in meters
            referenceObjectSizeInPixels = 120;
            referenceObjectXYpos = [367 463];
            referenceObjectROI = [referenceObjectSizeInPixels/2 10];
            
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 1000;   % cd/m2  
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 1;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 747;
            
            
        case 'scene10'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 40.0;                      % in meters
            referenceObjectShape = 'tree branch';
            referenceObjectSizeInMeters = 50/100;         % in meters
            referenceObjectSizeInPixels = 84;
            referenceObjectXYpos = [713 422];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 300;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 1;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 700;
            
        case 'scene11'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 40.0;                      % in meters
            referenceObjectShape = 'tree branch';
            referenceObjectSizeInMeters = 100/100;         % in meters
            referenceObjectSizeInPixels = 84;
            referenceObjectXYpos = [448 187];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 2000;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 1;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 750;
            
        case 'scene12'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 80.0;                      % in meters
            referenceObjectShape = 'tree branch';
            referenceObjectSizeInMeters = 100/100;         % in meters
            referenceObjectSizeInPixels = 84;
            referenceObjectXYpos = [224 606];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 2000;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 97;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 664;
         
        case 'scene13'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 7.0;                      % in meters
            referenceObjectShape = 'basket ball';
            referenceObjectSizeInMeters = 25/100;         % in meters
            referenceObjectSizeInPixels = 224;
            referenceObjectXYpos = [454 681];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 200;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 11;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = inf;
            
        case 'scene14'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 40.0;                      % in meters
            referenceObjectShape = 'rail';
            referenceObjectSizeInMeters = 100/100;         % in meters
            referenceObjectSizeInPixels = 72;
            referenceObjectXYpos = [324 324];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 2000;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 169;
            obj.sceneData.clippingRegion.x2 = 536;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 755;
            
        
        case 'scene15'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 50.0;                      % in meters
            referenceObjectShape = 'rail';
            referenceObjectSizeInMeters = 90/100;         % in meters
            referenceObjectSizeInPixels = 66;
            referenceObjectXYpos = [194 257];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 2500;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 215;
            obj.sceneData.clippingRegion.x2 = 632;
            obj.sceneData.clippingRegion.y1 = 96;
            obj.sceneData.clippingRegion.y2 = 776;
            
        case 'scene16'
            % custom spatial calibration information (tree branch)
            distanceToCamera = 400.0;                      % in meters
            referenceObjectShape = 'rail';
            referenceObjectSizeInMeters = 85/100;         % in meters
            referenceObjectSizeInPixels = 10;
            referenceObjectXYpos = [102 515];
            referenceObjectROI = [2 referenceObjectSizeInPixels/2];
           
            % custom illuminant
            obj.sceneData.customIlluminant.name         = 'D65';
            obj.sceneData.customIlluminant.wave         = 410:10:710;
            obj.sceneData.customIlluminant.meanSceneLum = 3000;   % cd/m2
            
            % custom clipping
            obj.sceneData.clippingRegion.x1 = 213;
            obj.sceneData.clippingRegion.x2 = Inf;
            obj.sceneData.clippingRegion.y1 = 1;
            obj.sceneData.clippingRegion.y2 = 700;
            
            
        otherwise
            error('Do not have any information fo scene named ''%s''.', sceneName);
    end
    
    
    
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



% Method to generate a reference object data struct specific to scene1
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
            'shape',            'plate', ...
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
            'shape',            'plate', ...
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
            'shape',            'plate', ...
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

function referenceObjectData = generateReferenceObjectDataStructForManchesterScene5(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.323, ...              % 
            'yChroma',      0.338, ...              %
            'Yluma',        8450,  ...              % cd/m2
            'CCT',          5924   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'sphere', ...
            'distanceToCamera', 56, ...             % meters
            'sizeInMeters',     30/100.0, ...       % for this scene, the reported size is the ball diameter
            'sizeInPixels',     167, ...            % estimated manually from the picture
            'roiXYpos',         [83 981], ...       % pixels (center)
            'roiSize',          [10 10] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded at Brufe, Terras do Bouro, Minho region, Portugal, on 25 July 2002 at 16:15'...
                  'under a blue sky with some wind.  Ambient temperature was 30ºC. Camera aperture was f/16, focus 3.0,'...
                  'and zoom maximum'] ...
    );    
end


function referenceObjectData = generateReferenceObjectDataStructForManchesterScene6(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.326, ...              % 
            'yChroma',      0.339, ...              %
            'Yluma',        11000,  ...              % cd/m2
            'CCT',          5803   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'sphere', ...
            'distanceToCamera', 3.1, ...            % meters
            'sizeInMeters',     1.6/100.0, ...      % for this scene, the reported size is the ball diameter
            'sizeInPixels',     57, ...             % estimated manually from the picture
            'roiXYpos',         [1303 986], ...     % pixels (center)
            'roiSize',          [5 5] ...           % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in the Picoto area, Braga, Minho region, Portugal, on 8 August 2002 at 12:57'...
                  'under direct sunlight with a thin cloud and a slight wind. Ambient temperature was 28 ºC. '...
                  'Camera aperture was f/22, focus 5.0, and zoom set to maximum giving a focal length of 75 mm'] ...
    );    
end


function referenceObjectData = generateReferenceObjectDataStructForManchesterScene7(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.330, ...              % 
            'yChroma',      0.341, ...              %
            'Yluma',        2698,  ...              % cd/m2
            'CCT',          5601   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'plate', ...
            'distanceToCamera', 4.0, ...            % meters
            'sizeInMeters',     11/100.0, ...       % for this scene, the reported size is the plate's height
            'sizeInPixels',     380, ...            % estimated manually from the picture
            'roiXYpos',         [12 640], ... % pixels (center)
            'roiSize',          [7 180] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in the Ribeira area, Porto, Portugal, on 10 July 2003 at 15:05 under '...
                  'direct sunlight with thin cloud and a slight wind. Ambient temperature was 26 ºC. '...
                  'Camera aperture was f/16, focus 8.5, and zoom set to maximum, giving a focal length of 75 mm'] ...
    );    
end

function referenceObjectData = generateReferenceObjectDataStructForManchesterScene8(referencePaintMaterialFileName)
    % Spectral data for reference paint material (variable: 'ref_n7')
    ref_n7 = [];
    load(referencePaintMaterialFileName);
    if (isempty(ref_n7))
        error('Data file does not contain the expected ''ref_n7'' field.');
    end
    
    referenceObjectData = struct(...
        'spectroRadiometerReadings', struct( ...    % Spectro-radiometer readings from the reference object
            'xChroma',      0.333, ...              % 
            'yChroma',      0.346, ...              %
            'Yluma',        6166,  ...              % cd/m2
            'CCT',          5492   ...              % deg kelvin
            ), ...
         'paintMaterial', struct( ...               % SPD of the reference object
            'name',   'Munsell N7 matt grey', ...
            'wave', ref_n7(:,1),...
            'spd',  ref_n7(:,2) ...
         ), ...
         'geometry', struct( ...                    % Geometry of the reference object
            'shape',            'plate', ...
            'distanceToCamera', 36.0, ...           % meters
            'sizeInMeters',     11/100.0, ...       % for this scene, the reported size is the plate's height
            'sizeInPixels',     36, ...            % estimated manually from the picture
            'roiXYpos',         [1334 626], ...       % pixels (center)
            'roiSize',          [6 18] ...         % pixels (halfwidth, halfheight)
         ), ...
         'info', ['Scene was recorded in Souto, Minho region, Portugal, on 8 July 2003 at 13:17 under '...
                  'direct sunlight with clear sky. Ambient temperature was 26 ºC. Camera aperture was f/16,'...
                  'focus 9.0, and zoom set to maximum giving a focal length of 75 mm'] ...
    );    
end
