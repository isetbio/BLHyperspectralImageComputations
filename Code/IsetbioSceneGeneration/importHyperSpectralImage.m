function importHyperSpectralImage(varargin)

    %% Get our project toolbox on the path
    myDir = fileparts(mfilename('fullpath'));
    pathDir = fullfile(myDir,'..','Toolbox','');
    AddToMatlabPathDynamically(pathDir);

    if (nargin == 0)
        s = struct(...
            'databaseName', 'manchester_database', ...  % name of the database
            'sceneName', 'scene4', ...                  % name of the scene in the database
            'clipLuminance', 12000, ...                 % only relevant for the sRGB rendition
            'gammaValue', 1.7, ...                      % only relevant for the sRGB rendition
            'outlineWidth', 2, ...                      % only relevant for the sRGB rendition - reference object outline width
            'showIsetbioData', 'true' ...               % flag indicating whether to show the generated isetbio scene and resulting optical image
            );
        exportIsetbioSceneObject = false;
    else
        s = varargin{1};
        exportIsetbioSceneObject = varargin{2};
    end
    
    switch (s.databaseName)
        case 'manchester_database'
            % Instantiate a ManchesterHyperSpectralImageDataExtractor
            hyperSpectralImageDataHandler = ManchesterHyperSpectralImageDataExtractor(s.sceneName);
        
        case 'harvard_database'
            % Instantiate a HarvardHyperSpectralImageDataExtractor
            hyperSpectralImageDataHandler = HarvardHyperSpectralImageDataExtractor(s.subsetDirectory,s.sceneName, s.applyMotionMask);
            
        case 'stanford_database'
            % Instantiate a StanfordHyperSpectralImageDataExtractor
            hyperSpectralImageDataHandler = StanfordHyperSpectralImageDataExtractor(s.sceneName);
            
        case 'penn_database'
            % Instantiate a StanfordHyperSpectralImageDataExtractor
            hyperSpectralImageDataHandler = PennHyperSpectralImageDataExtractor(s.sceneName);
            
        otherwise
            fprintf(2, 'Unknown database name (''%s''). Skipping scene.\n', s.databaseName);
            return;
    end
      
    % skip scene if it contains inconsistent spectral data
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
    hyperSpectralImageDataHandler.shootingInfo()
    
    % Show/Export Isetbio scene object
    if (exportIsetbioSceneObject)
        % Export isetbio scene object
        fileNameOfExportedSceneObject = hyperSpectralImageDataHandler.exportIsetbioSceneObject();
        if (s.showIsetbioData)
            showGeneratedIsetbioData(fileNameOfExportedSceneObject);
        end
    else
        sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
        if (s.showIsetbioData)
            showGeneratedIsetbioData(sceneObject);
        end
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
    
    if (1==2)
        % human optics
        oi = oiCreate('human');

        % Compute optical image of scene and
        oi = oiCompute(scene,oi);

        % Show optical image
        vcAddAndSelectObject(oi); oiWindow;
    end
    
end

