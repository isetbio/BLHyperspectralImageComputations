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
      
        % Compute the outersegment sequences for this scanpath
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

        
        showResults = true;
        scanIndex = 1
 
        if (showResults)
            timeAxis = scanData{scanIndex}.timeAxis;
            for k = 1:100:numel(scanData{scanIndex}.timeAxis)
                scenelContrastFrame = squeeze(scanData{scanIndex}.sceneLMSexcitationSequence(k,:,:,1));
                oiContrastFrame     = squeeze(scanData{scanIndex}.oiLMSexcitationSequence(k,:,:,1));
                isomerizationFrame  = squeeze(scanData{scanIndex}.isomerizationRateSequence(k,:,:));
                
                M = 10000;
                kMin = 100;
                coneExcitationRange = [0 0.7];
                if (k == 101)
                    h = figure(10); set(h, 'Position', [100 100 1024 500]); clf;
                    p1Axes = subplot(4,3,1);
                    p1 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, scenelContrastFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    set(gca, 'CLim', coneExcitationRange);
                    hold off
                    axis 'xy';
                    axis 'image'
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])

                    subplot(4,3,2);
                    p2 = imagesc(scanData{scanIndex}.sensorFOVxaxis, scanData{scanIndex}.sensorFOVyaxis, oiContrastFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    hold off
                    axis 'xy';
                    axis 'image'
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])

                    subplot(4,3,3)
                    p3 = imagesc((-10:9)*3, (-10:9)*3, isomerizationFrame);
                    hold on;
                    plot([0 0 ], [-100 100], 'r-');
                    plot([-100 100], [0 0 ], 'r-');
                    hold off
                    axis 'xy';
                    axis 'image'
                    set(gca, 'XLim', [min(scanData{scanIndex}.sensorFOVxaxis) max(scanData{scanIndex}.sensorFOVxaxis)], 'YLim',  [min(scanData{scanIndex}.sensorFOVyaxis) max(scanData{scanIndex}.sensorFOVyaxis)])
                    colormap(gray(1024));
                    
                    kMin = 100;
                    timeBins = max([1, k-M]):k;
                    p4Axes = subplot(4,3,(4:6));
                    baseRate = mean(mean(mean(squeeze(scanData{scanIndex}.isomerizationRateSequence(1:kMin,:,:)))));
                    d = permute(scanData{scanIndex}.isomerizationRateSequence(timeBins,:,:), [2 3 1]);
                    p4 = imagesc(timeAxis(timeBins), (1:400), reshape(d,[400 numel(timeBins)])-baseRate);
                    set(gca, 'CLim', [-10000 10000])
                    
                    p5Axes = subplot(4,3,(7:9));
                    d = permute(scanData{scanIndex}.photoCurrentSequence(timeBins,:,:), [2 3 1]);
                    p5 = imagesc(timeAxis(timeBins), (1:400), reshape(d,[400 numel(timeBins)]));
                    set(gca, 'CLim', [-100 0]);
                    set(h, 'Name', sprintf('t = %2.3f ms', scanData{scanIndex}.timeAxis(k)));
                    
                    p67Axes = subplot(4,3,(10:12)); 
                    p6 = plot(timeAxis(timeBins), scanData{scanIndex}.sensorPositionSequence(timeBins,1), 'r-');
                    hold on
                    p7 = plot(timeAxis(timeBins), scanData{scanIndex}.sensorPositionSequence(timeBins,2), 'b-');
                    hold off  
                    
                    figure(99); clf;
                    imagesc(timeAxis, (1:400), reshape(permute(scanData{scanIndex}.photoCurrentSequence, [2 3 1]), [400 numel(timeAxis)]));
                    set(gca, 'CLim', [-100 0]);
                    drawnow;    
                    
                elseif (k > 11)
                    set(p1, 'CData', scenelContrastFrame);
                    set(p1Axes, 'CLim', coneExcitationRange);
                    set(p2, 'CData', oiContrastFrame);
                    set(p3, 'CData', isomerizationFrame);
                    
                    
                    timeBins = max([1, k-M]):k;
                    if (k > kMin)
                        
                        d = permute(scanData{scanIndex}.isomerizationRateSequence(timeBins,:,:), [2 3 1]);
                        set(p4, 'XData', timeAxis(timeBins), 'CData', reshape(d,[400 numel(timeBins)])-baseRate);
                        set(p4Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);
                        
                        d = permute(scanData{scanIndex}.photoCurrentSequence(timeBins,:,:), [2 3 1]);
                        set(p5, 'XData', timeAxis(timeBins), 'CData', reshape(d,[400 numel(timeBins)]));
                        set(p5Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);
                    end
                    
                    
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





