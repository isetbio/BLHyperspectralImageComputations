function targetCone = getTargetCone(decoder, sensorData, conePositions, targetDecoderXYcoords, decodedContrastIndex, coneIndices)

    targetCone  = getTargetConeCoordsVersion1(sensorData, conePositions, targetDecoderXYcoords, coneIndices);
    targetCone  = getTargetConeCoordsVersion2(decoder, conePositions, targetCone.nearestDecoderRowColCoord, decodedContrastIndex, coneIndices);
end


function s = getTargetConeCoordsVersion1(sensorData, conePositions, targetDecoderPosition, coneIndices)
        % This version finds the cone that is closest to the target decoder position
        if isempty(coneIndices)
            s = [];
            return;
        end
        conePositionsDistanceToTarget = bsxfun(@minus, conePositions(coneIndices,:), targetDecoderPosition);
        coneDistances = sqrt(sum(conePositionsDistanceToTarget.^2, 2));
        [~, theIndex] = min(coneDistances(:));
        closestConeOfSelectedType = coneIndices(theIndex);
        [r,c] = ind2sub([numel(sensorData.spatialSupportY) numel(sensorData.spatialSupportX)], closestConeOfSelectedType);
        
        [X,Y] = meshgrid(sensorData.decodedImageSpatialSupportX, sensorData.decodedImageSpatialSupportY);
        d = sqrt((X-conePositions(closestConeOfSelectedType, 1)).^2 + (Y-conePositions(closestConeOfSelectedType, 2)).^2);
        [~,indexOfClosestDecoder] = min(d(:));
        [dr, rc] = ind2sub(size(X), indexOfClosestDecoder);
        
        s = struct(...
            'rowcolCoord', [r c], ...
            'xyCoord', conePositions(closestConeOfSelectedType,:), ...
            'nearestDecoderRowColCoord', [dr rc]);
        
        fprintf('Before: r=%d c=%d x=%2.1f, y = %2.1f\n', s.rowcolCoord(1), s.rowcolCoord(2), s.xyCoord(1), s.xyCoord(2));
end

function s = getTargetConeCoordsVersion2(decoder, conePositions, targetDecoderRowCol, decodedContrastIndex, coneIndices)
        % This version finds the cone that corresponding to the peak of target decoder's spatial filter
        if isempty(coneIndices)
            s = [];
            return;
        end
        
        spatialFilter = squeeze(decoder.filters(decodedContrastIndex, targetDecoderRowCol(1), targetDecoderRowCol(2),:,:, decoder.peakTimeBins(decodedContrastIndex)));
        [~, peakResponseConeIndex] = max(spatialFilter(:));
        [r,c] = ind2sub(size(spatialFilter), peakResponseConeIndex);
   
        s = struct(...
            'rowcolCoord', [r c], ...
            'xyCoord', conePositions(peakResponseConeIndex,:), ...
            'nearestDecoderRowColCoord', targetDecoderRowCol);
        
        fprintf('After: %d %d \n', s.rowcolCoord(1), s.rowcolCoord(2));
end
