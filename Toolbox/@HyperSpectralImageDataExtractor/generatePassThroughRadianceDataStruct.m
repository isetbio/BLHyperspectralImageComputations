function generatePassThroughRadianceDataStruct(obj, energy, customIlluminant)
 
    
    if (~isempty(customIlluminant))
        % illuminant adjustment vector
        illuminantAdjustmentVector = customIlluminant ./ obj.illuminant.spd;
        % adjust radiance
        energy = bsxfun(@times, energy, reshape(illuminantAdjustmentVector, [1 1 numel(illuminantAdjustmentVector)]));    
        % adjust illuminant 
        obj.illuminant.spd = obj.illuminant.spd .* illuminantAdjustmentVector;
    end
    
    obj.radianceData = struct(...
        'sceneName',    obj.sceneData.name, ...
        'wave',         obj.illuminant.wave, ...
        'illuminant',   obj.illuminant.spd, ... 
        'radianceMap',  energy ...                                                
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

