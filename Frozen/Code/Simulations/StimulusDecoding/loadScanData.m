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