function [imageRGB, outsideGamut] = LMStoRGBforSpecificDisplay(imageLMS, displaySPDs, coneFundamentals)
    [tmp, nCols, mRows] = ImageToCalFormat(imageLMS);
    tmp = inv(coneFundamentals' * displaySPDs) * tmp;
    for channelIndex = 1:3
        outsideGamut(channelIndex,1) = numel(find(squeeze(tmp(channelIndex,:)) < 0));
        outsideGamut(channelIndex,2) = numel(find(squeeze(tmp(channelIndex,:)) > 1));
    end
    imageRGB = CalFormatToImage(tmp, nCols, mRows);
end