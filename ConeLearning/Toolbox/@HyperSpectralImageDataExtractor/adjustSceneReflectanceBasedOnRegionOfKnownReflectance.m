% Method to compute the scene illuminant from a region of known reflectance
function adjustSceneReflectanceBasedOnRegionOfKnownReflectance(obj)
    
    if isempty(obj.sceneData.knownReflectionData.region)
        reflectanceCorrectionVector = obj.sceneData.knownReflectionData.suggestedCorrectionVector;
        fprintf('Using suggested correction vector\n');
    else
        fprintf('Computing white balance correction vector\n');
        x1 = obj.sceneData.knownReflectionData.region(1);
        y1 = obj.sceneData.knownReflectionData.region(2);
        x2 = obj.sceneData.knownReflectionData.region(3);
        y2 = obj.sceneData.knownReflectionData.region(4);

        measuredReflectanceSPD = squeeze(mean(mean(obj.reflectanceMap(y1:y2, x1:x2,:),1),2));
        nominalReflectanceSPD  = obj.sceneData.knownReflectionData.nominalReflectanceSPD';
        reflectanceCorrectionVector = (nominalReflectanceSPD ./ measuredReflectanceSPD);
    end
    
    obj.reflectanceMap = bsxfun(@times, obj.reflectanceMap, reshape(reflectanceCorrectionVector, [1 1 numel(reflectanceCorrectionVector)]));    
    
end

