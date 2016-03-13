function decodeAdaptiveOpticsResponses(rootPath, decodingParams, osType, adaptingFieldType, decodingConfiguration)

    decodingScansDir = getScansDir(rootPath, decodingConfiguration, adaptingFieldType, osType);
    decodingDirectory = getDecodingSubDirectory(decodingScansDir, decodingParams.exportSubDirectory);
    
    % Load the decoding filter     
    fprintf('Load decoding filter ...');
    decodingFiltersFileName = fullfile(decodingParams.exportSubDirectory, sprintf('DecodingFilters.mat'));
    load(decodingFiltersFileName, 'wVector', 'filterSpatialXdataInRetinalMicrons', 'filterSpatialYdataInRetinalMicrons'); 
    
    % load some of the decoding data (not sure if needed)
    fprintf('Load decoding data ...');
    decodingDataFileName = fullfile(decodingDirectory, 'DecodingData.mat');
    load(decodingDataFileName,   ...
        'decodingParams', ...
        'keptLconeIndices', 'keptMconeIndices', 'keptSconeIndices', ...
        'resampledSpatialXdataInRetinalMicrons', 'resampledSpatialYdataInRetinalMicrons');
    
    % Load responses
    adaptiveOpticsConfiguration = 'adaptiveOpticsStimulation';
    adaptiveOpticsImSource = {'ao_database', 'condition1'};
    scansDir = getScansDir(rootPath, adaptiveOpticsConfiguration, adaptingFieldType, osType);
    
    
    scanIndex = 1;
    scanFilename = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', adaptiveOpticsImSource{1}, adaptiveOpticsImSource{2}, scanIndex));
    % Load scan data
    [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, ...
                scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, ...
                scanPhotoCurrents] = ...
                loadScanData(scanFilename, decodingParams.temporalSubSamplingResolutionInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices);     
    load(scanFilename, 'scanSensor');


    % Spatially subsample LMS contrast sequences according to subSampledSpatialGrid, e.g, [2 2]
    displaySceneSampling = false;
    hFigSampling = figure(1);
    
    [scanLcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanLcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
    [scanMcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanMcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
    [scanScontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanScontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);

    
    
    

   
    % Compute L,M, and S-cone indices to keep (based on thesholdConeSeparation)
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = cherryPickConesToKeep(scanSensor, decodingParams.thresholdConeSeparation);
    
    decodingLatencyInBins = round(decodingParams.decodingLatencyInMilliseconds/decodingParams.temporalSubSamplingResolutionInMilliseconds);
    decodingMemoryInBins  = round(decodingParams.decodingMemoryInMilliseconds/decodingParams.temporalSubSamplingResolutionInMilliseconds); 
    
    
    designMatrix.n = numel(keptLconeIndices) + numel(keptMconeIndices) + numel(keptSconeIndices);
    designMatrix.lat = decodingLatencyInBins;
    designMatrix.m = decodingMemoryInBins;
    designMatrix.T = size(scanPhotoCurrents,2) - (designMatrix.lat + designMatrix.m);
    designMatrix.binWidth = decodingParams.temporalSubSamplingResolutionInMilliseconds;
    fprintf('Decoding filter will have %d coefficients\n', 1+(designMatrix.n*designMatrix.m));
    fprintf('Design matrix will have: %d rows and %d cols\n' , designMatrix.T, 1+(designMatrix.n*designMatrix.m));

    
    fprintf('\nPlease wait. Computing adaptive optics predictions ....'); 
            
    % Compute design matrix and stimulus vector
    testingStimulusTrain = [
        scanLcontrastSequence', ...
        scanMcontrastSequence', ...
        scanScontrastSequence' ...
        ];

    
    [Xtest, cTest] = assembleDesignMatrixAndStimulusVector(designMatrix.T, designMatrix.lat, designMatrix.m, designMatrix.n, scanPhotoCurrents, testingStimulusTrain);

    % Compute input stimulus prediction
    stimulusDimensions = size(cTest,2);
    cTestPrediction = cTest*0;
    for stimDim = 1:stimulusDimensions
        cTestPrediction(:, stimDim) = Xtest * wVector(:,stimDim);
    end
    
    
    adaptiveOpticsDecodingDirectory = getDecodingSubDirectory(scansDir, decodingParams.exportSubDirectory);
    outOfSamplePredictionDataFileName = fullfile(adaptiveOpticsDecodingDirectory, sprintf('OutOfSamplePredicition.mat'));
    save(outOfSamplePredictionDataFileName, 'cTestPrediction', 'scanSensor', 'filterSpatialXdataInRetinalMicrons', 'filterSpatialYdataInRetinalMicrons' ...
        );
    fprintf('Adaptive optics prediction saved to %s\n', outOfSamplePredictionDataFileName);
    fprintf('Done \n');
    
end

