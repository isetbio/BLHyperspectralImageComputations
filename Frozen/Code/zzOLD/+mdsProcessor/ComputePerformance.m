function performance = ComputePerformance(trueConeTypes, trueConeXYLocations, MDSprojection, coneIndices, performance, kStep, samplesPerFixation)

    LconeIndices = coneIndices{1};
    MconeIndices = coneIndices{2}; 
    SconeIndices = coneIndices{3};
    
    correctlyIdentifiedLMcones = 0;
    correctlyIdentifiedScones = 0;
    meanDistanceLMmosaic = 0;
    meanDistanceSmosaic = 0;
    
    for k = 1:size(trueConeXYLocations,1)
        
        if (trueConeTypes(k) == 2) && (ismember(k, LconeIndices))
            correctlyIdentifiedLMcones = correctlyIdentifiedLMcones + 1;
        elseif (trueConeTypes(k) == 3) && (ismember(k, MconeIndices))
            correctlyIdentifiedLMcones = correctlyIdentifiedLMcones + 1;
        elseif (trueConeTypes(k) == 4) && (ismember(k, SconeIndices))
            correctlyIdentifiedScones = correctlyIdentifiedScones + 1;
        end
        
        dx = (trueConeXYLocations(k,1) - MDSprojection(k,2));
        dy = (trueConeXYLocations(k,2) - MDSprojection(k,3));
        
        if (trueConeTypes(k) == 2) || (trueConeTypes(k) == 3)
            meanDistanceLMmosaic = meanDistanceLMmosaic + sqrt(dx^2+dy^2);
        else
            meanDistanceSmosaic = meanDistanceSmosaic + sqrt(dx^2+dy^2);
        end  
    end
    
    LMconesNum = numel(find(trueConeTypes == 2)) + numel(find(trueConeTypes == 3));
    SconesNum = numel(find(trueConeTypes == 4));
    
    meanDistanceLMmosaic = meanDistanceLMmosaic / LMconesNum;
    meanDistanceSmosaic = meanDistanceSmosaic / SconesNum;
    
    correctlyIdentifiedLMcones = correctlyIdentifiedLMcones / LMconesNum;
    correctlyIdentifiedScones = correctlyIdentifiedScones / SconesNum;
    
    if (isempty(performance))
        performance.correctlyIdentifiedLMcones = correctlyIdentifiedLMcones;
        performance.correctlyIdentifiedScones = correctlyIdentifiedScones;
        performance.meanDistanceLMmosaic = meanDistanceLMmosaic;
        performance.meanDistanceSmosaic = meanDistanceSmosaic;
        performance.fixationsNum = kStep / samplesPerFixation;
    else
        performance.correctlyIdentifiedLMcones = ...
            [performance.correctlyIdentifiedLMcones correctlyIdentifiedLMcones];
        
        performance.correctlyIdentifiedScones = ...
            [performance.correctlyIdentifiedScones correctlyIdentifiedScones];
        
        performance.meanDistanceLMmosaic = ...
            [performance.meanDistanceLMmosaic meanDistanceLMmosaic];
        
        performance.meanDistanceSmosaic = ...
            [performance.meanDistanceSmosaic meanDistanceSmosaic];
        
        performance.fixationsNum = ...
            [performance.fixationsNum kStep/samplesPerFixation];
    end
end

