function [imageRGB, belowGamut, aboveGamut, imageLuminance] = LMStoRGBforSpecificDisplay(imageLMS, renderingDisplay, boostFactor, displayGamma, beVerbose)
    % To Cal format for faster computation
    [tmpLMS, nCols, mRows] = ImageToCalFormat(imageLMS);
    
    % To linear RGB coords
    tmpRGB = tmpLMS' * inv(displayGet(renderingDisplay, 'rgb2lms'));
    
    % To XYZ tristim coords
    tmpXYZ = tmpRGB * displayGet(renderingDisplay, 'rgb2xyz');
    
    % Extract luma component, and reshape it in image format
    imageLuminance = CalFormatToImage((squeeze(tmpXYZ(:,2)))', nCols, mRows);

    % Compute out-of-gamut pixels
    for channelIndex = 1:3
        belowGamut(channelIndex) = numel(find(squeeze(tmpRGB(:,channelIndex)) < 0));
        aboveGamut(channelIndex) = numel(find(squeeze(tmpRGB(:,channelIndex)) > 1));
    end
    
    % Reshape to image format
    imageRGB = CalFormatToImage(tmpRGB', nCols, mRows);
    
    % Apply boost factor - this is > 1 for optical images, because they are
    % much darker than the scenes
    imageRGB  = imageRGB  * boostFactor;
    
    % Clip above and below
    imageRGB(imageRGB<0) = 0;
    imageRGB(imageRGB>1) = 1;
    
    % Apply gamma for display
    imageRGB =  imageRGB .^ displayGamma;
    
    % Feedback
    if (beVerbose) && ((any(belowGamut)) || (any(aboveGamut)))
        fprintf('RED   pixels above gamut: %d (below gamut: %d)\n', aboveGamut(1), belowGamut(1));
        fprintf('GREEN pixels above gamut: %d (below gamut: %d)\n', aboveGamut(2), belowGamut(2));
        fprintf('BLUE  pixels above gamut: %d (below gamut: %d)\n', aboveGamut(3), belowGamut(3));
    end
end