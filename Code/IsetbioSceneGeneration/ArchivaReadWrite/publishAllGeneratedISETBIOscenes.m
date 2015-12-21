function publishAllGeneratedISETBIOscenes

    [rootDir,~] = fileparts(which(mfilename));
    isetbioHyperSpectralScenesFolder = getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir');
    isetbioSceneNamePrefix = 'isetbioSceneFor_';
    
    % Get the subfolders
    d = dir(isetbioHyperSpectralScenesFolder);
    nDirs = numel(d);
    
    excludedDirs = {'.', '..', 'stanford_database', 'manchester_database', 'harvard_database'};
    % Go through the files in each of the subfolders
    fprintf('\n');
    
    dataFiles = [];
    
    for dirIndex = 1:nDirs
        if (ismember(d(dirIndex).name, excludedDirs)) || (~d(dirIndex).isdir)
            continue;
        end
        sceneSubFolder = fullfile(isetbioHyperSpectralScenesFolder , d(dirIndex).name);
        remotePath = rdtFullPath({'', 'resources', 'scenes', 'hyperspectral', d(dirIndex).name});
        
        sceneFiles = dir([sceneSubFolder sprintf('/%s*.mat', isetbioSceneNamePrefix)]);
        nSceneFiles = numel(sceneFiles);

        excludedScenes = {};
        
        switch (d(dirIndex).name)
            case 'manchester_database'
                % exclude scenes with artifacts
                excludedScenes = {...
                    'scene10', ...
                    'scene11', ...
                    'scene12' ...
                    };
        end
        
        cd(sceneSubFolder); 
        
        for fileIndex = 1: nSceneFiles
            originalSceneName = sceneFiles(fileIndex).name;
            simplifiedSceneName = strrep(originalSceneName, isetbioSceneNamePrefix, '');

            if ismember(strrep(simplifiedSceneName, '.mat', ''), excludedScenes)
                fprintf(2,'Skipping scene %s\n', simplifiedSceneName);
                continue;
            end
             
            dataFile = struct( ...
                'subFolder',  d(dirIndex).name, ...
                'artifactId', sprintf('%s', strrep(simplifiedSceneName, '.mat', '')),...
                'localFolder', sceneSubFolder, ...
                'originalFile',  originalSceneName, ...
                'localFile',  simplifiedSceneName, ...
                'remotePath', remotePath, ...
                'type', 'mat');
        
            dataFiles = [dataFiles, dataFile];
        end
    end
    
    cd(rootDir);

    pushSceneDataFilesToArchiva(dataFiles);
end

