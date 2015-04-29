% Manchester database - specific method to load the reflectance map
function loadReflectanceMap(obj)

    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);

    % Load the scene reflectance data ('reflectances');
    reflectances = [];
    load(fullfile(sourceDir, obj.sceneData.name, obj.sceneData.reflectanceDataFileName));
    if (isempty(reflectances))
        error('Data file does not contain the expected ''reflectances'' field.');
    end
    obj.reflectanceMap = reflectances;
    clear 'reflectances';
end
