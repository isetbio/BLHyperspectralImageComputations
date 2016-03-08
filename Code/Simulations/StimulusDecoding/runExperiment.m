function runExperiment

    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    experimentConfiguration = 'manchester';
    osType = 'biophysics-based';  % 'biophysics-based' or 'linear'
   % adaptingFieldType = 'MatchSpatiallyAveragedPhotonSPD';   % match photon SPD (mean luminance and chromaticity)
    adaptingFieldType = 'MacBethGrayD65MatchSceneLuminance'; % match luminance only (achromatic background) 
   % adaptingFieldType = 'NoAdaptationField';
    
    % Parameters of decoding: stimulus (scene window) spatial subsampling
    decodingParams.subSampledSpatialGrid = 1*[1 1];  % Here we parcelate the scene within the moaic's FOV using a 1x1 grid (mean contrast over mosaic's window)
    decodingParams.subSampledSpatialGrid = 20*[1 1];  % Here we parcelate the scene within the moaic's FOV using an 20x20 grid
    
    % Parameters of decoding: cone response subsampling
    coneSep = 0.0; % 1.5; % 0.0;  % 1.5 results in 107 cones
    decodingParams.thresholdConeSeparation = sqrt(coneSep^2 + coneSep^2);  % Here we only include responses from cones with are at least 3 cone apertures apart along both x- and y-dimensions
    
    % Parameters of decoding: temporal response subsampling
    decodingParams.temporalSubSamplingResolutionInMilliseconds = 10;
    
    % Parameters of decoding: decoding filter latency and memory
    % (neg. latency to negative to get the before stimulus onset)
    decodingParams.decodingLatencyInMilliseconds = -200;
    decodingParams.decodingMemoryInMilliseconds = 600;
    decodingParams.exportSubDirectory = sprintf('ConeSeparation_%2.2f__SpatiaGrid_%dx%d', coneSep, decodingParams.subSampledSpatialGrid(1), decodingParams.subSampledSpatialGrid(2));
    
    % runMode possible value: 'compute outer segment responses', 'assembleTrainingDataSet', 'computeDecodingFilter', ''visualizeDecodingFilter', 'visualizeInSamplePerformance', 'computeOutOfSamplePredictions';
    runMode = {'compute outer segment responses'};
   % runMode = {'assembleTrainingDataSet'}
   % runMode = {'computeDecodingFilter'}
   runMode = {'visualizeDecodingFilter'}
  %  runMode = {'visualizeInSamplePerformance'}
   % runMode = {'visualizeDecodingFilter'}
    
     %runMode = {'computeOutOfSamplePredictions'}
    
    if (ismember('compute outer segment responses', runMode))
        % 1. compute figuration@osBiophys responses for the ensemble of scenes  defined in experimentConfiguration
        computeOuterSegmentResponsesToStimulusSet(rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 2. Divide responses/stimuli is training and test sets 
        % Here we also define the spatial resolution with which to represent
        % the input stimulus, the subset of cones to use, and the temporal 
        % resolution with which to sample responses and stimuli
        trainingDataPercentange = 50; % GetTrainingDataPercentage();
        assembleTrainingDataSet(trainingDataPercentange, decodingParams, rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4a. Visualize decoding filter and in-sample performance
        visualizeDecodingFilters(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 5. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('assembleTrainingDataSet', runMode))
        % 2. Divide responses/stimuli is training and test sets 
        % Here we also define the spatial resolution with which to represent
        % the input stimulus, the subset of cones to use, and the temporal 
        % resolution with which to sample responses and stimuli
        trainingDataPercentange = 50; % GetTrainingDataPercentage();
        assembleTrainingDataSet(trainingDataPercentange,  decodingParams, rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4a. Visualize decoding filter and in-sample performance
        visualizeDecodingFilters(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 5. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('computeDecodingFilter', runMode))
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4a. Visualize decoding filter and in-sample performance
        visualizeDecodingFilters(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 5. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
    
    elseif (ismember('visualizeDecodingFilter', runMode))
        % 4a. Visualize decoding filter and in-sample performance
        visualizeDecodingFilters(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('visualizeInSamplePerformance', runMode))
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('computeOutOfSamplePredictions', runMode))
        % 4b. Visualize in-sample performance
        visualizeInSamplePerformance(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
       
        % 5. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, decodingParams.exportSubDirectory, osType, adaptingFieldType, experimentConfiguration);
    end
end

function  trainingDataPercentange = GetTrainingDataPercentage()
    trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    while (trainingDataPercentange < 1) || (trainingDataPercentange > 100)
        trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    end
end
