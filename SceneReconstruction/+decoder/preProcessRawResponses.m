function [signals, rawResponsePreprocessing] = preProcessRawResponses(signals, preProcessingParams, rawResponsePreprocessing)
    
    if (preProcessingParams.rawResponseBased == 0)
        rawResponsePreprocessing = [];
        return;
    end
    
    if (~isempty(rawResponsePreprocessing))
        if (preProcessingParams.rawResponseBased > 0)
            fprintf('\nCentering raw responses (zero mean)...');
            signals = bsxfun(@minus, signals, rawResponsePreprocessing.centering);
            if (preProcessingParams.rawResponseBased > 1)
                fprintf('\nNormalizing raw responses (unity std.dev.)...');
                signals = bsxfun(@times, signals, rawResponsePreprocessing.scaling);
                if (preProcessingParams.rawResponseBased > 2)
                    fprintf('\nWhitenning raw responses ...');
                    signals = signals';
                    signals = signals * rawResponsePreprocessing.whitening;
                    signals = signals';
                end
            end
        end
    else
        if (preProcessingParams.rawResponseBased > 0)
            fprintf('\nCentering raw responses (zero mean)...');
            rawResponsePreprocessing.centering = mean(signals,2);
            signals = bsxfun(@minus, signals, rawResponsePreprocessing.centering);
            if (preProcessingParams.rawResponseBased > 1)
                fprintf('\nNormalizing raw responses (unity std.dev.)...');
                rawResponsePreprocessing.scaling = 1.0./(sqrt(mean(signals.^2,2)));
                signals = bsxfun(@times, signals, rawResponsePreprocessing.scaling);
                if (preProcessingParams.rawResponseBased > 2)
                    fprintf('\nWhitenning raw responses ...');
                    % Compute whitening operator
                    rawResponsePreprocessing.whitening = decoder.computeWhiteningMatrix(signals', preProcessingParams.thresholdVarianceExplainedForWhiteningMatrix);
                    % Whiten signals
                    signals = ((signals')* rawResponsePreprocessing.whitening)';
                end
            end
        end
    end
    
end
