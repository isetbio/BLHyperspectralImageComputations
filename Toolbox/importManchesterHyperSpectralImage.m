function importManchesterHyperSpectralImage
   
    sceneData = struct(...
        'database', 'manchester_database', ...                                          % database directory
        'name', 'scene4', ...                                                           % scene subdirectory
        'referencePaintFileName',  'ref_n7.mat', ...                                    % name of reference paint data file
        'reflectanceDataFileName', 'ref_cyflower1bb_reg1.mat', ...                      % name of scene reflectance data file
        'spectralRadianceDataFileName', 'radiance_by_reflectance_cyflower1.mat' ...     % name of spectral radiance factor to convert scene reflectance to radiances in Watts/steradian/m^2/nm - akin to the scene illuminant
    );
    
    % Instantiate a HyperSpectralImageDataExtractor
    hyperSpectralImageDataHandler = HyperSpectralImageDataExtractor(sceneData);
   
    % Show an sRGB version of the hyperspectral image with the reference object outlined in red
    clipLuminance = 12000; gammaValue = 1.7;
    hyperSpectralImageDataHandler.showLabeledsRGBImage(clipLuminance, gammaValue);
    
    resp = input('Export isetbio scene object ? [1=yes] : ');
    if (resp ~= 1)
        % Get the isetbio scene object directly
        sceneObject = hyperSpectralImageDataHandler.isetbioSceneObject;
        test(sceneObject)
    
        disp('Bye bye');
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





