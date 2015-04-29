function importHyperSpectralImage(s)

    if (nargin == 0)
        s = struct('databaseName', 'manchester_database', 'sceneName','scene4', 'clipLuminance',12000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', 'true');
    end
    
    switch (s.databaseName)
        case 'manchester_database'
            % Instantiate a ManchesterHyperSpectralImageDataExtractor
            hyperSpectralImageDataHandler = ManchesterHyperSpectralImageDataExtractor(s.sceneName);
        otherwise
            fprintf(2, 'Unknown database name (''%s''). Skipping scene.\n', s.databaseName);
            return;
    end
      
    % skip scene if it contains incosistent spectral data
    if (hyperSpectralImageDataHandler.inconsistentSpectralData)
        fprintf(2,'Nothing exported for scene named ''%s''.\n',s.sceneName);
        return;
    end
        
    % Return shooting info
    hyperSpectralImageDataHandler.shootingInfo();

    % Plot the scene illuminant
    hyperSpectralImageDataHandler.plotSceneIlluminant();

    % Show an sRGB version of the hyperspectral image with the reference object outlined in red
    hyperSpectralImageDataHandler.showLabeledsRGBImage(s.clipLuminance, s.gammaValue, s.outlineWidth);

    if (1==2)
        % Get the isetbio scene object directly
        sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
        test(sceneObject);
    end
        
    % Export isetbio scene object
    fileNameOfExportedSceneObject = hyperSpectralImageDataHandler.exportIsetbioSceneObject();
    
    if (s.showIsetbioData)
        showGeneratedIsetbioData(fileNameOfExportedSceneObject);
    end
    
end

function showGeneratedIsetbioData(sceneObjectOrFileNameOfSceneObject)
    if (ischar(sceneObjectOrFileNameOfSceneObject)) && (exist(sceneObjectOrFileNameOfSceneObject, 'file'))
        % Load exported scene object
        load(sceneObjectOrFileNameOfSceneObject);
    else
        scene = sceneObjectOrFileNameOfSceneObject;
    end

    % display scene
    vcAddAndSelectObject(scene); sceneWindow;
    
    % human optics
    oi = oiCreate('human');
    
    % Compute optical image of scene and
    oi = oiCompute(scene,oi);
    
    % Shown optical image
    vcAddAndSelectObject(oi); oiWindow;
end

