% Method to compute the optical image
function computeOpticalImage(obj,varargin)

    if (isempty(varargin))
        forceRecompute = true;
    else
        % parse input arguments 
        defaultOpticsParams = struct('name', 'human-default', 'userDidNotPassOpticsParams', true);
        parser = inputParser;
        parser.addParamValue('forceRecompute',   true, @islogical);
        parser.addParamValue('opticsParams',     defaultOpticsParams, @isstruct);
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
        
        if (~isfield(opticsParams, 'userDidNotPassOpticsParams'))
            % the user passed an optics params struct, so forceRecompute
            fprintf('Since an optics params was passed, we will recompute the optical image');
            forceRecompute = true;
        end
    end
    

    if (forceRecompute == false)
        % Check if a cached optical image file exists in the path
        if (exist(obj.opticalImageCacheFileName, 'file'))
            if (obj.verbosity > 2)
                fprintf('Loading computed optical image from cache file (''%s'').\n', obj.opticalImageCacheFileName);
            end
            load(obj.opticalImageCacheFileName, 'opticalImage');
            obj.opticalImage = opticalImage;
            clear 'opticalImage'
        else
            fprintf('Cached optical image for scene ''%s'' does not exist. Will generate one\n', obj.sceneName);
            forceRecompute = true;
        end
    end
    
    if (forceRecompute)
        switch opticsParams.name
            case 'human-default'
                % generate default human optics
                obj.opticalImage = oiCreate('human');
            otherwise
                error('Do not know how to generated optics ''%s''!', opticsParams.name);
        end
        
        % Compute optical image
        obj.opticalImage = oiCompute(obj.opticalImage, obj.scene);
        
        % Save computed optical image
        opticalImage = obj.opticalImage;
        if (obj.verbosity > 2)
            fprintf('Saving computed optical image to cache file (''%s'').', obj.opticalImageCacheFileName);
        end
        save(obj.opticalImageCacheFileName, 'opticalImage');
        clear 'opticalImage'
    end
                
    if (visualizeResultsAsIsetbioWindows)
        vcAddAndSelectObject(obj.scene);
        sceneWindow;
        
        vcAddAndSelectObject(obj.opticalImage);
        oiWindow;
    end
    
    if (visualizeResultsAsImages)
        figure(554);
        imshow(oiGet(obj.opticalImage, 'rgb image'));
        truesize;
        drawnow;
    end
    
end

