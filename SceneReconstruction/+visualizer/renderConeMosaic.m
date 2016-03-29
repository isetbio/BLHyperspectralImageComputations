% Method to visualize the cone mosaic
function renderConeMosaic(sceneSetName, descriptionString) 

    sceneIndex = 1;
    scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
    fprintf('\nLoading scan data ''%s''. Please wait ...', scanFileName); 
    load(scanFileName, '-mat', 'scanData', 'expParams');
    
    scanData = scanData{1};
    scanSensor = scanData.scanSensor;

    % Compute indices of L,M, and S-cone indices to include (based on thesholdConeSeparation)
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = ...
        decoder.cherryPickConesToIncludeInDecoding(scanSensor, expParams.decoderParams.thresholdConeSeparationForInclusionInDecoder);
    
    xy = sensorGet(scanSensor, 'xy');
    coneTypes = sensorGet(scanSensor, 'cone type');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    hFig = figure(1);
    set(hFig, 'Position', [10 10 700 480], 'Color', [1 1 1]);
    clf;
    subplot('Position', [0.05 0.07 0.90 0.90]);
    hold on
    plot(xy(lConeIndices, 1), xy(lConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.8 0.5 0.6]);
    plot(xy(mConeIndices, 1), xy(mConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.2 0.6 0.6]);
    plot(xy(sConeIndices, 1), xy(sConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.7 0.4 1.0]);

    plot(xy(keptLconeIndices, 1), xy(keptLconeIndices, 2), 'ro', 'MarkerFaceColor', [1 0.2 0.5], 'MarkerEdgeColor', [0.8 0.5 0.6], 'MarkerSize', 16);
    plot(xy(keptMconeIndices, 1), xy(keptMconeIndices, 2), 'go', 'MarkerFaceColor', [0.2 0.8 0.5], 'MarkerEdgeColor', [0.2 0.6 0.6], 'MarkerSize', 16);
    plot(xy(keptSconeIndices, 1), xy(keptSconeIndices, 2), 'bo', 'MarkerFaceColor', [0.5 0.2 1.0], 'MarkerEdgeColor', [0.7 0.4 1.0], 'MarkerSize', 16);
    axis 'equal'; axis 'square'; box on;
    box off;
    axis 'equal'
    minX = min(xy(:,1))-3;
    maxX = max(xy(:,1))+3;
    minY = min(xy(:,2))-3;
    maxY = max(xy(:,2))+3;
    set(gca, 'XLim', [minX maxX], 'YLim', [minY maxY], 'FontSize', 14, 'XTick', [], 'YTick', []);
    xlabel(sprintf('%2.1f microns', maxX - minX), 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(sprintf('%2.1f microns', maxY - minY), 'FontSize', 18, 'FontWeight', 'bold');
    
    drawnow;
    imageFileName = fullfile(core.getDecodingDataDir(descriptionString), 'sensor.png')
    
    NicePlot.exportFigToPNG(imageFileName, hFig, 300);    
end


