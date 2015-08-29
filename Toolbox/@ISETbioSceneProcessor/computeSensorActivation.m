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
        parser.addParamValue('showEyeMovementCoverage', false, @islogical);
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
                
                % Generate custom cone
                pixel = sensorGet(obj.sensor,'pixel');
                pixel = pixelSet(pixel, 'size', [1.0 1.0]*sensorParams.coneAperture);
                obj.sensor  = sensorSet(obj.sensor, 'pixel', pixel);
                
                % Generate custom cone mosaic
                coneMosaic = coneCreate();
                coneMosaic = coneSet(coneMosaic, 'spatial density', [0.0 sensorParams.LMSdensities(1) sensorParams.LMSdensities(2) sensorParams.LMSdensities(3)]);  % Empty (missing cone), L, M, S
                obj.sensor = sensorCreateConeMosaic(obj.sensor,coneMosaic);
                
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
                    
               case 'saccadicEyeMovements'  
                   % Compute number of saccadic positions to cover the
                   % image with the desired overlap factor
                    xNodes = floor(0.35*oiGet(obj.opticalImage, 'width', 'microns')/sensorGet(obj.sensor, 'width', 'microns')*eyeMovementParams.overlapFactor);
                    yNodes = floor(0.35*oiGet(obj.opticalImage, 'height', 'microns')/sensorGet(obj.sensor, 'height', 'microns')*eyeMovementParams.overlapFactor);
                    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); gridXX = gridXX(:); gridYY = gridYY(:);
                    % randomize positions
                    indices = randperm(numel(gridXX));
                    %indices = 1:numel(gridXX);
                    saccadicXpos = gridXX(indices); saccadicYpos = gridYY(indices);

                    % Initialize positions
                    eyeMovementsNum = eyeMovementParams.samplesPerFixation*numel(-xNodes:xNodes)*numel(-yNodes:yNodes);
                    obj.sensor = sensorSet(obj.sensor,'positions', zeros(eyeMovementsNum,2));
            
                    % Generate the eye movement sequence
                    obj.sensor = emGenSequence(obj.sensor);
                    
                    % Add the saccadic eye movement component
                    sensorPositions = sensorGet(obj.sensor,'positions');
                    fx = round(sensorParams.conesAcross/eyeMovementParams.overlapFactor);
                    for saccadicIndex = 1:numel(saccadicXpos)
                        i1 = (saccadicIndex-1)*eyeMovementParams.samplesPerFixation + 1;
                        i2 = i1 + eyeMovementParams.samplesPerFixation - 1;
                        sensorPositions(i1:i2,1) = sensorPositions(i1:i2,1) + saccadicXpos(saccadicIndex) * fx;
                        sensorPositions(i1:i2,2) = sensorPositions(i1:i2,2) + saccadicYpos(saccadicIndex) * fx;
                    end
            
                    % update the sensor
                    obj.sensor = sensorSet(obj.sensor,'positions', sensorPositions);
                
               otherwise
                   error('Do not know how to generated eyeMovement ''%s''!', eyeMovementParams.name);
            end
            
        end
          
        drawFirst500millisecondsOfEyeMovements = false;
        if (drawFirst500millisecondsOfEyeMovements)
            figure(99);
            clf;
            positions = sensorGet(obj.sensor,'positions');
            time = [1:size(positions,1)]*sensorGet(obj.sensor, 'time interval');
            plot(time, positions(:,1), 'r.'); hold on;
            plot(time, positions(:,2), 'b.'); hold on;
            set(gca, 'XLim', [0 500*sensorGet(obj.sensor, 'time interval')]);
            xlabel('time (ms)');
            title('first 500 mseconds of eye movements');
            drawnow;
        end
        
        % Compute the sensor activation
        obj.sensor = sensorSet(obj.sensor, 'noise flag', sensorParams.noiseFlag);
        obj.sensor = coneAbsorptions(obj.sensor, obj.opticalImage);
        
        obj.sensorActivationImage = sensorGet(obj.sensor, 'volts');
        
        [coneRows, coneCols, timeBins] = size(obj.sensorActivationImage);
        totalConesNum = coneRows * coneCols;
        XTresponse = reshape(obj.sensorActivationImage, [totalConesNum timeBins]);
    
        if (showEyeMovementCoverage)
            showEyeMovementCoverageImage(obj);
        end
        
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
      
end


function showEyeMovementCoverageImage(obj)
    disp('Computing eye movement coverage ...');
    pause(0.1);
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
