function computeOuterSegmentResponse(obj, savePrefilteredOuterSegmentResponse)
       
    if (obj.displayComputationTimes)
        tic
    end
    
    if (strcmp(obj.adaptationModel, 'linear'))
        initialState = osInit;  % used to be riekeInit;
        initialState.timeInterval  = obj.core1Data.sensorTimeInterval;
        initialState.Compress = false;
        obj.adaptedPhotoCurrentXTresponse = osLinearCone(obj.photonAbsorptionXTresponse, initialState);  % used to be riekeLinearCone

        if (strcmp(obj.photocurrentNoise, 'RiekeNoise'))
            params.seed = 349573409;
            params.sampTime = obj.core1Data.sensorTimeInterval;
            [obj.adaptedPhotoCurrentXTresponse, ~] = osAddNoise(obj.adaptedPhotoCurrentXTresponse, params); % used to be riekeAddNoise
        end
    elseif (strcmp(obj.adaptationModel,'none'))
       obj.adaptedPhotoCurrentXTresponse = obj.photonAbsorptionXTresponse;
    else
       error('Unknown adaptation mode to use (''%s'')', obj.adaptationModelToUse);
    end

    if (savePrefilteredOuterSegmentResponse)
        obj.prefilteredAdaptedPhotoCurrentResponsesForSelectCones = obj.adaptedPhotoCurrentXTresponse(obj.maxResponsiveConeIndices,:);
    end
    
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

