function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
       % 
    % Computation steps. Uncomment the ones you want to execute
    computationInstructionSet = {...
       %'lookAtScenes' ...
       %'compute outer segment responses' ...      % compute OS responses. Data saved in the scansData directory
       'assembleTrainingDataSet' ...               % generates the training/testing design matrices. Data are saved in the decodingData directory
       'computeDecodingFilter' ...                 % computes the decoding filter based on the training data set (in-sample). Data stored in the decodingData directory
       'computeOutOfSamplePrediction' ...          % computes reconstructions based on the test data set (out-of-sample). Data stored in the decodingData directory
    };
    
    visualizationInstructionSet = {...
       % 'visualizeScan' ...                        % visualize the responses from one scan - under construction
       %'visualizeInSamplePerformance' ...            % visualize the decoder's in-sample deperformance
       %'visualizeOutOfSamplePerformance' ...         % visualize the decoder's out-of-sample deperformance
       'visualizeDecodingFilter' ...                % visualize the decoder filter's spatiotemporal dynamics
       % 'makeReconstructionVideo' ...              % generate video of the reconstruction
       % 'visualizeConeMosaic' ...                  % visualize the LMS cone mosaic used
    };
  
    % Specify what to compute
    instructionSet = computationInstructionSet;  
    %instructionSet = visualizationInstructionSet;
    
    
    % Specify the optical elements employed - This affects the name of the resutls dir
    opticalElements = 'none';  % choose from 'none', 'noOTF', 'fNumber1.0', 'default'
    inertPigments = 'none';    % choose between 'none', 'noLens', 'noMacular', 'default'
    
    % Specify mosaic size and reconstructed stimulus spatial resolution - This affects the name of the results dir
    mosaicSize = [16 20];
    reconstructedStimulusSpatialResolutionInMicrons = 6;
    % Specify the data set to use
    whichDataSet =  'small';

    switch (whichDataSet)
        case 'very_small'
            sceneSetName = 'manchester';
            scanSpatialOverlapFactor = 0.4; 
            fixationsPerScan = 10;
            
        case 'small'
            sceneSetName = 'manchester';  
            scanSpatialOverlapFactor = 0.60;  
            fixationsPerScan = 20;
            
        case 'original'
            sceneSetName = 'manchester';  
            scanSpatialOverlapFactor = 0.75; 
            fixationsPerScan = 20;
            
        case 'original_3'
            sceneSetName = 'manchester_3';  
            scanSpatialOverlapFactor = 0.75; 
            fixationsPerScan = 20;
            
        case 'large'
            sceneSetName = 'harvard_manchester';  
            scanSpatialOverlapFactor = 0.60; 
            fixationsPerScan = 20;
            
        otherwise
            error('Unknown dataset:''%s''.', whichDataSet)
    end
    
    
    
    if (~ismember('compute outer segment responses', instructionSet))
        
        % Select an existing set of scans data (according to the following params)
        opticalElements = 'none';  % choose from 'none', 'noOTF', 'fNumber1.0', 'default'
        inertPigments = 'none'; % choose between 'none', 'noLens', 'noMacular', 'default'
        fixationMeanDuration = 100; 
        microFixationGain = 0; 
        
        mosaicSize = [16 20];
        reconstructedStimulusSpatialResolutionInMicrons = 6;
        
        osType = '@osIdentity';
        resultsDir = core.getResultsDir(opticalElements, inertPigments, scanSpatialOverlapFactor, fixationMeanDuration, microFixationGain, mosaicSize, reconstructedStimulusSpatialResolutionInMicrons, osType);
        
        % Set data preprocessing params - This affects the name of the decodingDataDir
        designMatrixBased = 0;    % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
        rawResponseBased = 0;     % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
        useIdenticalPreprocessingOperationsForTrainingAndTestData = true;
        preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased, useIdenticalPreprocessingOperationsForTrainingAndTestData);
        updateExpParams = true;
        decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);
        
        p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
        fprintf('<strong>Using data from:\nResultsDir: ''%s''\nDecodingDataDir: ''%s''\nSceneSetName: ''%s''.</strong>\n', resultsDir, strrep(decodingDataDir,sprintf('%s/',p.computedDataDir),''), sceneSetName );
    end  
    
    for k = 1:numel(instructionSet)
        switch instructionSet{k}
            case 'lookAtScenes' 
                core.lookAtScenes(sceneSetName);

            case 'compute outer segment responses'
                expParams = experimentParams(sceneSetName, opticalElements, inertPigments, scanSpatialOverlapFactor, fixationsPerScan, mosaicSize, reconstructedStimulusSpatialResolutionInMicrons);
                core.computeOuterSegmentResponses(expParams);
                
                % Set the sceneSetName, resultsDir, decodingDataDir according to the params set by experimentParams()
                sceneSetName = expParams.sceneSetName;
                resultsDir = expParams.resultsDir;
                preProcessingParams = expParams.preProcessingParams;   % Get the data preprocessing params
                decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);
                updateExpParams = false;
                
            case 'visualizeScan'
                sceneIndex = input('Select the scene index to visualize: ');
                visualizer.renderScan(sceneSetName, resultsDir, sceneIndex);

            case 'assembleTrainingDataSet'
                trainingDataPercentange = 50;
                testingDataPercentage = 50;
                core.assembleTrainingSet(sceneSetName, resultsDir, decodingDataDir, trainingDataPercentange, testingDataPercentage, preProcessingParams, updateExpParams);

            case 'computeDecodingFilter'
                SVDbasedLowRankFilterVariancesExplained = [50 60 70 80 85 90 92 94 95 96 97 98 99.5 99.9 99.999];
                decoder.computeDecodingFilter(sceneSetName, decodingDataDir, SVDbasedLowRankFilterVariancesExplained);
                
            case 'computeOutOfSamplePrediction'
                decoder.computeOutOfSamplePrediction(sceneSetName, decodingDataDir);

            case 'visualizeDecodingFilter'
                visualizer.renderDecoderFilterDynamicsFigures(sceneSetName, decodingDataDir);

            case 'visualizeInSamplePerformance'
                visualizePerformanceForVarianceExplained = []; %99.99;  % empty for all variance levels, 
                visualizer.renderPerformanceFigures(sceneSetName, decodingDataDir, visualizePerformanceForVarianceExplained, 'InSample');

            case 'visualizeOutOfSamplePerformance'
                visualizePerformanceForVarianceExplained = [];  %99.99;  % empty for all variance levels, 
                visualizer.renderPerformanceFigures(sceneSetName, decodingDataDir,  visualizePerformanceForVarianceExplained, 'OutOfSample');

            case 'makeReconstructionVideo'
                visualizer.renderReconstructionVideo(sceneSetName, resultsDir, decodingDataDir);

            case 'visualizeConeMosaic'
                visualizer.renderConeMosaic(sceneSetName, resultsDir, decodingDataDir);

            otherwise
                error('Unknown instruction: ''%s''.\n', instructionSet{k});
        end  % switch 
    end % for k
