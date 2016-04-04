function sceneWithAdaptingField = sceneAddAdaptingField(scene, adaptingFieldParams, borderCols)

    adaptingFieldScene = core.generateAdaptingFieldScene(scene, adaptingFieldParams);
    
    sceneWithAdaptingField = scene;
    
    % Brute forcing the photons in the perimiter to that of the adapting field
    borderRows = 1:size(scene.data.photons,1);
    % add to left side
    sceneWithAdaptingField.data.photons(borderRows, 1:borderCols,:) = ...
        adaptingFieldScene.data.photons(borderRows, 1:borderCols,:);
    
    % add to right side
%     sceneWithAdaptingField.data.photons(borderRows, size(scene.data.photons,2)+(0:-1:-borderCols+1),:) = ...
%         adaptingFieldScene.data.photons(borderRows, size(scene.data.photons,2)+(0:-1:-borderCols+1),:);
%     
        
end

