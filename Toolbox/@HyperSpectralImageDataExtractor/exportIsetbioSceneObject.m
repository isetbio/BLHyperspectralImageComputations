% Method to generate and export an isetbio scene object
function exportFileName = exportIsetbioSceneObject(obj)

    % Generate isetbio scene
    scene = obj.isetbioSceneObject;
    
    % Assemble destination directory path
    destinationDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir'), obj.sceneData.database);
    
    if (~exist(destinationDir, 'dir'))
        mkdir(destinationDir);
    end
    
    exportFileName = fullfile(destinationDir, sprintf('isetbioSceneFor_%s.mat',obj.radianceData.sceneName));
    save(exportFileName, 'scene');
    fprintf('Isetbio scene object for scene named ''%s'' was exported to ''%s''.\n', sceneGet(scene, 'name'), exportFileName);
end

