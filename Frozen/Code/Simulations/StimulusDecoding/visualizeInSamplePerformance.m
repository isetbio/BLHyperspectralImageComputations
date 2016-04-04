function visualizeInSamplePerformance(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)

    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);

    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    
    decodingFiltersVarList = {....
        'cTrainPrediction', ...
        'cTrain', ...
        'filterSpatialXdataInRetinalMicrons', ...
        'filterSpatialYdataInRetinalMicrons'...
        };
    
    
    fprintf('\nLoading ''%s'' ...', decodingFiltersFileName);
    for k = 1:numel(decodingFiltersVarList)
        load(decodingFiltersFileName, decodingFiltersVarList{k});
    end

    for k = 1:size(cTrain, 2)
        cLimits(k,:) = max([max(abs(cTrain(:,k))) max(abs(cTrainPrediction(:,k)))])*[-1 1];
    end
    
    % select a range to plot
    timeBins = 1:size(cTrain,1);
   
    h = figure(10); clf;
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
    
end

