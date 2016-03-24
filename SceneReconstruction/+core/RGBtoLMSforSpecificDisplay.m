function imageLMS = RGBtoLMSforSpecificDisplay(imageRGB, displaySPDs, coneFundamentals)
    [tmp, nCols, mRows] = ImageToCalFormat(imageRGB);
    tmp = (coneFundamentals' * displaySPDs) * tmp;
    imageLMS = CalFormatToImage(tmp, nCols, mRows);
end
