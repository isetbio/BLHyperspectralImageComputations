function wVector = lowRankSVDbasedDecodingVector(U, S, V, C, thresholdVarianceExplained)

    dd = (diag(S)).^2;
    varianceExplained = cumsum(dd) / sum(dd) * 100;
    
    indicesBelowThreshold = find(varianceExplained <= thresholdVarianceExplained);
    if (isempty(indicesBelowThreshold))
        includedComponentsNum = 1;
        fprintf(2,'\n<strong>varianceExplained(1) (%2.2f) > thresholdVarianceExplained (%2.2f).\nWill only use first SVD component.</strong>\n', varianceExplained(1), thresholdVarianceExplained);
    else
        includedComponentsNum = indicesBelowThreshold(end);
    end
    
    k = min([size(S,1) includedComponentsNum]);
    includedComponents = 1:k;
    wVector =  (V(:,includedComponents) * inv(S(includedComponents,includedComponents)) * (U(:,includedComponents))') * C;
end
