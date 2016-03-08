function computeOutOfSamplePredictions(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)
    
    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);

    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    decodingFiltersVarList = {...
        'designMatrix', ...
        'wVector', ...
        'cTrainPrediction', ...
        'cTrain', ...
        'filterSpatialXdataInRetinalMicrons', ...
        'filterSpatialYdataInRetinalMicrons'...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingFiltersFileName);
    for k = 1:numel(decodingFiltersVarList)
        load(decodingFiltersFileName, decodingFiltersVarList{k});
    end
    
    decodingDataFileName = fullfile(decodingDirectory, sprintf('DecodingData.mat'));
    testingVarList = {...
        'scanSensor', ...
        'keptLconeIndices', 'keptMconeIndices', 'keptSconeIndices', ...
        'designMatrixTest', ...
        'testingTimeAxis', ...
        'testingPhotocurrents', ...
        'testingLcontrastSequence', ...
        'testingMcontrastSequence', ...
        'testingScontrastSequence' ...
        };
    
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(testingVarList)
        load(decodingDataFileName, testingVarList{k});
    end
    
    
    
    
    % display decoding filter
    fprintf('Displaying decoding filter\n');
   
    decodingFilter.conesNum = designMatrixTest.n;
    decodingFilter.latencyBins = designMatrixTest.lat;
    decodingFilter.memoryBins =  designMatrixTest.m;
    decodingFilter.timeAxis   = (designMatrixTest.lat + (0:(designMatrixTest.m-1)))*designMatrixTest.binWidth;
    
    
    
    dcTerm = 1;
    wVectorNormalized = wVector / max(abs(wVector(dcTerm+1:end)));
    featuresNum = size(wVector,1)
    spatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons)
    stimulusDimensions = size(wVector,2)
    
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
   
    timeBins = 1:decodingFilter.memoryBins;
    
    figure(3); 
     
    for stimDimIndex = 1:stimulusDimensions
        
        if (spatialFeaturesNum > 1)
            coneContrastDimIndex = floor((stimDimIndex-1)/spatialFeaturesNum)+1;
            spatialDimIndex = mod(stimDimIndex-1, spatialFeaturesNum) + 1;
            [spatialYDimIndex, spatialXDimIndex] = ind2sub([ numel(filterSpatialYdataInRetinalMicrons)  numel(filterSpatialXdataInRetinalMicrons)], spatialDimIndex);
        elseif (spatialFeaturesNum == 1)
            coneContrastDimIndex = stimDimIndex; 
        end
        
        clf;
        for coneIndex = 1:decodingFilter.conesNum
            temporalDecodingFilter = wVectorNormalized(dcTerm + (coneIndex-1)*numel(timeBins) + timeBins, stimDimIndex);
            
            if (spatialFeaturesNum == 1)
                if (coneIndex == 1) && (stimDimIndex == 1)
                    a.filter = zeros(decodingFilter.conesNum, numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(coneContrastDimIndex).filter(coneIndex,:) = temporalDecodingFilter;
            else
                if (coneIndex == 1) && (stimDimIndex == 1)
                    a.filter = zeros(decodingFilter.conesNum, numel(temporalDecodingFilter));
                    stimDecoder = repmat(a, [3 numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)]);
                end
                stimDecoder(coneContrastDimIndex, spatialYDimIndex, spatialXDimIndex).filter(coneIndex,:) = temporalDecodingFilter;
            end
            
            if ismember(filterConeIDs(coneIndex), lConeIndices)
                RGBval = [1 0. 0.];
            elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                RGBval = [0 1 0.0];
            elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                RGBval = [0.0 0 1];
            else
                error('No such cone type')
            end
            
            subplot(1,2,1);
            plot(decodingFilter.timeAxis, temporalDecodingFilter, 'k-', 'Color', RGBval);
            set(gca, 'YLim', [-1 1], 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)]);
            xlabel('msec');
            subplot(1,2,2);
            hold on;
            plot(decodingFilter.timeAxis, temporalDecodingFilter, 'k-', 'Color', RGBval);
            set(gca, 'YLim', [-1 1], 'XLim', [decodingFilter.timeAxis(1) decodingFilter.timeAxis(end)])
            xlabel('msec');
            drawnow;
        end % coneIndex
    end % stimIndex
    
    
    
    
    
    
    stimConeContrastIndex = 2; % s-cone decoding filter
    
    for timeBin = 1:numel(timeBins)
    h = figure(2); set(h, 'Name', sprintf('%d', timeBin));
    clf;
    kk = 0;
    for stimYindex = 1:numel(filterSpatialYdataInRetinalMicrons)
        for stimXindex = 1:numel(filterSpatialXdataInRetinalMicrons)
        kk = kk + 1;
        subplot(numel(filterSpatialYdataInRetinalMicrons),numel(filterSpatialXdataInRetinalMicrons),kk);
    
        coneRows = sensorGet(scanSensor, 'rows');
        coneCols = sensorGet(scanSensor, 'cols');
        filterMosaicLayoutRGBrepresentation = zeros(coneRows, coneCols, 3)+0.5;
    
        for coneIndex = 1:decodingFilter.conesNum
            % figure out the color of the filter entry
            if ismember(filterConeIDs(coneIndex), lConeIndices)
                RGBval = [0.5 0. 0.];
            elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                RGBval = [0 0.5 0.0];
            elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                RGBval = [0.0 0 0.5];
            else
                error('No such cone type')
            end
            % figure out the (row,col) position of the filter entry
            [row, col] = ind2sub([sensorGet(scanSensor, 'row') sensorGet(scanSensor, 'col')], filterConeIDs(coneIndex));

            filterMosaicLayoutRGBrepresentation(row, col, :) = [0.5 0.5 0.5] + RGBval * stimDecoder(stimConeContrastIndex, stimYindex, stimXindex).filter(coneIndex, timeBin);
        end
        image(filterMosaicLayoutRGBrepresentation);
        axis 'image'
        drawnow;
        end
        end
    
    
