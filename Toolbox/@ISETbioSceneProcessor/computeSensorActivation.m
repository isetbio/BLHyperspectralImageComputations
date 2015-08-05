% Method to compute the (time-varying) activation of a sensor mosaic
function XTresponse = computeSensorActivation(obj,varargin)

    if (isempty(varargin))
        forceRecompute = true;
    else
        % parse input arguments 
        defaultSensorParams = struct('name', 'human-default', 'userDidNotPassSensorParams', true);
        defaultEyeMovementParams = struct();
        
        parser = inputParser;
        parser.addParamValue('forceRecompute',    true, @islogical);
        parser.addParamValue('randomSeed',        []);
        parser.addParamValue('sensorParams',      defaultSensorParams, @isstruct);
        parser.addParamValue('eyeMovementParams', defaultEyeMovementParams, @isstruct);
        parser.addParamValue('visualizeResultsAsIsetbioWindows', false, @islogical);
        parser.addParamValue('visualizeResultsAsImages', false, @islogical);
        parser.addParamValue('generateVideo', false, @islogical);
        parser.addParamValue('saveSensorToFile', false, @islogical);
        % Execute the parser
        parser.parse(varargin{:});
        % Create a standard Matlab structure from the parser results.
        parserResults = parser.Results;
        pNames = fieldnames(parserResults);
        for k = 1:length(pNames)
            eval(sprintf('%s = parserResults.%s;', pNames{k}, pNames{k}))
        end
        
        if (~isfield(sensorParams, 'userDidNotPassSensorParams'))
            % the user passed an optics params struct, so forceRecompute
            fprintf('Since a sensor params was passed, we will recompute the sensor image.\n');
            forceRecompute = true;
        end
    end
    
    
    if (isempty(randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(randomSeed);
    end
    
    if (forceRecompute == false)
        % Check if a cached sensor image file exists in the path
        if (exist(obj.sensorCacheFileName, 'file'))
            if (obj.verbosity > 2)
                fprintf('Loading computed sensor from cache file (''%s'').', obj.sensorCacheFileName);
            end
            load(obj.sensorCacheFileName, 'sensor');
            obj.sensor = sensor;
            clear 'sensor'
        else
            fprintf('Cached sensor for scene ''%s'' does not exist. Will generate one\n', obj.sceneName);
            forceRecompute = true;
        end
    end
    
    if (forceRecompute)
        switch sensorParams.name
            case 'human-default'
                % Generate a sensor for human foveal vision
                obj.sensor = sensorCreate('human');
                % make it a large sensor, for debugging purposes
                newFOV = 4.0; % degrees
                [obj.sensor, actualFOVafter] = sensorSetSizeToFOV(obj.sensor, newFOV, obj.scene, obj.opticalImage);
                
            case 'humanLMS'
                % Generate custom sensor for human retina
                obj.sensor = sensorCreate('human');
                pixel = sensorGet(obj.sensor,'pixel');
                pixel = pixelSet(pixel, 'size', [1.0 1.0]*sensorParams.coneAperture);
                obj.sensor  = sensorSet(obj.sensor, 'pixel', pixel);
                
                coneP = coneCreate();
                coneP = coneSet(coneP, 'spatial density', [0.0 sensorParams.LMSdensities(1) sensorParams.LMSdensities(2) sensorParams.LMSdensities(3)]);  % Empty (missing cone), L, M, S
                obj.sensor = sensorCreateConeMosaic(obj.sensor,coneP);
                
                % Set the sensor size
                obj.sensor = sensorSet(obj.sensor, 'size', round(sensorParams.conesAcross*[sensorParams.heightToWidthRatio 1.0]));

                % Set the sensor wavelength sampling to that of the opticalimage
                obj.sensor = sensorSet(obj.sensor, 'wavelength', oiGet(obj.opticalImage, 'wavelength'));
                
                % Set the integration time
                obj.sensor = sensorSet(obj.sensor,'exp time', sensorParams.coneIntegrationTime);
                
            otherwise
                error('Do not know how to generated optics ''%s''!', sensorParams.name);
        end
        
        if (~isempty(fieldnames(eyeMovementParams)))
            % create em structure
            obj.eyeMovement = emCreate();
           
            % set sample time
            obj.eyeMovement  = emSet(obj.eyeMovement, 'sample time', eyeMovementParams.sampleTime);
            
            % set tremor amplitude
            obj.eyeMovement = emSet(obj.eyeMovement, 'tremor amplitude', eyeMovementParams.tremorAmplitude);     
         
            % Attach it to the sensor
            obj.sensor = sensorSet(obj.sensor,'eyemove', obj.eyeMovement);

            switch eyeMovementParams.name
               case 'default'
                    % Initialize positions
                    eyeMovementsNum = 1000;
                    eyeMovementPositions = zeros(eyeMovementsNum,2);
                    obj.sensor = sensorSet(obj.sensor,'positions', eyeMovementPositions);
            
                    % Generate the eye movement sequence
                    obj.sensor = emGenSequence(obj.sensor);
                    
               case 'fixationalEyeMovements'  
                   % Compute number of fixational positions to cover the
                   % image with the desired overlap factor
                    xNodes = floor(0.35*oiGet(obj.opticalImage, 'width', 'microns')/sensorGet(obj.sensor, 'width', 'microns')*eyeMovementParams.overlapFactor);
                    yNodes = floor(0.35*oiGet(obj.opticalImage, 'height', 'microns')/sensorGet(obj.sensor, 'height', 'microns')*eyeMovementParams.overlapFactor);
                    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); gridXX = gridXX(:); gridYY = gridYY(:);
                    % randomize positions
                    indices = randperm(numel(gridXX));
                    %indices = 1:numel(gridXX);
                    fixationXpos = gridXX(indices); fixationYpos = gridYY(indices);

                    % Initialize positions
                    eyeMovementsNum = eyeMovementParams.samplesPerFixation*numel(-xNodes:xNodes)*numel(-yNodes:yNodes);
                    eyeMovementPositions = zeros(eyeMovementsNum,2);
                    obj.sensor = sensorSet(obj.sensor,'positions', eyeMovementPositions);
            
                    % Generate the eye movement sequence
                    obj.sensor = emGenSequence(obj.sensor);
                    
                    % Add the fixational part
                    fixationalSensorPositions = sensorGet(obj.sensor,'positions');
                    fx = round(sensorParams.conesAcross/eyeMovementParams.overlapFactor);
                    for fixationIndex = 1:numel(fixationXpos)
                        i1 = (fixationIndex-1)*eyeMovementParams.samplesPerFixation + 1;
                        i2 = i1 + eyeMovementParams.samplesPerFixation - 1;
                        fixationalSensorPositions(i1:i2,1) = fixationalSensorPositions(i1:i2,1) + fixationXpos(fixationIndex) * fx;
                        fixationalSensorPositions(i1:i2,2) = fixationalSensorPositions(i1:i2,2) + fixationYpos(fixationIndex) * fx;
                    end
            
                    % update the sensor
                    obj.sensor = sensorSet(obj.sensor,'positions', fixationalSensorPositions);
                
               otherwise
                   error('Do not know how to generated eyeMovement ''%s''!', eyeMovementParams.name);
            end
            
        end
          
        % Compute the sensor activation
        obj.sensor = sensorSet(obj.sensor, 'noise flag', sensorParams.noiseFlag);
        obj.sensor = coneAbsorptions(obj.sensor, obj.opticalImage);
        
        obj.sensorActivationImage = sensorGet(obj.sensor, 'volts');
        
        [coneRows, coneCols, timeBins] = size(obj.sensorActivationImage);
        totalConesNum = coneRows * coneCols;
        XTresponse = reshape(obj.sensorActivationImage, [totalConesNum timeBins]);
    
        computeEyeMovementCoverageImage(obj);
        
        if (saveSensorToFile)
            % Save computed sensor
            sensor = obj.sensor;
            if (obj.verbosity > 2)
                fprintf('Saving computed sensor to cache file (''%s'').', obj.sensorCacheFileName);
            end
            save(obj.sensorCacheFileName, 'sensor');
        end
        
        clear 'sensor'  
    end
    
    if (visualizeResultsAsIsetbioWindows)
        vcAddAndSelectObject(obj.sensor);
        sensorWindow;
    end
    
    if (visualizeResultsAsImages) || (generateVideo)
        VisualizeResults(obj, XTresponse, generateVideo);
    end    
end


function computeEyeMovementCoverageImage(obj)
    opticalImageRGBrendering = oiGet(obj.opticalImage, 'rgb image');
    selectXPosIndices = 1:2:size(opticalImageRGBrendering,2);
    selectYPosIndices = 1:2:size(opticalImageRGBrendering,1);
        
    opticalImageRGBrendering = oiGet(obj.opticalImage, 'rgb image');
    opticalSampleSeparation  = oiGet(obj.opticalImage, 'distPerSamp','microns');
    % optical image axes in microns
    opticalImageXposInMicrons = (0:size(opticalImageRGBrendering,2)-1) * opticalSampleSeparation(1);
    opticalImageYposInMicrons = (0:size(opticalImageRGBrendering,1)-1) * opticalSampleSeparation(2);
    opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
    opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);
    
    sensorRowsCols = sensorGet(obj.sensor, 'size');
    sensorPositions = sensorGet(obj.sensor,'positions');
    sensorSampleSeparationInMicrons = sensorGet(obj.sensor,'pixel size','um');
    sensorPositionsInMicrons(:,1) = sensorPositions(:,1) * sensorSampleSeparationInMicrons(1);
    sensorPositionsInMicrons(:,2) = sensorPositions(:,2) * sensorSampleSeparationInMicrons(2);

    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparationInMicrons(1);
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparationInMicrons(2);
    
    h = figure(555);
    set(h, 'Position', [10 10 1200 970], 'Color', [0 0 0]);
    clf;
    imagesc(opticalImageXposInMicrons(selectXPosIndices), opticalImageYposInMicrons(selectYPosIndices), opticalImageRGBrendering(selectYPosIndices,selectXPosIndices,:));
    set(gca, 'CLim', [0 1]);    
    hold on;
    k = 1;
    % plot the sensor positions
    plot(-sensorPositionsInMicrons(:,1), sensorPositionsInMicrons(:,2), 'k.');
    for k = 1:size(sensorPositionsInMicrons,1)
        plot(-sensorPositionsInMicrons(k,1) + sensorOutlineInMicrons(:,1), sensorPositionsInMicrons(k,2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 2.0);
    end
    hold off;
    axis 'image'

    set(gca, 'XTick', [-2000:200:2000], 'YTick', [-2000:200:2000], 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)], 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]);
    set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
    xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);
    drawnow;
    pause(1.0)
