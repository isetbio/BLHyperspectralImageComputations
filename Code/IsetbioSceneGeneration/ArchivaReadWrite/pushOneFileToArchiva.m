function pushOneFileToArchiva

    theDataBase = 'stanford_database';
    theFile = 'Info.md';
    
    localFile = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir'), theDataBase, theFile);
    remotePath = rdtFullPath({'', 'resources', 'scenes', 'hyperspectral', theDataBase}); 
    artifactId = '0.info';
    version = '1';
    description = 'Information regarding any processing that was done on the original data files';
    
    % Get a client for isetbio
    client = RdtClient('isetbio');
    
    % Log into archiva
    client.credentialsDialog();
    
    % Change to the "remote path" where we want to publish the artifact
    client.crp(remotePath);
    
    % Push artifact 
    artifact = client.publishArtifact(...
            localFile, ...
            'artifactId', artifactId, ...
            'name', theFile,...
            'description', description, ...
            'version', version);

     % See metadata about the new artifact!
     disp(artifact);
        
end

