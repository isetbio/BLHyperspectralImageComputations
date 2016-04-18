function wVector = lowRankSVDbasedDecodingVector(U, S, V, C, thresholdVarianceExplained)  
    dd = (diag(S)).^2;
    varianceExplained = cumsum(dd) / sum(dd) * 100;
    
    indicesBelowThreshold = find(varianceExplained <= thresholdVarianceExplained);
    includedComponentsNum = indicesBelowThreshold(end);
    
    k = min([size(S,1) includedComponentsNum]);
    wVector =  (V(:,1:k) * inv(S(1:k,1:k)) * (U(:,1:k))') * C;
end
