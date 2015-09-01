function loadSpatioTemporalPhotonAbsorptionMatrix(obj, datafile, varargin)
    
    fprintf('Loading data from %s\n',which(datafile));
    obj.core1Data = load(datafile, '-mat');
    
    
end

