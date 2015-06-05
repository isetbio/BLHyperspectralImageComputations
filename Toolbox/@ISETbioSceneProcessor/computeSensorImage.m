% Method to compute the sensor image
function computeSensorImage(obj,varargin)

    if (isempty(varargin))
        forceRecompute = true;
    else
        % parse input arguments 
        defaultSensorParams = struct('name', 'human-default', 'userDidNotPassSensorParams', true);
        parser = inputParser;
        parser.addParamValue('forceRecompute',   true, @islogical);
        parser.addParamValue('sensorParams',     defaultSensorParams, @isstruct);
        parser.addParamValue('visualizeResultsAsIsetbioWindows', false, @islogical);
        parser.addParamValue('visualizeResultsAsImages', false, @islogical);
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
            fprintf('Since a sensor params was passed, we will recompute the sensor image');
            forceRecompute = true;
        end
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
                obj.sensor = sensorSet(obj.sensor, 'rows', 750);
                obj.sensor = sensorSet(obj.sensor, 'cols', 750);
            otherwise
                error('Do not know how to generated optics ''%s''!', sensorParams.name);
        end
        
        % Compute sensor activation
        obj.sensor = sensorComputeNoiseFree(obj.sensor, obj.opticalImage);
        
        % Save computed sensor
        sensor = obj.sensor;
        if (obj.verbosity > 2)
            fprintf('Saving computed sensor to cache file (''%s'').', obj.sensorCacheFileName);
        end
        save(obj.sensorCacheFileName, 'sensor');
        clear 'sensor'
    end
    
    % Compute sensor activation image
    obj.sensorActivationImage = sensorGet(obj.sensor, 'volts');
    disp('size of sensor activation');
    size(obj.sensorActivationImage)
        
    if (visualizeResultsAsIsetbioWindows)
        vcAddAndSelectObject(obj.sensor);
        sensorWindow;
    end
    
    if (visualizeResultsAsImages)
        figure();
        imagesc(obj.sensorActivationImage);
        colormap(hot(512));
        [min(obj.sensorActivationImage(:)) max(obj.sensorActivationImage(:))]
    end
    
    
end

