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
      
        % Generate adapting field scene
        sceneAdaptingField = core.generateAdaptingFieldScene(...
            scene, expParams.viewModeParams.adaptingFieldParams); 

        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);

        % Compute optical image of adapting scene
        oiAdaptingField = oiCreate('human');
        oiAdaptingField = oiCompute(oiAdaptingField, sceneAdaptingField);

        % Resample the optical images
        desiredResolution = 1.0;   % 1.0 micron
        oi                = oiSpatialResample(oi,desiredResolution,'um', 'linear', false);
        oiAdaptingField   = oiSpatialResample(oiAdaptingField,desiredResolution,'um', 'linear', false);
         
        % Create custom human sensor
        sensor = sensorCreate('human');
        sensorAdaptingField = sensor;
        [sensor, sensorFixationTimes] = core.customizeSensor(sensor, expParams.sensorParams, oi);
        [sensorAdaptingField, sensorAdaptingFieldFixationTimes] = core.customizeSensor(sensorAdaptingField, expParams.sensorAdaptingFieldParams, oiAdaptingField);

        % Compute isomerizations
        sensor = coneAbsorptions(sensor, oi);
        sensorAdaptingField = coneAbsorptions(sensorAdaptingField, oiAdaptingField);

        core.computeScanData(scene, oi, sensor, sensorFixationTimes, ...
            sceneAdaptingField, oiAdaptingField, sensorAdaptingField, sensorAdaptingFieldFixationTimes, ...
            expParams.viewModeParams.fixationsPerScan, ...
            expParams.viewModeParams.consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
            expParams.decoderParams.spatialSamplingInRetinalMicrons, ...
            expParams.decoderParams.extraMicronsAroundSensorBorder ...
        );

        
        pause
        
%         % Compute the time-series of LMSexcitations for this sensor
%         [lmsExcitationSequence, sceneSensorViewSpatialSupportInRetinalMicrons] = ...
%             core.computeSceneLMSstimulusSequence(scene, sensor, sceneLMS, positionIndices);
%     
%         % Compute isomerization rates for all positions

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
            core.showOpticalImagesOfSceneAndAdaptingField(oi, oiAdaptingField); 
        end
    end % sceneIndex
end





