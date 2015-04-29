function generateIlluminant(obj, sceneCalibrationStruct)

    % check wave vector 
    if (size(obj.reflectanceMap,3) ~= numel(sceneCalibrationStruct.illuminantSampling))
        error('The spectral sampled of the reflectance map spectral samples (%d) does not match the one specified in the sceneCalibrationStruct', size(obj.reflectanceMap,3), numel(sceneCalibrationStruct.illuminantSampling));
    end
    
    
    
    switch sceneCalibrationStruct.illuminantName
        case 'D65'
            load('spd_D65.mat');
            spd = SplineCmf(S_D65, spd_D65', WlsToS(reshape(sceneCalibrationStruct.illuminantSampling, [numel(sceneCalibrationStruct.illuminantSampling) 1])));
            
        otherwise
            error('Unknown illuminant: ''%s''', sceneCalibrationStruct.illuminantName);
    end
    
    obj.illuminant.wave = sceneCalibrationStruct.illuminantSampling';
    obj.illuminant.spd  = spd';
end
