function [subSampledSignal, subSampledTimeAxis] = subsampleTemporally(signal,  timeAxis, timeDimensionIndex, lowPassSignalFlag, newTau)
    
    originalTau = timeAxis(2)-timeAxis(1);
    decimationFactor = round(newTau/originalTau);
    tauInSamples     = sqrt((decimationFactor^2-1)/12);
    filterTime       = -round(3*tauInSamples):1:round(3*tauInSamples);
    kernel           = exp(-0.5*(filterTime/tauInSamples).^2);
    kernel           = kernel / sum(kernel);
    
    figure(3);
    plot(filterTime, kernel, 'k-');
    pause
    
    subSampledSignal = [];
    subSampledTimeAxis = [];
end

