function computeOuterSegmentResponses(expParams)

    showAndExportSceneFigures = true;
    showAndExportOpticalImages = true;
        
    % reset isetbio
    ieInit;
   
    [sceneData, sceneNames] = core.fetchTheIsetbioSceneDataSet(expParams.sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    for sceneIndex = 1: numel(sceneData)
        
        % Get the scene
        scene = sceneData{sceneIndex};
        
        % Force scene mean luminance to a set value
        scene = sceneAdjustLuminance(...
            scene, expParams.viewModeParams.forcedSceneMeanLuminance);
      
        % Add to the scene an adapting field border (10% of the total width)
        borderCols = round(sceneGet(scene, 'cols')*0.10);
        scene = core.sceneAddAdaptingField(...
            scene, expParams.viewModeParams.adaptingFieldParams, borderCols); 

        % Generate (possibly customized) human optics
        oi = oiCreate('human');
        oi = core.customizeOptics(oi, expParams.opticsParams);
        
        % Compute optical image
        oi = oiCompute(oi, scene);
        
        % Resample the optical image with a resolution = 0.5 x cone aperture.
        spatialSample = expParams.sensorParams.coneApertureInMicrons/2.0;
        oi = oiSpatialResample(oi, spatialSample, 'um', 'linear', false);
        
        % Create custom human sensor
        sensor = sensorCreate('human');
        [sensor, sensorFixationTimes, sensorAdaptingFieldFixationTimes] = ...
            core.customizeSensor(sensor, expParams.sensorParams, oi, borderCols/sceneGet(scene,'cols'));
       
        % Export figures
        if (showAndExportSceneFigures)
            visualizer.renderSceneAndAdaptingField(scene); 
        end
        
        if (showAndExportOpticalImages)
            visualizer.renderOpticalImagesOfSceneAndAdaptingField(oi, sensor, sensorFixationTimes, sensorAdaptingFieldFixationTimes); 
        end
      
        % Create outer segment
        if (strcmp(expParams.outerSegmentParams.type, '@osBiophys'))
            osOBJ = osBioPhys();
        elseif (strcmp(expParams.outerSegmentParams.type, '@osLinear'))
            osOBJ = osLinear();
        elseif (strcmp(expParams.outerSegmentParams.type, '@osIdentity'))
            osOBJ = osIdentity();
        else
            error('Unknown outer segment type: ''%s'' \n', expParams.outerSegmentParams.type);
        end
        
        if (expParams.outerSegmentParams.addNoise)
            osOBJ.osSet('noiseFlag', 1);
        else
            osOBJ.osSet('noiseFlag', 0);
        end
        
        scanData = core.computeScanData(scene, oi, sensor, osOBJ, ...
            sensorFixationTimes, sensorAdaptingFieldFixationTimes, ...
            expParams.viewModeParams.fixationsPerScan, ...
            expParams.viewModeParams.consecutiveSceneFixationsBetweenAdaptingFieldPresentation, ...
            expParams.decoderParams.spatialSamplingInRetinalMicrons, ...
            expParams.decoderParams.extraMicronsAroundSensorBorder, ...
            expParams.decoderParams.temporalSamplingInMilliseconds ...
        );

        scanFileName = core.getScanFileName(expParams.sceneSetName, expParams.resultsDir, sceneIndex);
        fprintf('Saving responses from scene  to %s ...',  scanFileName);
        save(scanFileName, 'scanData', 'scene', 'oi', 'expParams', '-v7.3');
        fprintf('Done saving \n');
        
    end % sceneIndex
end