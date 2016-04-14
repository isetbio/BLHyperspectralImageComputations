function testPreprocessing

    samples = 10000;
    dims = 2;
    
    Xtrain = 5 + randn(samples,1+dims);
    Xtrain(:,1) = 1;
    Xtrain(:,2) = Xtrain(:,3)*2.8 + Xtrain(:,2)*0.85
    
    Xtest = 5 + randn(samples*0.8,1+dims);
    Xtest(:,1) = 1;
    Xtest(:,2) = Xtest(:,3)*2.8 + Xtest(:,2)*0.85
    
    
    maxAll = max([max(abs(squeeze(Xtrain(:,2)))) max(abs(squeeze(Xtrain(:,3))))]);
   
    figure(1);
    clf;
    subplot(2,2,1)
    plot(Xtrain(:,2), Xtrain(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('original Xtrain data')

    
    % Compute centering operator
    oneColVector = ones(samples,1);
    centeringOperator = (1/samples*Xtrain'*oneColVector)'
   
    % Center Xtrain
    Xtrain = bsxfun(@minus, Xtrain, centeringOperator);
    Xtrain(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtrain(:,2)))) max(abs(squeeze(Xtrain(:,3))))]);
   
    
    subplot(2,2,2)
    plot(Xtrain(:,2), Xtrain(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('centering');
    
    
    % Compute normalizing operator: divide by stddev
    normalizingOperator = (1./(sqrt(1/samples*(Xtrain.^2)'*oneColVector)))';
    Xtrain = bsxfun(@times, Xtrain, normalizingOperator);
    Xtrain(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtrain(:,2)))) max(abs(squeeze(Xtrain(:,3))))]);
   
    
    subplot(2,2,3)
    plot(Xtrain(:,2), Xtrain(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('scaling');
    
    % Compute degree of whiteness of Xtrain
    varianceCovarianceMatrix = 1/samples*Xtrain'*Xtrain;
    upperDiagElements = triu(varianceCovarianceMatrix, 1);
    covariancesBefore = upperDiagElements(:)
    
    % Compute whitening operator:
    Sigma = 1/samples * Xtrain' * Xtrain;
    [U, Gamma, V] = svd(Sigma, 'econ');
    whiteningOperator = U * inv(sqrt(Gamma)) *V';
    Xtrain = Xtrain * whiteningOperator;
    Xtrain(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtrain(:,2)))) max(abs(squeeze(Xtrain(:,3))))]);
   
    varianceCovarianceMatrix = 1/samples*Xtrain'*Xtrain;
    upperDiagElements = triu(varianceCovarianceMatrix, 1);
    covariancesAfter = upperDiagElements(:)
    
    subplot(2,2,4)
    plot(Xtrain(:,2), Xtrain(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('whitened');
    
    figure(22);
    subplot(2,1,1)
    stem(1:numel(covariancesBefore), covariancesBefore, 'Marker', '.');
    subplot(2,1,2)
    stem(1:numel(covariancesAfter), covariancesAfter, 'Marker', '.');
    xlabel('filter dimension pair index')
    
    % Apply all operations on the Xtest matrix
    maxAll = max([max(abs(squeeze(Xtest(:,2)))) max(abs(squeeze(Xtest(:,3))))]);
    figure(2);
    clf;
    subplot(2,2,1)
    plot(Xtest(:,2), Xtest(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('original Xtest data')
    
    Xtest = bsxfun(@minus, Xtest, centeringOperator);
    Xtest(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtest(:,2)))) max(abs(squeeze(Xtest(:,3))))]);
     
    subplot(2,2,2)
    plot(Xtest(:,2), Xtest(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('centering (based on xTrain)');
    
    
    Xtest = bsxfun(@times, Xtest, normalizingOperator);
    Xtest(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtest(:,2)))) max(abs(squeeze(Xtest(:,3))))]);
     
    subplot(2,2,3)
    plot(Xtest(:,2), Xtest(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('scaling (based on xTrain)');
    
    Xtest = Xtest * whiteningOperator;
    Xtest(:,1) = 1;
    maxAll = max([max(abs(squeeze(Xtest(:,2)))) max(abs(squeeze(Xtest(:,3))))]);
    
    subplot(2,2,4)
    plot(Xtest(:,2), Xtest(:,3), 'k.')
    hold on
    plot([-maxAll maxAll], [ 0 0], 'r-');
    plot([0 0], [-maxAll maxAll], 'r-');
    set(gca, 'XLim', [-1 1]*maxAll, 'YLim', [-1 1]*maxAll);
    axis 'square'
    title('whitened (based on Xtrain)');
    
    
end
