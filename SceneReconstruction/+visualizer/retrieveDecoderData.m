function [decoderFilters, peakTimeBins, spatioTemporalSupport, coneTypes] = retrieveDecoderData(sceneSetName, decodingDataDir, computeSVDbasedLowRankFiltersAndPredictions, svdIndex)
    fprintf('\nLoading decoder filter ...');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    load(fileName, 'wVector',  'spatioTemporalSupport', 'coneTypes', 'expParams');
    fprintf('Done.\n');
    
    if (computeSVDbasedLowRankFiltersAndPredictions)
        load(fileName, 'wVectorSVDbased', 'SVDbasedLowRankFilterVariancesExplained');%, 'Utrain', 'Strain', 'Vtrain');
        wVector = squeeze(wVectorSVDbased(svdIndex,:,:));
    end
    
    %Separate the bias terms (1st row)
    biasTerms = wVector(1,:);
    wVector = wVector(2:end,:);
    
    % Allocate memory for unpacked stimDecoder
    sensorRows      = numel(spatioTemporalSupport.sensorRetinalYaxis);
    sensorCols      = numel(spatioTemporalSupport.sensorRetinalXaxis);
    xSpatialBinsNum = numel(spatioTemporalSupport.sensorFOVxaxis);                   % spatial support of decoded scene
    ySpatialBinsNum = numel(spatioTemporalSupport.sensorFOVyaxis);
    timeAxis        = spatioTemporalSupport.timeAxis;
    timeBinsNum     = numel(timeAxis);
    decoderFilters  = zeros(3, ySpatialBinsNum, xSpatialBinsNum, sensorRows, sensorCols, timeBinsNum);
    
    % Unpack the wVector into the stimDecoder
    for stimConeContrastIndex = 1:3
        for ySpatialBin = 1:ySpatialBinsNum
        for xSpatialBin = 1:xSpatialBinsNum
            stimulusDimension = sub2ind([ySpatialBinsNum xSpatialBinsNum 3], ySpatialBin, xSpatialBin, stimConeContrastIndex);
            for coneRow = 1:sensorRows
            for coneCol = 1:sensorCols
                coneIndex = sub2ind([sensorRows sensorCols], coneRow, coneCol);
                neuralResponseFeatureIndices = (coneIndex-1)*timeBinsNum + (1:timeBinsNum);
                decoderFilters(stimConeContrastIndex, ySpatialBin, xSpatialBin, coneRow, coneCol, :) = ...
                    squeeze(wVector(neuralResponseFeatureIndices, stimulusDimension));       
            end % coneRow
            end % coneCol
        end % xSpatialBin
        end % ySpatialBin
    end % coneContrastIndex
    
    % Find time of peak separately for the L-, M- and the S-cone decoders
    coneString = {'Lcone contrast', 'Mcone contrast', 'Scone contrast'};
    for decoderConeContrastIndex = 1:numel(coneString)
        % determine coords of peak response
        spatioTemporalFilter = squeeze(decoderFilters(decoderConeContrastIndex, :, :, :,:,:));
        % searh for the peak within +/- 50 msec from 0
        timeRange = 50;
        indicesForPeakResponseEstimation = find(abs(spatioTemporalSupport.timeAxis) <= timeRange);
        tmp = squeeze(spatioTemporalFilter(:,:,:,:,indicesForPeakResponseEstimation));
        [~, theIndexOfMaxResponse] = max(abs(tmp(:)));
        [peakConeRow, peakConeCol, peakDecoderYpos, peakDecoderXpos, idx] = ind2sub(size(tmp), theIndexOfMaxResponse);
        peakTimeBins(decoderConeContrastIndex) = indicesForPeakResponseEstimation(idx);
    end % stimConeContrastIndex
    
end