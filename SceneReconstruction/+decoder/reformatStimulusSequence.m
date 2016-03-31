function [stimulus, varargout] = reformatStimulusSequence(direction, stimulus, varargin)
    % The stimulus sequence is [spatialBinsY x spatialBinsX x 3cone contrasts x timeBins]
    % The decoder-format stimulus is [timeBins x (NspatialBins*3]
    
    if (strcmp(direction, 'ToDesignMatrixFormat'))
        originalSize = size(stimulus);
        stimulus = reshape(permute(stimulus, [4 1 2 3]), [originalSize(4) prod(originalSize(1:3))]);
        varargout{1} = originalSize;
    elseif (strcmp(direction, 'fromDesignMatrixFormat'))
        originalSize = varargin{1};
        stimulus = ipermute(reshape(stimulus, [originalSize(4) originalSize(1) originalSize(2) originalSize(3)]), [4 1 2 3]);
        varargout = {};
    else
        error('Unknown reshaping direction: ''%s''.', direction)
    end
end
