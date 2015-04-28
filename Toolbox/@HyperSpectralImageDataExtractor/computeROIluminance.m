% Method to compute the mean luminance of the reference object ROI
function roiLuminance = computeROIluminance(obj)

    cols = obj.referenceObjectData.geometry.roiXYpos(1) + (-obj.referenceObjectData.geometry.roiSize(1):obj.referenceObjectData.geometry.roiSize(1));
    rows = obj.referenceObjectData.geometry.roiXYpos(2) + (-obj.referenceObjectData.geometry.roiSize(2):obj.referenceObjectData.geometry.roiSize(2));

    % Make sure rows,cols are inside image limits
    cols = cols(find(cols >= 1));
    rows = rows(find(rows >= 1));
    cols = cols(find(cols <= size(obj.sceneLuminanceMap,2)));
    rows = rows(find(rows <= size(obj.sceneLuminanceMap,1)));
    
    v = obj.sceneLuminanceMap(rows,cols);
    roiLuminance = mean(v(:));
end


