% Method to compute the (time-varying) activation of a sensor mosaic
function computeSensorActivation(obj,varargin)

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
                % unload custom sensor params
                
                params.sz = round(sensorParams.conesAcross*[sensorParams.heightToWidthRatio 1.0]);
                params.rgbDensities = [0.0 0.6 0.3 0.1];  % Empty (missing cone), L, M, S
                params.coneAperture = [5 5]*1e-6;         % 5 microns, (specified in meters)
                
                % Generate sensor for human retina
                pixel = [];
                obj.sensor = sensorCreate('human',pixel,params);
                
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
                    xNodes = floor(oiGet(obj.opticalImage, 'width', 'microns')/sensorGet(obj.sensor, 'width', 'microns')/2*0.7*eyeMovementParams.overlapFactor);
                    yNodes = floor(oiGet(obj.opticalImage, 'height', 'microns')/sensorGet(obj.sensor, 'height', 'microns')/2*0.7*eyeMovementParams.overlapFactor);
                    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); gridXX = gridXX(:); gridYY = gridYY(:);
                    % randomize positions
                    indices = randperm(numel(gridXX));
                    fixationXpos = gridXX(indices); fixationYpos = gridYY(indices);

                    % Initialize positions
                    eyeMovementsNum = eyeMovementParams.samplesPerFixation*numel(-xNodes:xNodes)*numel(-yNodes:yNodes);
                    eyeMovementPositions = zeros(eyeMovementsNum,2);
                    obj.sensor = sensorSet(obj.sensor,'positions', eyeMovementPositions);
            
                    % Generate the eye movement sequence
                    obj.sensor = emGenSequence(obj.sensor);
                    
                    % Add the fixational part
                    fixationalSensorPositions = sensorGet(obj.sensor,'positions');
                    for fixationIndex = 1:numel(fixationXpos)
                        dX = fixationXpos(fixationIndex) * round(sensorParams.conesAcross/eyeMovementParams.overlapFactor);
                        dY = fixationYpos(fixationIndex) * round(sensorParams.conesAcross/eyeMovementParams.overlapFactor);
                        i1 = (fixationIndex-1)*eyeMovementParams.samplesPerFixation + 1;
                        i2 = i1 + eyeMovementParams.samplesPerFixation - 1;
                        fixationalSensorPositions(i1:i2,1) = fixationalSensorPositions(i1:i2,1)+dX;
                        fixationalSensorPositions(i1:i2,2) = fixationalSensorPositions(i1:i2,2)+dY;
                    end
            
                    % update the sensor
                    obj.sensor = sensorSet(obj.sensor,'positions', fixationalSensorPositions);
                
               otherwise
                   error('Do not know how to generated eyeMovement ''%s''!', eyeMovementParams.name);
            end
            
        end
          
        % Compute the sensor activation
        obj.sensor = sensorSet(obj.sensor, 'noise flag', 0);
        obj.sensor = coneAbsorptions(obj.sensor, obj.opticalImage);
        obj.sensorActivationImage = sensorGet(obj.sensor, 'volts');
        
        
        % Save computed sensor
        sensor = obj.sensor;
        if (obj.verbosity > 2)
            fprintf('Saving computed sensor to cache file (''%s'').', obj.sensorCacheFileName);
        end
        save(obj.sensorCacheFileName, 'sensor');
        clear 'sensor'
    end
    
    if (visualizeResultsAsIsetbioWindows)
        vcAddAndSelectObject(obj.sensor);
        sensorWindow;
    end
    
    if (visualizeResultsAsImages) || (generateVideo)
        VisualizeResults(obj, generateVideo);
    end    
end


function VisualizeResults(obj, generateVideo)
        
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

    h = figure();
    set(h, 'Position', [10 100 1260 770], 'Color', [0 0 0]);

    % Show the optical image
    subplot('Position', [0.42 0.30 0.59 0.68]);
    imagesc(opticalImageXposInMicrons, opticalImageYposInMicrons, opticalImageRGBrendering);
    hold on;
    set(gca, 'XTick', [-2000:200:2000], 'YTick', [-2000:200:2000], 'XLim', [opticalImageXposInMicrons(1) opticalImageXposInMicrons(end)], 'YLim', [opticalImageYposInMicrons(1) opticalImageYposInMicrons(end)]);
    set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
    xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);

    if (generateVideo)
        % Setup video stream
        writerObj = VideoWriter('SensorResponse.m4v', 'MPEG-4'); % H264 format
        writerObj.FrameRate = 60; 
        writerObj.Quality = 100;
        % Open video stream
        open(writerObj); 
    end

    % show the activation at each time step
    for k = 1:size(sensorNormalizedActivation,3)

        % 2D ensor activation 
        subplot('Position', [0.05 0.30 0.30 0.68]);

        imageAplitude = (squeeze(sensorNormalizedActivation(:,:,k))).^0.75;
        rgbImage(:,:,1) = imageAplitude .* maskLcones;
        rgbImage(:,:,2) = imageAplitude .* maskMcones;
        rgbImage(:,:,3) = imageAplitude .* maskScones;
        rgbImageXT(:,k,:) = reshape(rgbImage, [size(rgbImage,1)*size(rgbImage,2) 3]);
        imagesc((1:sensorRowsCols(2))*sensorSampleSeparationInMicrons(1), (1:sensorRowsCols(1))*sensorSampleSeparationInMicrons(2), rgbImage, [0 1]);

        set(gca, 'XTick', [0:50:1000], 'YTick', [0:50:1000]);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'FontSize', 12);
        axis 'image'
        xlabel('microns', 'FontSize', 14); ylabel('microns', 'FontSize', 14);
        colormap(hot(512));


        % Sensor location on the optical image
        subplot('Position', [0.42 0.30 0.59 0.68]);
        % plot the sensor position
        plot(-sensorPositionsInMicrons(k,1) + sensorOutlineInMicrons(:,1), sensorPositionsInMicrons(k,2) + sensorOutlineInMicrons(:,2), 'k-');
        axis 'image'

        % Update the X-T response
        subplot('Position', [0.05 0.05 0.92 0.20]);
        imagesc(rgbImageXT);
        set(gca, 'XColor', [0.8 0.8 0.6], 'YColor', [0.8 0.8 0.6], 'YTick', [], 'FontSize', 12);
        xlabel('time', 'FontSize', 14); ylabel('mosaic activation', 'FontSize', 14);
        drawnow;

        if (generateVideo)
            % add a frame to the video stream
            frame = getframe(gcf);
            writeVideo(writerObj, frame);
        end
    end

    if (generateVideo)
        % close video stream and save movie
        close(writerObj);
    end
end
