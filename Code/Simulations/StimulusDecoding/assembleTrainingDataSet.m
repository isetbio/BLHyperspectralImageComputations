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

function [contrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(originalContrastSequence, subSampledSpatialGrid, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, displaySceneSampling, figHandle)
    
    if (numel(subSampledSpatialGrid) ~= 2)
        subSampledSpatialGrid
        error('Expecting a 2 element vector');
    end
    
    if ((subSampledSpatialGrid(1) == 1) && (subSampledSpatialGrid(2) == 1))
        xRange = numel(spatialXdataInRetinalMicrons) * (spatialXdataInRetinalMicrons(2)-spatialXdataInRetinalMicrons(1));
        yRange = numel(spatialYdataInRetinalMicrons) * (spatialYdataInRetinalMicrons(2)-spatialYdataInRetinalMicrons(1));
        fprintf('Original spatial data %d x %d, covering an area of %2.2f x %2.2f microns.\n', numel(spatialXdataInRetinalMicrons), numel(spatialYdataInRetinalMicrons), xRange, yRange);
        fprintf('Will downsample to [1 x 1].\n');
        contrastSequence = mean(originalContrastSequence,1);
        resampledSpatialXdataInRetinalMicrons = 0;
        resampledSpatialYdataInRetinalMicrons = 0;
    else

        resampledSpatialXdataInRetinalMicrons = linspace(spatialXdataInRetinalMicrons(1), spatialXdataInRetinalMicrons(end), subSampledSpatialGrid(1));
        resampledSpatialYdataInRetinalMicrons = linspace(spatialYdataInRetinalMicrons(1), spatialYdataInRetinalMicrons(end), subSampledSpatialGrid(2));
        contrastSequence = zeros(numel(resampledSpatialXdataInRetinalMicrons)*numel(resampledSpatialYdataInRetinalMicrons), size(originalContrastSequence,2));

        [Xo,Yo] = meshgrid(spatialXdataInRetinalMicrons,spatialYdataInRetinalMicrons);
        [Xr,Yr] = meshgrid(resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons);
        method = 'linear';
        
        
        for tBin = 1:size(originalContrastSequence,2)
           originalFrame = reshape(squeeze(originalContrastSequence(:,tBin)), [numel(spatialYdataInRetinalMicrons) numel(spatialXdataInRetinalMicrons)]);
           resampledFrame = interp2(Xo,Yo,originalFrame,Xr,Yr,method);
           contrastSequence(:,tBin) = resampledFrame(:);
           
           if (displaySceneSampling)
               figure(figHandle);
               colormap(gray(512));
               cLim = [0 max([max(abs(originalFrame(:))) max(abs(resampledFrame(:)))])];
               if (tBin == 1)
                   gca1 = subplot(1,3,2);
                   p1 = imagesc(spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, originalFrame, cLim);
                   axis 'image'
                   gca2 = subplot(1,3,3);
                   p2 = imagesc(resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons, resampledFrame, cLim);
                   axis 'image'
               else
                   set(p1, 'CData', originalFrame);  set(gca1, 'CLim', cLim);
                   set(p2, 'CData', resampledFrame); set(gca2, 'CLim', cLim);
               end
               drawnow
           end
       end % tBin
       
    end
end


function [timeAxis, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, ...
          LcontrastSequence, McontrastSequence, ScontrastSequence, photoCurrents] = ...
    loadScanData(scanFilename, temporalSubSamplingInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices)

    % load stimulus LMS excitations and photocurrents 
    scanPlusAdaptationFieldLMSexcitationSequence = [];
    photoCurrents = [];
    
    load(scanFilename, ...
        'scanSensor', ...
        'photoCurrents', ...
        'scanPlusAdaptationFieldLMSexcitationSequence', ...
        'LMSexcitationXdataInRetinalMicrons', ...
        'LMSexcitationYdataInRetinalMicrons', ...
        'sensorAdaptationFieldParams');
    

    timeStep = sensorGet(scanSensor, 'time interval');
    timeBins = round(sensorGet(scanSensor, 'total time')/timeStep);
    timeAxis = (0:(timeBins-1))*timeStep;
    spatialBins = numel(LMSexcitationXdataInRetinalMicrons) * numel(LMSexcitationYdataInRetinalMicrons);
    
    % Compute baseline estimation bins (determined by the last points in the photocurrent time series)
    referenceBin = round(0.50*sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds/1000/timeStep);
    baselineEstimationBins = size(photoCurrents,3)-referenceBin+(-round(referenceBin/2):round(referenceBin/2));
    fprintf('Offsetting photocurrents by their baseline levels (estimated in [%2.2f - %2.2f] seconds.\n', baselineEstimationBins(1)*timeStep, baselineEstimationBins(end)*timeStep);
    
    % substract baseline from photocurrents
    photoCurrents = single(bsxfun(@minus, photoCurrents, mean(photoCurrents(:,:, baselineEstimationBins),3)));
    conesNum = size(photoCurrents,1) * size(photoCurrents,2);
    
    % reshape photoCurrent matrix to [ConesNum x timeBins]
    photoCurrents = reshape(photoCurrents(:), [conesNum timeBins]);
    
    % transform the scene's LMS Stockman excitations to LMS Weber contrasts
    adaptationFieldLMSexcitations = mean(scanPlusAdaptationFieldLMSexcitationSequence(baselineEstimationBins,:,:,:),1);
    scanPlusAdaptationFieldLMSexcitationSequence = bsxfun(@minus, scanPlusAdaptationFieldLMSexcitationSequence, adaptationFieldLMSexcitations);
    scanPlusAdaptationFieldLMSexcitationSequence = single(bsxfun(@rdivide, scanPlusAdaptationFieldLMSexcitationSequence, adaptationFieldLMSexcitations));
    
    % permute to make it [coneID X Y timeBins]
    LMScontrastSequences = permute(scanPlusAdaptationFieldLMSexcitationSequence, [4 2 3 1]);
    LcontrastSequence = squeeze(LMScontrastSequences(1, :, :, :));
    LcontrastSequence = reshape(LcontrastSequence(:), [spatialBins timeBins]);
    McontrastSequence = squeeze(LMScontrastSequences(2, :, :, :));
    McontrastSequence = reshape(McontrastSequence(:), [spatialBins timeBins]);
    ScontrastSequence = squeeze(LMScontrastSequences(3, :, :, :));
    ScontrastSequence = reshape(ScontrastSequence(:), [spatialBins timeBins]);
    
    % Only use photocurrents from the selected cone indices
    coneIndicesToKeep = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    photoCurrents = photoCurrents(coneIndicesToKeep, :);
    
    if (temporalSubSamplingInMilliseconds > 1)
        % According to Peter Kovasi:
        % http://www.peterkovesi.com/papers/FastGaussianSmoothing.pdf (equation 1)
        % Given a box average filter of width w x w, the equivalent 
        % standard deviation to apply to achieve roughly the same effect 
        % when using a Gaussian blur can be found by.
        % sigma = sqrt((w^2-1)/12)
        decimationFactor = round(temporalSubSamplingInMilliseconds/1000/timeStep);
        tauInSamples = sqrt((decimationFactor^2-1)/12);
        filterTime = -round(3*tauInSamples):1:round(3*tauInSamples);
        kernel = exp(-0.5*(filterTime/tauInSamples).^2);
        kernel = kernel / sum(kernel);
        
        for spatialSampleIndex = 1:spatialBins
            if (spatialSampleIndex == 1)
                % preallocate arrays
                tmp = single(downsample(conv(double(squeeze(LcontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
                LcontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                McontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                ScontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                photoCurrents2     = zeros(size(photoCurrents,1), numel(tmp), 'single');
            end
            % Subsample LMS contrast sequences by a factor decimationFactor using a lowpass Chebyshev Type I IIR filter of order 8.
            LcontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(LcontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
            McontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(McontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
            ScontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(ScontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
        end
 
        for coneIndex = 1:size(photoCurrents,1)
            % Subsample photocurrents by a factor decimationFactor using a HammingWindow.
            photoCurrents2(coneIndex,:) = single(downsample(conv(double(squeeze(photoCurrents(coneIndex,:))), kernel, 'same'), decimationFactor));
        end

        % Also decimate time axis
        timeAxis = timeAxis(1:decimationFactor:end);
    end
    
    
    % Cut the initial 250 and trailing 50 mseconds of data
    initialPeriodInMilliseconds = 250;
    trailingPeriodInMilliseconds = 50;
    timeBinsToCutFromStart = round((initialPeriodInMilliseconds/decimationFactor)/1000/timeStep);
    timeBinsToCutFromEnd = round((trailingPeriodInMilliseconds/decimationFactor)/1000/timeStep);
    timeBinsToKeep = (timeBinsToCutFromStart+1):(numel(timeAxis)-timeBinsToCutFromEnd);
    
    LcontrastSequence = LcontrastSequence2(:, timeBinsToKeep);
    McontrastSequence = McontrastSequence2(:, timeBinsToKeep);
    ScontrastSequence = ScontrastSequence2(:, timeBinsToKeep);
    
    % Only return photocurrents for the cones we are keeping
    photoCurrents = photoCurrents2(:, timeBinsToKeep);
    
    timeAxis = timeAxis(timeBinsToKeep);
    % reset time axis to start at t = 0;
    timeAxis = timeAxis - timeAxis(1);
    
    spatialXdataInRetinalMicrons = LMSexcitationXdataInRetinalMicrons;
    spatialYdataInRetinalMicrons = LMSexcitationYdataInRetinalMicrons;
end