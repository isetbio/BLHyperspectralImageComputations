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
        
        % Force scene mean luminance to a set value
        scene = sceneAdjustLuminance(...
            scene, expParams.viewModeParams.forcedSceneMeanLuminance);
      
        % Add to the scene an adapting field border (15% of the total width)
        borderCols = round(sceneGet(scene, 'cols')*0.15);
        scene = core.sceneAddAdaptingField(...
            scene, expParams.viewModeParams.adaptingFieldParams, borderCols); 

        
        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);

        % Resample the optical image
        oi = oiSpatialResample(oi, 1.0,'um', 'linear', false); % 1.0 micron for computations. note: this may be different for decoding
         
        
        % Create custom human sensor
        sensor = sensorCreate('human');
        [sensor, sensorFixationTimes, sensorAdaptingFieldFixationTimes] = ...
            core.customizeSensor(sensor, expParams.sensorParams, oi, borderCols/sceneGet(scene,'cols'));
       
        % Export figures
        if (showAndExportSceneFigures)
            core.showSceneAndAdaptingField(scene); 
        end
        
        if (showAndExportOpticalImages)
            core.showOpticalImagesOfSceneAndAdaptingField(oi, sensor, sensorFixationTimes, sensorAdaptingFieldFixationTimes); 
        end
        
        if (1==2)
        % Compute isomerizations
        sensor = coneAbsorptions(sensor, oi);
      
        core.computeScanData(scene, oi, sensor, ...
            sensorFixationTimes, sensorAdaptingFieldFixationTimes, ...
            expParams.viewModeParams.fixationsPerScan, ...
            expParams.viewModeParams.consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
            expParams.decoderParams.spatialSamplingInRetinalMicrons, ...
            expParams.decoderParams.extraMicronsAroundSensorBorder ...
        );
        end
        

        
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
        
        
        
    end % sceneIndex
end





