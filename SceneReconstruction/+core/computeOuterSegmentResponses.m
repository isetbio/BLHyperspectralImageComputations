function computeOuterSegmentResponses(expParams)

    showAndExportSceneFigures = false;
    showAndExportOpticalImages = false;
        
    % reset isetbio
    ieInit;
    
    [sceneData, sceneNames] = core.fetchTheIsetbioSceneDataSet(expParams.sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    % Determine where to save the scan data
    scansDataDir = core.getScansDataDir(expParams.descriptionString);
    
    for sceneIndex = 1: numel(sceneData)
        
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

        % Resample the optical image with a resolution = 0.5 cone aperture. NOTE: this may be different for decoding
        spatialSample = expParams.sensorParams.coneApertureInMicrons/2.0;
        oi = oiSpatialResample(oi, spatialSample, 'um', 'linear', false);
        
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
      
        % Create outer segment
        if (strcmp(expParams.outerSegmentParams.type, '@osBiophys'))
            osOBJ = osBioPhys();
        elseif (strcmp(expParams.outerSegmentParams.type, '@osLinear'))
            osOBJ = osLinear();
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

        fileName = fullfile(scansDataDir, sprintf('%s_scan_data.mat', sceneNames{sceneIndex}));
        fprintf('Saving data from scene ''%s'' to %s ...', sceneNames{sceneIndex}, fileName);
        save(fileName, 'scanData', 'scene', 'oi', 'expParams', '-v7.3');
        fprintf('Done saving \n');
        
        showResults = false;
        if (showResults)
            scanIndex = 1
            timeAxis = scanData{scanIndex}.timeAxis;
            isomerizationRange = [0 0.8*max(scanData{scanIndex}.isomerizationRateSequence(:))];
            
            for k = 1:numel(scanData{scanIndex}.timeAxis)
                scenelContrastFrame = squeeze(scanData{scanIndex}.sceneLMScontrastSequence(:,:,1,k));
                oiContrastFrame     = squeeze(scanData{scanIndex}.oiLMScontrastSequence(:,:,1,k));
                isomerizationFrame  = squeeze(scanData{scanIndex}.isomerizationRateSequence(:,:,k));
                
                M = 100;
                coneContrastRange = [-1 5];
                if (k == 2)
                    h = figure(10); set(h, 'Position', [100 100 1000 950]); clf;
                    p1Axes = subplot(4,3,1);
                    p1 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, scenelContrastFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    set(gca, 'CLim', coneContrastRange);
                    hC = colorbar('westoutside');
                    hC.Label.String = 'cone contrast';
                    hold off
                    axis 'xy';
                    axis 'image'
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                    title('Lcone contrast image (scene)');
                    
                    subplot(4,3,2);
                    p2 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, oiContrastFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    set(gca, 'CLim', coneContrastRange);
                    hold off
                    axis 'xy';
                    axis 'image'
                    
                    hC = colorbar('westoutside');
                    hC.Label.String = 'cone contrast';
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                    title('Lcone contrast image (optical image)');

                    subplot(4,3,3)
                    p3 = imagesc((-10:9)*3, (-10:9)*3, isomerizationFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    hold off
                    axis 'xy';
                    axis 'image'
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                    set(gca, 'CLim', isomerizationRange)
                    colormap(gray(1024));
                    
                    timeBins = max([1, k-M]):k;
                    p4Axes = subplot(4,3,(4:6));
                    p4 = imagesc(timeAxis(timeBins), (1:400), reshape(scanData{scanIndex}.isomerizationRateSequence(:,:, timeBins),[400 numel(timeBins)]));
                    set(gca, 'CLim', isomerizationRange)
                    hC = colorbar('westoutside');
                    hC.Label.String = 'isomerization rate (R*/cone/sec)';
                    title('isomerizations');
                    
                    p5Axes = subplot(4,3,(7:9));
                    p5 = imagesc(timeAxis(timeBins), (1:400), reshape(scanData{scanIndex}.photoCurrentSequence(:,:,timeBins),[400 numel(timeBins)]));
                    set(gca, 'CLim', [-100 0]);
                    set(h, 'Name', sprintf('t = %2.3f ms', scanData{scanIndex}.timeAxis(k)));
                    hC = colorbar('westoutside');
                    hC.Label.String = 'photocurrents (pAMps)';
                    title('photocurrents');
                    
                    p67Axes = subplot(4,3,(10:12)); 
                    p6 = plot(timeAxis(timeBins), scanData{scanIndex}.sensorPositionSequence(timeBins,1), 'r-');
                    hold on
                    p7 = plot(timeAxis(timeBins), scanData{scanIndex}.sensorPositionSequence(timeBins,2), 'b-');
                    hold off  
                    ylabel('eye position');
                    
                elseif (k > 2)
                    set(p1, 'CData', scenelContrastFrame);
                    set(p2, 'CData', oiContrastFrame);
                    set(p3, 'CData', isomerizationFrame);
                    
                    timeBins = max([1, k-M]):k;
                    set(p4, 'XData', timeAxis(timeBins), 'CData', reshape(scanData{scanIndex}.isomerizationRateSequence(:,:, timeBins),[400 numel(timeBins)]));
                    set(p4Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);    
                    set(p5, 'XData', timeAxis(timeBins), 'CData', reshape(scanData{scanIndex}.photoCurrentSequence(:,:,timeBins),[400 numel(timeBins)]));
                    set(p5Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);
                   

                    set(p6, 'XData', timeAxis(timeBins), 'YData', scanData{scanIndex}.sensorPositionSequence(timeBins,1));
                    set(p7, 'XData', timeAxis(timeBins), 'YData', scanData{scanIndex}.sensorPositionSequence(timeBins,2));
                    set(p67Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);
                    
                    set(h, 'Name', sprintf('t = %2.3f ms', scanData{scanIndex}.timeAxis(k)));
                    drawnow;
                end
            end
        end % showResults
        
        
    end % sceneIndex
end





