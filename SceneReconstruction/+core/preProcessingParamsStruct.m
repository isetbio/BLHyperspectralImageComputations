function preProcessingParams = preProcessingParamsStruct(designMatrixBased, rawResponseBased)
    preProcessingParams = struct(...
        'designMatrixBased', designMatrixBased, ...                                  % 0: nothing, 1:centering, 2:centering+norm, 3:centering+norm+whitening
        'rawResponseBased', rawResponseBased, ...                                    % 0: nothing, 1:centering, 2:centering+norm,
        'useIdenticalPreprocessingOperationsForTrainingAndTestData', true, ...
        'thresholdVarianceExplainedForWhiteningMatrix', 100 ...
    );
    
    if ((preProcessingParams.designMatrixBased > 0) && (preProcessingParams.rawResponseBased > 0))
        error('Choose preprocessing of either the raw responses OR of the design matrix, NOT BOTH');
    end
end