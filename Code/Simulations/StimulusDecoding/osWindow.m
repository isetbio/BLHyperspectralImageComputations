function osWindow(os, sensor, oi)

    opticalImageRGBrendering = oiGet(oi, 'rgb image');
    opticalSampleSeparation  = oiGet(oi, 'distPerSamp','microns');
    oiSpatialSupport = oiGet(oi,'spatial support','microns');
    
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    sensorRowsCols = sensorGet(sensor, 'size');
    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparationInMicrons(1);
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparationInMicrons(2);
    
    sensorPositionsInMicrons = bsxfun(@times, sensorGet(sensor,'positions'), sensorSampleSeparationInMicrons);
    
    xGrid = squeeze(oiSpatialSupport(:,:,1));
    yGrid = squeeze(oiSpatialSupport(:,:,2));
    xdata = squeeze(oiSpatialSupport(1,:,1));
    ydata = squeeze(oiSpatialSupport(:,1,2));
     
    
    % draw the sensor position (eye movements)
    
    size(sensorPositionsInMicrons,1)
    
    % circle around all positions
    while (1)
    for whichPosition = size(sensorPositionsInMicrons,1):-1:1
        
        figure(1000);
        clf;
        subplot(2,2,1);
    
    
        % draw the optical image
    
        image('XData', xdata, 'YData', ydata, 'CData', opticalImageRGBrendering);
        hold on
        axis 'image'
        xlabel('microns');
        ylabel('microns');
    
        %plot(sensorPositionsInMicrons(:,1), sensorPositionsInMicrons(:,2), 'r.-');
        plot(sensorPositionsInMicrons(whichPosition,1) + sensorOutlineInMicrons(:,1), sensorPositionsInMicrons(whichPosition,2) + sensorOutlineInMicrons(:,2), 'r-');

        indices = find(...
            (xGrid >= sensorPositionsInMicrons(whichPosition,1) - sensorRowsCols(2) * sensorSampleSeparationInMicrons(1)) & ...
            (xGrid <= sensorPositionsInMicrons(whichPosition,1) + sensorRowsCols(2) * sensorSampleSeparationInMicrons(1)) & ...
            (yGrid >= sensorPositionsInMicrons(whichPosition,2) - sensorRowsCols(1) * sensorSampleSeparationInMicrons(2)) & ...
            (yGrid <= sensorPositionsInMicrons(whichPosition,2) + sensorRowsCols(1) * sensorSampleSeparationInMicrons(2)) );
   
        [rows, cols] = ind2sub(size(xGrid), indices);
        rowRange = min(rows):max(rows);
        colRange = min(cols):max(cols);
   
        sensorSampledOpticalImage = opticalImageRGBrendering(rowRange,colRange,:);
        xGrid = xGrid(rowRange, colRange);
        yGrid = yGrid(rowRange, colRange);
   
        subplot(2,2,2);
        image('XData', squeeze(xGrid(1,:)), 'YData', squeeze(yGrid(:,1)), 'CData', sensorSampledOpticalImage);
        hold on;
        for r = 1:sensorRowsCols(1)
           for c = 1:sensorRowsCols(2)
            xpos = sensorPositionsInMicrons(whichPosition,1) +( -sensorRowsCols(2)/2 -0.5 + c) * sensorSampleSeparationInMicrons(1);
            ypos = sensorPositionsInMicrons(whichPosition,2) +( -sensorRowsCols(1)/2 -0.5 + r) * sensorSampleSeparationInMicrons(2);
            plot(xpos, ypos, 'r+');
           end
        end
        axis 'equal'
        axis 'tight'
        hold off
        title(sprintf('movement index: %d', whichPosition));
        drawnow;
        pause(0.5);
    end
    end
    
    
end


