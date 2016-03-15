function computeOuterSegmentResponses(expParams)

    % reset isetbio
    ieInit;
    
    sceneData = core.fetchTheIsetbioSceneDataSet(expParams.sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    for sceneIndex = 1:numel(sceneData)
        
        % Get the scene
        scene = sceneData{sceneIndex};
        
        % Force it's mean luminance to set value
        scene = sceneAdjustLuminance(...
            scene, expParams.viewingModeParams.forcedSceneMeanLuminance);
        
        % Generate adapting field scene
        adaptingFieldScene = core.generateAdaptingFieldScene(...
            scene, expParams.viewingModeParams.adaptingFieldParams);
        
        % Compute StockmanSharpee 2 deg LMS excitations
        sceneLMS = core.imageFromScene(scene, 'LMS');
        adaptingFieldSceneLMS = core.imageFromScene(adaptingFieldScene, 'LMS');
        
        showScene = true;
        if (showScene)
            core.showSceneAndAdaptingField(scene, adaptingFieldScene); 
        end
        
        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);

        % Compute optical image of adapting scene
        oiAdaptatingField = oiCreate('human');
        oiAdaptatingField = oiCompute(oiAdaptatingField, adaptingFieldScene);
    
        showOpticalImages = true;
        if (showOpticalImages);
            core.showOpticalImagesOfSceneAndAdaptingField(oi, oiAdaptatingField); 
        end
        
    end % sceneIndex
end





