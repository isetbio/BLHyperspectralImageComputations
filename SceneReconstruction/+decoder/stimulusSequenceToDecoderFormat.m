function [stimulus, originalSize] = stimulusSequenceToDecoderFormat(stimulus, direction, originalSize)
    % the stimulus sequence is [spatialBinsY x spatialBinsX x 3cones x timeBins]
    % the decoder format stimulus is [timeBins x (NspatialBins*3]
    
    if (strcmp(direction, 'toDecoderFormat'))
        originalSize = size(stimulus);
        stimulus = reshape(permute(stimulus, [4 1 2 3]), ...
            [originalSize(4) prod(originalSize(1:3))]);
        
    elseif (strcmp(direction, 'fromDecoderFormat'))
        stimulus = ipermute(...
            reshape(stimulus, [originalSize(4) originalSize(1) originalSize(2) originalSize(3)]), [4 1 2 3]);
        originalSize = [];
    else
        error('Unknown reshaping direction: ''%s''.', direction)
    end
    
end
