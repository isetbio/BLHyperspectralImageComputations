function sceneData = fetchTheIsetbioSceneDataSet(sceneSetName)

    % Set up remote data toolbox client
    remoteDataToolboxClient = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig')); 
   
    sceneSet = core.sceneSetWithName(sceneSetName);
    
    % Fetch the scene dataset
    sceneData = {};
    for sceneIndex = 1:numel(sceneSet)
        % Retrieve scene
        imsource = sceneSet{sceneIndex};
        fprintf('Fetching data for ''%s'' / ''%s''. Please wait... ', imsource{1}, imsource{2});
        remoteDataToolboxClient.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
        [d, artifactInfo] = remoteDataToolboxClient.readArtifact(imsource{2}, 'type', 'mat');
        if ismember('scene', fieldnames(d))
            sceneData{sceneIndex} = d.scene;
        else
            fprintf(' Scene contains compressed data. Uncompressing ...');
            sceneData{sceneIndex} = sceneFromBasis(d);
        end
        fprintf('Done fetching scene data.\n');
    end
    
end

