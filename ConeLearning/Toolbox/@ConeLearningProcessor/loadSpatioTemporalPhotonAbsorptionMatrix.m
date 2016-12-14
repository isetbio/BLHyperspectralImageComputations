function loadSpatioTemporalPhotonAbsorptionMatrix(obj, datafile, varargin)
    
    fprintf('Loading data from %s\n',which(datafile));
    obj.core1Data = load(datafile, '-mat');
    
    % load variables related to pre-computation of photon responses
    obj.conesAcross                       = obj.core1Data.sensorParamsStruct.conesAcross;
    obj.coneApertureInMicrons             = obj.core1Data.sensorParamsStruct.coneAperture/(1e-6);
  %  obj.coneIntegrationTimeInMilliseconds = obj.core1Data.sensorParamsStruct.coneIntegrationTime/(1e-3);
    obj.coneLMSdensities                  = obj.core1Data.sensorParamsStruct.LMSdensities;
    obj.eyeMicroMovementsPerFixation      = obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
    obj.sceneSet                          = obj.core1Data.allSceneNames;
    
    obj
end

