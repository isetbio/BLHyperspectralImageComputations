function maxAvailableSceneRotations = permuteEyeMovementsAndPhotoAbsorptionResponses(obj)

    % Set the rng for repeatable eye movements
    rng(obj.randomSeedForEyeMovementsOnDifferentScenes);
    
    % find minimal number of eye movements across all scenes
    minEyeMovements = 1000*1000*1000;
    totalEyeMovementsNum = 0;
    
    % permute eyemovements and XT response indices 
    for sceneIndex = 1:numel(obj.core1Data.allSceneNames)
         
        fprintf('Permuting eye movements and photon absorption rate sequences for scene %d (''%s'')\n', sceneIndex, obj.core1Data.allSceneNames{sceneIndex});
  
        responseLength = size(obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex},2);
        fixationsNum = responseLength / obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
        permutedFixationIndices = randperm(fixationsNum);
         
        % Ensure that all scenes have same maximal photon absorption rates (and
        % equal to the max absorption rate during scene 1)
        maxPhotonAbsorptionForCurrentScene = max(max(abs(obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex})));
        if (sceneIndex == 1)
            maxPhotonAbsorptionForScene1 = maxPhotonAbsorptionForCurrentScene;
        else
            obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = ...
            obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} / maxPhotonAbsorptionForCurrentScene * maxPhotonAbsorptionForScene1;
        end
            
        % do the permutation of eyemovements/responses
        tmp1 = obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}*0;
        tmp2 = obj.core1Data.eyeMovements{sceneIndex}*0;
        
        kk = 1:obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
        for fixationIndex = 1:fixationsNum
            sourceIndices = (permutedFixationIndices(fixationIndex)-1)*obj.core1Data.eyeMovementParamsStruct.samplesPerFixation + kk;
            destIndices = (fixationIndex-1)*obj.core1Data.eyeMovementParamsStruct.samplesPerFixation+kk;
            tmp1(:,destIndices) = obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}(:, sourceIndices);
            tmp2(destIndices,:) = obj.core1Data.eyeMovements{sceneIndex}(sourceIndices,:);
        end
        obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex} = tmp1;
        obj.core1Data.eyeMovements{sceneIndex} = tmp2;
        
        % compute min number of eyemovements across all scenes
        eyeMovementsNum = size(obj.core1Data.eyeMovements{sceneIndex},1);
        totalEyeMovementsNum = totalEyeMovementsNum + eyeMovementsNum;
        if (eyeMovementsNum < minEyeMovements)
            minEyeMovements = eyeMovementsNum;
        end   
    end % sceneIndex
    
    eyeMovementsPerSceneRotation = obj.fixationsPerSceneRotation * obj.core1Data.eyeMovementParamsStruct.samplesPerFixation;
    maxAvailableSceneRotations = floor(minEyeMovements / eyeMovementsPerSceneRotation);
end

