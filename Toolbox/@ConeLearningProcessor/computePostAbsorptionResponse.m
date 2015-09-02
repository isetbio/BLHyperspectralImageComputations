function computePostAbsorptionResponse(obj)
                
    tic
    if (strcmp(obj.adaptationModelToUse, 'linear'))
        initialState = riekeInit;
        initialState.timeInterval  = obj.core1Data.sensorTimeInterval;
        initialState.Compress = false;
        obj.adaptedPhotoCurrentXTresponse = riekeLinearCone(obj.photonAbsorptionXTresponse, initialState);

        if (strcmp(obj.noiseFlag, 'RiekeNoise'))
            params.seed = 349573409;
            params.sampTime = obj.core1Data.sensorTimeInterval;
            [obj.adaptedPhotoCurrentXTresponse, ~] = riekeAddNoise(obj.adaptedPhotoCurrentXTresponse, params);
        end
    elseif (strcmp(obj.adaptationModelToUse,'none'))
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
    fprintf('riekeStuff took %f\n', toc);

end

