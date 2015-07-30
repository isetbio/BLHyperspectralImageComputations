% Method to estimate the identity of each cone by analysis of their responses to a set of stimuli
function MDSprojection = estimateReceptorIdentities(obj, varargin)

    % parse input arguments 

    parser = inputParser;
    parser.addParamValue('demoMode', false, @islogical);
    parser.addParamValue('selectTimeBins', []);
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    parserResults = parser.Results;
    pNames = fieldnames(parserResults);
    for k = 1:length(pNames)
        eval(sprintf('%s = parserResults.%s;', pNames{k}, pNames{k}))
    end
        
    
    [coneRows, coneCols, timeBins] = size(obj.sensorActivationImage);
    totalConesNum = coneRows * coneCols;
      
    if (~isempty(selectTimeBins))
        XTresponse = reshape(obj.sensorActivationImage(:,:,selectTimeBins), [totalConesNum numel(selectTimeBins)]);
    else
        XTresponse = reshape(obj.sensorActivationImage, [totalConesNum timeBins]);
    end
    
    % Compute correlation matrix
    correlationMatrix = corrcoef(XTresponse');
    
    % extract a metric of distance from the correlation matrix
    % the higher the correlation, the lower the distance
    D = -log((correlationMatrix+1.0)/2.0);  % Benson's distance  metric from correlation
    %D = 1.0 - (correlationMatrix+1.0)/2.0;  % My (linear) distance metric from correlation
    
    % ensure D is symmetric
    if ~issymmetric(D)
        D = 0.5*(D+D');
    end
    
    % Do MDS scaling in 3 dimensions
    dimensionsNum = 3;
    [MDSprojection,stress] = mdscale(D,dimensionsNum);
end

