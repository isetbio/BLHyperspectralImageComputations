classdef ManchesterHyperSpectralImageDataExtractor < HyperSpectralImageDataExtractor
%MANCHESTERHYPERSPECTRALIMAGEDATAEXTRACTOR A @HyperspectralImageDataExtractor subclass, specialized for the Manchester data base
%  Usage:
%     sceneName = 'scene4';
%     
%     % Instantiate a ManchesterHyperSpectralImageDataExtractor
%     hyperSpectralImageDataHandler = ManchesterHyperSpectralImageDataExtractor(sceneName);
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

    properties
    end
    
    methods
        function obj = ManchesterHyperSpectralImageDataExtractor(sceneName)
            % Call the super-class constructor.
            obj = obj@HyperSpectralImageDataExtractor();
            
            % Generate the (database-specific) referenceObjectData
            generateSceneDataStruct(obj,sceneName);
            obj.referenceObjectData = obj.sceneData.referenceObjectData;
            
            % Call super-class method to generate the adianceStruct
            obj.generateRadianceDataStruct();
        end
    end
    
    methods (Access=public)
        generateSceneDataStruct(obj,sceneName);
    end
    
end

