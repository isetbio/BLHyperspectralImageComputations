% Manchester database - specific method to load the reflectance map
function loadReflectanceMap(obj)

    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);

    % Load the scene reflectance data ('reflectances');
    reflectances = [];
    load(fullfile(sourceDir, obj.sceneData.name, obj.sceneData.reflectanceDataFileName));
    if (isempty(reflectances))
        error('Data file does not contain the expected ''reflectances'' field.');
    end

    if (isfield(obj.sceneData, 'clippingRegion')) && (~isempty(fieldnames(obj.sceneData.clippingRegion)))
        % clip image according to clipping region
        if isinf(obj.sceneData.clippingRegion.y2)
            obj.sceneData.clippingRegion.y2 = size(reflectances,1);
        end
        if isinf(obj.sceneData.clippingRegion.x2)
            obj.sceneData.clippingRegion.x2 = size(reflectances,2);
        end
        reflectances = reflectances(obj.sceneData.clippingRegion.y1:obj.sceneData.clippingRegion.y2, obj.sceneData.clippingRegion.x1:obj.sceneData.clippingRegion.x2, :);
    end
    
    obj.reflectanceMap = reflectances;
    clear 'reflectances';
end
