function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
        
    % Computation steps. Uncomment the ones you want to execute
    instructionSet = {...
       %'lookAtScenes' ...
        'compute outer segment responses' ...      % compute OS responses. Data saved in the scansData directory
        'assembleTrainingDataSet' ...              % generates the training/testing design matrices. Data are saved in the decodingData directory
        'preprocessDesignMatrices' ...
        'computeDecodingFilter' ...                 % computes the decoding filter based on the training data set (in-sample). Data stored in the decodingData directory
        'computeOutOfSamplePrediction' ...          % computes reconstructions based on the test data set (out-of-sample). Data stored in the decodingData directory
       % 'visualizeScan' ...                        % visualize the responses from one scan - under construction
       % 'visualizeDecodingFilter' ...              % visualize the decoder filter's spatiotemporal dynamics
       % 'visualizeInSamplePrediction' ...          % visualize the decoder's in-sample deperformance
       % 'visualizeOutOfSamplePrediction' ...       % visualize the decoder's out-of-sample deperformance
       % 'makeReconstructionVideo' ...              % generate video of the reconstruction
       % 'visualizeConeMosaic' ...                  % visualize the LMS cone mosaic used
     };
  

    sceneSetName = 'harvard_manchester';
    resultsDir = sprintf('%s/@osLinear', 'Overlap0.40_Fixation200ms_MicrofixationGain0_DesignMatrixPreProcessing2');
    trainingDataPercentange = 50;
    testingDataPercentage = 50;
            
    for k = 1:numel(instructionSet)

        if (exist('expParams', 'var'))
            sceneSetName = expParams.sceneSetName;
            resultsDir = expParams.resultsDir;
            fprintf('Will analyze data from %s and %s\n', sceneSetName, resultsDir);
        end

        switch instructionSet{k}
            case 'lookAtScenes' 
                core.lookAtScenes(sceneSetName);

            case 'compute outer segment responses'
                expParams = experimentParams(sceneSetName);
                core.computeOuterSegmentResponses(expParams);

            case 'visualizeScan'
                sceneIndex = input('Select the scene index to visualize: ');
                visualizer.renderScan(sceneSetName, resultsDir, sceneIndex);

            case 'assembleTrainingDataSet'
                core.assembleTrainingSet(sceneSetName, resultsDir, trainingDataPercentange, testingDataPercentage);

            case 'preprocessDesignMatrices'
                decoder.preProcessDesignMatrices(sceneSetName, resultsDir);
                
            case 'computeDecodingFilter'
                onlyComputeDesignMatrixRank = false;
                decoder.computeDecodingFilter(sceneSetName, resultsDir, onlyComputeDesignMatrixRank);

            case 'computeOutOfSamplePrediction'
                decoder.computeOutOfSamplePrediction(sceneSetName, resultsDir);

            case 'visualizeDecodingFilter'
                visualizer.renderDecoderFilterDynamicsFigures(sceneSetName, resultsDir);

            case 'visualizeInSamplePrediction'
                visualizer.renderPredictionsFigures(sceneSetName, resultsDir, 'InSample');

            case 'visualizeOutOfSamplePrediction'
                visualizer.renderPredictionsFigures(sceneSetName, resultsDir, 'OutOfSample');

            case 'makeReconstructionVideo'
                visualizer.renderReconstructionVideo(sceneSetName, resultsDir);

            case 'visualizeConeMosaic'
                visualizer.renderConeMosaic(sceneSetName, resultsDir);

            otherwise
                error('Unknown instruction: ''%s''.\n', instructionSet{k});
        end  % switch 
    end % for k
  
end

function expParams = experimentParams(sceneSetName)

   decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', 3.0, ...                 % reconstructed scene resolution in retinal microns
        'extraMicronsAroundSensorBorder', 0, ...                    % decode this many additional (or less, if negative) microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                   % temporal resolution of reconstruction
        'latencyInMillseconds', -150, ...                           % latency of the decoder filter (negative for non-causal time delays)
        'memoryInMilliseconds', 500, ...                            % memory of the decoder filter
        'designMatrixPreProcessing', 2 ...                          % 0: nothing, 1:centering, 2:centering+norm, 3:centering+norm+whitening
    );

    sensorTimeStepInMilliseconds = 0.1;                             % must be small enough to avoid numerical instability in the outer segment current computation
    integrationTimeInMilliseconds = 50;
    
    % sensor params for scene viewing
    overlap = 0.4;
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        
        'LMSdensities', [0.6 0.3 0.1], ...        
        'spatialGrid', [18 26], ...                                                 % [rows, cols]
        'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed',  1552784, ...                                                 % fixed value to ensure repeatable results
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...
            'meanFixationDurationInMilliseconds', 200, ...
            'stDevFixationDurationInMilliseconds', 20, ...
            'meanFixationDurationInMillisecondsForAdaptingField', 200, ...
            'stDevFixationDurationInMillisecondsForAdaptingField', 20, ...
            'microFixationGain', 0, ...
            'fixationOverlapFactor', overlap^2, ...     
            'saccadicScanMode',  'randomized'... %                        % 'randomized' or 'sequential', to visit eye position grid sequentially
        ) ...
    );
    
    outerSegmentParams = struct(...
        'type', '@osLinear', ...                       % choose between '@osBiophys' and '@osLinear'
        'addNoise', true ...
    );
    
    adaptingFieldParams = struct(...
        'type', 'SpecifiedReflectanceIlluminatedBySpecifiedIlluminant', ...
        'surfaceReflectance', struct(...
                                'type', 'MacBethPatchNo', ...
                                'patchNo', 16 ...
                            ), ...
        'illuminantName', 'D65', ...
        'meanLuminance', 300 ...
    );
    
    viewModeParams = struct(...
        'fixationsPerScan', 10, ...                                              % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 50, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', 300 ...
    );
    
    % assemble resultsDir based on key params
    resultsDir = sprintf('Overlap%2.2f_Fixation%dms_MicrofixationGain%d_DesignMatrixPreProcessing%d/%s', overlap, sensorParams.eyeMovementScanningParams.meanFixationDurationInMilliseconds, sensorParams.eyeMovementScanningParams.microFixationGain, decoderParams.designMatrixPreProcessing, outerSegmentParams.type);
    
    % organize all  param structs into one superstruct
    expParams = struct(...
        'resultsDir',           resultsDir, ...                               % Where computed data will be saved
        'sceneSetName',         sceneSetName, ...                              % the name of the scene set to be used
        'viewModeParams',       viewModeParams, ...
        'sensorParams',         sensorParams, ...
        'outerSegmentParams',   outerSegmentParams, ...
        'decoderParams',        decoderParams ...
    );
end