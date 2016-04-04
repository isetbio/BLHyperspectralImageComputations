function [imageCMF, clippedPixelsNum] = imageFromSceneOrOpticalImage(sceneOrOpticalImage, CMFname, varargin)

    % parse input
    defaultClipLuminance = [];
    p = inputParser;
    p.addRequired('sceneOrOpticalImage', @isstruct);
    p.addRequired('CMFname', @ischar);
    p.addParamValue('clipLuminance', defaultClipLuminance, @isnumeric);
    p.parse(sceneOrOpticalImage, CMFname, varargin{:});
    
    switch CMFname
        case 'LMS'
            CMF = core.loadStockmanSharpe2DegFundamentals();
        case 'XYZ'
            CMF = core.loadXYZCMFs();
        case 'sRGB'
            CMF = core.loadXYZCMFs();
    end
    
    switch (sceneOrOpticalImage.type)
        case 'scene'
            S = WlsToS(sceneGet(sceneOrOpticalImage, 'wave'));
            energy = sceneGet(sceneOrOpticalImage, 'energy');
        case 'opticalimage'
            S = WlsToS(oiGet(sceneOrOpticalImage, 'wave'));
            energy = oiGet(sceneOrOpticalImage, 'energy');
        otherwise
            error('Do not know how to handle ISET object of type: ''%s''\n', sceneOrOpticalImage.type)
    end
            
    imageCMF = MultispectralToSensorImage(energy, S, CMF.T, CMF.S); 
    
    if (strcmp(CMFname, 'sRGB'))
        [imageCMF, clippedPixelsNum, luminanceRange] = core.XYZtoSRGB(imageCMF, p.Results.clipLuminance);
    else
        clippedPixelsNum = [];
    end 
end