function osWindowBefore(os, sensor, oi)

    opticalImageRGBrendering = oiGet(oi, 'rgb image');
    opticalSampleSeparation  = oiGet(oi, 'distPerSamp','microns');
    oiSpatialSupport = oiGet(oi,'spatial support','microns');
    
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    sensorRowsCols = sensorGet(sensor, 'size');
    [R,C] = meshgrid(1:sensorRowsCols(1), 1:sensorRowsCols(2));
    sensorXsamplingGrid = (C(:)-0.5) * sensorSampleSeparationInMicrons(1);
    sensorYsamplingGrid = (R(:)-0.5) * sensorSampleSeparationInMicrons(2);
    
    dx = sensorRowsCols(2) * sensorSampleSeparationInMicrons(2);
    dy = sensorRowsCols(1) * sensorSampleSeparationInMicrons(1);
    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * dx/2;
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * dy/2;
    sensorPositionsInMicrons = bsxfun(@times, sensorGet(sensor,'positions'), sensorSampleSeparationInMicrons);
    
        
    xGrid = squeeze(oiSpatialSupport(:,:,1));
    yGrid = squeeze(oiSpatialSupport(:,:,2));
    opticalImageXdata = squeeze(xGrid(1,:));  % x-positions from 1st row
    opticalImageYdata = squeeze(yGrid(:,1));  % y-positions from 1st col
     
    % display a subsampled version of the optical image to save time
    opticalImageSubsampledXdata = opticalImageXdata(1):2:opticalImageXdata(end);
    opticalImageSubsampledYdata = opticalImageYdata(1):2:opticalImageYdata(end);
    opticalImageSubsampledRGBrendering = opticalImageRGBrendering(1:2:end, 1:2:end,:);
    
    hFig = figure(1000);
    figSize = [1024 1200];
    set(hFig, 'Position', [10 10 figSize(1) figSize(2)]);
    imageWidthToHeightRatio = size(opticalImageRGBrendering,2) / size(opticalImageRGBrendering,1);
    
    axesStruct = generateAxes(hFig, figSize, imageWidthToHeightRatio);
    
    size(sensorPositionsInMicrons,1)
    % circle around all sensor positions
    while (1)
        
        for whichPosition = 1:2:size(sensorPositionsInMicrons,1)
        
            tic
            currentSensorPosition = sensorPositionsInMicrons(whichPosition,:);
        
            % find image pixels falling within the sensor outline
            pixelIndices = find(...
                (xGrid >= currentSensorPosition(1) - dx*0.6) & (xGrid <= currentSensorPosition(1) + dx*0.6) & ...
                (yGrid >= currentSensorPosition(2) - dy*0.6) & (yGrid <= currentSensorPosition(2) + dy*0.6) );
            [rows, cols] = ind2sub(size(xGrid), pixelIndices);
        
        
            rowRange = min(rows):1:max(rows);
            colRange = min(cols):1:max(cols);
            sensorSampledOpticalImage = opticalImageRGBrendering(rowRange,colRange,:);
            xGridSubset = xGrid(rowRange, colRange);
            yGridSubset = yGrid(rowRange, colRange);
            sensorViewXdata = squeeze(xGridSubset(1,:));
            sensorViewYdata = squeeze(yGridSubset(:,1));
        
            if (whichPosition == 1)
                % draw the optical image
                [p1,p2] = displayOpticalImageAndSensorPosition(axesStruct.opticalImageAxes, opticalImageSubsampledXdata, opticalImageSubsampledYdata, opticalImageSubsampledRGBrendering, currentSensorPosition, sensorOutlineInMicrons);
            end
            
            % update sensor position
            displayUpdatedSensorPosition(p1,p2,currentSensorPosition, sensorOutlineInMicrons);
        
        
            if (whichPosition == 1)
                % draw the sensor view
                [s1, s2] = displaySensorView(axesStruct.sensorViewAxes, sensorViewXdata, sensorViewYdata, sensorSampledOpticalImage, currentSensorPosition, sensorXsamplingGrid, sensorYsamplingGrid, dx, dy);
            else
                updateSensorView(axesStruct.sensorViewAxes, s1,s2, sensorViewXdata, sensorViewYdata, sensorSampledOpticalImage, currentSensorPosition, sensorXsamplingGrid, sensorYsamplingGrid, dx, dy);
            end
            drawnow;
            toc
        
    end
    end

end

