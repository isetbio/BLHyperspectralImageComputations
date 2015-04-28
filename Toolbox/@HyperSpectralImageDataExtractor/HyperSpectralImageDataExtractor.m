classdef HyperSpectralImageDataExtractor < handle
%HYPERSPECTRALIMAGEDATAEXTRACTOR Abstarct class to extract hyperspectral image data
% Use one of its subclasses, such as @ManchesterHyperSpectralImageDataExtractor.
% For more information: doc ManchesterHyperSpectralImageDataExtractor
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
    end
    
    % Protected properties, so that our subclasses can set them
    properties (SetAccess = protected)
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
        
        % Information about the scene shooting
        shootingInfo;
    end
    
    properties (Constant)
        wattsToLumens = 683;
    end
    
    % Protected, so that our subclasses can set/get them
    properties (Access = protected)
        % struct with filenames of different data files for the current scene
        % passed during instantiation of the HyperSpectralImageDataExtractor
        sceneData = struct();
        
        % The XYZ CMFs
        sensorXYZ = [];
    end
    
    % Public API
    methods
        % Constructor
        function obj = HyperSpectralImageDataExtractor()
            % Load CIE '31 CMFs
            colorMatchingData = load('T_xyz1931.mat');
            obj.sensorXYZ = struct;
            obj.sensorXYZ.S = colorMatchingData.S_xyz1931;
            obj.sensorXYZ.T = colorMatchingData.T_xyz1931;
            clear 'colorMatchingData';
        end
        
        % Method to display an sRGB version of the hyperspectral image with the reference object outlined in red
        showLabeledsRGBImage(obj, clipLuminance, gammaValue, outlineWidth);
        
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
        
        function info = get.shootingInfo(obj)
            info = obj.referenceObjectData.info;
        end
        
        function plotSceneIlluminant(obj)
            % Plot the illuminant
            h = figure(1);
            set(h, 'Position', [10 920 560 420]);
            plot(obj.radianceData.wave, obj.radianceData.illuminant, 'ks-');
            xlabel('wavelength (nm)');
            ylabel('Energy (Watts/steradian/m^2/nm');
            title('Scene illuminant');
        end
    end
    
    methods (Abstract)
        generateSceneDataStruct(obj,sceneName);
    end
    
    
    % Protected methods
    methods (Access = protected)
        generateRadianceDataStruct(obj);
        roiLuminance = computeROIluminance(obj);
        chromaticity = computeROIchromaticity(obj);
    end
end

