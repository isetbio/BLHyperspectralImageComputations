function [response, varargout] = reformatResponseSequence(direction, response, varargin)
    % The response sequence is [rowsOfCones x colsOfCones x timeBins]
    % The decoder-format response is [rowsOfCones*colsOfCones x timeBins]
    
    if (strcmp(direction, 'ToDesignMatrixFormat'))
        originalSize = size(response);
        response = reshape(response, [prod(originalSize(1:2)) originalSize(3)]);
        varargout{1} = originalSize;
    elseif (strcmp(direction, 'FromDesignMatrixFormat'))
        originalSize = varargin{1};
        response = reshape(response, originalSize);
    else
        error('Unknown reshaping direction: ''%s''.', direction)
    end
end

