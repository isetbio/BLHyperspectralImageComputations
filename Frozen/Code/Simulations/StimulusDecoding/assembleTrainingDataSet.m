function assembleTrainingDataSet(trainingDataPercentange, decodingParams, rootPath, osType, adaptingFieldType, configuration)

    minargs = 6;
    maxargs = 6;
    narginchk(minargs, maxargs);
    
    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingParams.exportSubDirectory); 
    
    [trainingImageSet, ~, ~, ~, ~] = configureExperiment(configuration)
    
    displayTrainingMosaic = true;
    displayStimulusAndResponse = false; % true;
    displaySceneSampling = false;
    
    % Compute number of training and testing scans
    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    
    for imageIndex = 1:numel(trainingImageSet)
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = fullfile(scansDir, sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2}));
        load(scanFilename, 'scansNum', 'scanSensor');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
        fprintf('image %s/%s contains %d scans. Will use %d of these for training. \n', imsource{1}, imsource{2}, scansNum, trainingScans);
        totalTrainingScansNum = totalTrainingScansNum + trainingScans;
        totalTestingScansNum = totalTestingScansNum + (scansNum-trainingScans);
    end
    
    fprintf('Total training scans: %d\n', totalTrainingScansNum)
    fprintf('Total testing scans:  %d\n', totalTestingScansNum);
    
    % Compute L,M, and S-cone indices to keep (based on thesholdConeSeparation)
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = cherryPickConesToKeep(scanSensor, decodingParams.thresholdConeSeparation);
    
    if (displayTrainingMosaic)
        xy = sensorGet(scanSensor, 'xy');
        coneTypes = sensorGet(scanSensor, 'cone type');
        lConeIndices = find(coneTypes == 2);
        mConeIndices = find(coneTypes == 3);
        sConeIndices = find(coneTypes == 4);
        hFigSampling = figure(1);
        set(hFigSampling, 'Position', [10 10 1200 450]);
        clf;
        subplot(1,3,1);
        hold on
        plot(xy(lConeIndices, 1), xy(lConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.8 0.5 0.6]);
        plot(xy(mConeIndices, 1), xy(mConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.2 0.6 0.6]);
        plot(xy(sConeIndices, 1), xy(sConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.7 0.4 1.0]);

        plot(xy(keptLconeIndices, 1), xy(keptLconeIndices, 2), 'ro', 'MarkerFaceColor', [1 0.2 0.5], 'MarkerEdgeColor', [0.8 0.5 0.6], 'MarkerSize', 8);
        plot(xy(keptMconeIndices, 1), xy(keptMconeIndices, 2), 'go', 'MarkerFaceColor', [0.2 0.8 0.5], 'MarkerEdgeColor', [0.2 0.6 0.6], 'MarkerSize', 8);
        plot(xy(keptSconeIndices, 1), xy(keptSconeIndices, 2), 'bo', 'MarkerFaceColor', [0.5 0.2 1.0], 'MarkerEdgeColor', [0.7 0.4 1.0], 'MarkerSize', 8);
        axis 'equal'; axis 'square'; box on;
        drawnow;
    end
    

    decodingLatencyInBins = round(decodingParams.decodingLatencyInMilliseconds/decodingParams.temporalSubSamplingResolutionInMilliseconds);
    decodingMemoryInBins  = round(decodingParams.decodingMemoryInMilliseconds/decodingParams.temporalSubSamplingResolutionInMilliseconds); 
    
    % partition the data into training and testing components
    trainingScanIndex = 0;
    testingScanIndex = 0;
   
    totalImages = numel(trainingImageSet);
    for imageIndex = 1:totalImages
  
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = fullfile(scansDir, sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2}));
        load(scanFilename, 'scansNum');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
      
        % load training data
        for scanIndex = 1:trainingScans
            
            % filename for this scan
            scanFilename = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex));
            fprintf('Loading training data from %s\n', scanFilename);
            
            % Load scan data
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, ...
                scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, ...
                scanPhotoCurrents] = ...
                loadScanData(scanFilename, decodingParams.temporalSubSamplingResolutionInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices);
            
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialGrid, e.g, [2 2]
            [scanLcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanLcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            [scanMcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanMcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            [scanScontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanScontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            
            % pre-allocate memory
            if (trainingScanIndex == 0)
                trainingTimeAxis            = (0:(timeBins*totalTrainingScansNum-1))*(timeAxis(2)-timeAxis(1));
                trainingLcontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTrainingScansNum, 'single');
                trainingMcontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTrainingScansNum, 'single');
                trainingScontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTrainingScansNum, 'single');
                trainingPhotocurrents       = zeros(conesNum, timeBins*totalTrainingScansNum, 'single');
                
                designMatrix.n = numel(keptLconeIndices) + numel(keptMconeIndices) + numel(keptSconeIndices);
                designMatrix.lat = decodingLatencyInBins;
                designMatrix.m = decodingMemoryInBins;
                designMatrix.T = size(trainingPhotocurrents,2) - (designMatrix.lat + designMatrix.m);
                designMatrix.binWidth = decodingParams.temporalSubSamplingResolutionInMilliseconds;
                fprintf('Decoding filter will have %d coefficients\n', 1+(designMatrix.n*designMatrix.m));
                fprintf('Design matrix will have: %d rows and %d cols\n' , designMatrix.T, 1+(designMatrix.n*designMatrix.m));
            end
            
            % determine insertion time point
            currentTimeBin = trainingScanIndex*timeBins+1;
            timeBinRange = (0:timeBins-1);
            theTimeBins = currentTimeBin + timeBinRange;
            
            fprintf('last bin for scan %d, image: %d, : %d (allocated: %d)\n', scanIndex, imageIndex, theTimeBins(end), numel(trainingTimeAxis))
            
            % insert
            trainingLcontrastSequence(:, theTimeBins) = scanLcontrastSequence;
            trainingMcontrastSequence(:, theTimeBins) = scanMcontrastSequence;
            trainingScontrastSequence(:, theTimeBins) = scanScontrastSequence;
            trainingPhotocurrents(:, theTimeBins) = scanPhotoCurrents;
            
            % update training scan index
            trainingScanIndex = trainingScanIndex + 1;
      
            
            if (displayStimulusAndResponse)   
                binIndicesToPlot = 1:theTimeBins(end);
                timeLims = [trainingTimeAxis(1) trainingTimeAxis(binIndicesToPlot(end))];
                
                maxContrast = max([max(trainingLcontrastSequence(:)) max(trainingMcontrastSequence(:)) max(trainingScontrastSequence(:))]);
                maxPhotoCurrent = max(max(abs(trainingPhotocurrents(:, binIndicesToPlot))));
            
                hFig = figure(2);
                set(hFig, 'Color', [0 0 0], 'Name', sprintf('Scans: 1 - %d of %d', scanIndex, trainingScans), 'Position', [10 60 2880/2 1000]);
                clf;
                subplot('Position', [0.02 0.70 0.97 0.25]);
                hold on;
                plot(trainingTimeAxis(binIndicesToPlot), trainingLcontrastSequence(:,binIndicesToPlot), 'r.-');
                plot(trainingTimeAxis(binIndicesToPlot), trainingMcontrastSequence(:,binIndicesToPlot), 'g.-');
                plot(trainingTimeAxis(binIndicesToPlot), trainingScontrastSequence(:,binIndicesToPlot), 'b.-');
                ylabel('Weber cone contrast');
                set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims, 'YLim', maxContrast*[-1 1]);
                hold off;
                box on

                subplot('Position', [0.02 0.40 0.97 0.25]);
                hold on;
                lconeIndex = 1; 
                mconeIndex = numel(keptLconeIndices) + 1;
                sconeIndex = numel(keptLconeIndices) + numel(keptMconeIndices) + 1;
                plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(lconeIndex,binIndicesToPlot), 'r.-');
                plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(mconeIndex,binIndicesToPlot), 'g.-');
                plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(sconeIndex,binIndicesToPlot), 'b.-');
                hold off;
            
                set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims, 'YLim', [-1 1]*maxPhotoCurrent);
                xlabel('time (sec)');
                ylabel('current [pAmps]');
            
                subplot('Position', [0.02 0.07 0.97 0.25]);
                imagesc(trainingTimeAxis(binIndicesToPlot), 1:conesNum, trainingPhotocurrents(:,binIndicesToPlot));
                set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims);
                set(gca, 'CLim', max(max(abs(trainingPhotocurrents(:,binIndicesToPlot))))*[-1 1]);
                xlabel('time (sec)');
                ylabel('cone id');
                colormap(bone(512));
                drawnow
            end % displayStimulusAndResponse
        end % scanIndex
        
        fprintf('Added training data from image %d (%d scans)\n', imageIndex, trainingScanIndex);

        

        % Now load testing data
        for scanIndex = trainingScans+1:scansNum
            
            % filename for this scan
            scanFilename = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex));
            fprintf('Loading testing data from %s\n', scanFilename);
            
            % Load scan data
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, ...
                scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, ...
                scanPhotoCurrents] = ...
                loadScanData(scanFilename, decodingParams.temporalSubSamplingResolutionInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices);
            
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialGrid, e.g, [2 2]
            [scanLcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanLcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            [scanMcontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanMcontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            [scanScontrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(scanScontrastSequence, decodingParams.subSampledSpatialGrid, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, displaySceneSampling, hFigSampling);
            
            % pre-allocate memory
            if (testingScanIndex == 0)
                testingTimeAxis            = (0:(timeBins*totalTestingScansNum-1))*(timeAxis(2)-timeAxis(1));
                testingLcontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTestingScansNum, 'single');
                testingMcontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTestingScansNum, 'single');
                testingScontrastSequence   = zeros(prod(decodingParams.subSampledSpatialGrid), timeBins*totalTestingScansNum, 'single');
                testingPhotocurrents       = zeros(conesNum,  timeBins*totalTestingScansNum, 'single');
                
                designMatrixTest = designMatrix;
                designMatrixTest.T = size(testingPhotocurrents,2) - (designMatrix.lat + designMatrix.m);
            end
            
            % determine insertion time point
            currentTimeBin = testingScanIndex*timeBins+1;
            timeBinRange = (0:timeBins-1);
            theTimeBins = currentTimeBin + timeBinRange;
            
            % insert
            testingLcontrastSequence(:, theTimeBins) = scanLcontrastSequence;
            testingMcontrastSequence(:, theTimeBins) = scanMcontrastSequence;
            testingScontrastSequence(:, theTimeBins) = scanScontrastSequence;
            testingPhotocurrents(:, theTimeBins) = scanPhotoCurrents;
            
            % update testing scan index
            testingScanIndex = testingScanIndex + 1;
        end % scanIndex
        fprintf('Added testing data from image %d (%d scans)\n', imageIndex, testingScanIndex);
        
    end % imageIndex
    
    fprintf('Sizes of training data sets \n');
    size(trainingTimeAxis)
    size(trainingLcontrastSequence)
    size(trainingMcontrastSequence)
    size(trainingScontrastSequence)
    size(trainingPhotocurrents)
    
    fprintf('Sizes of testing data sets \n');
    size(testingTimeAxis)
    size(testingLcontrastSequence)
    size(testingMcontrastSequence)
    size(testingScontrastSequence)
    size(testingPhotocurrents)
    
    
    fprintf('Saving decoding data ...');
    decodingDataFileName = fullfile(decodingDirectory, 'DecodingData.mat');
    save(decodingDataFileName, 'scanSensor',   ...
        'decodingParams', ...
        'keptLconeIndices', 'keptMconeIndices', 'keptSconeIndices', ...
        'resampledSpatialXdataInRetinalMicrons', 'resampledSpatialYdataInRetinalMicrons', ...
        'trainingDataPercentange', ...
        'designMatrix', 'trainingTimeAxis', 'trainingPhotocurrents', 'trainingLcontrastSequence', 'trainingMcontrastSequence', 'trainingScontrastSequence', ...
        'designMatrixTest','testingTimeAxis',  'testingPhotocurrents', 'testingLcontrastSequence',  'testingMcontrastSequence',  'testingScontrastSequence', ...
        '-v7.3');
    fprintf('Decoding data saved to %s', decodingDataFileName);
end

