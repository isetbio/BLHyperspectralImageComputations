function [LMSexcitationSequenceSubSampled, photoCurrentsSubSampled, sensorSubSampled] = ...
                subSampleSequences(LMSexcitationSequence, photoCurrents, sensor, newSensorTimeInterval)
       
    % Before downsampling, convolve with a Gaussian kernel
    originalTimeInterval = sensorGet(sensor, 'time interval');
    decimationFactor = round(newSensorTimeInterval/originalTimeInterval);
    tauInSamples = sqrt((decimationFactor^2-1)/12);
    filterTime = -round(3*tauInSamples):1:round(3*tauInSamples);
    kernel = exp(-0.5*(filterTime/tauInSamples).^2);
    kernel = kernel / sum(kernel);
    

    % Compute subsampling sample indices
    originalTimePoints = round(sensorGet(sensor, 'total time')/originalTimeInterval);
    [~,tOffset] = max(kernel);
    subSampledIndices = tOffset + 0:decimationFactor:originalTimePoints;
    subSampledIndices = subSampledIndices(subSampledIndices>0);
     
    fprintf('\tLowpassing signals with a filter with %2.5f msec time constant and subsampling with a resolution of %2.2f msec.\n', tauInSamples*originalTimeInterval*1000, newSensorTimeInterval*1000);

    % LMS excitation sequence
    LMSexcitationSequenceSubSampled = zeros(numel(subSampledIndices), size(LMSexcitationSequence,2), size(LMSexcitationSequence,3), size(LMSexcitationSequence,4), 'single');
    for i = 1:size(LMSexcitationSequence,2)
         for j = 1:size(LMSexcitationSequence, 3)
             for k = 1:size(LMSexcitationSequence, 4)
                 tmp = conv(squeeze(LMSexcitationSequence(:,i, j, k)), kernel, 'same');
                 LMSexcitationSequenceSubSampled(:, i, j, k) = single(tmp(subSampledIndices));
             end
         end
    end
     
    % Sensor positions
    originalPositions = sensorGet(sensor, 'positions');
    subSampledPositions = zeros(numel(subSampledIndices), size(originalPositions,2), 'single');
    for i = 1:size(originalPositions,2)
        % we do not low pass the positions
        subSampledPositions(:,i) = single(squeeze(originalPositions(subSampledIndices,i)));
    end
    
    % Photon rate
    originalIsomerizations = sensorGet(sensor, 'photon rate');
    subSampledIsomerizations = zeros(size(originalIsomerizations,1), size(originalIsomerizations,2), numel(subSampledIndices), 'single');
    for i = 1:size(originalIsomerizations,1)
         for j = 1:size(originalIsomerizations, 2)
             tmp = conv(squeeze(originalIsomerizations(i, j, :)), kernel, 'same');
             subSampledIsomerizations(i,j,:) = single(tmp(subSampledIndices));
         end
    end
    
    % Photocurrents
    photoCurrentsSubSampled = zeros(size(photoCurrents,1), size(photoCurrents,2), numel(subSampledIndices), 'single');
    for i = 1:size(photoCurrents,1)
        for j = 1:size(photoCurrents,2)
             tmp = conv(squeeze(photoCurrents(i,j,:)), kernel, 'same');
             photoCurrentsSubSampled(i,j,:) = single(tmp(subSampledIndices));
        end
    end
    
    % Update sensor struct for consistency with new time sampling
    sensorSubSampled = sensor;
    sensorSubSampled = sensorSet(sensorSubSampled, 'time interval', newSensorTimeInterval);
    sensorSubSampled = sensorSet(sensorSubSampled, 'photon rate',  subSampledIsomerizations);
    sensorSubSampled = sensorSet(sensorSubSampled, 'positions',   subSampledPositions);
end