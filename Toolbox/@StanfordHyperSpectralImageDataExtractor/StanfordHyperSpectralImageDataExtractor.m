classdef StanfordHyperSpectralImageDataExtractor < HyperSpectralImageDataExtractor
%STANFORDHYPERSPECTRALIMAGEDATAEXTRACTOR A @HyperspectralImageDataExtractor subclass, specialized for the Stanford data base


    properties
    end
    
    methods
        function obj = StanfordHyperSpectralImageDataExtractor(sceneName)
            % Call the super-class constructor.
            obj = obj@HyperSpectralImageDataExtractor();
            
            databaseName = 'stanford_database';
    
            obj.sceneData = struct(...
                'database', databaseName, ...              % database directory
                'name',     sceneName, ...                 % scene name (also subdirectory)
                'referenceObjectData', struct(), ...       % struct with reference object data
                'reflectanceDataFileName', '', ...         % name of scene reflectance data file
                'spectralRadianceDataFileName', '' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
            );
        
            
%             scene = sceneFromHyperSpectralImageData(...
%                 'sceneName',            obj.radianceData.sceneName, ...
%                 'wave',                 obj.illuminant.wave, ...
%                 'illuminantEnergy',     obj.illuminant.spd, ... 
%                 'radianceEnergy',       obj.radianceData.radianceMap, ...
%                 'sceneDistance',        obj.referenceObjectData.geometry.distanceToCamera, ...
%                 'scenePixelsPerMeter',  obj.referenceObjectData.geometry.sizeInPixels/obj.referenceObjectData.geometry.sizeInMeters  ...
%             );
        
              
             % Generate the (database-specific) referenceObjectData
             populateSceneDataStruct(obj);
%             
             % Generate reference object data
             obj.referenceObjectData = obj.sceneData.referenceObjectData;
%  
             % Load the illuminant
             obj.loadIlluminant();
%             
%             % Load the reflectance map
             obj.loadReflectanceMap();
       
            
        end
    end
    
    methods (Access=protected)  
        % Stanford database-specific implementation of the populateSceneDataStruct
        populateSceneDataStruct(obj,sceneName);
        
        % Stanford database-specific implementation of the loadReflectanceMap 
        loadReflectanceMap(obj);
        
        % Stanford database-specific implementation of the loadIlluminant
        loadIlluminant(obj);
    end
    
    
end

