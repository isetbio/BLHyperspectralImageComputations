% Method to generate and export an isetbio scene object
function exportFileName = exportIsetbioSceneObject(obj)

    % Generate isetbio scene
    scene = sceneFromHyperSpectralImageData(...
        'sceneName',            obj.radianceData.sceneName, ...
        'wave',                 obj.radianceData.wave, ...
        'illuminantEnergy',     obj.radianceData.illuminant, ... 
        'radianceEnergy',       obj.radianceData.radianceMap, ...
        'sceneDistance',        obj.referenceObjectData.geometry.distanceToCamera, ...
        'scenePixelsPerMeter',  obj.referenceObjectData.geometry.sizeInPixels/obj.referenceObjectData.geometry.sizeInMeters  ...
    );

    % Assemble destination directory path
    destinationDir = fullfile(getpref('HyperSpectralImageComputations', 'isetbioSceneDataBaseDir'), obj.sceneData.database);
    
    if (~exist(destinationDir, 'dir'))
        mkdir(destinationDir);
    end
    
    exportFileName = fullfile(destinationDir, obj.radianceData.sceneName);
    save(exportFileName, 'scene');
    fprintf('Isetbio scene object for scene named ''%s'' was exported to ''%s''.\n', sceneGet(scene, 'name'), exportFileName);
end

