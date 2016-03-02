function runExperiment

    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    experimentConfiguration = 'manchester';
    osType = 'biophysics-based';  % 'biophysics-based' or 'linear'
    adaptingFieldType = 'MacBethGrayD65MatchSceneLuminance';   % 'MacBethGrayD65MatchSceneLuminance' or 'MatchSpatiallyAveragedPhotonSPD'
   
    % runMode possible value: 'compute outer segment responses', 'assembleTrainingDataSet', 'computeDecodingFilter', 'computeOutOfSamplePredictions';
    
    runMode = {'compute outer segment responses'};
%     runMode = {'assembleTrainingDataSet'}
%     runMode = {'computeDecodingFilter'};
%     runMode = {'computeOutOfSamplePredictions'};
    
    if (ismember('compute outer segment responses', runMode))
        % 1. compute figuration@osBiophys responses for the ensemble of scenes  defined in experimentConfiguration
        computeOuterSegmentResponsesToStimulusSet(rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 2. Divide responses/stimuli is training and test sets 
        % Here we also define the spatial resolution with which to represent
        % the input stimulus, the subset of cones to use, and the temporal 
        % resolution with which to sample responses and stimuli
        trainingDataPercentange = 50; % GetTrainingDataPercentage();
        assembleTrainingDataSet(trainingDataPercentange, rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, osType, adaptingFieldType, experimentConfiguration);
        
        % 4. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('assembleTrainingDataSet', runMode))
        % 2. Divide responses/stimuli is training and test sets 
        % Here we also define the spatial resolution with which to represent
        % the input stimulus, the subset of cones to use, and the temporal 
        % resolution with which to sample responses and stimuli
        trainingDataPercentange = 50; % GetTrainingDataPercentage();
        assembleTrainingDataSet(trainingDataPercentange, rootPath, osType, adaptingFieldType, experimentConfiguration);
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, osType, adaptingFieldType, experimentConfiguration);
        % 4. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, osType, adaptingFieldType, experimentConfiguration);
        
    elseif (ismember('computeDecodingFilter', runMode))
        % 3. Compute decoding filter
        computeDecodingFilter(rootPath, osType, adaptingFieldType, experimentConfiguration);
        % 4. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, osType, adaptingFieldType, experimentConfiguration);
    else
        % 4. Compute out-of-sample predictions
        computeOutOfSamplePredictions(rootPath, osType, adaptingFieldType, experimentConfiguration);
    end
end

function  trainingDataPercentange = GetTrainingDataPercentage()
    trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    while (trainingDataPercentange < 1) || (trainingDataPercentange > 100)
        trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    end
end
