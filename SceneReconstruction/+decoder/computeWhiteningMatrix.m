function whiteningMatrix = computeWhiteningMatrix(X, thresholdVarianceExplained)
    Sigma = 1/size(X,1) * (X') * X;
    [U, Gamma, V] = svd(Sigma, 'econ');
    
    dd = (diag(Gamma)).^1;
    varianceExplained = cumsum(dd) / sum(dd) * 100;
    singularVectorIndicesBelowThreshold = find(varianceExplained <= thresholdVarianceExplained);
    includedComponentsNum = singularVectorIndicesBelowThreshold(end);
    U = U(:,1:includedComponentsNum);
    V = V(:,1:includedComponentsNum);
    Gamma = Gamma(1:includedComponentsNum,1:includedComponentsNum);
    whiteningMatrix = U * (inv(sqrt(Gamma))) * V';
    
    figure(111);
    plot(1:numel(varianceExplained), varianceExplained, 'k.-');
    hold on
    plot(includedComponentsNum*[1 1], [0 100], 'r-');
    hold off;
    set(gca, 'XLim', [1 numel(dd)], 'YLim', [50 100], 'YTick', 0:5:100);
    xlabel('whitening matrix singular component number');
    ylabel('cumulative sqrt(variance) explained');
    drawnow;
    fprintf('To account for %2.1f%% of the total variance of the whitening matrix, we keep the first %d of its %d SVD components.', thresholdVarianceExplained, includedComponentsNum, size(Gamma,1));
end

