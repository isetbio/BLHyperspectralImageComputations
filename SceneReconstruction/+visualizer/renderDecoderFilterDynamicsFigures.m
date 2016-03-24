function renderDecoderFilterDynamicsFigures(sceneSetName, descriptionString)

    [scanSensor, sensorRows, sensorCols, ...
     sensorFOVxaxis, sensorFOVyaxis, ...                             % spatial support of decoded scene
     sceneRetinalProjectionXData, sceneRetinalProjectionYData, ...   % spatial support of scene's retinal projection (in retinal microns)
     opticalImageXData, opticalImageYData, ...                       % spatial support of scene's optical image (in retinal microns)
     timeAxis...                                                     % time axis for decoding filter
    ] = retrieveScanData(sceneSetName, descriptionString);
    

    xSpatialBinsNum     = numel(sensorFOVxaxis);
    ySpatialBinsNum     = numel(sensorFOVyaxis);
    spatialDimsNum      = xSpatialBinsNum * ySpatialBinsNum;
    timeBinsNum         = numel(timeAxis);
    
    
    % Allocate memory for unpacked stimDecoder
    stimDecoder = zeros(3, numel(sensorFOVyaxis), numel(sensorFOVxaxis), sensorRows, sensorCols, timeBinsNum);
    
    fprintf('\nLoading decoder filter ...');
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector');
    fprintf('Done.\n');

    % Normalize wVector for plotting in [-1 1]
    wVector = wVector / max(abs(wVector(:)));
    weightRange = max(abs(wVector(:)))*[-1.0 1.0];
    
    % Unpack the wVector into the stimDecoder
    dcTerm = 1;
    for stimConeContrastIndex = 1:3
        for ySpatialBin = 1:ySpatialBinsNum
        for xSpatialBin = 1:xSpatialBinsNum
            spatialStimDim = sub2ind([ySpatialBinsNum xSpatialBinsNum], ySpatialBin, xSpatialBin);
            stimulusDimension = (stimConeContrastIndex-1)*spatialDimsNum + spatialStimDim;
            for coneRow = 1:sensorRows
            for coneCol = 1:sensorCols
                coneIndex = sub2ind([sensorRows sensorCols], coneRow, coneCol);
                neuralResponseFeatureIndices = (coneIndex-1)*timeBinsNum + (1:timeBinsNum);
                stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, coneRow, coneCol, :) = ...
                    squeeze(wVector(dcTerm + neuralResponseFeatureIndices, stimulusDimension));       
            end % coneRow
            end % coneCol
        end % xSpatialBin
        end % ySpatialBin
    end % coneContrastIndex
    
    mConeFreePosXcoord = 10;
    mConeFreePosYcoord = 6;
   
    mConeRichPosXcoord = 7;
    mConeRichPosYcoord = 8;
    
    stimulusXpositionsToExamine = mConeRichPosXcoord;
    stimulusYpositionsToExamine = mConeRichPosYcoord;
    
    figure(1); clf;
    %niceCmap = cbrewer('div', 'Spectral', 1024);
    %niceCmap = cbrewer('seq', 'PuBu', 1024);
    
    niceCmap = cbrewer('div', 'RdGy', 1024);
    colormap(niceCmap(end:-1:1,:));
    
    figure(2); clf;
    
    stimConeContrastIndex = 1;
    kk = 0;
    for ySpatialBin = ySpatialBinsNum:-1:1
        for xSpatialBin = 1:xSpatialBinsNum
            
            indicesForPeakResponseEstimation = find((timeAxis >-20) & (timeAxis < 60));
            causalTimeAxis = timeAxis(indicesForPeakResponseEstimation(1):indicesForPeakResponseEstimation(end));
            tmp = squeeze(stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, :,:,indicesForPeakResponseEstimation));
            [~, idx] = max(abs(tmp(:)));
            [peakConeRow, peakConeCol, idx] = ind2sub(size(tmp), idx);
            [~,peakTimeBin] = min(abs(timeAxis - causalTimeAxis(idx)));
            fprintf('filter at (%d,%d) peaks at %2.0f msec\n', xSpatialBin, ySpatialBin, timeAxis(peakTimeBin));
            
            spatioTemporalFilter = squeeze(stimDecoder(stimConeContrastIndex, ySpatialBin, xSpatialBin, :,:,:));
            
            kk = kk + 1;
            
            figure(1)
            subplot(ySpatialBinsNum, xSpatialBinsNum, kk);
            imagesc(squeeze(spatioTemporalFilter(:,:, peakTimeBin)));
            set(gca, 'XTick', [], 'YTick', [], 'CLim', weightRange);
            axis 'xy';
            axis 'square'
            drawnow
            
            figure(2)
            subplot(ySpatialBinsNum, xSpatialBinsNum, kk);
            plot(timeAxis, squeeze(spatioTemporalFilter(peakConeRow, peakConeCol, :)), 'ks-');
            hold on;
            plot([0 0], [-1 1], 'r-');
            plot([timeAxis(1) timeAxis(end)], [0 0], 'r-');
            hold off
            axis 'square';
            set(gca, 'XTick', [], 'YTick', [], 'XLim', [timeAxis(1) timeAxis(end)], 'YLim', weightRange);
            drawnow;
        end
    end


    
end

function [ scanSensor, sensorRows, sensorCols, sensorFOVxaxis, sensorFOVyaxis, ...
           sceneRetinalProjectionXData, sceneRetinalProjectionYData, ...
           opticalImageXData, opticalImageYData, timeAxis] = ...
        retrieveScanData(sceneSetName, descriptionString)
    
    sceneSet = core.sceneSetWithName(sceneSetName);
    scansDataDir = core.getScansDataDir(descriptionString);
    sceneIndex = 1; imsource  = sceneSet{sceneIndex};
    sceneName = sprintf('%s_%s', imsource{1}, imsource{2});
    fprintf('Loading scan data for ''%s''. Please wait ... ', sceneName);
    fileName = fullfile(scansDataDir, sprintf('%s_scan_data.mat', sceneName));
    load(fileName, 'scanData', 'scene', 'oi', 'expParams');
    scanIndex = 1; scanData = scanData{scanIndex};
    
    scanSensor                  = scanData.scanSensor;
    sensorRows                  = sensorGet(scanSensor, 'row');
    sensorCols                  = sensorGet(scanSensor, 'col');
    sensorFOVxaxis              = scanData.sensorFOVxaxis;
    sensorFOVyaxis              = scanData.sensorFOVyaxis;
    sceneRetinalProjectionXData = scanData.sceneRetinalProjectionXData;
    sceneRetinalProjectionYData = scanData.sceneRetinalProjectionYData;
    opticalImageXData           = scanData.opticalImageXData;
    opticalImageYData           = scanData.opticalImageYData;
    timeAxis                    = expParams.decoderParams.latencyInMillseconds + ...
                                     (0:1:round(expParams.decoderParams.memoryInMilliseconds/expParams.decoderParams.temporalSamplingInMilliseconds)-1) * ...
                                     expParams.decoderParams.temporalSamplingInMilliseconds;
    
end
