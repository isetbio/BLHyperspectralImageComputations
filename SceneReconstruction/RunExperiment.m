function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
        
    % Computation steps. Uncomment the ones you want to execute
    computationInstructionSet = {...
       %'lookAtScenes' ...
       'compute outer segment responses' ...       % compute OS responses. Data saved in the scansData directory
       'assembleTrainingDataSet' ...               % generates the training/testing design matrices. Data are saved in the decodingData directory
       'computeDecodingFilter' ...                 % computes the decoding filter based on the training data set (in-sample). Data stored in the decodingData directory
       'computeOutOfSamplePrediction' ...          % computes reconstructions based on the test data set (out-of-sample). Data stored in the decodingData directory
    };
    
    visualizationInstructionSet = {...
       % 'visualizeScan' ...                        % visualize the responses from one scan - under construction
       %'visualizeDecodingFilter' ...                % visualize the decoder filter's spatiotemporal dynamics
       'visualizeInSamplePrediction' ...            % visualize the decoder's in-sample deperformance
       'visualizeOutOfSamplePrediction' ...         % visualize the decoder's out-of-sample deperformance
       % 'makeReconstructionVideo' ...              % generate video of the reconstruction
       % 'visualizeConeMosaic' ...                  % visualize the LMS cone mosaic used
    };
  
    % Specify what to compute
    instructionSet = computationInstructionSet;  
    %instructionSet = visualizationInstructionSet;
    
    
    % Set data preprocessing params - This affects the name of the decodingDataDir
    designMatrixBased = 0;    % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
    rawResponseBased = 3;     % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
    preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased);
    
    computeSVDbasedLowRankFiltersAndPredictions = true;
    lowRankApproximations = [100 200 400 800 1600 3200 6400 12800];
    
    % Specify the data set to use
    whichDataSet = 'very_small';
    
    switch (whichDataSet)
        case 'very_small'
            sceneSetName = 'manchester';  
            scanSpatialOverlapFactor = 0.40; 
            fixationsPerScan = 10;
            
        case 'small'
            sceneSetName = 'manchester';  
            scanSpatialOverlapFactor = 0.50;  
            fixationsPerScan = 10;
            
        case 'original'
            sceneSetName = 'manchester';  
            scanSpatialOverlapFactor = 0.8; 
            fixationsPerScan = 20;
            
        case 'large'
            sceneSetName = 'harvard_manchester';  
            scanSpatialOverlapFactor = 0.50; 
            fixationsPerScan = 20;
            
        otherwise
            error('Unknown dataset:''%s''.', whichDataSet)
    end
    
    
    
    if (~ismember('compute outer segment responses', instructionSet))
        % Select an existing set of scans data (according to the following params)
        fixationMeanDuration = 200; 
        microFixationGain = 1; 
        osType = '@osLinear';
        resultsDir = core.getResultsDir(scanSpatialOverlapFactor,fixationMeanDuration, microFixationGain, osType);
        decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);
        p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
        fprintf('<strong>Using data from:\nResultsDir: ''%s''\nDecodingDataDir: ''%s''. </strong>\n', resultsDir, strrep(decodingDataDir,sprintf('%s/',p.computedDataDir),''));
    end  
    
    for k = 1:numel(instructionSet)
        switch instructionSet{k}
            case 'lookAtScenes' 
                core.lookAtScenes(sceneSetName);

            case 'compute outer segment responses'
                expParams = experimentParams(sceneSetName, scanSpatialOverlapFactor, fixationsPerScan);
                core.computeOuterSegmentResponses(expParams);
                
                % Set the sceneSetName, resultsDir, decodingDataDir according to the params set by experimentParams()
                sceneSetName = expParams.sceneSetName;
                resultsDir = expParams.resultsDir;
                decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);

            case 'visualizeScan'
                sceneIndex = input('Select the scene index to visualize: ');
                visualizer.renderScan(sceneSetName, resultsDir, sceneIndex);

            case 'assembleTrainingDataSet'
                trainingDataPercentange = 50;
                testingDataPercentage = 50;
                core.assembleTrainingSet(sceneSetName, resultsDir, decodingDataDir, trainingDataPercentange, testingDataPercentage, preProcessingParams);

            case 'computeDecodingFilter'
                decoder.computeDecodingFilter(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, lowRankApproximations);

            case 'computeOutOfSamplePrediction'
                decoder.computeOutOfSamplePrediction(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions);

            case 'visualizeDecodingFilter'
                visualizer.renderDecoderFilterDynamicsFigures(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions);

            case 'visualizeInSamplePrediction'
                visualizer.renderPredictionsFigures(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, 'InSample');

            case 'visualizeOutOfSamplePrediction'
                visualizer.renderPredictionsFigures(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, 'OutOfSample');

            case 'makeReconstructionVideo'
                visualizer.renderReconstructionVideo(sceneSetName, resultsDir, decodingDataDir);

            case 'visualizeConeMosaic'
                visualizer.renderConeMosaic(sceneSetName, resultsDir, decodingDataDir);

            otherwise
                error('Unknown instruction: ''%s''.\n', instructionSet{k});
        end  % switch 
    end % for k
end


function expParams = experimentParams(sceneSetName, scanSpatialOverlapFactor, fixationsPerScan)

   decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', 3.0, ...                 % reconstructed scene resolution in retinal microns
        'extraMicronsAroundSensorBorder', 0, ...                    % decode this many additional (or less, if negative) microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                   % temporal resolution of reconstruction
        'latencyInMillseconds', -150, ...                           % latency of the decoder filter (negative for non-causal time delays)
        'memoryInMilliseconds', 500 ...                             % memory of the decoder filter
    );
    
    sensorTimeStepInMilliseconds = 0.1;                             % must be small enough to avoid numerical instability in the outer segment current computation
    integrationTimeInMilliseconds = 50;
    
    % sensor params for scene viewing
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
            'microFixationGain', 1, ...
            'fixationOverlapFactor', scanSpatialOverlapFactor^2, ...     
            'saccadicScanMode',  'randomized'...                                    % 'randomized' or 'sequential', to visit eye position grid sequentially
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
        'fixationsPerScan', fixationsPerScan, ...                                              % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 50, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', 300 ...
    );
    
    % assemble resultsDir based on key params
    resultsDir = core.getResultsDir(scanSpatialOverlapFactor,sensorParams.eyeMovementScanningParams.meanFixationDurationInMilliseconds, sensorParams.eyeMovementScanningParams.microFixationGain, outerSegmentParams.type);
    
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

function preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased)
    preProcessingParams = struct(...
        'designMatrixBased', designMatrixBased, ...                                 % 0: nothing, 1:centering, 2:centering+norm, 3:centering+norm+whitening
        'rawResponseBased', rawResponseBased ...                                    % 0: nothing, 1:centering, 2:centering+norm,
    );
    
    if ((preProcessingParams.designMatrixBased > 0) && (preProcessingParams.rawResponseBased > 0))
        error('Choose preprocessing of either the raw responses OR of the design matrix, NOT BOTH');
    end
end
