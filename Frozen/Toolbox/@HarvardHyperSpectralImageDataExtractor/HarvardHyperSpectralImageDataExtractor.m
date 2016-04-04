classdef HarvardHyperSpectralImageDataExtractor < HyperSpectralImageDataExtractor
    %HARVARDHYPERSPECTRALIMAGEDATAEXTRACTOR A @HyperspectralImageDataExtractor subclass, specialized for the Harvard data base
    
    properties (SetAccess = private)
        motionMaskIsOn
        cameraSensitivityProfile
    end
    
    methods
         function obj = HarvardHyperSpectralImageDataExtractor(subset, sceneName, applyMotionMask)
             % Call the super-class constructor.
            obj = obj@HyperSpectralImageDataExtractor();
            
            databaseName = 'harvard_database';
            
            obj.sceneData = struct(...
                'database', databaseName, ...              % database directory
                'subset',   subset, ...                    % subset directory name
                'name',     sceneName, ...                 % scene name
                'referenceObjectData', struct(), ...       % struct with reference object data
                'reflectanceDataFileName', '', ...         % name of scene reflectance data file
                'spectralRadianceDataFileName', '' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
            );
        
            % Set the motion flag
            obj.motionMaskIsOn = applyMotionMask;
            
            % Load the camera sensitivity profile
            obj.loadCameraSensitivityProfile();
            
            % Generate the (database-specific) referenceObjectData
            obj.populateSceneDataStruct();
            
            % Generate reference object data
            obj.referenceObjectData = obj.sceneData.referenceObjectData;
 
            % Load the reflectance map
            obj.loadReflectanceMap();
            
            % Adjust the reflectance map if a region of known reflectance
            % exists in the scene (e.g., imgg3)
            if (~isempty(obj.sceneData.knownReflectionData))
                obj.adjustSceneReflectanceBasedOnRegionOfKnownReflectance();
            end
            
            if (isempty(obj.sceneData.spectralRadianceDataFileName))
                % if the spectralRadianceDataFileName is empty, generate an illuminant based on the info at obj.sceneData.customIlluminant
                obj.generateIlluminant();
            else
                loadIlluminant(obj);
            end
            
            % Call super-class method to generate the radianceStruct
            obj.inconsistentSpectralData = obj.generateRadianceDataStruct();
            
         end
         
    end
    
    
    methods (Access=protected)
        
        % Harvard database-specific implementation of the populateSceneDataStruct
        populateSceneDataStruct(obj,sceneName);
        
        % Harvard database-specific implementation of the loadReflectanceMap 
        loadReflectanceMap(obj);
        
        %  Harvard database-specific implementation of the loadIlluminant
        loadIlluminant(obj);
    end
    
    methods (Access = private)  
        loadCameraSensitivityProfile(obj);
    end
    
end

