% Method to visualize the cone mosaic
function renderConeMosaic(figNo, scanSensor, expParams)

    % Compute indices of L,M, and S-cone indices to include (based on thesholdConeSeparation)
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = ...
        decoder.cherryPickConesToIncludeInDecoding(scanSensor, expParams.decoderParams.thresholdConeSeparationForInclusionInDecoder);
    
    xy = sensorGet(scanSensor, 'xy');
    coneTypes = sensorGet(scanSensor, 'cone type');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    hFigSampling = figure(figNo);
    set(hFigSampling, 'Position', [10 10 1200 450]);
    clf;
    subplot(1,3,1);
    hold on
    plot(xy(lConeIndices, 1), xy(lConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.8 0.5 0.6]);
    plot(xy(mConeIndices, 1), xy(mConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.2 0.6 0.6]);
    plot(xy(sConeIndices, 1), xy(sConeIndices, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', [0.7 0.4 1.0]);

    plot(xy(keptLconeIndices, 1), xy(keptLconeIndices, 2), 'ro', 'MarkerFaceColor', [1 0.2 0.5], 'MarkerEdgeColor', [0.8 0.5 0.6], 'MarkerSize', 8);
    plot(xy(keptMconeIndices, 1), xy(keptMconeIndices, 2), 'go', 'MarkerFaceColor', [0.2 0.8 0.5], 'MarkerEdgeColor', [0.2 0.6 0.6], 'MarkerSize', 8);
    plot(xy(keptSconeIndices, 1), xy(keptSconeIndices, 2), 'bo', 'MarkerFaceColor', [0.5 0.2 1.0], 'MarkerEdgeColor', [0.7 0.4 1.0], 'MarkerSize', 8);
    axis 'equal'; axis 'square'; box on;
    drawnow;
        
end


