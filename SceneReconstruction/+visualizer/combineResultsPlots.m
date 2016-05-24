function combineResultsPlots

    % Specify the optical elements employed
    opticalElements = 'default';                       % choose from 'none', 'noOTF', 'fNumber1.0', 'default'
    inertPigments = 'default';                         % choose between 'none', 'noLens', 'noMacular', 'default'
    
    
    % Specify mosaic size, mosaic LMS densities, and reconstructed stimulus spatial resolution
    mosaicSize = [22 26];                           % coneRows, coneCols
    mosaicLMSdensities = [0.6 0.3 0.1];             % densities of LMS cones
    reconstructedStimulusSpatialResolutionInMicrons = 3;
    
    % Specify eye movement kinetics
    overlap = 0.8;
    meanFixationDuration = 150;
    microFixationGain = 1;                          % use 0 for static stimulation (i.e., stimuli flashed on for time = meanFixationDuration), 1 for normal eye movements
        
    % Specify outer-segment type
    osType = '@osLinear';
    
    resultsDir = core.getResultsDir(opticalElements, inertPigments, overlap, meanFixationDuration, microFixationGain, mosaicSize, mosaicLMSdensities, reconstructedStimulusSpatialResolutionInMicrons, osType);
    
    % Specify preprocessing params
    rawResponseBasedPreProcessing = 0; 
    
    designMatrixBasedPreProcessing = 1;
    preProcessingParams = core.preProcessingParamsStruct(designMatrixBasedPreProcessing, rawResponseBasedPreProcessing);
    decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);
    files{1} = fullfile(decodingDataDir, 'PerformanceSummary.png');

    designMatrixBasedPreProcessing = 2;
    preProcessingParams = core.preProcessingParamsStruct(designMatrixBasedPreProcessing, rawResponseBasedPreProcessing);
    decodingDataDir = core.getDecodingDataDir(resultsDir, preProcessingParams);
    files{2} = fullfile(decodingDataDir, 'PerformanceSummary.png');

    [X,map,alpha] = imread(files{1});
    size(X)
    size(map)
    size(alpha)
    
    X = imresize(X,1.0, 'cubic', 'Antialiasing', true);
    
    hFig = figure();
    set(hFig, 'Position', [1 1 size(X,1), size(X,2)])
    subplot('Position', [0.00 0.0 1.0 1.0]);
    image(X);
    truesize(hFig)
    drawnow;
end

