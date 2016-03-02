function runExperiment

    experimentConfiguration = 'manchester'
    trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    if (trainingDataPercentange < 1) || (trainingDataPercentange > 100)
        error('% must be in [0 .. 100]\n');
    end
    
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    scansDir = sprintf('ScansData.%sConfig', experimentConfiguration);
    if (exist(scansDir) == 7)
        removeAll = input(sprintf('%s folder exists already. Remove everything it it? [y == YES] : ', scansDir), 's');
        if (strcmp(removeAll, 'y'))
            fprintf('Will remove everything in %s. Hit enter to do so.\n', scansDir);
            pause
            delete(sprintf('%s/*', scansDir));
        end
    else
        fprintf('%s folder does not exist. Will create it\n', scansDir);
        mkdir(scansDir);
    end
    
    % 1. compute figuration@osBiophys responses for the ensemble of scenes 
    % defined in experimentConfiguration
    computeOuterSegmentResponsesToStimulusSet(experimentConfiguration);
    
    % 2. Divide responses/stimuli is training and test sets 
    % Here we also define the spatial resolution with which to represent
    % the input stimulus, the subset of cones to use, and the temporal 
    % resolution with which to sample responses and stimuli
    assembleTrainingDataSet(trainingDataPercentange, experimentConfiguration);

    % 3. Compute decoding filter
    computeDecodingFilter(experimentConfiguration);
    
    % 4.
    computeOutOfSamplePredictions(experimentConfiguration)
end

