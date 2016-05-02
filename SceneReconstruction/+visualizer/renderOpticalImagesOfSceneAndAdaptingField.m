function renderOpticalImagesOfSceneAndAdaptingField(oi, sensor, fixationTimes, adaptingFieldFixationTimes)

    CMF = core.loadXYZCMFs();
    S = WlsToS(oiGet(oi, 'wave'));
    
    sceneRetinalIlluminanceMap = oiGet(oi, 'illuminance');
    irradiance = oiGet(oi, 'energy');
    tmpXYZ = MultispectralToSensorImage(irradiance, S, CMF.T, CMF.S); 
    [retinalImageSRGB, clippedPixelsNum, illuminanceRange1] = core.XYZtoSRGB(tmpXYZ, []);
   
    % everything above maxSRGB will be clipped
    maxSRGB = 0.06; % max(retinalImageSRGB(:))
    retinalImageSRGB = retinalImageSRGB / maxSRGB;
    retinalImageSRGB(retinalImageSRGB>1) = 1;
    retinalImageSRGB(retinalImageSRGB<0) = 0;
    
    minRetinalIlluminance = min(sceneRetinalIlluminanceMap(:));
    maxRetinalIlluminance = max(sceneRetinalIlluminanceMap(:));
    meanRetinalIlluminance = mean(sceneRetinalIlluminanceMap(:));
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    load(fullfile(p.rootPath, p.colormapsSubDir, 'CustomColormaps.mat'), 'spectralLUT');
    
    hFig = figure(2); clf; set(hFig, 'Position', [10 10 528 768]); colormap(spectralLUT);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 1, ...
               'heightMargin',   0.01, ...
               'widthMargin',    0.00, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.002, ...
               'bottomMargin',   0.002, ...
               'topMargin',      0.00);
           
    
    subplot('Position', subplotPosVectors(1,1).v);
    
    spatialSupport = oiGet(oi, 'spatial support', 'microns');
    oiXdataInRetinalMicrons = squeeze(spatialSupport(1,:,1));
    oiYdataInRetinalMicrons = squeeze(spatialSupport(:,1,2));
    
    gamma = 1/1.6;
    imagesc(oiXdataInRetinalMicrons,  oiYdataInRetinalMicrons, retinalImageSRGB.^gamma);  axis 'image';
    
    % superimpose eye movements
    hold on;
    sensorPositions = sensorGet(sensor, 'positions');
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    sensorPositionsInRetinalMicrons(:,1) = -sensorPositions(:,1)*sensorSampleSeparationInMicrons(1);
    sensorPositionsInRetinalMicrons(:,2) =  sensorPositions(:,2)*sensorSampleSeparationInMicrons(2);
    
    
    allPositionIndices = 1:size(sensorPositionsInRetinalMicrons,1);
    idx = find(allPositionIndices <= fixationTimes.offsetBins(end));
    sceneFixationPositionIndices = allPositionIndices(idx);
    idx = find(allPositionIndices >= adaptingFieldFixationTimes.onsetBins(1));
    adaptationPositionIndices = allPositionIndices(idx);
    plot(sensorPositionsInRetinalMicrons( sceneFixationPositionIndices,1), sensorPositionsInRetinalMicrons( sceneFixationPositionIndices,2), 'r.');
    plot(sensorPositionsInRetinalMicrons( adaptationPositionIndices,1), sensorPositionsInRetinalMicrons( adaptationPositionIndices,2), 'y.');
    
    hold off
    set(gca, 'CLim', [0 1]);
    set(gca, 'XTick', [], 'YTick', []);
    hCbar = colorbar('westoutside');
    hCbar.Label.String = 'retinal illuminance';
    hCbar.FontSize = 12;
    
    subplot('Position', subplotPosVectors(2,1).v);
    imagesc(oiXdataInRetinalMicrons,  oiYdataInRetinalMicrons, sceneRetinalIlluminanceMap);  axis 'image';
    set(gca, 'CLim', [0 maxRetinalIlluminance]);
    set(gca, 'XTick', [], 'YTick', []);
    hCbar = colorbar('westoutside');
    hCbar.Label.String = 'retinal illuminance';
    hCbar.FontSize = 12;
    title(sprintf('retinal illuminance: min = %2.1f, mean=%2.1f, max=%2.2f', minRetinalIlluminance, meanRetinalIlluminance, maxRetinalIlluminance), 'FontSize', 16);
    drawnow;
    
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    pngFileName = fullfile(p.rootPath, p.figureExportsSubDir, sprintf('%s_opticalImage.png', oiGet(oi, 'name')));
    NicePlot.exportFigToPNG(pngFileName, hFig, 300);
end