end


function VisualizeResults(obj, XTresponse, generateVideo)
        
    activationRange = [min(obj.sensorActivationImage(:)) max(obj.sensorActivationImage(:))];
    sensorNormalizedActivation = obj.sensorActivationImage / max(activationRange);

    opticalImageRGBrendering = oiGet(obj.opticalImage, 'rgb image');
    opticalSampleSeparation  = oiGet(obj.opticalImage, 'distPerSamp','microns');

    sensorRowsCols = sensorGet(obj.sensor, 'size');
    sensorPositions = sensorGet(obj.sensor,'positions');
    sensorSampleSeparationInMicrons = sensorGet(obj.sensor,'pixel size','um');
    sensorPositionsInMicrons(:,1) = sensorPositions(:,1) * sensorSampleSeparationInMicrons(1);
    sensorPositionsInMicrons(:,2) = sensorPositions(:,2) * sensorSampleSeparationInMicrons(2);

    sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * sensorRowsCols(2)/2 * sensorSampleSeparationInMicrons(1);
    sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * sensorRowsCols(1)/2 * sensorSampleSeparationInMicrons(2);

    % optical image axes in microns
    opticalImageXposInMicrons = (0:size(opticalImageRGBrendering,2)-1) * opticalSampleSeparation(1);
    opticalImageYposInMicrons = (0:size(opticalImageRGBrendering,1)-1) * opticalSampleSeparation(2);
    opticalImageXposInMicrons = opticalImageXposInMicrons - round(opticalImageXposInMicrons(end)/2);
    opticalImageYposInMicrons = opticalImageYposInMicrons - round(opticalImageYposInMicrons(end)/2);

    coneType = sensorGet(obj.sensor, 'cone type');
    maskLcones = double(coneType == 2);
    maskMcones = double(coneType == 3);
    maskScones = double(coneType == 4);

    % allocate memory for spatiotemporal activation
    rgbImageXT = zeros(size(sensorNormalizedActivation,1)*size(sensorNormalizedActivation,2), size(sensorNormalizedActivation,3), 3);

    h = figure(123);
    set(h, 'Position', [10 100 1440 770], 'Color', [0 0 0]);

    commonSquareSizeX = 0.14;
    commonSquareSizeY = commonSquareSizeX * 1440/770;
    opticalImageSubPlotPosition  = [0.03 0.30 0.47 0.68];
    xtResponseSubPlotPosition    = [0.025 0.05 0.96 0.20];
    
    sensor2DactivationSubPlotPosition        = [0.525 0.51 commonSquareSizeX  commonSquareSizeY ];
    
    actualSensorMosaicSubPlotPosition        = [0.68 0.69 commonSquareSizeX  commonSquareSizeY ];
    reconstructedSensorMosaicSubPlotPosition = [0.68 0.31 commonSquareSizeX commonSquareSizeY ];  
    MDSDim2SubPlotPosition                   = [0.84 0.69 commonSquareSizeX  commonSquareSizeY ];
    MDSDim3SubPlotPosition                   = [0.84 0.31 commonSquareSizeX commonSquareSizeY ];  
    
    
    

    if (generateVideo)
        % Setup video stream
        writerObj = VideoWriter('SensorResponse.m4v', 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        % Open video stream
        open(writerObj); 
    end

    MDSprojection = [];
    
    % show the activation at each time step
    for k = 1:size(sensorNormalizedActivation,3)

        clf;
        % Show the optical image
        subplot('Position', opticalImageSubPlotPosition);
        selectXPosIndices = 1:2:size(opticalImageRGBrendering,2);
        selectYPosIndices = 1:2:size(opticalImageRGBrendering,1);
        
        imagesc(opticalImageXposInMicrons(selectXPosIndices), opticalImageYposInMicrons(selectYPosIndices), opticalImageRGBrendering(selectYPosIndices,selectXPosIndices,:));
        set(gca, 'CLim', [0 1]);
        hold on;
        % plot the sensor position
        mink = max([1 k-40]);
        plot(-sensorPositionsInMicrons(mink:k,1), sensorPositionsInMicrons(mink:k,2), 'w.-');
        plot(-sensorPositionsInMicrons(1:k,1), sensorPositionsInMicrons(1:k,2), 'k.');
        plot(-sensorPositionsInMicrons(k,1) + sensorOutlineInMicrons(:,1), sensorPositionsInMicrons(k,2) + sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 2.0);
        hold off;
        axis 'image'
        
        set(gca, 'XTick', [-2000:200:2000], 'YTick', [-2000:200:2000], 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)], 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
        xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);
    
        if (k > 30)
           MDSprojection = ISETbioSceneProcessor.estimateReceptorIdentities(XTresponse, 'demoMode', false, 'selectTimeBins', [1:k]);
           MDSprojectionCopy = MDSprojection;
        end

        % 2D ensor activation 
        subplot('Position', sensor2DactivationSubPlotPosition);
        imagesc((1:sensorRowsCols(2))*sensorSampleSeparationInMicrons(1), (1:sensorRowsCols(1))*sensorSampleSeparationInMicrons(2), sensorNormalizedActivation(:,:,k));
        set(gca, 'CLim', [0 1]);
        rgbImageXT(:,k) = reshape(squeeze(sensorNormalizedActivation(:,:,k)), [size(sensorNormalizedActivation,1)*size(sensorNormalizedActivation,2) 1]);
         
        
        
        set(gca, 'XTick', [0:5:1000], 'YTick', [0:5:1000]);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
        axis 'image'
        xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);
        title('sensor activation', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        colormap(hot(512));

        % Update the X-T response
        subplot('Position', xtResponseSubPlotPosition);
        imagesc(rgbImageXT);
        set(gca, 'Clim', [0 1]);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'YTick', [], 'FontSize', 12);
        xlabel('time', 'FontSize', 16, 'FontWeight', 'b'); ylabel('sensor activation', 'FontSize', 16, 'FontWeight', 'b');

        conesToPlot = 20;
        coneSize = 30;
        whiteBackground = false;
        [xyOriginal,coneType, support,spread,delta] = conePlotHelper(obj.sensor, conesToPlot, coneSize);
        [support, spread, delta, coneMosaicImage] = conePlot(xyOriginal,coneType, support,spread,delta,whiteBackground);
        
        subplot('Position', actualSensorMosaicSubPlotPosition);
        imshow(coneMosaicImage);
        axis 'square';
        title('cone mosaic (actual)', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        subplot('Position', reconstructedSensorMosaicSubPlotPosition);
        if (~isempty(MDSprojection))
            % find optimal orientation of xy positions to match the
            % original
            dimA = 1; dimB = 2;
            xy(:,1) =  MDSprojectionCopy(:,dimA);
            xy(:,2) =  MDSprojectionCopy(:,dimB);
            
            rotateThisPlane = true;
            if (rotateThisPlane) && (k > 200)
                A = MDSprojectionCopy; A(:,3) = 0; 
                B = A; B(:,dimA) = xyOriginal(:,1); B(:,dimB) = xyOriginal(:,2);
                [ret_R, ret_t] = rigid_transform_3D(MDSprojectionCopy, B);
                rotatedMDSprojection = (ret_R*A') + repmat(ret_t, 1, size(MDSprojectionCopy,1));
                MDSprojection =  rotatedMDSprojection';
                xy(:,1) =  MDSprojection(:,dimA);
                xy(:,2) =  MDSprojection(:,dimB);
            end
            
            xy = xy / max(abs(xy(:))) * max(abs(xyOriginal(:)));
            [support, spread, delta, dim1vsdim2] = conePlot(xy,coneType, support,spread,delta,whiteBackground);
            for channelIndex = 1:3
                dim1vsdim2(:,:,channelIndex) = dim1vsdim2(:,:,channelIndex)/max(max(max(dim1vsdim2(:,:,channelIndex))));
            end
            
            dim1vsdim2(dim1vsdim2>1) =1;
            imshow(dim1vsdim2);
        end
        set(gca, 'Color', [0 0 0], 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'XTick', [], 'YTick', []);
        box on
        axis 'equal';
        title('d1 x d2', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        subplot('Position', MDSDim2SubPlotPosition);
        if (~isempty(MDSprojection))
            dimA = 1; dimB = 3;
            xy(:,1) =  MDSprojectionCopy(:,dimA);
            xy(:,2) =  MDSprojectionCopy(:,dimB);
            
            rotateThisPlane = false;
            if (rotateThisPlane)
                A = MDSprojectionCopy; A(:,2) = 0; 
                B = A; B(:,dimA) = xyOriginal(:,1); B(:,dimB) = xyOriginal(:,2);
                [ret_R, ret_t] = rigid_transform_3D(MDSprojectionCopy, B);
                rotatedMDSprojection = (ret_R*A') + repmat(ret_t, 1, size(MDSprojectionCopy,1));
                MDSprojection =  rotatedMDSprojection';
                xy(:,1) =  MDSprojection(:,dimA);
                xy(:,2) =  MDSprojection(:,dimB);
            end

            xy = xy / max(abs(xy(:))) * max(abs(xyOriginal(:)));
            [support, spread, delta, dim1vsdim3] = conePlot(xy,coneType, support,spread,delta,whiteBackground);
            dim1vsdim3 = dim1vsdim3;
            for channelIndex = 1:3
                dim1vsdim3(:,:,channelIndex) = dim1vsdim3(:,:,channelIndex)/max(max(max(dim1vsdim3(:,:,channelIndex))));
            end
            dim1vsdim3(dim1vsdim3>1) =1;
            imshow(dim1vsdim3);
        end
        set(gca, 'Color', [0 0 0], 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'XTick', [], 'YTick', []);
        box on
        axis 'equal';
        title('d1 x d3', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        
        subplot('Position', MDSDim3SubPlotPosition);
        if (~isempty(MDSprojection))
            dimA = 2; dimB = 3;
            xy(:,1) =  MDSprojectionCopy(:,dimA);
            xy(:,2) =  MDSprojectionCopy(:,dimB);
            
            rotateThisPlane = false;
            if (rotateThisPlane)
                A = MDSprojectionCopy; A(:,1) = 0; 
                B = A; B(:,dimA) = xyOriginal(:,1); B(:,dimB) = xyOriginal(:,2);
                [ret_R, ret_t] = rigid_transform_3D(MDSprojectionCopy, B);
                rotatedMDSprojection = (ret_R*A') + repmat(ret_t, 1, size(MDSprojectionCopy,1));
                MDSprojection = rotatedMDSprojection';
                xy(:,1) =  MDSprojection(:,dimA);
                xy(:,2) =  MDSprojection(:,dimB);
            end
            xy = xy / max(abs(xy(:))) * max(abs(xyOriginal(:)));
            [support, spread, delta, dim2vsdim3] = conePlot(xy,coneType, support,spread,delta,whiteBackground);
            for channelIndex = 1:3
                dim2vsdim3(:,:,channelIndex) = dim2vsdim3(:,:,channelIndex)/max(max(max(dim2vsdim3(:,:,channelIndex))));
            end
            dim2vsdim3(dim2vsdim3>1) =1;
            imshow(dim2vsdim3);
        end
        set(gca, 'Color', [0 0 0], 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'XTick', [], 'YTick', []);
        axis 'equal';
        box on
        title('d2 x d3', 'FontSize', 14, 'Color', [0.8 0.8 0.6]);
        
        drawnow;
        
        if (generateVideo)
            
            reason(1) = (k < 1000);
            reason(2) = (mod(k-1, 20) == 0) && (k >= 1000);
            reason(3) = (mod(k-1, 40) == 0) && (k >= 2000);
            reason(4) = (mod(k-1, 60) == 0) && (k >= 4000);
            reason(5) = (mod(k-1, 80) == 0) && (k >= 8000);
            reason(6) = (mod(k-1, 100) == 0) && (k >= 10000);
            reason(7) = (k == size(sensorNormalizedActivation,3));
            
            if (reason(6))
                reason(1:5) = false;
            elseif (reason(5))
                reason(1:4) = false;
            elseif (reason(4))
                reason(1:3) = false;
            elseif (reason(3))
                reason(1:2) = false;
            elseif (reason(2))
                reason(1) = false;
            end

            if (any(reason))
                % add a frame to the video stream
                frame = getframe(gcf);
                writeVideo(writerObj, frame);
                fprintf('Added frame at k = %d\n', k);
            end
        end
    end

    if (generateVideo)
        % close video stream and save movie
        close(writerObj);
    end
end


function [R,t] = rigid_transform_3D(A, B)
    centroid_A = mean(A);
    centroid_B = mean(B);

    N = size(A,1);

    H = (A - repmat(centroid_A, N, 1))' * (B - repmat(centroid_B, N, 1));

    [U,S,V] = svd(H);

    R = V*U';

    if det(R) < 0
        %fprintf('Reflection detected\n');
        V(:,3) = V(:,3) * (-1);
        R = V*U';
    end

    t = -R*centroid_A' + centroid_B';
end

