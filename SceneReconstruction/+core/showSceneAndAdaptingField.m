function showSceneAndAdaptingField(scene, adaptingFieldScene)
        
    sceneXYZ = core.imageFromScene(scene, 'XYZ');
    sceneLuminanceMap = 683*squeeze(sceneXYZ(:,:,2));
    minLuminance = min(sceneLuminanceMap(:));
    maxLuminance = max(sceneLuminanceMap(:));
    meanLuminance = mean(sceneLuminanceMap(:));
    
    sceneXYZ = core.imageFromScene(adaptingFieldScene, 'XYZ');
    adaptingFieldSceneLuminanceMap = 683*squeeze(sceneXYZ(:,:,2));
    
    sceneSRGB          = core.imageFromScene(scene, 'sRGB');
    adaptingFieldSRGB  = core.imageFromScene(adaptingFieldScene, 'sRGB');
    
    % everything above maxSRGB will be clipped
    maxSRGB = 4; % max(sceneSRGB(:))
    sceneSRGB = sceneSRGB / maxSRGB;
    adaptingFieldSRGB = adaptingFieldSRGB /maxSRGB;
    sceneSRGB(sceneSRGB>1) = 1;
    adaptingFieldSRGB(adaptingFieldSRGB>1) = 1;
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'spectralLUT');
    
    hFig = figure(1); clf; set(hFig, 'Position', [10 10 1024 935]); colormap(spectralLUT);
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
    imshow(cat(2, sceneSRGB.^gamma , adaptingFieldSRGB.^gamma ));  axis 'image';
    set(gca, 'CLim', [0 1]);
    set(gca, 'XTick', [], 'YTick', []);
    
    subplot('Position', subplotPosVectors(2,1).v);
    imagesc(cat(2, sceneLuminanceMap, adaptingFieldSceneLuminanceMap));  axis 'image';
    hCbar = colorbar('southoutside');
    hCbar.Label.String = 'luminance (cd/m2)';
    hCbar.FontSize = 12;
    set(gca, 'CLim', [0 maxLuminance]);
    set(gca, 'XTick', [], 'YTick', []);
    title(sprintf('luminance: min=%2.1f mean=%2.1f, max=%2.1f cd/m2', minLuminance, meanLuminance, maxLuminance), 'FontSize', 16);
    
    
    pngFileName = fullfile(p.rootPath, p.figureExportsSubDir, sprintf('%s_scene.png', sceneGet(scene, 'name')));
    NicePlot.exportFigToPNG(pngFileName, hFig, 300);
end
            