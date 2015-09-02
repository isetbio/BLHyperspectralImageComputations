function computePostAbsorptionResponse(obj)
       
    if (obj.displayComputationTimes)
        tic
    end
    
    if (strcmp(obj.adaptationModel, 'linear'))
        initialState = riekeInit;
        initialState.timeInterval  = obj.core1Data.sensorTimeInterval;
        initialState.Compress = false;
        obj.adaptedPhotoCurrentXTresponse = riekeLinearCone(obj.photonAbsorptionXTresponse, initialState);

        if (strcmp(obj.photocurrentNoise, 'RiekeNoise'))
            params.seed = 349573409;
            params.sampTime = obj.core1Data.sensorTimeInterval;
            [obj.adaptedPhotoCurrentXTresponse, ~] = riekeAddNoise(obj.adaptedPhotoCurrentXTresponse, params);
        end
    elseif (strcmp(obj.adaptationModel,'none'))
       obj.adaptedPhotoCurrentXTresponse = obj.photonAbsorptionXTresponse;
    else
       error('Unknown adaptation mode to use (''%s'')', obj.adaptationModelToUse);
    end

    obj.prefilteredAdaptedPhotoCurrentXTresponse = obj.adaptedPhotoCurrentXTresponse;
    
    % apply pre-correlation filter
    if (~isempty(obj.precorrelationFilter))
        signalLength = size(obj.adaptedPhotoCurrentXTresponse,2);
        for coneIndex = 1:size(obj.adaptedPhotoCurrentXTresponse,1)
            tmp = conv(squeeze(obj.adaptedPhotoCurrentXTresponse(coneIndex,:)), obj.precorrelationFilter);
            obj.adaptedPhotoCurrentXTresponse(coneIndex,:) = tmp(1:signalLength);
        end
    end
    
    if (obj.displayComputationTimes)
        fprintf('Photocurrent computations took %f seconds.\n', toc);
    end
end

