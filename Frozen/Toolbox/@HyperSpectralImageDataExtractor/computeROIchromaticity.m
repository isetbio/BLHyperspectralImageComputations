% Method to compute the mean chromaticity of the  the reference object ROI
function chromaticity = computeROIchromaticity(obj)

    if ((isempty(obj.referenceObjectData.geometry.roiXYpos)) || (isempty(obj.referenceObjectData.geometry.roiSize)))
        chromaticity(1) = nan;
        chromaticity(2) = nan;
        return;
    end
    
    cols = obj.referenceObjectData.geometry.roiXYpos(1) + (-obj.referenceObjectData.geometry.roiSize(1):obj.referenceObjectData.geometry.roiSize(1));
    rows = obj.referenceObjectData.geometry.roiXYpos(2) + (-obj.referenceObjectData.geometry.roiSize(2):obj.referenceObjectData.geometry.roiSize(2));
    
    % Make sure rows,cols are inside image limits
    cols = cols(find(cols >= 1));
    rows = rows(find(rows >= 1));
    cols = cols(find(cols <= size(obj.sceneXYZmap,2)));
    rows = rows(find(rows <= size(obj.sceneXYZmap,1)));
    
    X = squeeze(obj.sceneXYZmap(rows,cols,1));
    Y = squeeze(obj.sceneXYZmap(rows,cols,2));
    Z = squeeze(obj.sceneXYZmap(rows,cols,3));
    meanX = mean(X(:));
    meanY = mean(Y(:));
    meanZ = mean(Z(:));
    chromaticity(1) = meanX / (meanX+meanY+meanZ);
    chromaticity(2) = meanY / (meanX+meanY+meanZ);
end