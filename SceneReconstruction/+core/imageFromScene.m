function [imageCMF, clippedPixelsNum] = imageFromScene(scene, CMFname, varargin)

    % parse input
    defaultClipLuminance = [];
    p = inputParser;
    p.addRequired('scene', @isstruct);
    p.addRequired('CMFname', @ischar);
    p.addParamValue('clipLuminance', defaultClipLuminance, @isnumeric);
    p.parse(scene, CMFname, varargin{:});
    
    switch CMFname
        case 'LMS'
            CMF = core.loadStockmanSharpe2DegFundamentals();
        case 'XYZ'
            CMF = core.loadXYZCMFs();
        case 'sRGB'
            CMF = core.loadXYZCMFs();
    end
    
    S = WlsToS(sceneGet(scene, 'wave'));
    radiance = sceneGet(scene, 'energy');
    imageCMF = MultispectralToSensorImage(radiance, S, CMF.T, CMF.S); 
    
    if (strcmp(CMFname, 'sRGB'))
        [imageCMF, clippedPixelsNum, luminanceRange] = core.XYZtoSRGB(imageCMF, p.Results.clipLuminance);
    else
        clippedPixelsNum = [];
    end 
end