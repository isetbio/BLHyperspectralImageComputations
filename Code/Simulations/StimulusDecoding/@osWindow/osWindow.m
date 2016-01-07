classdef osWindow < handle
    
    properties (Dependent)
        oi
        sensor
        os
    end
    
    properties (Access = private)
        
        oiPrivate;
        osPrivate;
        sensorPrivate; 
        
        % figure handle
        hFig;
        
        lastFigWidth = 0;
        lastFigHeight = 0;
        
        % struct containing all the figure axes
        axesStruct;
        
        % the time slider uicontrol
        timeSlider;
        
        % Optical image - related properties
        % - struct with handles to overlay plots for the optical image
        opticalImageOverlayPlots;
        
        % - RGB rendering of the optical image
        opticalImageRGBrendering;
        opticalImageRGBrenderingFullRes;
        
        % - X- and Y-axis for optical image (in microns)
        opticalImageXdata;
        opticalImageYdata;
        opticalImageXgrid;
        opticalImageYgrid;
        
        % Sensor - related properties
        sensorOutlineInMicrons;
        sensorSizeInMicrons
        sensorPositionsInMicrons;
        
        % - X- and Y-axis for sensor (in microns)
        % - struct with handles to overlay plots for the sensor view image
        sensorViewOverlayPlots;
        sensorViewXdata;
        sensorViewYdata;
        sensorViewOpticalImage;
        sensorXsamplingGrid;
        sensorYsamplingGrid;
    end
    
    % Public API
    methods
        % Constructor
        function obj = osWindow(os, sensor, oi)
            
            obj.init(); 
            
            obj.oi = oi;
            obj.os = os;
            obj.sensor = sensor;
            
            % whenever we set a new oi, sensor, we re-generate the different figure handles
            obj.generateAxesAndControls();
            
            obj.initOpticalImageDisplay();
            obj.initSensorViewDisplay();
        end % constructor

    
        function initSensorViewDisplay(obj)
            positionIndex = 1;
            currentSensorPosition = squeeze(obj.sensorPositionsInMicrons(positionIndex,:));
            obj.findImagePixelsUnderSensor(currentSensorPosition);
            
            cla(obj.axesStruct.sensorViewAxes);
            obj.sensorViewOverlayPlots.p1 = image('XData', obj.sensorViewXdata, 'YData', obj.sensorViewYdata, 'CData', obj.sensorViewOpticalImage, 'parent', obj.axesStruct.sensorViewAxes);
            hold(obj.axesStruct.sensorViewAxes, 'on');
            xpos = currentSensorPosition(1) -obj.sensorSizeInMicrons(1)/2 +  obj.sensorXsamplingGrid;
            ypos = currentSensorPosition(2) -obj.sensorSizeInMicrons(2)/2 +  obj.sensorYsamplingGrid;
            obj.sensorViewOverlayPlots.p2  = plot(obj.axesStruct.sensorViewAxes, xpos, ypos, 'w+', 'MarkerSize', 8);
            hold(obj.axesStruct.sensorViewAxes, 'off');
            axis(obj.axesStruct.sensorViewAxes,'ij'); axis(obj.axesStruct.sensorViewAxes,'equal');
            
            set(obj.axesStruct.sensorViewAxes, ...
                 'XLim', round(currentSensorPosition(1) + obj.sensorSizeInMicrons(1)*0.55*[-1 1]), ...
                 'YLim', round(currentSensorPosition(2) + obj.sensorSizeInMicrons(2)*0.55*[-1 1]), ...
                 'XColor', [0 0 0], 'YColor', [0 0 0]);
            set(obj.axesStruct.sensorViewAxes, 'FontSize', 12);
            tickPositions = -2000:20:2000;
            set(obj.axesStruct.sensorViewAxes, 'XTick', tickPositions, 'YTick', tickPositions);
            box(obj.axesStruct.sensorViewAxes, 'on');
        end
        
        function updateSensorViewDisplay(obj, kPos)
            currentSensorPosition = squeeze(obj.sensorPositionsInMicrons(kPos,:));
            obj.findImagePixelsUnderSensor(currentSensorPosition);
            set(obj.sensorViewOverlayPlots.p1, 'XData', obj.sensorViewXdata, 'YData', obj.sensorViewYdata, 'CData', obj.sensorViewOpticalImage);  
            xpos = currentSensorPosition(1) -obj.sensorSizeInMicrons(1)/2 +  obj.sensorXsamplingGrid;
            ypos = currentSensorPosition(2) -obj.sensorSizeInMicrons(2)/2 +  obj.sensorYsamplingGrid;
            set(obj.sensorViewOverlayPlots.p2, 'XData', xpos, 'YData', ypos); 
            set(obj.axesStruct.sensorViewAxes, ...
                 'XLim', round(currentSensorPosition(1) + obj.sensorSizeInMicrons(1)*0.55*[-1 1]), ...
                 'YLim', round(currentSensorPosition(2) + obj.sensorSizeInMicrons(2)*0.55*[-1 1]));
             
            title(obj.axesStruct.sensorViewAxes, sprintf('position index: %d', kPos), 'Color', [1 1 1], 'FontSize', 14);
        end
        
        function findImagePixelsUnderSensor(obj,currentSensorPosition)
            % find image pixels falling within the sensor outline
            pixelIndices = find(...
                (obj.opticalImageXgrid >= currentSensorPosition(1) - obj.sensorSizeInMicrons(1)*0.6) & ...
                (obj.opticalImageXgrid <= currentSensorPosition(1) + obj.sensorSizeInMicrons(1)*0.6) & ...
                (obj.opticalImageYgrid >= currentSensorPosition(2) - obj.sensorSizeInMicrons(2)*0.6) & ...
                (obj.opticalImageYgrid <= currentSensorPosition(2) + obj.sensorSizeInMicrons(2)*0.6) );
            [rows, cols] = ind2sub(size(obj.opticalImageXgrid), pixelIndices);
            
            rowRange = min(rows):1:max(rows);
            colRange = min(cols):1:max(cols);
            obj.sensorViewOpticalImage = obj.opticalImageRGBrenderingFullRes(rowRange,colRange,:);
            xGridSubset = obj.opticalImageXgrid(rowRange, colRange);
            yGridSubset = obj.opticalImageYgrid(rowRange, colRange);
            obj.sensorViewXdata = squeeze(xGridSubset(1,:));
            obj.sensorViewYdata = squeeze(yGridSubset(:,1));
        end
        
        function initOpticalImageDisplay(obj)  
            positionIndex = 1;
            currentSensorPosition = squeeze(obj.sensorPositionsInMicrons(positionIndex,:));
            
            cla(obj.axesStruct.opticalImageAxes);
            image('XData', obj.opticalImageXdata, 'YData', obj.opticalImageYdata, 'CData', ...
                  obj.opticalImageRGBrendering, 'parent', obj.axesStruct.opticalImageAxes);
            hold(obj.axesStruct.opticalImageAxes, 'on');
            obj.opticalImageOverlayPlots.p1 = plot(obj.axesStruct.opticalImageAxes, currentSensorPosition(1) + obj.sensorOutlineInMicrons(:,1), currentSensorPosition(2) + obj.sensorOutlineInMicrons(:,2), 'r-', 'LineWidth', 2);
            obj.opticalImageOverlayPlots.p2 = plot(obj.axesStruct.opticalImageAxes, currentSensorPosition(1) + obj.sensorOutlineInMicrons(:,1), currentSensorPosition(2) + obj.sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 1);
            hold(obj.axesStruct.opticalImageAxes, 'off');
            axis(obj.axesStruct.opticalImageAxes,'ij'); axis(obj.axesStruct.opticalImageAxes,'equal');
            set(obj.axesStruct.opticalImageAxes, 'XLim', 0.8*max(abs(obj.opticalImageXdata(:)))*[-1 1], 'YLim', .8*max(abs(obj.opticalImageYdata(:)))*[-1 1])
            set(obj.axesStruct.opticalImageAxes, 'XTick', [], 'YTick', []);
        end
        
        function updateOpticalImageDisplay(obj, kPos)
            currentSensorPosition = squeeze(obj.sensorPositionsInMicrons(kPos,:));
            set(obj.opticalImageOverlayPlots.p1, 'XData', currentSensorPosition(1) + obj.sensorOutlineInMicrons(:,1), 'YData', currentSensorPosition(2) + obj.sensorOutlineInMicrons(:,2));
            set(obj.opticalImageOverlayPlots.p2, 'XData', currentSensorPosition(1) + obj.sensorOutlineInMicrons(:,1), 'YData', currentSensorPosition(2) + obj.sensorOutlineInMicrons(:,2));
        end
        
        function set.os(obj, os)
            % generate our private copy of the outer segment
            obj.osPrivate = os;
        end
        
        function set.sensor(obj, sensor)
            % generate our private copy of the outer segment
            obj.sensorPrivate = sensor;
            
            % compute sensor positions in microns
            sensorSampleSeparationInMicrons = sensorGet(obj.sensorPrivate,'pixel size','um');
            obj.sensorPositionsInMicrons = bsxfun(@times, sensorGet(sensor,'positions'), sensorSampleSeparationInMicrons);
            
            % compute sensor cone sampling grid
            sensorRowsCols = sensorGet(obj.sensorPrivate, 'size');
            dx = sensorRowsCols(2) * sensorSampleSeparationInMicrons(2);
            dy = sensorRowsCols(1) * sensorSampleSeparationInMicrons(1);
            obj.sensorSizeInMicrons = [dx dy]; 
           
            [R,C] = meshgrid(1:sensorRowsCols(1), 1:sensorRowsCols(2));
            obj.sensorXsamplingGrid = (C(:)-0.5) * sensorSampleSeparationInMicrons(1);
            obj.sensorYsamplingGrid = (R(:)-0.5) * sensorSampleSeparationInMicrons(2);
            obj.sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * dx/2;
            obj.sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * dy/2;
            
        end
        
        function set.oi(obj, oi)
            % generate our private copy of the optical image
            obj.oiPrivate = oi;
            
            % generate RGB rendering of the optical image
            obj.opticalImageRGBrenderingFullRes = oiGet(obj.oiPrivate, 'rgb image');
            
            oiSpatialSupport = oiGet(obj.oiPrivate,'spatial support','microns');
            obj.opticalImageXgrid = squeeze(oiSpatialSupport(:,:,1)); 
            obj.opticalImageYgrid = squeeze(oiSpatialSupport(:,:,2));
            obj.opticalImageXdata = squeeze(obj.opticalImageXgrid(1,:));  % x-positions from 1st row
            obj.opticalImageYdata = squeeze(obj.opticalImageYgrid(:,1));  % y-positions from 1st col
    
            % subsample the optical image by a factor of 2 to speed up display
            k = 2;
            obj.opticalImageXdata = obj.opticalImageXdata(1):k:obj.opticalImageXdata(end);
            obj.opticalImageYdata = obj.opticalImageYdata(1):k:obj.opticalImageYdata(end);
            obj.opticalImageRGBrendering = obj.opticalImageRGBrenderingFullRes(1:k:end, 1:k:end,:);
        end
    
    end
        
    methods (Access = private)  
        function init(obj)
            obj.hFig = figure();
            aspectRatio = 800/1000;
            screenSize = get(0,'ScreenSize');
            screenSize(4) = screenSize(4)/2;
            set(obj.hFig, 'Position',[10 1000 screenSize(4)*aspectRatio screenSize(4)], 'SizeChangedFcn', {@resizeOSwindow, obj, aspectRatio})
        end
        
        function generateAxesAndControls(obj)  
            p = get(obj.hFig, 'Position');
            w = 800;
            h = 1000;
            imageWidthToHeightRatio = size(obj.opticalImageRGBrendering,2) / size(obj.opticalImageRGBrendering,1);
            
            leftMargin = 5/w;
            opticalImageWidth  = (w-10)/w;
            opticalImageHeight = (w-10)/imageWidthToHeightRatio/h;
            bottomMargin = (h-10)/h - opticalImageHeight - 5/h;
    
            % generate plot axes
            sensorViewWidth = 200/w; sensorViewHeight = 200/h; 
            spatiotemporalViewWidth = 500/w; spatiotemporalViewHeight = 200/h;
            spatialViewWidth  = 200/w; spatialViewHeight = 200/h;
            obj.axesStruct.opticalImageAxes = axes('parent',obj.hFig,'unit','normalized','position',[leftMargin bottomMargin opticalImageWidth opticalImageHeight], 'Color', [0 0 0]);
            obj.axesStruct.sensorViewAxes   = axes('parent',obj.hFig,'unit','normalized','position',[leftMargin+20/w bottomMargin+20/h sensorViewWidth sensorViewHeight], 'Color', [0 0 0]);
            
            % generate response time series axes
            obj.axesStruct.spatioTemporalPopulationResponseAxes = axes('parent',obj.hFig,'unit','normalized','position',[leftMargin bottomMargin-spatiotemporalViewHeight-20/h spatiotemporalViewWidth spatiotemporalViewHeight], 'Color', [0 0 0]);
            obj.axesStruct.singleUnitResponseAxes = axes('parent',obj.hFig,'unit','normalized','position',[leftMargin bottomMargin-1.5*spatiotemporalViewHeight-50/h spatiotemporalViewWidth spatiotemporalViewHeight/2], 'Color', [0 0 0]);
            
            % generate 2D instantaneous response axes
            positionVector = [leftMargin+50/w+spatiotemporalViewWidth bottomMargin-1.5*spatiotemporalViewHeight-50/h spatialViewWidth spatialViewHeight];
            obj.axesStruct.spatialPopulationResponseAxes = axes('parent',obj.hFig,'unit','normalized','position', positionVector, 'Color', [0 0 0]);
            
            % generate time slider
            timeSliderLeftMargin = leftMargin;
            timeSliderBottom = (5)/h;
            
            obj.timeSlider = uicontrol(...
                'Parent', obj.hFig,...
                'Style', 'slider',...
                'BackgroundColor', [0.4 0.6 0.9], ...
                'Min', 1, 'Max', size(obj.sensorPositionsInMicrons,1), 'Value', 1,...
                'Units', 'normalized',...
                'Position', [timeSliderLeftMargin, timeSliderBottom 0.99 0.012]);    
           
            % set the slider step
            set(obj.timeSlider, 'SliderStep', 1.0/((obj.timeSlider.Max-obj.timeSlider.Min)*10)*[1 1]);
            
            % set the callback
            addlistener(obj.timeSlider,'ContinuousValueChange', ...
                                      @(hFigure,eventdata) timeSliderCallback(obj.timeSlider,eventdata, obj));                          
        end
        
    end
end

% Callback for figure resizing
function resizeOSwindow(hObject,Event, obj, aspectRatio)
    
    posVector = get(hObject,'Position');
    
    width = posVector(3);
    height = width/aspectRatio;
    
    set(obj.hFig,'Position',[posVector(1:2) width height]);
    
end


% Callback for time slider
function timeSliderCallback(hObject,eventdata, obj)
    currentTimeBin = round(get(hObject,'Value'));
    obj.updateOpticalImageDisplay(currentTimeBin);
    obj.updateSensorViewDisplay(currentTimeBin);
end