function computeDisparityMatrix(obj,timeBinRange)
    % compute correlation matrix up to this point
    tic
    correlationMatrix = corrcoef((obj.adaptedPhotoCurrentXTresponse(:,timeBinRange))');

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
    fprintf('disparity Matrix took %f\n', toc);
end