function [s1, s2] = displaySensorView(sensorViewAxes, xData, yData, sensorSampledOpticalImage, currentSensorPosition, sensorXsamplingGrid, sensorYsamplingGrid, dx, dy)
    cla(sensorViewAxes)
    s1 = image('XData', xData, 'YData', yData, 'CData', sensorSampledOpticalImage, 'parent', sensorViewAxes);
    hold(sensorViewAxes, 'on');
    xpos = currentSensorPosition(1) -dx/2 +  sensorXsamplingGrid;
    ypos = currentSensorPosition(2) -dy/2 +  sensorYsamplingGrid;
    s2 = plot(sensorViewAxes, xpos, ypos, 'w+', 'MarkerSize', 8);   
    hold(sensorViewAxes, 'off');
    axis(sensorViewAxes,'ij'); axis(sensorViewAxes,'equal');
    dx = round(dx*0.55); dy = round(dy*0.55);
    set(sensorViewAxes, 'XLim', currentSensorPosition(1) +[-dx dx], 'YLim', currentSensorPosition(2) +[-dy dy], 'XColor', [0 0 0], 'YColor', [0 0 0]);
    set(sensorViewAxes, 'FontSize', 12);
    tickPositions = -2000:20:2000;
    set(sensorViewAxes, 'XTick', tickPositions, 'YTick', tickPositions);
    box(sensorViewAxes, 'on');
    %xlabel(sensorViewAxes, 'microns', 'FontSize', 12); ylabel(sensorViewAxes, 'microns', 'FontSize', 12);
    title(sensorViewAxes, sprintf('position index'), 'Color', [1 1 1], 'FontSize', 14);
end

function updateSensorView(sensorViewAxes, s1,s2, xData, yData, sensorSampledOpticalImage, currentSensorPosition, sensorXsamplingGrid, sensorYsamplingGrid, dx, dy)
    set(s1, 'XData', xData, 'YData', yData, 'CData', sensorSampledOpticalImage);  
    xpos = currentSensorPosition(1) -dx/2 +  sensorXsamplingGrid;
    ypos = currentSensorPosition(2) -dy/2 +  sensorYsamplingGrid;
    set(s2, 'XData', xpos, 'YData', ypos); 
    set(sensorViewAxes, 'XLim', round(currentSensorPosition(1) + 0.55*[-dx dx]), 'YLim', round(currentSensorPosition(2) +0.55*[-dy dy]), 'XColor', [1 1 1], 'YColor', [1 1 1]);
    title(sensorViewAxes, sprintf('position index'), 'Color', [1 1 1], 'FontSize', 14);
end

function [p1,p2] = displayOpticalImageAndSensorPosition(opticalImageAxes, xData, yData, opticalImageRGBrendering, currentSensorPosition, sensorOutlineInMicrons)
    cla(opticalImageAxes)
    image('XData', xData, 'YData', yData, 'CData', opticalImageRGBrendering, 'parent', opticalImageAxes);
    hold(opticalImageAxes, 'on');
    p1 = plot(opticalImageAxes, currentSensorPosition(1) + sensorOutlineInMicrons(:,1), currentSensorPosition(2) + sensorOutlineInMicrons(:,2), 'r-', 'LineWidth', 2);
    p2 = plot(opticalImageAxes, currentSensorPosition(1) + sensorOutlineInMicrons(:,1), currentSensorPosition(2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 1);
    hold(opticalImageAxes, 'off');
    axis(opticalImageAxes,'ij'); axis(opticalImageAxes,'equal');
    set(opticalImageAxes, 'XLim', 0.8*max(abs(xData(:)))*[-1 1], 'YLim', .8*max(abs(yData(:)))*[-1 1])
    set(opticalImageAxes, 'XTick', [], 'YTick', []);
    %xlabel(opticalImageAxes, 'microns'); ylabel(opticalImageAxes, 'microns');
    disp('here');
end

function displayUpdatedSensorPosition(p1,p2,currentSensorPosition, sensorOutlineInMicrons)
    set(p1, 'XData', currentSensorPosition(1) + sensorOutlineInMicrons(:,1), 'YData', currentSensorPosition(2) + sensorOutlineInMicrons(:,2));
    set(p2, 'XData', currentSensorPosition(1) + sensorOutlineInMicrons(:,1), 'YData', currentSensorPosition(2) + sensorOutlineInMicrons(:,2));
end


function axesStruct = generateAxes(hFig, figSize, imageWidthToHeightRatio)
    w = figSize(1); h = figSize(2);
    leftMargin = 5/w;
    opticalImageWidth  = (w-10)/w;
    opticalImageHeight = (w-10)/imageWidthToHeightRatio/h;
    bottomMargin = (h-10)/h - opticalImageHeight - 5/h;
    
    sensorViewWidth = 256/w; sensorViewHeight = 256/w; 
    axesStruct.opticalImageAxes = axes('parent',hFig,'unit','normalized','position',[leftMargin bottomMargin opticalImageWidth opticalImageHeight], 'Color', [0 0 0]);
    axesStruct.sensorViewAxes   = axes('parent',hFig,'unit','normalized','position',[leftMargin+20/w bottomMargin+20/w sensorViewWidth sensorViewHeight], 'Color', [0 0 0]);
end



