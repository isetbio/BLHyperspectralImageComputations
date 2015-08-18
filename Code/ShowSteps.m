function ShowSteps

    databaseName = 'manchester_database';
    sceneName = 'scene1';
    
    verbosity = 10;
    sceneProcessor = ISETbioSceneProcessor(databaseName, sceneName, verbosity);
    
    sceneProcessor.computeOpticalImage(...
                'forceRecompute', true, ...
                'visualizeResultsAsIsetbioWindows', false, ...
                'visualizeResultsAsImages', false ...
            );
        
    
    sceneRGBmatrix = sceneGet(sceneProcessor.scene, 'rgb image');
    support = sceneGet(sceneProcessor.scene,'spatialsupport','m');
    
    sceneXrangeInMeters = [min(min(support(:,:,1))) max(max(support(:,:,1))) ];
    sceneYrangeInMeters = [min(min(support(:,:,2))) max(max(support(:,:,2))) ];
    sceneYposNum  = size(support,1);
    sceneXposNum  = size(support,2);
    sceneXaxis = linspace(sceneXrangeInMeters(1), sceneXrangeInMeters(2), sceneXposNum);
    sceneYaxis = linspace(sceneYrangeInMeters(1), sceneYrangeInMeters(2), sceneYposNum);
    
    opticalImageRGBmatrix = oiGet(sceneProcessor.opticalImage, 'rgb image');
    opticalImageInterSampleDistanceInMicrons = oiGet(sceneProcessor.opticalImage,'distPerSamp','microns')
    opticalImageInterSampleDistanceInDegrees = oiGet(sceneProcessor.opticalImage,'distPerSamp','degrees')
    support = oiGet(sceneProcessor.opticalImage,'spatialsupport','microns');
    opticalImageXrangeInMicrons = [min(min(support(:,:,1))) max(max(support(:,:,1))) ];
    opticalImageYrangeInMicrons = [min(min(support(:,:,2))) max(max(support(:,:,2))) ];
    
    opticalImageYposNum  = size(support,1);
    opticalImageXposNum  = size(support,2);
    opticalImageXaxis = linspace(opticalImageXrangeInMicrons(1), opticalImageXrangeInMicrons(2), opticalImageXposNum);
    opticalImageYaxis = linspace(opticalImageYrangeInMicrons(1), opticalImageYrangeInMicrons(2), opticalImageYposNum);
    
    
    eyeMovementInMicrons = [...
            0    0; ...
            99 505 ...
        ];
    
    
    
    
    coneAperture = 3*1e-6;
    conesAcross = 20;
    LMSdensities = [0.6 0.3 0.1];
    coneIntegrationTime = 0.050;
    
    sensor = sensorCreate('human');
    pixel  = sensorGet(sensor,'pixel');
    pixel  = pixelSet(pixel, 'size', [1.0 1.0]*coneAperture);
    sensor = sensorSet(sensor, 'pixel', pixel);
                
    coneP = coneCreate();
    coneP = coneSet(coneP, 'spatial density', [0.0 LMSdensities(1) LMSdensities(2) LMSdensities(3)]);  % Empty (missing cone), L, M, S
    sensor = sensorCreateConeMosaic(sensor,coneP);
                
    % Set the sensor size
    sensorRows = conesAcross;
    sensorCols = conesAcross;
    sensor = sensorSet(sensor, 'size', [sensorRows sensorCols]);

    % Set the sensor wavelength sampling to that of the opticalimage
    sensor = sensorSet(sensor, 'wavelength', oiGet(sceneProcessor.opticalImage, 'wavelength'));
                
    % Set the integration time
    sensor = sensorSet(sensor,'exp time', coneIntegrationTime);
           
    sensor = sensorSet(sensor, 'noise flag', 0);
    
    
    sensorHeight = sensorGet(sensor,'height','microns');
    sensorWidth = sensorGet(sensor,'width','microns');
    
    
    for kPos = 1:size(eyeMovementInMicrons ,1)
        sensorPositionInCones(kPos,1) = -eyeMovementInMicrons(kPos,1) / (coneAperture*1e6);
        sensorPositionInCones(kPos,2) =  eyeMovementInMicrons(kPos,2) / (coneAperture*1e6);
    end
    
    % create eye movement struct
    eyeMovement = emCreate();
    % Attach it to the sensor
    sensor = sensorSet(sensor,'eyemove', eyeMovement);
            
    sensor = sensorSet(sensor,'positions', sensorPositionInCones*0);
    sensor = emGenSequence(sensor);
    sensor = sensorSet(sensor,'positions', sensorPositionInCones);
    
    sensor = coneAbsorptions(sensor, sceneProcessor.opticalImage);
        
    sensorActivationImage = sensorGet(sensor, 'volts');

    coneXYLocations    = sensorGet(sensor, 'xy');
    coneTypes          = sensorGet(sensor, 'cone type');
                
                
    % FIGURE 1 - SCENE and OPTICAL IMAGE
    hFig = figure(1); clf;
    set(hFig, 'Color', [0 0 0], 'Position', [10 10 1550 680]);
    
    subplot('Position', [0.05 0.07 0.43 0.90]);
    imagesc(sceneXaxis, sceneYaxis, sceneRGBmatrix);
    axis 'image'
    xlabel('meters', 'Color', [1 1 0.8]); ylabel('meters',  'Color', [1 1 0.8]);
    set(gca, 'XColor', [1 1 0.8], 'YColor', [1 1 0.8]);
    title('scene',  'Color', [1 1 0.8]);
    
    subplot('Position', [0.56 0.07 0.43 0.90]);
    imagesc(opticalImageXaxis, opticalImageYaxis, opticalImageRGBmatrix);
    hold on;
    kPos = 2;
    xL = eyeMovementInMicrons(kPos,1) - sensorWidth/2;
    xR = xL + sensorWidth;
    y1 = eyeMovementInMicrons(kPos,2) - sensorHeight/2;
    y2 = y1 + sensorHeight;
    plot([xL xL xR xR xL], [y1 y2 y2 y1 y1], 'w-');
    hold off;
    
    axis 'image'
    xlabel('retinal microns',  'Color', [1 1 0.8]); ylabel('retinal microns',  'Color', [1 1 0.8]);
    set(gca, 'XColor', [1 1 0.8], 'YColor', [1 1 0.8]);
    title('optical image', 'Color', [1 1 0.8]);
    
    % Set fonts for all axes, legends, and titles
    NicePlot.setFontSizes(hFig, 'FontSize', 18); 
    NicePlot.exportFigToPDF('SceneAndOpticalImage.pdf',hFig,300);
    
    
    
    
    
    hFig = figure(2); clf;
    set(hFig, 'Color', [0 0 0], 'Position', [10 10 1550 680]);
    
    subplotPosVector = NicePlot.getSubPlotPosVectors(...
        'rowsNum',      1, ...
        'colsNum',      3, ...
        'widthMargin',  0.07, ...
        'leftMargin',   0.06, ...
        'bottomMargin', 0.06, ...
        'heightMargin', 0.09, ...
        'topMargin',    0.01);
    
    subplot('Position', subplotPosVector(1,1).v);
    imagesc(opticalImageXaxis, opticalImageYaxis, opticalImageRGBmatrix);
    axis 'image'
    hold on;
    kPos = 2;
    xL = eyeMovementInMicrons(kPos,1) - sensorWidth/2;
    xR = xL + sensorWidth;
    y1 = eyeMovementInMicrons(kPos,2) - sensorHeight/2;
    y2 = y1 + sensorHeight;
    plot([xL xL xR xR xL], [y1 y2 y2 y1 y1], 'w-');
    hold off;
    set(gca, 'XLim', 100 + [-100 100], 'YLim', 505+[-100 100]);
    
    xlabel('retinal microns',  'Color', [1 1 0.8]); ylabel('retinal microns',  'Color', [1 1 0.8]);
    set(gca, 'XColor', [1 1 0.8], 'YColor', [1 1 0.8]);
    title('optical image', 'Color', [1 1 0.8]);
    
    
    subplot('Position', subplotPosVector(1,2).v);
    xaxis = linspace(-(size(sensorActivationImage,1)/2-0.5)*coneAperture*1e6, (size(sensorActivationImage,1)/2-0.5)*coneAperture*1e6, size(sensorActivationImage,1));
    yaxis = linspace(-(size(sensorActivationImage,2)/2-0.5)*coneAperture*1e6, (size(sensorActivationImage,2)/2-0.5)*coneAperture*1e6, size(sensorActivationImage,2));
    imagesc(xaxis, yaxis, sensorActivationImage(:,:,kPos));
    hold on;
    plot([-30 30], [0 0], '-', 'Color', [1 1 1]);
    plot([0 0], [-30 30], '-', 'Color', [1 1 1]);
    xlabel('retinal microns',  'Color', [1 1 0.8]); ylabel('retinal microns',  'Color', [1 1 0.8]);
    set(gca, 'XColor', [1 1 0.8], 'YColor', [1 1 0.8], 'Color', [0 0 0], 'XTick', [-100 : 10 : 100], 'YTick', [-100 : 10 : 100]);
    axis 'image'
    axis 'ij'
    title('sensor activation', 'Color', [1 1 0.8]);
    colormap(hot);
    
    subplot('Position', subplotPosVector(1,3).v);
    hold on;
    LconeIndices = find(coneTypes == 2);
    MconeIndices = find(coneTypes == 3);
    SconeIndices = find(coneTypes == 4);
    coneColors = [1 0 0; 0 1 0; 0 0.5 1.0];
    coneColors2 = [1 0.5 0.5; 0.5 1 0.5; 0.3 0.7 1.0];
    plot(coneXYLocations(LconeIndices, 1), coneXYLocations(LconeIndices, 2), 'o', 'MarkerFaceColor', coneColors2(1,:), 'MarkerEdgeColor', coneColors(1,:), 'MarkerSize', 12);
    plot(coneXYLocations(MconeIndices, 1), coneXYLocations(MconeIndices, 2), 'o', 'MarkerFaceColor', coneColors2(2,:), 'MarkerEdgeColor', coneColors(2,:), 'MarkerSize', 12);
    plot(coneXYLocations(SconeIndices, 1), coneXYLocations(SconeIndices, 2), 'o', 'MarkerFaceColor', coneColors2(3,:), 'MarkerEdgeColor', coneColors(3,:), 'MarkerSize', 12);
    plot([-30 30], [0 0], '-', 'Color', [1 1 1]);
    plot([0 0], [-30 30], '-', 'Color', [1 1 1]);
    xlabel('retinal microns',  'Color', [1 1 0.8]); ylabel('retinal microns',  'Color', [1 1 0.8]);
    set(gca, 'XColor', [1 1 0.8], 'YColor', [1 1 0.8], 'Color', [0 0 0], 'XTick', [-100 : 10 : 100], 'YTick', [-100 : 10 : 100]);
    axis 'image';
    axis 'ij'
    box on;
    title('sensor mosaic', 'Color', [1 1 0.8]);
    
    NicePlot.setFontSizes(hFig, 'FontSize', 18); 
    NicePlot.exportFigToPDF('OpticalImageSensorActivationAndSensorMosaic.pdf',hFig,300);
    
    drawnow
end

