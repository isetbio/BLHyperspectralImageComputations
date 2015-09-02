function  displaySingleConeTraces(obj, photonAbsorptionTracesAxes, photoCurrentTracesAxes)

    coneColorsFace = [ ...
        1 0.5 0.5; ...
        0.5 1 0.5; ...
        0.3 0.7 1.0...
        ];
    
    % photon absorptions
    minR = min(obj.videoData.photonAsborptionTraces(:));
    maxR = max(obj.videoData.photonAsborptionTraces(:));
    if (isempty(obj.photonAbsorptionTracesRange))
        obj.photonAbsorptionTracesRange = [minR maxR];
    end
    if (obj.photonAbsorptionTracesRange(1) > minR)
        obj.photonAbsorptionTracesRange(1) = minR;
    end
    if (obj.photonAbsorptionTracesRange(2) < maxR)
        obj.photonAbsorptionTracesRange(2) = maxR;
    end
    
    plot(photonAbsorptionTracesAxes, 1:size(obj.videoData.photonAsborptionTraces,2), obj.videoData.photonAsborptionTraces(1,:), '-',  'Color', coneColorsFace(1,:), 'LineWidth', 2.0);
    hold(photonAbsorptionTracesAxes, 'on');
    plot(photonAbsorptionTracesAxes, 1:size(obj.videoData.photonAsborptionTraces,2), obj.videoData.photonAsborptionTraces(2,:), '-',  'Color', coneColorsFace(2,:), 'LineWidth', 2.0);
    plot(photonAbsorptionTracesAxes, 1:size(obj.videoData.photonAsborptionTraces,2), obj.videoData.photonAsborptionTraces(3,:), '-',  'Color', coneColorsFace(3,:), 'LineWidth', 2.0);
    hold(photonAbsorptionTracesAxes, 'off');
    axis(photonAbsorptionTracesAxes,'off');
    box(photonAbsorptionTracesAxes,'off');
    set(photonAbsorptionTracesAxes, 'YLim', obj.photonAbsorptionTracesRange);
    set(photonAbsorptionTracesAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []); 
    title(photonAbsorptionTracesAxes, 'photon absorptions', 'Color', [1 1 1], 'FontSize', 14);
    
    % noisy, adapted photocurrents
    minR = min(obj.videoData.photoCurrentTraces(:));
    maxR = max(obj.videoData.photoCurrentTraces(:));
    if (isempty(obj.photoCurrentsTracesRange))
        obj.photoCurrentsTracesRange = [minR maxR];
    end
    if (obj.photoCurrentsTracesRange(1) > minR)
        obj.photoCurrentsTracesRange(1) = minR;
    end
    if (obj.photoCurrentsTracesRange(2) < maxR)
        obj.photoCurrentsTracesRange(2) = maxR;
    end
    
    plot(photoCurrentTracesAxes, 1:size(obj.videoData.photoCurrentTraces,2), obj.videoData.photoCurrentTraces(1,:), '-',  'Color', coneColorsFace(1,:), 'LineWidth', 2.0);
    hold(photoCurrentTracesAxes, 'on');
    plot(photoCurrentTracesAxes, 1:size(obj.videoData.photoCurrentTraces,2), obj.videoData.photoCurrentTraces(2,:), '-',  'Color', coneColorsFace(2,:), 'LineWidth', 2.0);
    plot(photoCurrentTracesAxes, 1:size(obj.videoData.photoCurrentTraces,2), obj.videoData.photoCurrentTraces(3,:), '-',  'Color', coneColorsFace(3,:), 'LineWidth', 2.0);
    hold(photoCurrentTracesAxes, 'off');
    axis(photoCurrentTracesAxes,'off');
    box(photoCurrentTracesAxes,'off');
    set(photoCurrentTracesAxes, 'YLim', obj.photoCurrentsTracesRange);
    set(photoCurrentTracesAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', []); 
    
    title(photoCurrentTracesAxes, 'photocurrent (pre-filter)', 'Color', [1 1 1], 'FontSize', 14);
end

