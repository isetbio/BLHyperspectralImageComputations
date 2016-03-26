function imageLumMap = displayRGBtoLuminanceforSpecificDisplay(imageRGB, RGBtoXYZ)
    [tmp, nCols, mRows] = ImageToCalFormat(imageRGB);
    tmp = RGBtoXYZ * tmp;
    imageXYZ = CalFormatToImage(tmp, nCols, mRows);
    imageLumMap = squeeze(imageXYZ(:,:,2));
end