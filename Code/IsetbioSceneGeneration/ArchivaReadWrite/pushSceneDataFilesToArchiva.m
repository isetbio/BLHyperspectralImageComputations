function pushSceneDataFilesToArchiva(dataFiles)

    nDataFiles = numel(dataFiles);
    if (nDataFiles > 0)
        fprintf('Will push %d data files to archiva.\n', nDataFiles);
    else
        return;
    end
    
    % Publish artifacts.
    client = RdtClient('isetbio');
    client.credentialsDialog();
    
    for dataFileIndex = 1:nDataFiles
        
        dataFile = dataFiles(dataFileIndex);

        % Determine if the file contains compressed data (e.g. Stanford images)
        S = whos('-file', fullfile(dataFile.localFolder, dataFile.originalFile));
        dataIsCompressed = true;
        for fieldIndex = 1:numel(S)
            if (strcmp(S(fieldIndex).name, 'scene'))
                dataIsCompressed = false;
            end
        end
        
        if dataIsCompressed
            load(fullfile(dataFile.localFolder, dataFile.originalFile));
            tmpFile = fullfile(dataFile.localFolder, dataFile.localFile);
            for fieldIndex = 1:numel(S)
                if (fieldIndex == 1)
                   eval(sprintf('save(''%s'', ''%s'');', tmpFile, S(fieldIndex).name))
                else
                   eval(sprintf('save(''%s'', ''%s'', ''-append'');', tmpFile, S(fieldIndex).name))
                end
            end
            if strfind(lower(dataFile.localFile), 'male')
                description = sprintf('%s. Spatial and illuminant data available. Scene was shot under Tungten illumination and subsequently re-illuminated in software using D65. For more information, please visit https://scien.stanford.edu/index.php/hyperspectral-image-data/', comment)
            else
                description = sprintf('%s. Spatial and illuminant data available. For more information, please visit https://scien.stanford.edu/index.php/hyperspectral-image-data/', comment)
            end
        else  
            load(fullfile(dataFile.localFolder, dataFile.originalFile), 'scene', 'description');
            if isempty(description)
                description = 'There is no further info regarding this scene.';
            end

            data.scene = scene;
            data.description = description;
            tmpFile = fullfile(dataFile.localFolder, dataFile.localFile);
            save(tmpFile, '-struct', 'data');
        end
        
        
        % change to the "remote path" where we want to publish the artifact
        client.crp(dataFile.remotePath);
    
        % each artifact must have a version, the default is version '1'
        version = '1';

        % supply the configuration, which now contains publishing credentials
        artifact = client.publishArtifact(...
            tmpFile, ...
            'artifactId', dataFile.artifactId, ...
            'name', dataFile.localFile,...
            'description', description, ...
            'version', version);

        % See metadata about the new artifact!
        disp(artifact);

        if (1==2)
        % Visit the new artifact on the web!
        % From the directory listing, click on png file and check that the image in
        % the brwoser matches the image in the Matlab figure.
        client.openBrowser(artifact);
        end
        
        system(sprintf('rm %s', tmpFile));
    end

end