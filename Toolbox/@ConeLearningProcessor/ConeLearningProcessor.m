classdef ConeLearningProcessor < handle
    %CONELEARNINGPROCESSOR Class to handle cone learning in the ISETBIO
    % compute framework
    %   
    
    % Mosaic parameters
    properties (SetAccess = private)
        conesAcross
        coneApertureInMicrons
        coneIntegrationTimeInMilliseconds
        coneLMSdensities
        eyeMicroMovementsPerFixation
        sceneSet
    end
    
    % Cone learning parameters (user-specified or defaults)
    properties (SetAccess = private)
        fixationsPerSceneRotation;
        adaptationModelToUse;
        noiseFlag;
        precorrelationFilter;
        disparityMetric;
        mdsWarningsOFF;
        coneLearningUpdateInFixations;
        randomSeedForEyeMovementsOnDifferentScenes = 234823568;
    end
    
    % Internal data
    properties (Access = private)
        core1Data = struct();   % Core computed params (computed by computeSpatioTemporalPhotonAbsorptionMatrix() ) 
        
        videoData = struct();
        % CLims range for current2Dresponse and shortXTresponse
        responseRange = [];
        % CLims range for disparity matrix
        disparityRange = [];
        
        % current fixation time and number
        fixationTimeInMilliseconds;
        fixationsNum;
        
        maxResponsiveConeIndices;
        photonAbsorptionTracesRange = [];
        photoCurrentsTracesRange = [];
        
        photonAbsorptionXTresponse;             % current agreggate photon absorption XT response
        adaptedPhotoCurrentXTresponse;          % current aggregate photo-current XT response 
        prefilteredAdaptedPhotoCurrentXTresponse;
        
        disparityMatrix;
        MDSprojection;                  % current MDSprojection
        MDSstress;                      % current MDSstress
        
        unwrappedMDSprojection;         % unwrapped stuff - computed by unwrapMDSprojection       
        unwrappedLconeIndices;
        unwrappedMconeIndices;
        unwrappedSconeIndices;
        unwrappedLMconeIndices;
        unwrappedLMcenter;
        unwrappedScenter;
        unwrappedPrivot;
    
        coneMosaicLearningAccuracy = [];
    end
    
    % Public API
    methods
        % Constructor
        function obj = ConeLearningProcessor()
        end % constructor
    end
    
    methods (Access = public)
        exportFile = computeSpatioTemporalPhotonAbsorptionMatrix(obj, varargin);
        generateConeLearningProgressVideo(obj, datafile, varargin);
    end
    
    methods (Access = private)
        loadSpatioTemporalPhotonAbsorptionMatrix(obj, datafile);
        
        % computational methods
        computePostAbsorptionResponse(obj);
        D = computeDisparityMatrix(obj,timeBinRange);
        unwrapMDSprojection(obj);
        computeConeMosaicLearningProgression(obj, fixationsNum);
        
        % display update methods
        computeOpticalImageVideoData(obj, sceneIndex)
        computeEyeMovementVideoData(obj, sceneIndex, timeBins);
        displayOpticalImageAndEyeMovements(obj, opticalImageAxes, eyeMovementIndex)
        
        determineMaximallyResponseLMSConeIndices(obj, sceneIndex);
        displaySingleConeTraces(obj, photonAbsorptionTraces, photoCurrentTraces);
        
        displayCurrent2Dresponse(obj, current2DResponseAxes);
        displayShortHistoryXTresponse(obj, xtResponseAxes);
        
        displayDisparityMatrix(obj, dispMatrixAxes);
        displayLearnedConeMosaic(obj, xyMDSAxes, xzMDSAxes, yzMDSAxes, mosaicAxes)
        displayConeMosaicProgress(obj, performanceAxes1, performanceAxes2);
        
        displayTimeInfo(obj,timeDisplayAxes);
    end
    
end

