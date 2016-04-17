function X = lowRankApproximationFromSVDcomponents(V, S, U, includedComponentsNum)
    k = min([size(S,1) includedComponentsNum]);
    X =  (V(:,1:k) * inv(S(1:k,1:k)) * (U(:,1:k))');
end
