function computeOuterSegmentResponses(expParams)

    showAndExportSceneFigures = true;
    showAndExportOpticalImages = true;
        
    % reset isetbio
    ieInit;
    
    sceneData = core.fetchTheIsetbioSceneDataSet(expParams.sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    for sceneIndex = 1:numel(sceneData)
        
        % Get the scene
        scene = sceneData{sceneIndex};
        
        % Force it's mean luminance to set value
        scene = sceneAdjustLuminance(...
            scene, expParams.viewModeParams.forcedSceneMeanLuminance);
        
        % Get the luminance map of the original scene
        originalResolution = sceneGet(scene, 'spatial resolution', 'um');
      
        % Generate adapting field scene
        adaptingFieldScene = core.generateAdaptingFieldScene(...
            scene, expParams.viewModeParams.adaptingFieldParams);
        
        
        adaptingFieldSceneLMS = core.imageFromSceneOrOpticalImage(adaptingFieldScene, 'LMS');

        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);

        % Compute optical image of adapting scene
        oiAdaptatingField = oiCreate('human');
        oiAdaptatingField = oiCompute(oiAdaptatingField, adaptingFieldScene);

        % Resample the optical images
        desiredResolution = expParams.sensorParams.opticalImageResamplingInRetinalMicrons;
        oi                = oiSpatialResample(oi,desiredResolution,'um', 'linear', false);
        oiAdaptatingField = oiSpatialResample(oiAdaptatingField,desiredResolution,'um', 'linear', false);
         
        % Create custom human sensor
        sensor = sensorCreate('human');
        sensorAdaptingField = sensor;
        [sensor, sensorFixationTimes] = core.customizeSensor(sensor, expParams.sensorParams, oi);
        [sensorAdaptingField, sensorAdaptingFieldFixationTimes] = core.customizeSensor(sensorAdaptingField, expParams.sensorAdaptingFieldParams, oiAdaptatingField);

        core.computeScanData(scene, oi, sensor, sensorFixationTimes, ...
            expParams.viewModeParams.fixationsPerScan, ...
            expParams.decoderParams.sceneResamplingInRetinalMicrons, ...
            expParams.decoderParams.extraMicronsAroundSensorBorder);

        
        pause
        
%         % Compute the time-series of LMSexcitations for this sensor
%         [lmsExcitationSequence, sceneSensorViewSpatialSupportInRetinalMicrons] = ...
%             core.computeSceneLMSstimulusSequence(scene, sensor, sceneLMS, positionIndices);
%     
%         % Compute isomerization rates for all positions
%         sensor = coneAbsorptions(sensor, oi);
%         sensorAdaptingField = coneAbsorptions(sensorAdaptingField, oiAdaptatingField);
% 
%         % Generate free-view scan sensor by mixing the two sensors according to the view mode used
%         scanSensor = core.generateFreeViewScanSensor(sensor, sensorAdaptingField, expParams.viewModeParams, sensorFixationTimes, sensorAdaptingFieldFixationTimes);
%     
%         % Compute outer segment response
%         if (strcmp(osType, 'biophysics-based'))
%             osOBJ = osBioPhys();
%         else
%             osOBJ = osLinear();
%         end
%         
%         osOBJ.osSet('noiseFlag', 1);
%         osOBJ.osCompute(scanSensor);
%         photoCurrents = osGet(osOBJ, 'ConeCurrentSignal');
        
        
        % Export figures
        if (showAndExportSceneFigures)
            core.showSceneAndAdaptingField(scene, adaptingFieldScene); 
        end
        
        if (showAndExportOpticalImages)
            core.showOpticalImagesOfSceneAndAdaptingField(oi, oiAdaptatingField); 
        end
    end % sceneIndex
end





