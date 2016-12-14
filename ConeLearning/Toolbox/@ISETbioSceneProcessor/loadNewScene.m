% Method to load a new scene
function loadNewScene(obj, databaseName, sceneName)

    % initialize everything
    obj.init();
    
    % generate the resources root dir name
    obj.resourcesRootDirName = getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir');
     
    % save current databaseName and sceneName
    obj.sceneName = sceneName;
    obj.databaseName = databaseName;
    
    % generate sceneFileName
    sceneFileName = fullfile(obj.resourcesRootDirName, databaseName, sprintf('isetbioSceneFor_%s.mat',sceneName));
    fprintf('Loading %s\n', sceneFileName);
    
    % generate cached optical image file
    obj.opticalImageCacheFileName = fullfile(obj.resourcesRootDirName, databaseName, sprintf('isetbioOpticalImageFor_%s.mat',sceneName));
   
    % generate cached sensor image file
    obj.sensorCacheFileName = fullfile(obj.resourcesRootDirName, databaseName, sprintf('isetbioSensorImageFor_%s.mat',sceneName));
   
    
    % load isetbio scene
    load(sceneFileName, 'scene');
    obj.scene = scene;
    
    % clear temp variable
    clear 'scene'
end
