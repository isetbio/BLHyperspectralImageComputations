function whiteningMatrix = computeWhiteningMatrix(X)
    Sigma = 1/size(X,1) * (X') * X;
    [U, Gamma, V] = svd(Sigma, 'econ');
    whiteningMatrix = U * (inv(sqrt(Gamma))) * V';
end