end


function expParams = experimentParams(sceneSetName, opticalElements, inertPigments, scanSpatialOverlapFactor, fixationsPerScan, mosaicSize, reconstructedStimulusSpatialResolutionInMicrons)

     
    sensorTimeStepInMilliseconds = 0.1;                             % must be small enough to avoid numerical instability in the outer segment current computation
    integrationTimeInMilliseconds = 50;
    
    % optical elements
    switch (opticalElements)
        
        case 'none'
            opticsParams = struct(...
                'offAxisIlluminationFallOff', false, ...                    % true/empty:  (default off-axis) or false = no fall-off (custom setting)
                'opticalTransferFunctionBased', false, ...                  % true/empty:  (default, shift-invariant OTF) or false (diffraction-limited)
                'customFNumber', 1.0 ...                                      % empty: (for default value) or some value (custom)          
            );
        
        case 'noOTF'
            opticsParams = struct(...
                'offAxisIlluminationFallOff', [], ...                       % true/empty:  (default off-axis) or false = no fall-off (custom setting)
                'opticalTransferFunctionBased', false, ...                  % true/empty:  (default, shift-invariant OTF) or false (diffraction-limited)
                'customFNumber', [] ...                                     % empty: (for default value) or some value (custom)          
            );
        
        case 'fNumber1.0'
            opticsParams = struct(...
                'offAxisIlluminationFallOff', [], ...                       % true/empty:  (default off-axis) or false = no fall-off (custom setting)
                'opticalTransferFunctionBased', [], ...                  % true/empty:  (default, shift-invariant OTF) or false (diffraction-limited)
                'customFNumber', 1.0 ...                                     % empty: (for default value) or some value (custom)          
            );
        
        case 'default'
            opticsParams = struct(...
                'offAxisIlluminationFallOff', [], ...                       % true/empty:  (default off-axis) or false = no fall-off (custom setting)
                'opticalTransferFunctionBased', [], ...                     % true/empty:  (default, shift-invariant OTF) or false (diffraction-limited)
                'customFNumber', [] ...                                     % empty: (for default value) or some value (custom)          
            );
        
        otherwise
            error('Unknown optical elements ''%s''!\n', opticalElements);
    end
    
    % inert pigments
    switch (inertPigments)
        case 'none'
            lensOpticalDensity = 0;
            macularOpticalDensity = 0;
            
        case 'noLens'
            lensOpticalDensity = 0;
            macularOpticalDensity = [];
           
        case 'noMacular'
            lensOpticalDensity = [];
            macularOpticalDensity = 0;
            
        case 'default'
            lensOpticalDensity = [];
            macularOpticalDensity = [];
            
        otherwise
            error('Unknown inert pigments ''%s''!\n', inertPigments);
    end
    
    % sensor params 
    sensorParams = struct(...
        'lensOpticalDensity', lensOpticalDensity, ...                                % empty (for default lens density) or a lens density number in [0..1] 0 = no absorption
        'macularOpticalDensity', macularOpticalDensity, ...                             % empty (for default macular density) or a macular density number in [0..1]  0 = no absorption
        'conePeakOpticalDensities', [0.5 0.5 0.5], ...              % empty (for default peak optical pigment densities) or a [3x1] vector in [0 .. 0.5]
        'coneApertureInMicrons', 3.0, ...        
        'LMSdensities', [0.6 0.3 0.1], ...        
        'spatialGrid', mosaicSize, ... % [18 26], [rows, cols]
        'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed',  1552784, ...                                                 % fixed value to ensure repeatable results
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...
            'meanFixationDurationInMilliseconds', 100, ...
            'stDevFixationDurationInMilliseconds', 0, ...
            'meanFixationDurationInMillisecondsForAdaptingField', 200, ...
            'stDevFixationDurationInMillisecondsForAdaptingField', 0, ...
            'microFixationGain', 0, ...
            'fixationOverlapFactor', scanSpatialOverlapFactor^2, ...     
            'saccadicScanMode',  'randomized'...                                    % 'randomized' or 'sequential', to visit eye position grid sequentially
        ) ...
    );
    
    outerSegmentParams = struct(...
        'type', '@osIdentity', ...                       % choose between '@osBiophys', '@osLinear', and @osIdentity
        'addNoise', true ...
    );
    
    meanLuminance = 300;
    if (strcmp(opticalElements, 'none'))
        meanLuminance = 5;
        fprintf(2,'Because opticalElements is set to none, and to achieve a comparable retinal illuminance, we set the mean luminance to %2.1f cd/m2\n', meanLuminance);
    end
    
    adaptingFieldParams = struct(...
        'type', 'SpecifiedReflectanceIlluminatedBySpecifiedIlluminant', ...
        'surfaceReflectance', struct(...
                                'type', 'MacBethPatchNo', ...
                                'patchNo', 16 ...
                            ), ...
        'illuminantName', 'D65', ...
        'meanLuminance', meanLuminance...
    );
    
    viewModeParams = struct(...
        'fixationsPerScan', fixationsPerScan, ...                                              % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 50, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', meanLuminance ...
    );



   designMatrixBased = 0;    % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
   rawResponseBased = 0;     % 0: nothing, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
   useIdenticalPreprocessingOperationsForTrainingAndTestData = true;
   preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased, useIdenticalPreprocessingOperationsForTrainingAndTestData);
        
   decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', reconstructedStimulusSpatialResolutionInMicrons, ...  % reconstructed scene resolution in retinal microns
        'extraMicronsAroundSensorBorder', -5*sensorParams.coneApertureInMicrons, ...             % decode this many additional (or less, if negative) microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                    % temporal resolution of reconstruction (used to be 10)
        'latencyInMillseconds', -150, ...                           % latency of the decoder filter (negative for non-causal time delays) (used to be -150)
        'memoryInMilliseconds', 400 ...                             % memory of the decoder filter (used to be 500)
    );
  

    % assemble resultsDir based on key params
    resultsDir = core.getResultsDir(...
        opticalElements, inertPigments, ...
        scanSpatialOverlapFactor,...
        sensorParams.eyeMovementScanningParams.meanFixationDurationInMilliseconds, ...
        sensorParams.eyeMovementScanningParams.microFixationGain, ...
        sensorParams.spatialGrid, ...
        decoderParams.spatialSamplingInRetinalMicrons, ...
        outerSegmentParams.type);
    
    % organize all  param structs into one superstruct
    expParams = struct(...
        'resultsDir',           resultsDir, ...                                % Where computed data will be saved
        'sceneSetName',         sceneSetName, ...                              % the name of the scene set to be used
        'viewModeParams',       viewModeParams, ...
        'opticsParams',         opticsParams, ...
        'sensorParams',         sensorParams, ...
        'outerSegmentParams',   outerSegmentParams, ...
        'preProcessingParams',  preProcessingParams, ...
        'decoderParams',        decoderParams ...
    );
end

function preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased, useIdenticalPreprocessingOperationsForTrainingAndTestData)
    preProcessingParams = struct(...
        'designMatrixBased', designMatrixBased, ...                                  % 0: nothing, 1:centering, 2:centering+norm, 3:centering+norm+whitening
        'rawResponseBased', rawResponseBased, ...                                    % 0: nothing, 1:centering, 2:centering+norm,
        'useIdenticalPreprocessingOperationsForTrainingAndTestData', useIdenticalPreprocessingOperationsForTrainingAndTestData, ...
        'thresholdVarianceExplainedForWhiteningMatrix', 100 ...
    );
    
    if ((preProcessingParams.designMatrixBased > 0) && (preProcessingParams.rawResponseBased > 0))
        error('Choose preprocessing of either the raw responses OR of the design matrix, NOT BOTH');
    end
end
