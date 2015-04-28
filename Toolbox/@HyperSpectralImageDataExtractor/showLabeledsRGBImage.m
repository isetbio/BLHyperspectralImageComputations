% Method to display an sRGB version of the hyperspectral image with the reference object outlined in red
function showLabeledsRGBImage(obj, clipLuminance, gammaValue)

    % To cal format for fast computations
    [sceneXYZcalFormat, nCols, mRows] = ImageToCalFormat(obj.sceneXYZmap);
    
    % Clip luminance
    scenexyYcalFormat = XYZToxyY(sceneXYZcalFormat);
    lumaChannel = obj.wattsToLumens * scenexyYcalFormat(3,:);
    lumaChannel(lumaChannel > clipLuminance) = clipLuminance;
    scenexyYcalFormat(3,:) = lumaChannel/obj.wattsToLumens;
    sceneXYZcalFormat = xyYToXYZ(scenexyYcalFormat);
    
    % Compute sRGB image
    [sRGBcalFormat,M] = XYZToSRGBPrimary(sceneXYZcalFormat/max(sceneXYZcalFormat(:)));
    sRGBimage = CalFormatToImage(sRGBcalFormat, nCols, mRows);

    % Report out of gamut pixels
    lessThanZeroPixels = numel(find(sRGBimage(:) < 0));
    greaterThanOnePixels = numel(find(sRGBimage(:) > 1));
    totalPixels = numel(sRGBimage);
    fprintf('\nsRGB image\n\tRange: [%2.2f .. %2.2f]', min(sRGBimage(:)), max(sRGBimage(:)));
    fprintf('\n\tPixels < 0: %d out of %d (%2.3f%%)', lessThanZeroPixels, totalPixels, lessThanZeroPixels/totalPixels*100.0);
    fprintf('\n\tPixels > 1: %d out of %d (%2.3f%%)\n\n', greaterThanOnePixels, totalPixels, greaterThanOnePixels/totalPixels*100.0);

    % To gamut
    sRGBimage(sRGBimage < 0) = 0;
    sRGBimage(sRGBimage > 1) = 1;
    
    % Apply inverted gamma table
    sRGBimage = sRGBimage .^ (1/gammaValue);   
 
    % Label reference object
    outlineWidth = 4;
    [rowIndices, colIndices] = indicesForRedRectangle(obj, outlineWidth);
    for k = 1:numel(rowIndices)
        if (mod(k,10) < 5)
            sRGBimage(rowIndices(k), colIndices(k),1) = 1;
            sRGBimage(rowIndices(k), colIndices(k),2) = 0;
            sRGBimage(rowIndices(k), colIndices(k),3) = 0;
        else
            sRGBimage(rowIndices(k), colIndices(k),1) = 0;
            sRGBimage(rowIndices(k), colIndices(k),2) = 0;
            sRGBimage(rowIndices(k), colIndices(k),3) = 1;
        end
    end
    
    % Display it
    figure(2); clf;
    imshow(sRGBimage, 'Border','tight'); truesize;
    title('sRGB image with reference object outlined in red');
    
    % Keep a copy of it
    obj.sRGBimage = sRGBimage;
end

function [rowIndices, colIndices] = indicesForRedRectangle(obj, outlineWidth)
    colIndices = [];
    rowIndices = [];
    
    for k = 1:outlineWidth
        newColIndices = obj.referenceObjectData.geometry.roiXYpos(1) + (-obj.referenceObjectData.geometry.roiSize(1)-outlineWidth:obj.referenceObjectData.geometry.roiSize(1)+outlineWidth);
        newRowIndices = ones(size(newColIndices)) * (obj.referenceObjectData.geometry.roiXYpos(2)-obj.referenceObjectData.geometry.roiSize(2)-k);
        colIndices = [colIndices newColIndices];
        rowIndices = [rowIndices newRowIndices];
    end
    
    for k = 1:outlineWidth
        newColIndices = obj.referenceObjectData.geometry.roiXYpos(1) + (-obj.referenceObjectData.geometry.roiSize(1)-outlineWidth:obj.referenceObjectData.geometry.roiSize(1)+outlineWidth);
        newRowIndices = ones(size(newColIndices)) * (obj.referenceObjectData.geometry.roiXYpos(2)+obj.referenceObjectData.geometry.roiSize(2)+k);
        colIndices = [colIndices newColIndices];
        rowIndices = [rowIndices newRowIndices];
    end
    
    for k = 1:outlineWidth
        newRowIndices = obj.referenceObjectData.geometry.roiXYpos(2) + (-obj.referenceObjectData.geometry.roiSize(2)-outlineWidth:obj.referenceObjectData.geometry.roiSize(2)+outlineWidth);
        newColIndices = ones(size(newRowIndices)) * (obj.referenceObjectData.geometry.roiXYpos(1)-obj.referenceObjectData.geometry.roiSize(1)-k);
        colIndices = [colIndices newColIndices];
        rowIndices = [rowIndices newRowIndices];
    end
    
    for k = 1:outlineWidth
        newRowIndices = obj.referenceObjectData.geometry.roiXYpos(2) + (-obj.referenceObjectData.geometry.roiSize(2)-outlineWidth:obj.referenceObjectData.geometry.roiSize(2)+outlineWidth);
        newColIndices = ones(size(newRowIndices)) * (obj.referenceObjectData.geometry.roiXYpos(1)+obj.referenceObjectData.geometry.roiSize(1)+k);
        colIndices = [colIndices newColIndices];
        rowIndices = [rowIndices newRowIndices];
    end
end



