% Method to compute the mean luminance of the ROI
function roiLuminance = computeROIluminance(obj)

    cols = obj.referenceObjectData.geometry.roiXYpos(1) + (-obj.referenceObjectData.geometry.roiSize(1):obj.referenceObjectData.geometry.roiSize(1));
    rows = obj.referenceObjectData.geometry.roiXYpos(2) + (-obj.referenceObjectData.geometry.roiSize(2):obj.referenceObjectData.geometry.roiSize(2));
    v = obj.sceneLuminanceMap(rows,cols);
    roiLuminance = mean(v(:));
end


