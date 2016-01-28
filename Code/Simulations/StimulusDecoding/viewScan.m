function viewScan

    % Spacify images
    imageSources = {...
        {'manchester_database', 'scene1'} ...
        {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
        {'manchester_database', 'scene4'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    for imageIndex = 1:numel(imageSources)
        imsource = imageSources{imageIndex};
        
        for scanIndex = 1:1
            scanFilename = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            whos('-file', scanFilename)
            load(scanFilename, 'scanSensor', 'scanPlusAdaptationFieldTimeAxis', 'scanPlusAdaptationFieldLMSexcitationSequence', 'LMSexcitationXdataInRetinalMicrons', 'LMSexcitationYdataInRetinalMicrons', 'sensorAdaptationFieldParams');
        end
                
        % Compute outer-segment response
        osB = osBioPhys();
        osB.osSet('noiseFlag', 1);
        osB.osCompute(scanSensor);

        photoCurrents = osGet(osB, 'ConeCurrentSignal'); 
        
        % Smooth photocurrent using a Gaussian temporal filter with a 10 msec sigma
        tauInSeconds = 5/1000;
        fprintf('Lowpassing raw photocurrents with a filter with %2.2f msec time constant\n', tauInSeconds*1000);
        tauInSamples = round(tauInSeconds / sensorGet(scanSensor, 'time interval'));
        kernelTimeSupport = ((-3*tauInSamples):(3*tauInSamples))*sensorGet(scanSensor, 'time interval');
        kernel = exp(-0.5*(kernelTimeSupport/tauInSeconds).^2);
        kernel = kernel / sum(kernel);
        photoCurrentsLowPass = photoCurrents*0;
        for i = 1:size(photoCurrents,1)
            for j = 1:size(photoCurrents,2)
                photoCurrentsLowPass(i,j,:) = conv(squeeze(photoCurrents(i,j,:)), kernel, 'same');
            end
        end
        
        % Substract baseline (determined by the last point in the photocurrent time series)
        binsToRemove = round(sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds/2/1000*sensorGet(scanSensor, 'time interval'));
        
        
        lastBinsRaw = size(photoCurrents,3)-binsToRemove+(-binsToRemove/4:binsToRemove/4);
        photoCurrents = bsxfun(@minus, photoCurrents, photoCurrents(:,:,lastBinsRaw));
        lastBinsLowPass = size(photoCurrentsLowPass,3)-binsToRemove;
        photoCurrentsLowPass = bsxfun(@minus, photoCurrentsLowPass, photoCurrentsLowPass(:,:,lastBinsLowPass));
        
        % Compute upsampled photocurrent maps for visualization
        fprintf('Upsampling raw photocurrent maps.\n');
        [LconePhotocurrentMap, MconePhotocurrentMap, SconePhotocurrentMap, photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, ...
            LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateIsomerizationMaps(scanSensor, photoCurrents);

        
        fprintf('Upsampling low-passed photocurrent maps.\n');
        [LconePhotocurrentMapLowPass, MconePhotocurrentMapLowPass, SconePhotocurrentMapLowPass, photocurrentMapXdataInRetinalMicrons, photocurrentMapYdataInRetinalMicrons, ...
            LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateIsomerizationMaps(scanSensor, photoCurrentsLowPass);

        
        
        % Compute upsampled isomerization maps for visualization
        fprintf('Upsampling isomerization maps.\n');
        isomerizationRates = sensorGet(scanSensor, 'photon rate');
        [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap, isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, ...
            LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateIsomerizationMaps(scanSensor, isomerizationRates);

        % Displayed range of LMS cone photocurrents (computed from the outer segments)
        LMphotocurrentRange = [min([min(LconePhotocurrentMap(:)) min(MconePhotocurrentMap(:))]) max([max(LconePhotocurrentMap(:)) max(MconePhotocurrentMap(:))])];
        SphotocurrentRange  = [min(SconePhotocurrentMap(:)) max(SconePhotocurrentMap(:))];
       
        % Displayed range of LMS cone excitations (computed from the scene data using Stockman fundamentals)
        LMconeExcitationRange = [min(min(min(min(scanPlusAdaptationFieldLMSexcitationSequence(:, :, : ,1:2))))) max(max(max(max(scanPlusAdaptationFieldLMSexcitationSequence(:, :, : ,1:2)))))];
        SconeExcitationRange  = [min(min(min(scanPlusAdaptationFieldLMSexcitationSequence(:, :, : ,3)))) max(max(max(scanPlusAdaptationFieldLMSexcitationSequence(:, :, : ,3))))];
        
        % Displayed range of LMS isomerizations (computed from the sensor)
        LMisomerizationRange = [min([min(LconeIsomerizationMap(:)) min(MconeIsomerizationMap(:))]) max([max(LconeIsomerizationMap(:)) max(MconeIsomerizationMap(:))])];
        SisomerizationRange  = [min(SconeIsomerizationMap(:)) max(SconeIsomerizationMap(:))];
        
        % Select a row,col for the isomerization map
        targetLconeRowIndex = 1;
        targetLconeColIndex = 1;
        
        targetMconeRowIndex = 1;
        targetMconeColIndex = 1;
        
        targetSconeRowIndex = 1;
        targetSconeColIndex = 1;
        
        
        % Determine the equivalent position in the excitation map
        targetLconeXpos = isomerizationMapXdataInRetinalMicrons(LconeCols(targetLconeColIndex));
        targetLconeYpos = isomerizationMapYdataInRetinalMicrons(LconeRows(targetLconeRowIndex));
        targetMconeXpos = isomerizationMapXdataInRetinalMicrons(MconeCols(targetMconeColIndex));
        targetMconeYpos = isomerizationMapYdataInRetinalMicrons(MconeRows(targetMconeRowIndex));
        targetSconeXpos = isomerizationMapXdataInRetinalMicrons(SconeCols(targetSconeColIndex));
        targetSconeYpos = isomerizationMapYdataInRetinalMicrons(SconeRows(targetSconeRowIndex));
        
        
        [~, ix] = min(abs(LMSexcitationXdataInRetinalMicrons - targetLconeXpos));
        targetLconeColInExcitationMap = ix;
        [~, ix] = min(abs(LMSexcitationYdataInRetinalMicrons - targetLconeYpos));
        targetLconeRowInExcitationMap = ix;
        
        [~, ix] = min(abs(LMSexcitationXdataInRetinalMicrons - targetMconeXpos));
        targetMconeColInExcitationMap = ix;
        [~, ix] = min(abs(LMSexcitationYdataInRetinalMicrons - targetMconeYpos));
        targetMconeRowInExcitationMap = ix;
        
        [~, ix] = min(abs(LMSexcitationXdataInRetinalMicrons - targetSconeXpos));
        targetSconeColInExcitationMap = ix;
        [~, ix] = min(abs(LMSexcitationYdataInRetinalMicrons - targetSconeYpos));
        targetSconeRowInExcitationMap = ix;
        
        figure(1);
        clf;
        subplot(3,1,1)
        hold on;
        
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(LconePhotocurrentMap(LconeRows(targetLconeRowIndex), LconeCols(targetLconeColIndex), :))/LMphotocurrentRange(2), '-', 'Color', [0.4 0.4 0.3]);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(LconePhotocurrentMapLowPass(LconeRows(targetLconeRowIndex), LconeCols(targetLconeColIndex), :))/LMphotocurrentRange(2), '-', 'Color', [1 1 0.9], 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(LconeIsomerizationMap(LconeRows(targetLconeRowIndex), LconeCols(targetLconeColIndex), :))/LMisomerizationRange(2), 'r-', 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(:, targetLconeRowInExcitationMap, targetLconeColInExcitationMap, 1))/LMconeExcitationRange(2), 'm-', 'LineWidth', 2.0);
        plot(kernelTimeSupport, kernel, 'w-', 'LineWidth', 2.0);
        % plot the analysis limits
        plot(scanPlusAdaptationFieldTimeAxis(binsToRemove)*[1 1],     [0 1], '-', 'Color', [0.5 0.5 1.0]);
        plot(scanPlusAdaptationFieldTimeAxis(end-binsToRemove)*[1 1], [0 1], '-', 'Color', [0.5 0.5 1.0]);
        
        
        hold off;
        h1 = legend('Lcone photocurrent (raw)', 'Lcone photocurrent (lowpass)', 'Lcone isomerization rate', 'Lcone excitation (Stockman)', 'smoothing kernel', 'analysisTbegin', 'analysisTend');
        set(h1, 'FontSize', 12, 'Color', [0.2 0.2 0.2], 'TextColor', [0.8 0.8 0.8]);
        set(gca, 'Color', [0.2 0.2 0.2], 'XLim', [scanPlusAdaptationFieldTimeAxis(1) scanPlusAdaptationFieldTimeAxis(end)]);
        
        subplot(3,1,2);
        hold on
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(MconePhotocurrentMap(MconeRows(targetMconeRowIndex), MconeCols(targetMconeColIndex), :))/LMphotocurrentRange(2), '-', 'Color', [0.4 0.4 0.3]);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(MconePhotocurrentMapLowPass(MconeRows(targetMconeRowIndex), MconeCols(targetMconeColIndex), :))/LMphotocurrentRange(2), '-', 'Color', [1 1 0.9], 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(MconeIsomerizationMap(MconeRows(targetMconeRowIndex), MconeCols(targetMconeColIndex), :))/LMisomerizationRange(2), 'g-', 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(:, targetMconeRowInExcitationMap, targetMconeColInExcitationMap, 2))/LMconeExcitationRange(2), 'y-', 'LineWidth', 2.0);
        hold off;
        h2 = legend('Mcone photocurrent (raw)', 'Mcone photocurrent (lowpass)', 'Mcone isomerization rate', 'Mcone excitation (Stockman)');
        set(h2, 'FontSize', 12, 'Color', [0.2 0.2 0.2], 'TextColor', [0.8 0.8 0.8]);
        set(gca, 'Color', [0.2 0.2 0.2], 'XLim', [scanPlusAdaptationFieldTimeAxis(1) scanPlusAdaptationFieldTimeAxis(end)]);
        
        subplot(3,1,3)
        hold on;
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(SconePhotocurrentMap(SconeRows(targetSconeRowIndex), SconeCols(targetSconeColIndex), :))/SphotocurrentRange(2), '-', 'Color', [0.4 0.4 0.3]);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(SconePhotocurrentMapLowPass(SconeRows(targetSconeRowIndex), SconeCols(targetSconeColIndex), :))/SphotocurrentRange(2), '-', 'Color', [1 1 0.9], 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(SconeIsomerizationMap(SconeRows(targetSconeRowIndex), SconeCols(targetSconeColIndex), :))/SisomerizationRange(2), 'b-', 'LineWidth', 2.0);
        plot(scanPlusAdaptationFieldTimeAxis, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(:, targetSconeRowInExcitationMap, targetSconeColInExcitationMap, 3))/SconeExcitationRange(2), 'c-', 'LineWidth', 2.0);
        hold off;
        h3 = legend('Scone photocurrent (raw)', 'Scone photocurrent (lowpass)', 'Scone isomerization rate', 'Scone excitation (Stockman)');
        set(h3, 'FontSize', 12, 'Color', [0.2 0.2 0.2], 'TextColor', [0.8 0.8 0.8]);
        set(gca, 'Color', [0.2 0.2 0.2], 'XLim', [scanPlusAdaptationFieldTimeAxis(1) scanPlusAdaptationFieldTimeAxis(end)]);
        drawnow
        
        fprintf('Displaying ... \n');
        hFig = figure(2);
        clf;
        colormap(bone);
        
        for binIndex = 1:1:numel(scanPlusAdaptationFieldTimeAxis)
            set(hFig, 'Name', sprintf('%2.2f msec', 1000*scanPlusAdaptationFieldTimeAxis(binIndex)));
            
            if (binIndex == 1)
                subplot(2,3,1);
                hLconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
                hold on;
                plot(LMSexcitationXdataInRetinalMicrons(targetLconeColInExcitationMap), LMSexcitationYdataInRetinalMicrons(targetLconeRowInExcitationMap), 'ro');
                plot([0 0], [LMSexcitationYdataInRetinalMicrons(1) LMSexcitationYdataInRetinalMicrons(end)], 'r-');
                plot([LMSexcitationXdataInRetinalMicrons(1) LMSexcitationXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', LMconeExcitationRange);
                title('Lcone excitation'); 
                colorbar
                
                subplot(2,3,2);
                hMconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
                hold on;
                plot(LMSexcitationXdataInRetinalMicrons(targetMconeColInExcitationMap), LMSexcitationYdataInRetinalMicrons(targetMconeRowInExcitationMap), 'go');
                plot([0 0], [LMSexcitationYdataInRetinalMicrons(1) LMSexcitationYdataInRetinalMicrons(end)], 'r-');
                plot([LMSexcitationXdataInRetinalMicrons(1) LMSexcitationXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', LMconeExcitationRange);
                title('Mcone excitation');
                colorbar
                
                subplot(2,3,3);
                hSconeExcMap = imagesc(LMSexcitationXdataInRetinalMicrons, LMSexcitationYdataInRetinalMicrons, squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));
                hold on;
                plot(LMSexcitationXdataInRetinalMicrons(targetSconeColInExcitationMap), LMSexcitationYdataInRetinalMicrons(targetSconeRowInExcitationMap), 'bo');
                plot([0 0], [LMSexcitationYdataInRetinalMicrons(1) LMSexcitationYdataInRetinalMicrons(end)], 'r-');
                plot([LMSexcitationXdataInRetinalMicrons(1) LMSexcitationXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', SconeExcitationRange);
                title('Scone excitation');
                colorbar
                
                subplot(2,3,4);
                hLconeIsomMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(LconeIsomerizationMap(:,:,binIndex)));
                hold on;
                plot(targetLconeXpos, targetLconeYpos, 'ro');
                plot([0 0], [isomerizationMapYdataInRetinalMicrons(1) isomerizationMapYdataInRetinalMicrons(end)], 'r-');
                plot([isomerizationMapXdataInRetinalMicrons(1) isomerizationMapXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', LMisomerizationRange);
                title('Lcone isomerization');
                colorbar
                
                subplot(2,3,5);
                hMconeIsomMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(MconeIsomerizationMap(:,:,binIndex)));
                hold on;
                plot(targetMconeXpos, targetMconeYpos, 'go');
                plot([0 0], [isomerizationMapYdataInRetinalMicrons(1) isomerizationMapYdataInRetinalMicrons(end)], 'r-');
                plot([isomerizationMapXdataInRetinalMicrons(1) isomerizationMapXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', LMisomerizationRange);
                title('Mcone isomerization');
                colorbar
                
                subplot(2,3,6);
                hSconeIsomMap = imagesc(isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, squeeze(SconeIsomerizationMap(:,:,binIndex)));
                hold on;
                plot(targetSconeXpos, targetSconeYpos, 'bo');
                plot([0 0], [isomerizationMapYdataInRetinalMicrons(1) isomerizationMapYdataInRetinalMicrons(end)], 'r-');
                plot([isomerizationMapXdataInRetinalMicrons(1) isomerizationMapXdataInRetinalMicrons(end)], [0 0], 'r-');
                hold off
                axis 'image'
                set(gca, 'CLim', SisomerizationRange);
                title('Scone isomerization');
                colorbar  
            else
                set(hLconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,1)));
                set(hMconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,2)));
                set(hSconeExcMap, 'CData', squeeze(scanPlusAdaptationFieldLMSexcitationSequence(binIndex, :,:,3)));
                
                set(hLconeIsomMap, 'CData', squeeze(LconeIsomerizationMap(:,:,binIndex)));
                set(hMconeIsomMap, 'CData', squeeze(MconeIsomerizationMap(:,:,binIndex)));
                set(hSconeIsomMap, 'CData', squeeze(SconeIsomerizationMap(:,:,binIndex)));
            end
            drawnow;
        end
        
    end
    
end

function [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap, isomerizationMapXdataInRetinalMicrons, isomerizationMapYdataInRetinalMicrons, ...
    LconeRows, LconeCols, MconeRows, MconeCols, SconeRows, SconeCols] = generateIsomerizationMaps(scanSensor, coneSignals)
    
    coneTypes          = sensorGet(scanSensor, 'cone type')-1;
    sensorRowsCols     = sensorGet(scanSensor, 'size');
    sensorSampleSeparationInMicrons = sensorGet(scanSensor,'pixel size','um');
    
    upSampleFactor = 5;
    zeroPadRows = 1;
    zeroPadCols = 1;
    
    
    LconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    MconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    SconeIsomerizationMap = zeros((sensorRowsCols(1)+2*zeroPadRows)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols)*upSampleFactor, size(coneSignals,3));
    
    LconeRows = [];
    LconeCols = [];
    MconeRows = [];
    MconeCols = [];
    SconeRows = [];
    SconeCols = [];
    
    for coneRow = 1:sensorRowsCols(1)
    for coneCol = 1:sensorRowsCols(2)
       mapRow = (coneRow+zeroPadRows)*upSampleFactor;
       mapCol = (coneCol+zeroPadCols)*upSampleFactor;     
       coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
       if (coneTypes(coneIndex) == 1)
           LconeRows = [LconeRows mapRow];
           LconeCols = [LconeCols mapCol];
           LconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       elseif (coneTypes(coneIndex) == 2)
           MconeRows = [MconeRows mapRow];
           MconeCols = [MconeCols mapCol];
           MconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       elseif (coneTypes(coneIndex) == 3)
           SconeRows = [SconeRows mapRow];
           SconeCols = [SconeCols mapCol];
           SconeIsomerizationMap(mapRow, mapCol, :) = coneSignals(coneRow, coneCol, :);
       else
           error('Cone type must be 1, 2 or 3');
       end
    end
    end
    
    % Generate Gaussian kernel
    x = -(upSampleFactor-1)/2:(upSampleFactor-1)/2;
    [X,Y] = meshgrid(x,x);
    sigma = upSampleFactor/2.9;
    gaussianKernel = exp(-0.5*(X/sigma).^2).*exp(-0.5*(Y/sigma).^2);
    gaussianKernel = gaussianKernel / max(gaussianKernel(:));
    
    for binIndex = 1:size(coneSignals,3)
        LconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(LconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
        MconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(MconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
        SconeIsomerizationMap(:,:,binIndex) = conv2(squeeze(SconeIsomerizationMap(:,:,binIndex)), gaussianKernel, 'same'); 
    end
    
    isomerizationMapXdataInRetinalMicrons = (0:size(LconeIsomerizationMap,2)-1)/(size(LconeIsomerizationMap,2)-1) - 0.5;
    isomerizationMapXdataInRetinalMicrons = isomerizationMapXdataInRetinalMicrons * (sensorRowsCols(2)+zeroPadCols*2)*sensorSampleSeparationInMicrons(1);
    isomerizationMapYdataInRetinalMicrons = (0:size(LconeIsomerizationMap,1)-1)/(size(LconeIsomerizationMap,1)-1) - 0.5;
    isomerizationMapYdataInRetinalMicrons = isomerizationMapYdataInRetinalMicrons * (sensorRowsCols(1)+zeroPadRows*2)*sensorSampleSeparationInMicrons(2);
    
end

