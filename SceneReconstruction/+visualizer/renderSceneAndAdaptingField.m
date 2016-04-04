function renderSceneAndAdaptingField(scene)
        
    sceneXYZ = core.imageFromSceneOrOpticalImage(scene, 'XYZ');
    sceneLuminanceMap = 683*squeeze(sceneXYZ(:,:,2));
    minLuminance = min(sceneLuminanceMap(:));
    maxLuminance = max(sceneLuminanceMap(:));
    meanLuminance = mean(sceneLuminanceMap(:));
 
    sceneSRGB = core.imageFromSceneOrOpticalImage(scene, 'sRGB');
    
    % everything above maxSRGB will be clipped
    maxSRGB = 4; % max(sceneSRGB(:))
    sceneSRGB = sceneSRGB / maxSRGB;
    sceneSRGB(sceneSRGB>1) = 1;
    sceneSRGB(sceneSRGB<0) = 0;
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'spectralLUT');
    
    hFig = figure(1); clf; set(hFig, 'Position', [10 10 528 768]); colormap(spectralLUT);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 1, ...
               'heightMargin',   0.01, ...
               'widthMargin',    0.00, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.002, ...
               'bottomMargin',   0.002, ...
               'topMargin',      0.00);
    gamma = 1/1.6;       
    subplot('Position', subplotPosVectors(1,1).v);
    spatialSupport = sceneGet(scene, 'spatial support', 'microns');
    sceneXdataInRetinalMicrons = squeeze(spatialSupport(1,:,1));
    sceneYdataInRetinalMicrons = squeeze(spatialSupport(:,1,2));
    
    imagesc(sceneXdataInRetinalMicrons, sceneYdataInRetinalMicrons, sceneSRGB.^gamma);  axis 'image';
    hCbar = colorbar('westoutside');
    hCbar.Label.String = 'luminance (cd/m2)';
    hCbar.FontSize = 12;
    set(gca, 'CLim', [0 1]);
    set(gca, 'XTick', [], 'YTick', []);
    
    subplot('Position', subplotPosVectors(2,1).v);
    imagesc(sceneXdataInRetinalMicrons, sceneYdataInRetinalMicrons, sceneLuminanceMap);  axis 'image';
    hCbar = colorbar('westoutside');
    hCbar.Label.String = 'luminance (cd/m2)';
    hCbar.FontSize = 12;
    set(gca, 'CLim', [0 maxLuminance]);
    set(gca, 'XTick', [], 'YTick', []);
    title(sprintf('luminance: min=%2.1f mean=%2.1f, max=%2.1f cd/m2', minLuminance, meanLuminance, maxLuminance), 'FontSize', 16);
    
    
    pngFileName = fullfile(p.rootPath, p.figureExportsSubDir, sprintf('%s_scene.png', sceneGet(scene, 'name')));
    NicePlot.exportFigToPNG(pngFileName, hFig, 300);
end
            