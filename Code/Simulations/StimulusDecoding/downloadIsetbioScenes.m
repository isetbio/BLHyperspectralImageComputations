function downloadIsetbioScenes

    addNeddedToolboxesToPath();
    
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    
    
    % Retrieve Stanford memorial church scene from Stanford database
    tic
    %client.crp('resources/scenes/hyperspectral/stanford_database');
    %[artifactData, artifactInfo] = client.readArtifact('StanfordMemorial', 'type', 'mat')
    
    client.crp('resources/scenes/hyperspectral/manchester_database');
    [artifactData, artifactInfo] = client.readArtifact('scene1', 'type', 'mat')
    
    toc
    
    % Compute and show scene
    tic
    if ismember('scene', fieldnames(artifactData))
        fprintf('data contains uncompressed scene data');
    else
        fprintf('data contains compressed scene data');
        basis = artifactData.basis;
        comment = artifactData.comment;
        illuminant = artifactData.illuminant;
        mcCOEF = artifactData.mcCOEF;
        save('tmp.mat', 'basis', 'comment', 'illuminant', 'mcCOEF');
        wList = 380:5:780;
        scene = sceneFromFile('tmp.mat', 'multispectral', [],[],wList);
        scene = sceneSet(scene, 'distance', artifactData.dist);
        scene = sceneSet(scene, 'wangular', artifactData.fov);
        delete('tmp.mat');
    end
    toc
    vcAddAndSelectObject(scene); sceneWindow;
    
    % Compute and show optical image
    tic
    oi = oiCreate('human');
    oi = oiCompute(oi, scene);
    toc
    vcAddAndSelectObject(oi); oiWindow;
    
    % Save optical image
    getpref('HyperSpectralImageIsetbioComputations','opticalImagesCacheDir')
    
end

function addNeddedToolboxesToPath()
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd ..
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
end

