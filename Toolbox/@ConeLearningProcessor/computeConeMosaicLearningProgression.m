function computeConeMosaicLearningProgression(obj, fixationsNum)

    correctlyIdentifiedLMcones = 0;
    correctlyIdentifiedScones = 0;
    meanDistanceLMmosaic = 0;
    meanDistanceSmosaic = 0;
    

    for coneIndex = 1:size(obj.core1Data.trueConeXYLocations,1)
        
        if (obj.core1Data.trueConeTypes(coneIndex) == 2) && (ismember(coneIndex, obj.unwrappedLconeIndices))
            correctlyIdentifiedLMcones = correctlyIdentifiedLMcones + 1;
        elseif (obj.core1Data.trueConeTypes(coneIndex) == 3) && (ismember(coneIndex, obj.unwrappedMconeIndices))
            correctlyIdentifiedLMcones = correctlyIdentifiedLMcones + 1;
        elseif (obj.core1Data.trueConeTypes(coneIndex) == 4) && (ismember(coneIndex, obj.unwrappedSconeIndices))
            correctlyIdentifiedScones = correctlyIdentifiedScones + 1;
        end
     
        dx = (obj.core1Data.trueConeXYLocations(coneIndex,1) - obj.unwrappedMDSprojection(coneIndex,2));
        dy = (obj.core1Data.trueConeXYLocations(coneIndex,2) - obj.unwrappedMDSprojection(coneIndex,3));
        
        if (obj.core1Data.trueConeTypes(coneIndex) == 2) || (obj.core1Data.trueConeTypes(coneIndex) == 3)
            meanDistanceLMmosaic = meanDistanceLMmosaic + sqrt(dx^2+dy^2);
        elseif (obj.core1Data.trueConeTypes(coneIndex) == 4)
            meanDistanceSmosaic = meanDistanceSmosaic + sqrt(dx^2+dy^2);
        else
            error('cone type = %d\n', obj.core1Data.trueConeTypes(coneIndex));
        end  
    end % coneIndex
    
    LMconesNum = numel(find(obj.core1Data.trueConeTypes == 2)) + numel(find(obj.core1Data.trueConeTypes == 3));
    SconesNum = numel(find(obj.core1Data.trueConeTypes == 4));
    
    meanDistanceLMmosaic = meanDistanceLMmosaic / LMconesNum;
    meanDistanceSmosaic = meanDistanceSmosaic / SconesNum;
    
    correctlyIdentifiedLMcones = correctlyIdentifiedLMcones / LMconesNum;
    correctlyIdentifiedScones = correctlyIdentifiedScones / SconesNum;
    
    if (isempty(obj.coneMosaicLearningAccuracy))
        obj.coneMosaicLearningAccuracy.correctlyIdentifiedLMcones = correctlyIdentifiedLMcones;
        obj.coneMosaicLearningAccuracy.correctlyIdentifiedScones = correctlyIdentifiedScones;
        obj.coneMosaicLearningAccuracy.meanDistanceLMmosaic = meanDistanceLMmosaic;
        obj.coneMosaicLearningAccuracy.meanDistanceSmosaic = meanDistanceSmosaic;
        obj.coneMosaicLearningAccuracy.fixationsNum = fixationsNum;
    else
        obj.coneMosaicLearningAccuracy.correctlyIdentifiedLMcones = ...
            [obj.coneMosaicLearningAccuracy.correctlyIdentifiedLMcones correctlyIdentifiedLMcones];
        obj.coneMosaicLearningAccuracy.correctlyIdentifiedScones = ...
            [obj.coneMosaicLearningAccuracy.correctlyIdentifiedScones correctlyIdentifiedScones];
        obj.coneMosaicLearningAccuracy.meanDistanceLMmosaic = ...
            [obj.coneMosaicLearningAccuracy.meanDistanceLMmosaic meanDistanceLMmosaic];
        obj.coneMosaicLearningAccuracy.meanDistanceSmosaic = ...
            [obj.coneMosaicLearningAccuracy.meanDistanceSmosaic meanDistanceSmosaic];
        obj.coneMosaicLearningAccuracy.fixationsNum = ...
            [ obj.coneMosaicLearningAccuracy.fixationsNum fixationsNum];
    end
    
    
end

