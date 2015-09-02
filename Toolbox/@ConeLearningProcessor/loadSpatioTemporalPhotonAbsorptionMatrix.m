function loadSpatioTemporalPhotonAbsorptionMatrix(obj, datafile, varargin)
    
    fprintf('Loading data from %s\n',which(datafile));
    obj.core1Data = load(datafile, '-mat');
    
    % convert to photon absorption rate
    fprintf('Converting to photon absorption rate\n');
    for sceneIndex = 1:numel(obj.core1Data.allSceneNames)
        % to photon rate
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = ...
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}/obj.core1Data.sensorConversionGain/obj.core1Data.sensorExposureTime;
    end % sceneIndex
    
end

