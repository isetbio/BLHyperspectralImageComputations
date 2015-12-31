function downloadIsetbioScenes

    addNeddedToolboxesToPath();
    
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    
    
    % Retrieve Stanford memorial church scene from Stanford database
    client.crp('resources/scenes/hyperspectral/stanford_database');
    [artifactData, artifactInfo] = client.readArtifact('StanfordMemorial', 'type', 'mat');
    artifactData
    artifactInfo
    
    % Compute optical image
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

