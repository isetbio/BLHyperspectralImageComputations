function computeDisparityMatrix(obj,timeBinRange)
    % compute correlation matrix up to this point
    if (obj.displayComputationTimes)
        tic
    end
    
    % compute sub-sampled time range for correlations
    subsampledBinRange = timeBinRange(1:obj.correlationComputationIntervalInMilliseconds:end);
    
    % compute correlations
    correlationMatrix = corrcoef((obj.adaptedPhotoCurrentXTresponse(:,subsampledBinRange))');

    % Compute disparity matrix
    if (strcmp(obj.disparityMetric, 'linear'))
        D = 1-(correlationMatrix+1.0)/2.0;
    elseif (strcmp(obj.disparityMetric, 'log'))
        D = -log((correlationMatrix+1.0)/2.0);
    else
        error('Unknown disparity metric ''%s''', obj.disparityMetric);
    end
    if ~issymmetric(D)
        D = 0.5*(D+D');
    end
    obj.disparityMatrix = D;
    if (obj.displayComputationTimes)
        fprintf('\tCorrelation and disparity matrices computeation took %f seconds. \n', toc);
    end
end
