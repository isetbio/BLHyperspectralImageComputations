function RunExperiment

    % Computation steps. Uncomment the ones you want to execute
    computationInstructionSet = {...
       %'lookAtScenes' ...
       'compute outer segment responses' ...        % compute outer-segment responses. Data saved in the scansData directory
       'assembleTrainingDataSet' ...                % generates the training/testing design matrices. Data are saved in the decodingData directory
       'computeDecodingFilter' ...                  % computes the decoding filter based on the training data set (in-sample). Data stored in the decodingData directory
       'computeOutOfSamplePrediction' ...           % computes reconstructions based on the test data set (out-of-sample). Data stored in the decodingData directory
    };
    
    % Visualization options. Uncomment the ones you want 
    visualizationInstructionSet = {...
       % 'visualizeScan' ...                        % visualize the responses from one scan - under construction
       %'visualizeInSamplePerformance' ...          % visualize the decoder's in-sample deperformance
       %'visualizeOutOfSamplePerformance' ...       % visualize the decoder's out-of-sample deperformance
       'visualizeInAndOutOfSamplePerformance' ...   % visualize the decoder's in & out-of-sample deperformance
       'visualizeDecodingFilter' ...                % visualize the decoder filter's spatiotemporal dynamics
       % 'makeReconstructionVideo' ...              % generate video of the reconstruction
       % 'visualizeConeMosaic' ...                  % visualize the LMS cone mosaic used
    };

    program = computationInstructionSet;
    %program = visualizationInstructionSet;
    
    
    % Specify the optical elements employed
    opticalElements = 'default';                       % choose from 'none', 'noOTF', 'fNumber1.0', 'default'
    inertPigments = 'default';                         % choose between 'none', 'noLens', 'noMacular', 'default'
    
    % Specify mosaic size, mosaic LMS densities, and reconstructed stimulus spatial resolution
    mosaicSize = [22 26];                           % coneRows, coneCols
    mosaicLMSdensities = [0.0 1.0 0.0];             % densities of LMS cones
    reconstructedStimulusSpatialResolutionInMicrons = 3;
    
    % Specify eye movement kinetics
    meanFixationDuration = 150;
    stdFixationDuration = 20;
    microFixationGain = 1;                          % use 0 for static stimulation (i.e., stimuli flashed on for time = meanFixationDuration), 1 for normal eye movements
        
    % Specify preprocessing params
    designMatrixBasedPreProcessing = 2;             % 0: none, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening
    rawResponseBasedPreProcessing = 0;              % 0: none, 1:centering, 2:centering+std.dev normalization, 3:centering+norm+whitening

    % Specify outer-segment type
    %osType = '@osIdentity';
    osType = '@osLinear';
    %osType = '@osBiophys';
    
    % Specify the data set to use
    whichDataSet =  'harvard_machester_upenn';      % 'very_small', 'small', 'harvard', 'upenn', 'large', 'original', 'harvard_machester_upenn'
    
    core.executeProgram(program, whichDataSet, ...
        opticalElements, inertPigments, ...
        mosaicSize, mosaicLMSdensities, reconstructedStimulusSpatialResolutionInMicrons, ...
        meanFixationDuration, stdFixationDuration, microFixationGain, ...
        osType, ...
        designMatrixBasedPreProcessing, rawResponseBasedPreProcessing);
    
end