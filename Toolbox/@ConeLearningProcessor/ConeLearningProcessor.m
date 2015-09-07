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
    
    % Cone learning analysis parameters (user-specified or defaults)
    properties (SetAccess = private)
        fixationsPerSceneRotation;
        adaptationModel;
        photocurrentNoise;
        precorrelationFilterSpecs;
        disparityMetric;
        mdsWarningsOFF;
        correlationComputationIntervalInMilliseconds;
        coneLearningUpdateIntervalInFixations;
        randomSeedForEyeMovementsOnDifferentScenes = 234823568;
        displayComputationTimes;
        outputFormat;
    end
    
    properties (SetAccess = private, Dependent)
        outputPDFFileName;
        outputVideoFileName;
        outputMatFileName;
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
        
        precorrelationFilter = [];
        
        maxResponsiveConeIndices;
        photonAbsorptionTracesRange = [];
        photoCurrentsTracesRange = [];
        
        photonAbsorptionXTresponse;             % current agreggate photon absorption XT response
        adaptedPhotoCurrentXTresponse;          % current aggregate photo-current XT response 
        prefilteredAdaptedPhotoCurrentResponsesForSelectCones;
        
        disparityMatrix;
        MDSprojection;                  % current MDSprojection
        MDSstress;                      % current MDSstress
        lastMDSscaleSucceeded;          % flag indicating whether the last call to mdsscale succeeded
        
        unwrappedMDSprojection;         % unwrapped stuff - computed by unwrapMDSprojection       
        unwrappedLconeIndices;
        unwrappedMconeIndices;
        unwrappedSconeIndices;
        unwrappedLMconeIndices;
        unwrappedLMcenter;
        unwrappedScenter;
        unwrappedPrivot;
    
        coneMosaicLearningProgress = [];
    end
    
    % Public API
    methods
        % Constructor
        function obj = ConeLearningProcessor()
        end % constructor
    end
    
    methods (Access = public)
        exportFile = computeSpatioTemporalPhotonAbsorptionMatrix(obj, varargin);
        learnConeMosaic(obj, datafile, varargin);
    end
    
    % getters for dependent properties
    methods
        function filename = get.outputPDFFileName(obj)
            filename = sprintf('%s.pdf', obj.assembleOutputFileName);
        end
        function filename = get.outputMatFileName(obj)
            filename = sprintf('%s.mat', obj.assembleOutputFileName);
        end
        function filename = get.outputVideoFileName(obj)
            filename = sprintf('%s.m4v', obj.assembleOutputFileName);
        end 
    end
    
    methods (Access = private)
        % import data and convert to photon absorption rates
        loadSpatioTemporalPhotonAbsorptionMatrix(obj, datafile);
        
        % computational methods
        computePrecorrelationFilter(obj);
        maxAvailableSceneRotations = permuteEyeMovementsAndPhotoAbsorptionResponses(obj);
        computePostAbsorptionResponse(obj, savePrefilteredAdaptedPhotoCurrentXTresponse);
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
        displayConeMosaicLearningProgress(obj, performanceAxes1, performanceAxes2);
        
        displayTimeInfo(obj,timeDisplayAxes);
        
        filename = assembleOutputFileName(obj, extention);
    end
    
end

