function importManchesterHyperSpectralImage
   
    % green scenes
    sceneName = 'scene1'; clipLuminance = 4000;  gammaValue = 1.7; outlineWidth = 1;
    sceneName = 'scene2'; clipLuminance = 4000;  gammaValue = 1.7; outlineWidth = 1;
    sceneName = 'scene3'; clipLuminance = 4000;  gammaValue = 1.7; outlineWidth = 1;
    sceneName = 'scene4'; clipLuminance = 12000; gammaValue = 1.7; outlineWidth = 2;
    
    sceneName = 'scene5'; clipLuminance = 4000; gammaValue = 1.7; outlineWidth = 2;  % this has discrepancy in the number of spectral bands
    sceneName = 'scene6'; clipLuminance = 14000; gammaValue = 1.7; outlineWidth = 2;
    
    % Instantiate a ManchesterHyperSpectralImageDataExtractor
    hyperSpectralImageDataHandler = ManchesterHyperSpectralImageDataExtractor(sceneName);
   
    % Return shooting info
    hyperSpectralImageDataHandler.shootingInfo()
    
    % Plot the scene illuminant
    hyperSpectralImageDataHandler.plotSceneIlluminant();
    
    % Show an sRGB version of the hyperspectral image with the reference object outlined in red
    hyperSpectralImageDataHandler.showLabeledsRGBImage(clipLuminance, gammaValue, outlineWidth);
    
    resp = input('Export isetbio scene object ? [1=yes] : ');
    if (resp ~= 1)
        % Get the isetbio scene object directly
        sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
        test(sceneObject)
        return;
    end

    % Export isetbio scene object
    fileNameOfExportedSceneObject = hyperSpectralImageDataHandler.exportIsetbioSceneObject();
    test(fileNameOfExportedSceneObject)
end

function test(sceneObjectOrFileNameOfSceneObject)
    if (ischar(sceneObjectOrFileNameOfSceneObject)) && (exist(sceneObjectOrFileNameOfSceneObject, 'file'))
        % Load exported scene object
        load(sceneObjectOrFileNameOfSceneObject);
    else
        scene = sceneObjectOrFileNameOfSceneObject;
    end
    
    whos 'scene'
    % display scene
    vcAddAndSelectObject(scene); sceneWindow;
    
    % human optics
    oi = oiCreate('human');
    
    % Compute optical image of scene and
    oi = oiCompute(scene,oi);
    
    % Shown optical image
    vcAddAndSelectObject(oi); oiWindow;
end





