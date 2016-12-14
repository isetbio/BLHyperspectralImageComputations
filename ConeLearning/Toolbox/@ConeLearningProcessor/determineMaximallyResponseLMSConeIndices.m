function determineMaximallyResponseLMSConeIndices(obj, sceneIndex)

    % find max responsive L, M and S cone for plotting their response traces
    coneIndexOfMaxResponse = zeros(1,4);
    for coneType = 2:4
        coneIndices = find(obj.core1Data.trueConeTypes == coneType);
        coneResponses = obj.core1Data.XTphotonAbsorptionMatrices{sceneIndex}(coneIndices,:);
        maxConeResponse = -Inf;
        for coneIndex = 1:numel(coneIndices)
            if (maxConeResponse < max(squeeze(coneResponses(coneIndex,:))))
                coneIndexOfMaxResponse(coneType) = coneIndices(coneIndex);
                maxConeResponse = max(squeeze(coneResponses(coneIndex,:)));
            end
        end
    end % coneType
    
    obj.maxResponsiveConeIndices = coneIndexOfMaxResponse(2:4);   
end

