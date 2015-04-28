classdef HyperSpectralImageDataExtractor < handle
%HYPERSPECTRALIMAGEDATAEXTRACTOR Class to extract hyperspectral image data
%Usage:
%     sceneData = struct(...
%         'database', 'manchester_database', ...                                          % database directory
%         'name', 'scene4', ...                                                           % scene subdirectory
%         'referencePaintFileName',  'ref_n7.mat', ...                                    % name of reference paint data file
%         'reflectanceDataFileName', 'ref_cyflower1bb_reg1.mat', ...                      % name of scene reflectance data file
%         'spectralRadianceDataFileName', 'radiance_by_reflectance_cyflower1.mat' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
%     );
%     
%     % Instantiate a @HyperSpectralImageDataExtractor object
%     hyperSpectralImageDataHandler = HyperSpectralImageDataExtractor(sceneData);
%    
%     % Display a sRGB version of the hyperspectral image with the reference object outlined in red
%     clipLuminance = 12000; gammaValue = 1.7;
%     hyperSpectralImageDataHandler.showLabeledsRGBImage(clipLuminance, gammaValue);
%     
%     % Get the isetbio scene object directly
%     sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
%     
%     % Export the isetbio scene object
%     fileNameOfExportedSceneObject = hyperSpectralImageDataHandler.exportIsetbioSceneObject();
%
%    4/28/2015   npc    Wrote it.
%
    
    properties(SetAccess = private)
        % Luminance map of hyperspectral image
        sceneLuminanceMap;
        
        % XYZ sensor map of hyperspectral image
        sceneXYZmap;
        
        % sRGBimage of the scene with the reference object outlined in red
        sRGBimage;
        
        % struct with spectral data of the scene and the illuminant
        radianceData = struct(...
            'sceneName',    '', ...
            'wave',         [], ...
            'illuminant',   [], ... 
            'radianceMap',  [] ...                                                
        );
    
        % struct with various information regarding the reference object in the scene
        referenceObjectData = struct(...
            'spectroRadiometerReadings', struct(), ...
            'paintMaterial',             struct(), ...
            'geometry',                  struct(), ...
            'info',                      ''...
        );  
    end
    
    properties(SetAccess = private, Dependent = true)
        % The computed isetbio scene object
        isetbioSceneObject;
    end
    
    properties (Constant)
        wattsToLumens = 683;
    end
    
    properties (Access = private)
        % struct with filenames of different data files for the current scene
        % passed during instantiation of the HyperSpectralImageDataExtractor
        sceneData = struct();
        
        % The XYZ CMFs
        sensorXYZ = [];
    end
    
    % Public API
    methods
        % Constructor
        function obj = HyperSpectralImageDataExtractor(sceneData)
            % Load CIE '31 CMFs
            colorMatchingData = load('T_xyz1931.mat');
            obj.sensorXYZ = struct;
            obj.sensorXYZ.S = colorMatchingData.S_xyz1931;
            obj.sensorXYZ.T = colorMatchingData.T_xyz1931;
            clear 'colorMatchingData';

            % generate local copy of sceneData struct
            obj.sceneData = sceneData;
            
            % Generate the reference object data struct
            obj.generateReferenceObjectDataStruct();
    
            % Generate the radiance data struct
            obj.generateRadianceDataStruct();
        end
        
        % Method to display an sRGB version of the hyperspectral image with the reference object outlined in red
        showLabeledsRGBImage(obj, clipLuminance, gammaValue);
        
        % Method to export generated isetbio scene object
        exportFileName = exportIsetbioSceneObject(obj);
        
        % Getter for dependent property isetbioSceneObject
        function scene = get.isetbioSceneObject(obj)
			% Generate isetbio scene
            fprintf('<strong>Generating isetbio scene object.</strong>\n');
            scene = sceneFromHyperSpectralImageData(...
                'sceneName',            obj.radianceData.sceneName, ...
                'wave',                 obj.radianceData.wave, ...
                'illuminantEnergy',     obj.radianceData.illuminant, ... 
                'radianceEnergy',       obj.radianceData.radianceMap, ...
                'sceneDistance',        obj.referenceObjectData.geometry.distanceToCamera, ...
                'scenePixelsPerMeter',  obj.referenceObjectData.geometry.sizeInPixels/obj.referenceObjectData.geometry.sizeInMeters  ...
            );
        
		end
    end
    
    % Private methods
    methods (Access = private)
        generateReferenceObjectDataStruct(obj);
        generateRadianceDataStruct(obj);
        roiLuminance = computeROIluminance(obj);
    end
end

