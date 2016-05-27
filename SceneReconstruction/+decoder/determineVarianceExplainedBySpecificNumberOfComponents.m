function varianceExplainedForTargetComponentsNum = determineVarianceExplainedBySpecificNumberOfComponents(S, targetComponentsNum)
    dd = (diag(S)).^2;
    varianceExplained = cumsum(dd) / sum(dd) * 100;
    
    componentsNum = 1:size(S,1);
    
    [~,idx] = min(abs(componentsNum-targetComponentsNum));
    varianceExplainedForTargetComponentsNum = varianceExplained(idx);  
end

