function sensorData = retrieveSensorData(sceneSetName, resultsDir, decoder, targetLdecoderXYcoords, targetMdecoderXYcoords, targetSdecoderXYcoords)

    scanFileName = core.getScanFileName(sceneSetName, resultsDir, 1);
    load(scanFileName, 'scanData');
    
    % Sensor data    
    sensorData.spatialSupportX = scanData{1}.sensorRetinalXaxis;
    sensorData.spatialSupportY = scanData{1}.sensorRetinalYaxis;
    sensorData.spatialOutlineX = [sensorData.spatialSupportX(1) sensorData.spatialSupportX(end) sensorData.spatialSupportX(end) sensorData.spatialSupportX(1)   sensorData.spatialSupportX(1)];
    sensorData.spatialOutlineY = [sensorData.spatialSupportY(1) sensorData.spatialSupportY(1)   sensorData.spatialSupportY(end) sensorData.spatialSupportY(end) sensorData.spatialSupportY(1)];
    sensorData.decodedImageSpatialSupportX = scanData{1}.sensorFOVxaxis;
    sensorData.decodedImageSpatialSupportY = scanData{1}.sensorFOVyaxis;
    dx = (sensorData.decodedImageSpatialSupportX(2)-sensorData.decodedImageSpatialSupportX(1))/2;
    dy = (sensorData.decodedImageSpatialSupportY(2)-sensorData.decodedImageSpatialSupportY(1))/2;
    sensorData.decodedImageOutlineX = [sensorData.decodedImageSpatialSupportX(1)-dx sensorData.decodedImageSpatialSupportX(1)-dx   sensorData.decodedImageSpatialSupportX(end)+dx sensorData.decodedImageSpatialSupportX(end)+dx sensorData.decodedImageSpatialSupportX(1)-dx];
    sensorData.decodedImageOutlineY = [sensorData.decodedImageSpatialSupportY(1)-dy sensorData.decodedImageSpatialSupportY(end)+dy sensorData.decodedImageSpatialSupportY(end)+dy sensorData.decodedImageSpatialSupportY(1)-dy   sensorData.decodedImageSpatialSupportY(1)-dy];
        
    % returm other useful info: coords for the most central L,M, and S-cone
    conePositions = sensorGet(scanData{1}.scanSensor, 'xy');
    coneTypes = sensorGet(scanData{1}.scanSensor, 'cone type');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    sensorData.conePositions = conePositions;
    sensorData.coneTypes     = coneTypes;

    sensorData.targetLCone = visualizer.getTargetCone(decoder, sensorData, conePositions, targetLdecoderXYcoords, 1, lConeIndices);
    sensorData.targetMCone = visualizer.getTargetCone(decoder, sensorData, conePositions, targetMdecoderXYcoords, 2, mConeIndices);
    sensorData.targetSCone = visualizer.getTargetCone(decoder, sensorData, conePositions, targetSdecoderXYcoords, 3, sConeIndices);

end