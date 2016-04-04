function [imageCMF, clippedPixelsNum, luminanceRange] = XYZtoSRGB(imageCMF, clipLuminance)
    [tmp, nCols, mRows] = ImageToCalFormat(imageCMF);
    
    xyY = XYZToxyY(tmp);
    luma = 683*squeeze(xyY(3,:));
    clippedPixelsNum = 0;
    luminanceRange = [min(luma(:)) max(luma(:))];
    
    if (~isempty(clipLuminance))
        % clip luminance
        indices = find(luma>clipLuminance);
        luma(indices) = clipLuminance;
        clippedPixelsNum = numel(indices);
        xyY(3,:) = luma/683;
        tmp = xyYToXYZ(xyY);
    end

    tmp = XYZToSRGBPrimary(tmp);
    imageCMF = CalFormatToImage(tmp, nCols, mRows);
end
