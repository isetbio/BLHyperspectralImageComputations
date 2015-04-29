classdef ManchesterHyperSpectralImageDataExtractor < HyperSpectralImageDataExtractor
%MANCHESTERHYPERSPECTRALIMAGEDATAEXTRACTOR A @HyperspectralImageDataExtractor subclass, specialized for the Manchester data base
%  Usage:
%     sceneName = 'scene4';
%     
%     % Instantiate a ManchesterHyperSpectralImageDataExtractor
%     hyperSpectralImageDataHandler = ManchesterHyperSpectralImageDataExtractor(sceneName);
%    
%     % Return shooting info
%     hyperSpectralImageDataHandler.shootingInfo()
% 
%     % Plot the scene illuminant
%     hyperSpectralImageDataHandler.plotSceneIlluminant();
%    
%     % Display a sRGB version of the hyperspectral image with the reference object outlined in red
%     clipLuminance = 12000; gammaValue = 1.7; outlineWidth = 2;
%     hyperSpectralImageDataHandler.showLabeledsRGBImage(clipLuminance, gammaValue, outlineWidth);
%     
%     % Get the isetbio scene object directly
%     sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
%     
%     % Export the isetbio scene object
%     fileNameOfExportedSceneObject = hyperSpectralImageDataHandler.exportIsetbioSceneObject();
%
%    4/28/2015   npc    Wrote it.
%

    properties
    end
    
    methods
        function obj = ManchesterHyperSpectralImageDataExtractor(sceneName, sceneCalibrationStruct)
            % Call the super-class constructor.
            obj = obj@HyperSpectralImageDataExtractor();
            
            databaseName = 'manchester_database';
    
            obj.sceneData = struct(...
                'database', databaseName, ...              % database directory
                'name',     sceneName, ...                 % scene name (also subdirectory)
                'referenceObjectData', struct(), ...       % struct with reference object data
                'reflectanceDataFileName', '', ...         % name of scene reflectance data file
                'spectralRadianceDataFileName', '' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
            );

            % Generate the (database-specific) referenceObjectData
            populateSceneDataStruct(obj);
            
            % Generate reference object data
            if isempty(fieldnames(obj.sceneData.referenceObjectData))
                % if the referenceObjectData is empty, generate a generic ne based on the passed sceneCalibrationStruct
                obj.referenceObjectData = obj.generateGenericReferenceObjectDataStruct(sceneCalibrationStruct);
            else
                obj.referenceObjectData = obj.sceneData.referenceObjectData;
            end
            
            % Load the reflectance map
            loadReflectanceMap(obj);
            
            if (isempty(obj.sceneData.spectralRadianceDataFileName))
                % if the spectralRadianceDataFileName is empty, generate an illuminant based on the passed sceneCalibrationStruct
                obj.generateIlluminant(sceneCalibrationStruct);
            else
                loadIlluminant(obj);
            end
            
            % Call super-class method to generate the radianceStruct
            obj.inconsistentSpectralData = obj.generateRadianceDataStruct();
        end
    end
    
    methods (Access=protected)
        
        % Manchester database-specific implementation of the populateSceneDataStruct
        populateSceneDataStruct(obj,sceneName);
        
        % Manchester database-specific implementation of the loadReflectanceMap 
        loadReflectanceMap(obj);
        
        % Manchester database-specific implementation of the loadIlluminant
        loadIlluminant(obj);
    end
    
end

