function showOpticalImagesOfSceneAndAdaptingField(oi, oiAdaptatingField)

    CMF = core.loadXYZCMFs();
    S = WlsToS(oiGet(oi, 'wave'));
    
    sceneRetinalIlluminanceMap = oiGet(oi, 'illuminance');
    irradiance = oiGet(oi, 'energy');
    tmpXYZ = MultispectralToSensorImage(irradiance, S, CMF.T, CMF.S); 
    [retinalImageSRGB, clippedPixelsNum, illuminanceRange1] = core.XYZtoSRGB(tmpXYZ, []);
   
    adaptingFieldSceneRetinalIlluminanceMap = oiGet(oiAdaptatingField, 'illuminance');
    irradiance = oiGet(oiAdaptatingField, 'energy');
    tmpXYZ = MultispectralToSensorImage(irradiance, S, CMF.T, CMF.S); 
    [retinalAdaptingImageSRGB, clippedPixelsNum, illuminanceRange2] = core.XYZtoSRGB(tmpXYZ, []);
    
    % everything above maxSRGB will be clipped
    maxSRGB = 0.06; % max(retinalImageSRGB(:))
    retinalImageSRGB = retinalImageSRGB / maxSRGB;
    retinalAdaptingImageSRGB = retinalAdaptingImageSRGB / maxSRGB;
    retinalImageSRGB(retinalImageSRGB>1) = 1;
    retinalAdaptingImageSRGB(retinalAdaptingImageSRGB>1) = 1;
    
    minRetinalIlluminance = min(sceneRetinalIlluminanceMap(:));
    maxRetinalIlluminance = max(sceneRetinalIlluminanceMap(:));
    meanRetinalIlluminance = mean(sceneRetinalIlluminanceMap(:));
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'spectralLUT');
    
    hFig = figure(22); clf; set(hFig, 'Position', [10 10 1024 935]); colormap(spectralLUT);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 1, ...
               'heightMargin',   0.002, ...
               'widthMargin',    0.00, ...
               'leftMargin',     0.006, ...
               'rightMargin',    0.002, ...
               'bottomMargin',   0.005, ...
               'topMargin',      0.00);
           
    gamma = 1/1.6;
    subplot('Position', subplotPosVectors(1,1).v);
    imshow(cat(2, retinalImageSRGB.^gamma, retinalAdaptingImageSRGB.^gamma));  axis 'image';
    set(gca, 'CLim', [0 1]);
    set(gca, 'XTick', [], 'YTick', []);
     
    subplot('Position', subplotPosVectors(2,1).v);
    imagesc(cat(2, sceneRetinalIlluminanceMap, adaptingFieldSceneRetinalIlluminanceMap));  axis 'image';
    set(gca, 'CLim', [0 maxRetinalIlluminance]);
    set(gca, 'XTick', [], 'YTick', []);
    hCbar = colorbar('southoutside');
    hCbar.Label.String = 'retinal illuminance';
    hCbar.FontSize = 12;
    title(sprintf('retinal illuminance: min = %2.1f, mean=%2.1f, max=%2.2f', minRetinalIlluminance, meanRetinalIlluminance, maxRetinalIlluminance), 'FontSize', 16);
    drawnow;
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    pngFileName = fullfile(p.rootPath, p.figureExportsSubDir, sprintf('%s_opticalImage.png', oiGet(oi, 'name')));
    NicePlot.exportFigToPNG(pngFileName, hFig, 300);
end

