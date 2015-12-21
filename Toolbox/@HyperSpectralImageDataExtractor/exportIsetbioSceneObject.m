% Method to generate and export an isetbio scene object
function exportFileName = exportIsetbioSceneObject(obj, exportMode)

    % Generate isetbio scene
    scene = obj.isetbioSceneObject;
    description = obj.shootingInfo();
    
    % Assemble destination directory path
    destinationDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir'), obj.sceneData.database);
    
    if (~exist(destinationDir, 'dir'))
        mkdir(destinationDir);
    end
    
    exportFileName = fullfile(destinationDir, sprintf('isetbioSceneFor_%s.mat',obj.radianceData.sceneName));
    
    if (strcmp(exportMode, 'full'))
        save(exportFileName, 'scene', 'description');
        fprintf('Isetbio scene object (uncompressed) for scene named ''%s'' was exported to ''%s''.\n', sceneGet(scene, 'name'), exportFileName);
    elseif (strcmp(exportMode, 'compressed')) 
        sceneToFile(exportFileName,scene,0.9999, 'canonical');
        %save(exportFileName, '??', 'description');
        fprintf('Isetbio scene object (compressed) for scene named ''%s'' was exported to ''%s''.\n', sceneGet(scene, 'name'), exportFileName);
    else
        error('Unknown export mode: %s\n', exportMode);
    end 
end

