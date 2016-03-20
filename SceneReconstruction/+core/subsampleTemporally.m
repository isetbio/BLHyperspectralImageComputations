function [subSampledSignal, subSampledTimeAxis, kernel, filterTimeInTimeAxisUnits] = subsampleTemporally(signal,  timeAxis, timeDimensionIndex, lowPassSignal, newTau)
    
    originalTau = timeAxis(2)-timeAxis(1);
    decimationFactor = round(newTau/originalTau);
    subSampledIndices = 1:decimationFactor:numel(timeAxis);
    subSampledTimeAxis = timeAxis(subSampledIndices);
    
    if (lowPassSignal)
        tauInSamples     = sqrt((decimationFactor^2-1)/12);
        filterTime       = -round(3.3*tauInSamples):1:round(3.3*tauInSamples);
        kernel           = exp(-0.5*(filterTime/tauInSamples).^2);
        kernel           = kernel / sum(kernel);
        filterTimeInTimeAxisUnits = filterTime * originalTau;
    else
       kernel = []; 
    end
    
    if (ndims(signal) == 1)
        if (lowPassSignal)
            tmpSignal = conv(signal, kernel, 'same');
        end
        subSampledSignal = tmpSignal(subSampledIndices);
        return;
    end
    
    % make the timeDimension the last dimension
    otherDims = setdiff((1:ndims(signal)), timeDimensionIndex);
    permutationOrder = [otherDims timeDimensionIndex];
    tmpSignal = permute(signal, permutationOrder);
    
    % keep size of the tmpSignal for later  inverse reshaping
    inverseReshapingParams = size(tmpSignal);
    inverseReshapingParams(end) = numel(subSampledIndices);
    
    % Reshape into a 2D array, in which all non-temporal dimensions are
    % all assembled in the first dimension, and the temporal dimension
    % is the 2nd dimension
    tmpSignalDims2D = [prod(size(tmpSignal))/size(tmpSignal,ndims(tmpSignal)) size(tmpSignal,ndims(tmpSignal)) ];
    tmpSignal = reshape(tmpSignal, tmpSignalDims2D);

    % Preallocate memory for the sub-sampled signal    
    subSampledSignal = zeros(size(tmpSignal,1), numel(subSampledIndices));

    for k = 1:size(tmpSignal,1)
        if (lowPassSignal)
            tmpSignal(k,:) = conv(squeeze(tmpSignal(k,:)), kernel, 'same');
        end
        subSampledSignal(k,:) = squeeze(tmpSignal(k,subSampledIndices));
    end
    
    % Back to original signal size
    subSampledSignal = ipermute(reshape(subSampledSignal, inverseReshapingParams), permutationOrder);
end

