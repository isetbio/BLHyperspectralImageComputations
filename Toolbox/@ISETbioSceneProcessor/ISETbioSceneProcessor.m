classdef ISETbioSceneProcessor < handle
    %ISETBIOSIMULATOR Class to handle all of the isebio image processing
    %   Detailed explanation goes here
    
    properties
        % verbosity
        verbosity;
    end
    
    properties (SetAccess = private)
        % the input scene isetbio struct
        scene;
        
        % the optical image isetbio struct
        opticalImage;
        
        % the sensor isetbio struct
        sensor;
        
        % the eye movement isetbio struct
        eyeMovement;
        
        % the sensor activation image (volts)
        sensorActivationImage
    end
    
    properties (Access = private)
        % the name of the resources root directory
        resourcesRootDirName;
        
        % the name of the current database
        databaseName;
        
        % the name of the current scene
        sceneName;
        
        % the name of the cached optical image
        opticalImageCacheFileName;
        
        % the name of the cached sensor image
        sensorCacheFileName;
    end
    
    
    % Public API
    methods
        % Constructor
        function obj = ISETbioSceneProcessor(databaseName, sceneName, verbosity)
            obj.verbosity = verbosity;
            obj.loadNewScene(databaseName, sceneName);
        end
        
        % Method to load a new scene
        loadNewScene(obj,databaseName, sceneName);
        
        % Method to compute the optical image
        computeOpticalImage(obj,varargin);
        
        % Method to compute the (time-varying) activation of a sensor mosaic
        computeSensorActivation(obj,varargin);
        
        % Method to estimate the identity of each cone by analysis of their
        % responses to a set of stimuli
        MDSprojection = estimateReceptorIdentities(obj, varargin);
    end
    
    
    methods (Access = private)
        % Method to init ISETbioSceneProcessir
        init(obj);
        
    end
    
end

