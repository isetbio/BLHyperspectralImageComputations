function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
        
    % Computation steps. Uncomment the ones you want to execute
    instructionSet = {...
       %'lookAtScenes' ...
        'compute outer segment responses' ...      % compute OS responses. Data saved in the scansData directory
        'assembleTrainingDataSet' ...               % generates the training/testing design matrices. Data are saved in the decodingData directory
       'computeDecodingFilter' ...                 % computes the decoding filter based on the training data set (in-sample). Data stored in the decodingData directory
        'computeOutOfSamplePrediction' ...          % computes reconstructions based on the test data set (out-of-sample). Data stored in the decodingData directory
       % 'visualizeScan' ...                        % visualize the responses from one scan - under construction
        %
        'visualizeDecodingFilter' ...              % visualize the decoder filter's spatiotemporal dynamics
       % 'visualizeInSamplePrediction' ...          % visualize the decoder's in-sample deperformance
       % 'visualizeOutOfSamplePrediction' ...       % visualize the decoder's out-of-sample deperformance
       % 'makeReconstructionVideo' ...              % generate video of the reconstruction
       % 'visualizeConeMosaic' ...                  % visualize the LMS cone mosaic used
        };
  
%    sceneSetName = 'manchester';
%    resultsDir = 'AdaptEvery40Fixations/@osLinear';
%    trainingDataPercentange = 75;
%    testingDataPercentage = 25;
    

    sceneSetName = 'harvard_manchester'
    resultsDir = sprintf('%s/@osLinear', 'Fixation200msMicrofixationGain1');
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
                expParams = experimentParams();
                core.computeOuterSegmentResponses(expParams);

            case 'visualizeScan'
                sceneIndex = input('Select the scene index to visualize: ');
                visualizer.renderScan(sceneSetName, resultsDir, sceneIndex);

            case 'assembleTrainingDataSet'
                core.assembleTrainingSet(sceneSetName, resultsDir, trainingDataPercentange, testingDataPercentage);

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
                error('Unknown instruction: ''%s''.\n', instructionSet{1});
        end  % switch 
    end % for k
    return;        
            
    sceneSetName = 'manchester_harvard_0';          % 4018 x 28081, rank: 258
    resultsDir = 'manchester_harvard_0/@osLinear';
    
    sceneSetName = 'manchester_harvard_1';          % 9849 x 28081, rank: 339
    resultsDir = 'manchester_harvard_0/@osLinear';
    
    sceneSetName = 'manchester_harvard_2';          % 9849 x 28081, rank: 107
    resultsDir = 'manchester_harvard_0/@osLinear';
    
    sceneSetName = 'manchester_harvard_3';          % 9849 x 28081, rank: 116
    resultsDir = 'manchester_harvard_0/@osLinear';
    
    sceneSetName = 'manchester_harvard_4';          % 9849 x 28081, rank: ???
    resultsDir = 'manchester_harvard_0/@osLinear';
    
    for imIndex = 5:5 % 27
        
        try
            sceneSetName = sprintf('manchester_harvard_%d', imIndex);          % 
            resultsDir = sprintf('manchester_harvard_%d/@osLinear', imIndex);

            trainingDataPercentange = 15;
            testingDataPercentage = 15;
    
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
                        expParams = experimentParams();
                        core.computeOuterSegmentResponses(expParams);

                    case 'visualizeScan'
                        sceneIndex = input('Select the scene index to visualize: ');
                        visualizer.renderScan(sceneSetName, resultsDir, sceneIndex);

                    case 'assembleTrainingDataSet'
                        core.assembleTrainingSet(sceneSetName, resultsDir, trainingDataPercentange, testingDataPercentage);

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
                        error('Unknown instruction: ''%s''.\n', instructionSet{1});
                end  % switch 
            end % for k
    
        catch err
            fprintf('Eror with %d\n', imIndex);
        end
    
    end % imIndex
    
end

function expParams = experimentParams()

   decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', 3.0, ...                 % reconstructed scene resolution in retinal microns
        'extraMicronsAroundSensorBorder', 0, ...                    % decode this many additional (or less, if negative) microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                   % temporal resolution of reconstruction
        'latencyInMillseconds', -150, ...                           % latency of the decoder filter (negative for non-causal time delays)
        'memoryInMilliseconds', 600 ...                             % memory of the decoder filter
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
            'fixationOverlapFactor', 0.4^2, ...     
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
        'fixationsPerScan', 20, ...                                               % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 50, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', 300 ...
    );
    
    % assemble all  param structs into one superstruct
    resultsDir = sprintf('Fixation200msMicrofixationGain1/%s', outerSegmentParams.type);
    expParams = struct(...
        'resultsDir',           resultsDir, ...                               % Where computed data will be saved
        'sceneSetName',         'harvard_manchester', ...                     % the name of the scene set to be used
        'viewModeParams',       viewModeParams, ...
        'sensorParams',         sensorParams, ...
        'outerSegmentParams',   outerSegmentParams, ...
        'decoderParams',        decoderParams ...
    );
end