function generatePassThroughRadianceDataStruct(obj, photons, waveRange)
 
    
    indices = find((obj.illuminant.wave>= waveRange(1))&(obj.illuminant.wave<=waveRange(2)));

    obj.radianceData = struct(...
        'sceneName',    obj.sceneData.name, ...
        'wave',         obj.illuminant.wave(indices), ...
        'illuminant',   obj.illuminant.spd(indices), ... 
        'radianceMap',  photons(:,:,indices) ...                                                
    );

    
    obj.illuminant.wave = obj.radianceData.wave(1): mean(diff(obj.radianceData.wave)): obj.radianceData.wave(end);
    obj.illuminant.spd = obj.radianceData.illuminant;
    obj.radianceData.wave = obj.illuminant.wave;
    obj.illuminant.wave = obj.illuminant.wave(:);
    
    % Compute and store XYZ image
    obj.sceneXYZmap = MultispectralToSensorImage(obj.radianceData.radianceMap, WlsToS(obj.illuminant.wave), obj.sensorXYZ.T, obj.sensorXYZ.S);
    
    % Compute and store luminance map
    obj.sceneLuminanceMap = obj.wattsToLumens * squeeze(obj.sceneXYZmap(:,:,2));
    
end

