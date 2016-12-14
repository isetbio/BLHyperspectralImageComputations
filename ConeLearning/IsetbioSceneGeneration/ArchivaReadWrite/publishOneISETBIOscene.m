function publishOneISETBIOscene

    [rootDir,~] = fileparts(which(mfilename));
    isetbioHyperSpectralScenesFolder = getpref('HyperSpectralImageIsetbioComputations', 'isetbioSceneDataBaseDir');
    isetbioSceneNamePrefix = 'isetbioSceneFor_';
    
    % Get the subfolders
    d = dir(isetbioHyperSpectralScenesFolder);
    nDirs = numel(d);
    
    theDataBase = 'penn_database';
    theSceneName = 'BearFruitGrayG.mat';
    
    % Go through the files in each of the subfolders
    fprintf('\n');
    
    dataFiles = [];
    
    for dirIndex = 1:nDirs
        if (~strcmp(d(dirIndex).name, theDataBase)) || (~d(dirIndex).isdir)
            fprintf('Skipping directory: %s\n', d(dirIndex).name);
            continue;
        end
        sceneSubFolder = fullfile(isetbioHyperSpectralScenesFolder , d(dirIndex).name);
        remotePath = rdtFullPath({'', 'resources', 'scenes', 'hyperspectral', d(dirIndex).name});
        
        sceneFiles = dir([sceneSubFolder sprintf('/%s*.mat', isetbioSceneNamePrefix)]);
        nSceneFiles = numel(sceneFiles);
        
        cd(sceneSubFolder); 
        
        for fileIndex = 1: nSceneFiles
            originalSceneName = sceneFiles(fileIndex).name;
            simplifiedSceneName = strrep(originalSceneName, isetbioSceneNamePrefix, '');
        
            if (~strcmp(simplifiedSceneName, theSceneName))
                fprintf('Skipping %s\n', simplifiedSceneName);
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

