function generateIlluminant(obj)

    % check wave vector 
    if (size(obj.reflectanceMap,3) ~= numel(obj.sceneData.customIlluminant.wave))
        error('The spectral sampled of the reflectance map spectral samples (%d) does not match the one specified in the sceneCalibrationStruct', size(obj.reflectanceMap,3), numel(sceneCalibrationStruct.illuminantSampling));
    end
    
    switch obj.sceneData.customIlluminant.name
        case 'D65'
            load('spd_D65.mat');
            newS = WlsToS(reshape(obj.sceneData.customIlluminant.wave, [numel(obj.sceneData.customIlluminant.wave) 1]));
            spd = SplineCmf(S_D65, spd_D65', newS);
            
        otherwise
            error('Unknown illuminant: ''%s''', obj.sceneData.customIlluminant.name);
    end
    
    obj.illuminant.wave = SToWls(newS);
    obj.illuminant.spd  = spd';
end
