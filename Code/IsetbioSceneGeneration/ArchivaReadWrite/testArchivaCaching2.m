function testArchivaCaching2
%    BenTestArchivaCaching();
     myTestArchivaCaching()
end

function BenTestArchivaCaching
    % use an alternative cache folder and make sure it's empty
    cacheFolder = fullfile(pwd, 'cacheTests')

    if exist(cacheFolder, 'dir')
        rmdir(cacheFolder, 's');
    end

    theDataBase = 'manchester_database';
    sceneNames = {...
        'scene1'
        };
    remotePath = rdtFullPath({'', 'resources', 'scenes', 'hyperspectral', theDataBase}); 
    
    % choose an arbitrary isetbio artifact, ~3.6MB
    client = RdtClient('isetbio');
    client.configuration.cacheFolder = cacheFolder;
    client.crp(remotePath);

    % fetch it a few times
    reps = 3;
    disp('fetch times')
    fetchTimes = zeros(1, reps);
    for ii = 1:reps
        tic();
        for k = 1:numel(sceneNames)
            k
            [data, artifact(k)] = client.readArtifact(sceneNames{k}, 'type', 'mat');
            artifact(k)
        end
        fetchTimes(ii) = toc()
        disp(fetchTimes);
    end
    
    % load the file directly a few times
    disp('local load times');
    localLoadTimes = zeros(1, reps);
    for ii = 1:reps
        tic();
        data = load(artifact(k).localPath);
        localLoadTimes(ii) = toc();
        disp(localLoadTimes);
    end


end

function myTestArchivaCaching
    
    theDataBase = 'manchester_database';
    sceneNames = {...
        'scene1', ...
        'scene2', ...
        'scene3', ...
        'scene4', ...
        'scene6', ...
        'scene7', ...
        'scene8', ...
        };
        
    remotePath = rdtFullPath({'', 'resources', 'scenes', 'hyperspectral', theDataBase}); 
    
    % Get a client for isetbio
    client = RdtClient('isetbio');
    cacheFolder = '/Users/nicolas/.gradle/caches/modules-2/files-2.1/resources.scenes.hyperspectral.manchester_database'
    if (exist(cacheFolder, 'dir'))
        disp('Cache exists. Removing');
        rmdir(cacheFolder, 's')
    end

    %client.configuration.cacheFolder = cacheFolder;
    client.crp(remotePath);
    
    
    % Get scenes
    for repeatIndex = 1:3
        tic
        for k = 1:numel(sceneNames)
            [data, artifact] = client.readArtifact(sceneNames{k}, 'type', 'mat');
        end
        fprintf('Fetching from archiva for repeat %d : %f seconds.\n', repeatIndex, toc);
    end
    
end

function readFileFromArchiva(client, filename, filetype)

    % fetch our artifact
    [data, artifact] = client.readArtifact(filename, 'type', filetype);
    %save(filename, 'data');
end

function readFileFromDisk(filename, filetype)

    % fetch our artifact
    load(fullfile('Data',filename), 'data');
    %vcAddAndSelectObject(data.scene); sceneWindow;

end