end

    
    % Plot the stimDecoder(1,5,1)
    
    % Plot the stimDecoder(1,1,5)
    
    pause
    % First, lets plot in-sample predictions
    for k = 1:size(cTrain, 2)
        cLimits(k,:) = max([max(abs(cTrain(:,k))) max(abs(cTrainPrediction(:,k)))])*[-1 1];
    end
    
    % select a range to plot
    timeBins = 1:size(cTrain,1);
   
    h = figure(1);
    set(h, 'Name', 'In sample predictions');
    clf;
    subplot(1,3,1);
    plot(cTrain(timeBins,1), cTrainPrediction(timeBins,1), 'r.');
    set(gca, 'XLim', cLimits(1,:), 'YLim', cLimits(1,:));
    axis 'square';
    subplot(1,3,2);
    plot(cTrain(timeBins,2), cTrainPrediction(timeBins,2), 'g.');
    set(gca, 'XLim', cLimits(2,:), 'YLim', cLimits(2,:));
    axis 'square';
    subplot(1,3,3);
    plot(cTrain(timeBins,3), cTrainPrediction(timeBins,3), 'b.');
    set(gca, 'XLim', cLimits(3,:), 'YLim', cLimits(3,:));
    axis 'square';
    
    
    h = figure(2);
    set(h, 'Name', 'In sample predictions');
    clf;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 1, ...
       'heightMargin',  0.04, ...
       'widthMargin',    0.01, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.01, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.03);

    subplot('Position', subplotPosVectors(1,1).v);
    plot(timeBins, cTrain(timeBins,1), 'k-'); hold on;
    plot(timeBins, cTrainPrediction(timeBins,1), 'r-'); hold off;
    subplot('Position', subplotPosVectors(2,1).v);
    plot(timeBins, cTrain(timeBins,2), 'k-'); hold on;
    plot(timeBins, cTrainPrediction(timeBins,2), 'g-'); hold off;
    subplot('Position', subplotPosVectors(3,1).v);
    plot(timeBins, cTrain(timeBins,3), 'k-'); hold on;
    plot(timeBins, cTrainPrediction(timeBins,3), 'b-'); hold off
    drawnow; 
    

    fprintf('\nPlease wait. Computing out-of-sample predictions ....');
    
    
    testingStimulusTrain = [
        testingLcontrastSequence', ...
        testingMcontrastSequence', ...
        testingScontrastSequence' ...
        ];
    [Xtest, cTest] = assembleDesignMatrixAndStimulusVector(designMatrixTest.T, designMatrixTest.lat, designMatrixTest.m, designMatrixTest.n, testingPhotocurrents, testingStimulusTrain);

    stimulusDimensions = size(cTest,2)
    cTestPrediction = cTest*0;
    for stimDim = 1:stimulusDimensions
        cTestPrediction(:, stimDim) = Xtest * wVector(:,stimDim);
    end
    
    fprintf('Done \n');
     
     
     % select a range to plot
    timeBins = 1:size(cTest,1);
    
    h = figure(11);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    subplot(1,3,1);
    plot(cTest(timeBins,1), cTestPrediction(timeBins,1), 'r.');
    set(gca, 'XLim', cLimits(1,:), 'YLim', cLimits(1,:));
    axis 'square';
    subplot(1,3,2);
    plot(cTest(timeBins,2), cTestPrediction(timeBins,2), 'g.');
    set(gca, 'XLim', cLimits(2,:), 'YLim', cLimits(2,:));
    axis 'square';
    subplot(1,3,3);
    plot(cTest(timeBins,3), cTestPrediction(timeBins,3), 'b.');
    set(gca, 'XLim', cLimits(3,:), 'YLim', cLimits(3,:));
    axis 'square';
    
    
    h = figure(12);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 3, ...
       'colsNum', 1, ...
       'heightMargin',  0.04, ...
       'widthMargin',    0.01, ...
       'leftMargin',     0.02, ...
       'rightMargin',    0.01, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.03);

    subplot('Position', subplotPosVectors(1,1).v);
    plot(timeBins, cTest(timeBins,1), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,1), 'r-'); hold off;
    subplot('Position', subplotPosVectors(2,1).v);
    plot(timeBins, cTest(timeBins,2), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,2), 'g-'); hold off;
    subplot('Position', subplotPosVectors(3,1).v);
    plot(timeBins, cTest(timeBins,3), 'k-'); hold on;
    plot(timeBins, cTestPrediction(timeBins,3), 'b-'); hold off
    drawnow; 
    
    
end