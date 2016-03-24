function renderScan(sceneSetName, descriptionString, sceneIndex)

    scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
    fprintf('\nLoading scan data ''%s''. Please wait ...', scanFileName); 
    load(scanFileName, '-mat', 'scanData', 'scene', 'oi', 'expParams');
    fprintf('Done. \n');
    
    displayName = 'LCD-Apple'; %'OLED-Samsung'; % 'OLED-Samsung', 'OLED-Sony';
    gain = 25;
    [coneFundamentals, displaySPDs, wave] = core.LMSRGBconversionData(displayName, gain);
    
        
    for scanIndex = 1:numel(scanData)
        sensorRows                  = sensorGet(scanData{scanIndex}.scanSensor, 'row');
        sensorCols                  = sensorGet(scanData{scanIndex}.scanSensor, 'col');
        timeAxis                    = scanData{scanIndex}.timeAxis;
        sensorFOVxaxis              = scanData{scanIndex}.sensorFOVxaxis;
        sensorFOVyaxis              = scanData{scanIndex}.sensorFOVyaxis;
        sceneRetinalProjectionXData = scanData{scanIndex}.sceneRetinalProjectionXData;
        sceneRetinalProjectionYData = scanData{scanIndex}.sceneRetinalProjectionYData;
        opticalImageXData           = scanData{scanIndex}.opticalImageXData;
        opticalImageYData           = scanData{scanIndex}.opticalImageYData;
        sceneBackgroundExcitations  = scanData{scanIndex}.sceneBackgroundExcitations;
        oiBackgroundExcitations     = scanData{scanIndex}.oiBackgroundExcitations;
    
        isomerizationRange = [0 0.8*max(scanData{scanIndex}.isomerizationRateSequence(:))];
        conesNum = size(scanData{scanIndex}.isomerizationRateSequence,1)*size(scanData{scanIndex}.isomerizationRateSequence,2);
        coneSeparation = sensorGet(scanData{scanIndex}.scanSensor,'pixel size','um');
    
        isomerizationFrameXaxis = 0:(sensorCols-1)*coneSeparation;
        isomerizationFrameYaxis = 0:(sensorRows-1)*coneSeparation;
        isomerizationFrameXaxis = isomerizationFrameXaxis - (isomerizationFrameXaxis(end)-isomerizationFrameXaxis(1))/2;
        isomerizationFrameYaxis = isomerizationFrameYaxis - (isomerizationFrameYaxis(end)-isomerizationFrameYaxis(1))/2;

        timeBinsDisplayed = 100;
        coneContrastRange = [-1 5];
    
        for k = 1:numel(timeAxis)
            sceneLMScontrastFrame = squeeze(scanData{scanIndex}.sceneLMScontrastSequence(:,:,:,k));
            sceneLMSexcitationFrame = core.excitationFromContrast(sceneLMScontrastFrame, sceneBackgroundExcitations);
            [RGBframe, predictionOutsideGamut] = ...
                core.LMStoRGBforSpecificDisplay(...
                    sceneLMSexcitationFrame, ...
                    displaySPDs, coneFundamentals);
            if (any(predictionOutsideGamut>0))
                predictionOutsideGamut
            end
        
            aboveIndices = find(RGBframe>1);
            RGBframe(aboveIndices) = 1;
            belowIndices = find(RGBframe<0);
            RGBframe(belowIndices) = 0;
            above = numel(aboveIndices);
            below =  numel(belowIndices);
            if (above > 0 || below > 0)
                [above below]
            end
            RGBframe = RGBframe.^(1.0/1.8);
            
            sceneLconeContrastFrame = squeeze(sceneLMScontrastFrame(:,:,1));
            opticalImageLconeContrastFrame = squeeze(scanData{scanIndex}.oiLMScontrastSequence(:,:,1,k));
            isomerizationFrame = squeeze(scanData{scanIndex}.isomerizationRateSequence(:,:,k));

            if (k == 2)
                h = figure(10); set(h, 'Position', [100 100 1000 950]); clf;
                colormap(gray(1024));

                p1Axes = subplot(4,3,1);
                p1 = imagesc(sensorFOVxaxis, sensorFOVyaxis, RGBframe); % sceneLconeContrastFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                set(gca, 'CLim', [0 1]);
                hC = colorbar('westoutside');
                hC.Label.String = 'scene cone contrast';
                hold off
                axis 'xy';
                axis 'image'
                set(gca, 'XLim', [min(sensorFOVxaxis) max(sensorFOVxaxis)], 'YLim',  [min(sensorFOVyaxis) max(sensorFOVyaxis)])
                title('Lcone contrast image (scene)');

                subplot(4,3,2);
                p2 = imagesc(sensorFOVxaxis, sensorFOVyaxis, opticalImageLconeContrastFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                set(gca, 'CLim', coneContrastRange);
                hold off
                axis 'xy';
                axis 'image'

                hC = colorbar('westoutside');
                hC.Label.String = 'cone contrast';
                set(gca, 'XLim', [min(sensorFOVxaxis) max(sensorFOVxaxis)], 'YLim',  [min(sensorFOVyaxis) max(sensorFOVyaxis)])
                title('Lcone contrast image (optical image)');

                subplot(4,3,3)
                p3 = imagesc(isomerizationFrameXaxis, isomerizationFrameYaxis, isomerizationFrame);
                hold on;
                plot([0 0 ], [-100 100], 'r-');
                plot([-100 100], [0 0 ], 'r-');
                hold off
                axis 'xy';
                axis 'image'
                set(gca, 'XLim', [min(sensorFOVxaxis) max(sensorFOVxaxis)], 'YLim',  [min(sensorFOVyaxis) max(sensorFOVyaxis)])
                set(gca, 'CLim', isomerizationRange)

                timeBins = max([1, k-timeBinsDisplayed]):k;
                p4Axes = subplot(4,3,(4:6));
                p4 = imagesc(timeAxis(timeBins), (1:conesNum), reshape(scanData{scanIndex}.isomerizationRateSequence(:,:, timeBins),[conesNum numel(timeBins)]));
                set(gca, 'CLim', isomerizationRange)
                hC = colorbar('westoutside');
                hC.Label.String = 'isomerization rate (R*/cone/sec)';
                title('isomerizations');

                p5Axes = subplot(4,3,(7:9));
                p5 = imagesc(timeAxis(timeBins), (1:conesNum), reshape(scanData{scanIndex}.photoCurrentSequence(:,:,timeBins),[conesNum numel(timeBins)]));
                set(gca, 'CLim', [-100 0]);
                set(h, 'Name', sprintf('t = %2.3f ms', timeAxis(k)));
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
                set(p1, 'CData', RGBframe); % sceneLconeContrastFrame);
                set(p2, 'CData', opticalImageLconeContrastFrame);
                set(p3, 'CData', isomerizationFrame);

                timeBins = max([1, k-timeBinsDisplayed]):k;
                set(p4, 'XData', timeAxis(timeBins), 'CData', reshape(scanData{scanIndex}.isomerizationRateSequence(:,:, timeBins),[conesNum numel(timeBins)]));
                set(p4Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);    
                set(p5, 'XData', timeAxis(timeBins), 'CData', reshape(scanData{scanIndex}.photoCurrentSequence(:,:,timeBins),[conesNum numel(timeBins)]));
                set(p5Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);


                set(p6, 'XData', timeAxis(timeBins), 'YData', scanData{scanIndex}.sensorPositionSequence(timeBins,1));
                set(p7, 'XData', timeAxis(timeBins), 'YData', scanData{scanIndex}.sensorPositionSequence(timeBins,2));
                set(p67Axes, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);

                set(h, 'Name', sprintf('t = %2.3f ms', timeAxis(k)));
                drawnow;
            end
        end  % for k 
    end % scanIndex
    
end

