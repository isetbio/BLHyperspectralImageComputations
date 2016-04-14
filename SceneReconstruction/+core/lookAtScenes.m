function lookAtScenes(sceneSetName)

    [sceneData, sceneNames] = core.fetchTheIsetbioSceneDataSet(sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    retainedSceneNames = {};
    for sceneIndex = 1: numel(sceneData)
        
        % Get the scene
        scene = sceneData{sceneIndex};
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);
        spatialSample = 3/2.0;
        oi = oiSpatialResample(oi, spatialSample, 'um', 'linear', false);
        
        figure(1);
        subplot(1,2,1);
        imshow(sceneGet(scene, 'RGB'));
        pixelSize = sceneGet(scene, 'spatial resolution', 'um');
        title(sprintf('pixel size: %2.1f microns', pixelSize(1)));
        subplot(1,2,2);
        imshow(oiGet(oi, 'RGB'));
        pixelSize = oiGet(oi, 'spatial resolution', 'um');
        title(sprintf('pixel size: %2.1f microns', pixelSize(1)));
        drawnow;
        
        keep = input('Retain scene ?[1=yes] : ');
        
        if (keep == 1)
            retainedSceneNames{numel(retainedSceneNames)+1} = sceneNames{sceneIndex}
        end
    end
    
    retainedSceneNames
    
end
