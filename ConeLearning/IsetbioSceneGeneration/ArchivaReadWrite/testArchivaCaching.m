function testArchivaCaching

    theDataBase = 'penn_database';
    sceneNames = {...
        'BearFruitGrayB', ...
        'BearFruitGrayG', ...
        'BearFruitGrayR', ...
        'BearFruitGrayY', ...
        };
    
    theDataBase = 'harvard_database';
    sceneNames = {...
        'img1', ...
        'img2', ...
        'img3', ...
        'img4', ...
        'img5', ...
        'img6', ...
        'imga1', ...
        'imga2', ...
        'imga3', ...
        'imga4', ...
        'imga5', ...
        'imga6', ...
        'imga7', ...
        'imga8', ...
        'imgb1', ...
        'imgb2', ...
        'imgb3', ...
        'imgb4', ...
        'imgb5', ...
        'imgb6', ...
        'imgb7', ...
        'imgb8', ...
        'imgb9', ...
        'imgc1', ...
        'imgc2', ...
        'imgc3', ...
        'imgc4', ...
        'imgc5', ...
        'imgc6', ...
        'imgc7', ...
        'imgc8', ...
        'imgc9', ...
        'imgd0', ...
        'imgd1', ...
        'imgd2', ...
        'imgd3', ...
        'imgd4', ...
        'imgd5', ...
        'imgd6', ...
        'imgd7', ...
        'imgd8', ...
        'imgd9', ...
        'imge0', ...
        'imge1', ...
        'imge2', ...
        'imge3', ...
        'imge4', ...
        'imge5', ...
        'imge6', ...
        'imge7', ...
        'imgf1', ...
        'imgf2', ...
        'imgf3', ...
        'imgf4', ...
        'imgf5', ...
        'imgf6', ...
        'imgf7', ...
        'imgf8', ...
        'imgg0', ...
        'imgg1', ...
        'imgg2', ...
        'imgg3', ...
        'imgg4', ...
        'imgg5', ...
        'imgg6', ...
        'imgg7', ...
        'imgg8', ...
        'imgg9', ...
        'imgh0', ...
        'imgh1', ...
        'imgh2', ...
        'imgh3', ...
        'imgh4', ...
        'imgh5', ...
        'imgh6', ...
        'imgh7', ...
        };
    
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
    
    cacheFolder = sprintf('/Users/nicolas/.gradle/caches/modules-2/files-2.1/resources.scenes.hyperspectral.%s', theDataBase);
    if (exist(cacheFolder, 'dir'))
        fprintf('Cache %s exists. Removing.\n',cacheFolder);
        rmdir(cacheFolder, 's')
    end
    
    % change to the "remote path" where we want to publish the artifact
    client.crp(remotePath);
    
    tic
    for k = 1:numel(sceneNames)
        readFileFromDisk(sceneNames{k}, 'mat');
    end
    fprintf('Fetching ftrom disk: %f seconds.\n', toc);
    pause
    
    % Get scenes
    for repeatIndex = 1:3
        tic
        for k = 1:numel(sceneNames)
            readFileFromArchiva(client, sceneNames{k}, 'mat');
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

