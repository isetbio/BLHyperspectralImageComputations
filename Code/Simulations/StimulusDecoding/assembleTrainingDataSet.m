function assembleTrainingDataSet

    % cd to here
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    [trainingImageSet, ~, ~, ~, ~] = configureExperiment('manchester');
    
    trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    if (trainingDataPercentange < 1) || (trainingDataPercentange > 100)
        error('% must be in [0 .. 100]\n');
    end
    
    % Compute number of training and testing scans
    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    for imageIndex = 1:numel(trainingImageSet)
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2});
        load(scanFilename, 'scansNum');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
        fprintf('image %s/%s contains %d scans. Will use %d of these for training. \n', imsource{1}, imsource{2}, scansNum, trainingScans);
        
        totalTrainingScansNum = totalTrainingScansNum + trainingScans;
        totalTestingScansNum = totalTestingScansNum + (scansNum-trainingScans);
    end
    
    fprintf('Total training scans: %d\n', totalTrainingScansNum)
    fprintf('Total testing scans:  %d\n', totalTestingScansNum);
    
    
    % Parameters of decoding
    % The contrast sequences [space x time] to be decoded, have an original spatial resolution whose retinal dimension would be 1 micron
    % Here we subsample this. To first approximation, we take the mean over
    % all space, so we have only 1 spatial bin
    subSampledSpatialBins = [1 1];
            
    
    
    % paertition the data into training and testing components
    trainingScanIndex = 0;
    testingScanIndex = 0;
    
    totalImages = numel(trainingImageSet);
    for imageIndex = 2 % 1:totalImages
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2});
        load(scanFilename, 'scansNum');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
      
        % load training data
        for scanIndex = 1:trainingScans
            
            % Load scan data
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, scanPhotoCurrents] = loadScanData(scanFilename);
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialBins, e.g, [2 2]
            scanLcontrastSequence = subSampleSpatially(scanLcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanMcontrastSequence = subSampleSpatially(scanMcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanScontrastSequence = subSampleSpatially(scanScontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            
            % pre-allocate memory
            if (trainingScanIndex == 0)
                trainingTimeAxis            = (0:(timeBins*totalTrainingScansNum*totalImages-1))*(timeAxis(2)-timeAxis(1));
                trainingLcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingMcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingScontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingPhotocurrents       = zeros(conesNum,    timeBins*totalTrainingScansNum*totalImages, 'single');
            end
            
            % determine insertion time point
            currentTimeBin = trainingScanIndex*timeBins+1;
            timeBinRange = (0:timeBins-1);
            theTimeBins = currentTimeBin + timeBinRange;
            
            % insert
            
            trainingLcontrastSequence(:, theTimeBins) = scanLcontrastSequence;
            trainingMcontrastSequence(:, theTimeBins) = scanMcontrastSequence;
            trainingScontrastSequence(:, theTimeBins) = scanScontrastSequence;
            trainingPhotocurrents(:, theTimeBins) = scanPhotoCurrents;
            
            % update training scan index
            trainingScanIndex = trainingScanIndex + 1;
            
            
            % max cone contrast
            maxContrast = max([max(abs(trainingLcontrastSequence(:))) max(abs(trainingMcontrastSequence(:)))  max(abs(trainingScontrastSequence(:))) ]);
            
            h = figure(1);
            set(h, 'Color', [1 1 1], 'Name', sprintf('Scans: %d - %d', scanIndex, trainingScans));
            
            subplot(1,3,1);
            hold on;
            plot([-1 1], [0 0], 'r-');
            plot([0 0], [-1 1], 'r-');
            plot(trainingLcontrastSequence(:,1:theTimeBins(end)), trainingMcontrastSequence(:,1:theTimeBins(end)), 'k.');
            hold off;
            xlabel('Lcontrast'); ylabel('Mcontrast');
            axis 'square'
            set(gca, 'XLim', maxContrast*[-1 1], 'YLim', maxContrast*[-1 1]);
            
            subplot(1,3,2);
            hold on;
            plot([-1 1], [0 0], 'r-');
            plot([0 0], [-1 1], 'r-');
            plot(trainingLcontrastSequence(:,1:theTimeBins(end)), trainingScontrastSequence(:,1:theTimeBins(end)), 'k.');
            hold off;
            xlabel('Lcontrast'); ylabel('Scontrast');
            axis 'square'
            set(gca, 'XLim', maxContrast*[-1 1], 'YLim', maxContrast*[-1 1]);
            
            subplot(1,3,3);
            hold on;
            plot([-1 1], [0 0], 'r-');
            plot([0 0], [-1 1], 'r-');
            plot(trainingMcontrastSequence(:,1:theTimeBins(end)), trainingScontrastSequence(:,1:theTimeBins(end)), 'k.');
            hold off;
            xlabel('Mcontrast'); ylabel('Scontrast');
            axis 'square'
            set(gca, 'XLim', maxContrast*[-1 1], 'YLim', maxContrast*[-1 1]);
            drawnow;
            
            
            h = figure(2);
            set(h, 'Color', [0 0 0], 'Name', sprintf('Scans: %d - %d', scanIndex, trainingScans));
            clf;
            subplot('Position', [0.02 0.54 0.97 0.46]);
            hold on;
            plot(trainingTimeAxis(1:theTimeBins(end)), trainingLcontrastSequence(:,1:theTimeBins(end)), 'r-');
            plot(trainingTimeAxis(1:theTimeBins(end)), trainingMcontrastSequence(:,1:theTimeBins(end)), 'g-');
            plot(trainingTimeAxis(1:theTimeBins(end)), trainingScontrastSequence(:,1:theTimeBins(end)), 'b-');
            
            ylabel('Weber cone contrast');
            set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', [trainingTimeAxis(1) trainingTimeAxis(theTimeBins(end))], 'YLim', maxContrast*[-1 1]);
            hold off;
            
            subplot('Position', [0.02 0.05 0.97 0.46]);
            imagesc(trainingTimeAxis(1:theTimeBins(end)), 1:conesNum, trainingPhotocurrents(:,1:theTimeBins(end)));
            set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', [trainingTimeAxis(1) trainingTimeAxis(theTimeBins(end))]);
            xlabel('time (sec)');
            ylabel('cone id');
            colormap(bone(512));
            drawnow
        
        end % scanIndex
        fprintf('Added training data from image %d (%d scans)\n', imageIndex, trainingScanIndex);
        
        
    
        % load testing data
        for scanIndex = trainingScans+1:scansNum
            
            % Load scan data
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, scanPhotoCurrents] = loadScanData(scanFilename);
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialBins, e.g, [2 2]
            scanLcontrastSequence = subSampleSpatially(scanLcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanMcontrastSequence = subSampleSpatially(scanMcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanScontrastSequence = subSampleSpatially(scanScontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            
            % pre-allocate memory
            if (testingScanIndex == 0)
                testingTimeAxis            = (0:(timeBins*totalTestingScansNum*totalImages-1))*(timeAxis(2)-timeAxis(1));
                testingLcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingMcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingScontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingPhotocurrents       = zeros(conesNum,    timeBins*totalTestingScansNum*totalImages, 'single');
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
    
    
    
    
end

function contrastSequence = subSampleSpatially(originalContrastSequence, subSampledSpatialBins, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons)
    
    if (numel(subSampledSpatialBins) ~= 2)
        subSampledSpatialBins
        error('Expecting a 2 element vector');
    end
    
    if ((subSampledSpatialBins(1) == 1) && (subSampledSpatialBins(2) == 1))
        xRange = numel(spatialXdataInRetinalMicrons) * (spatialXdataInRetinalMicrons(2)-spatialXdataInRetinalMicrons(1));
        yRange = numel(spatialYdataInRetinalMicrons) * (spatialYdataInRetinalMicrons(2)-spatialYdataInRetinalMicrons(1));
        fprintf('\nOriginal spatial data %d x %d, covering an area of %2.2f x %2.2f microns\n', numel(spatialXdataInRetinalMicrons), numel(spatialYdataInRetinalMicrons), xRange, yRange);
        fprintf('\nWill downsample to [1 x 1]\n');
        contrastSequence = mean(originalContrastSequence,1);
    else
       subSampledSpatialBins
       error('This subsampling is not yet implemented\n'); 
    end
    
end


function [timeAxis, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, LcontrastSequence, McontrastSequence, ScontrastSequence, photoCurrents] = loadScanData(scanFilename)
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
    %fprintf('Offsetting photocurrents by their baseline levels (estimated in [%2.2f - %2.2f] seconds.\n', baselineEstimationBins(1)*timeStep, baselineEstimationBins(end)*timeStep);
    
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
    
    
    % Finally, cut the initial 200 and trailing 50 mseconds of data
    timeBinsToCutFromStart = round(200/1000/timeStep)
    timeBinsToCutFromEnd = round(50/1000/timeStep)
    timeBinsToKeep = (timeBinsToCutFromStart+1):(timeBins-timeBinsToCutFromEnd);
    
    LcontrastSequence = LcontrastSequence(:, timeBinsToKeep);
    McontrastSequence = McontrastSequence(:, timeBinsToKeep);
    ScontrastSequence = ScontrastSequence(:, timeBinsToKeep);
    photoCurrents = photoCurrents(:, timeBinsToKeep);
    timeAxis = timeAxis(timeBinsToKeep);
    % reset time axis to start at t = 0;
    timeAxis = timeAxis - timeAxis(1);
    
    
    spatialXdataInRetinalMicrons = LMSexcitationXdataInRetinalMicrons;
    spatialYdataInRetinalMicrons = LMSexcitationYdataInRetinalMicrons;
end


