classdef HyperSpectralImageDataExtractor < handle
    %HYPERSPECTRALIMAGEDATAEXTRACTOR Class to extract hyperspectral image data
    %   Usage:
    % 
    
    properties(SetAccess = private)
        sceneLuminanceMap;
        sceneXYZmap;
        radianceData;
        referenceObjectData;
        isetbioSceneObject;
    end
    
    properties (Constant)
        wattsToLumens = 683;
    end
    
    properties (Access = private)
        sceneData = struct();
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
        
    end
    
    methods (Access = private)
        extractHyperpectralSceneData(obj);
        generateReferenceObjectDataStruct(obj);
        generateRadianceDataStruct(obj);
        roiLuminance = computeROIluminance(obj);
    end
end

