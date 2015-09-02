function displayLearnedConeMosaic(obj, xyMDSAxes, xzMDSAxes, yzMDSAxes, mosaicAxes)

    % Determine specral range
    xx = squeeze(obj.unwrappedMDSprojection(:,1));
    minX = min(xx);
    maxX = max(xx);
    margin = 100 - (maxX - minX);
    if (margin < 0)
        margin = 0;
    end
    XLims = [minX-margin/2 maxX+margin/2];
    spatialExtent = max(obj.core1Data.trueConeXYLocations(:)) * 1.2;
    YLims = spatialExtent*[-1 1];
    ZLims = spatialExtent*[-1 1];
    
    % Plot the three 2-D views of the unwrapped MDS projection
    coneIndices = {...
        obj.unwrappedLconeIndices ...
        obj.unwrappedMconeIndices ...
        obj.unwrappedSconeIndices ...
    };

    coneColorsEdge = [...
        1 0 0; ...
        0 1 0; ...
        0 0.5 1.0...
        ];
    coneColorsFace = [ ...
        1 0.5 0.5; ...
        0.5 1 0.5; ...
        0.3 0.7 1.0...
        ];
                
    for viewIndex = 1:3
        
        switch viewIndex
            case 1
                drawingAxes = xyMDSAxes;
                viewingAngles = [0 90];    
            case 2
                drawingAxes = xzMDSAxes;
                viewingAngles = [0 0];
            case 3
                drawingAxes = yzMDSAxes;
                viewingAngles = [90 0];
        end % switch viewIndex
        
        for coneType = 1:numel(coneIndices)
            scatter3(drawingAxes, ...
                obj.unwrappedMDSprojection(coneIndices{coneType},1), ...
                obj.unwrappedMDSprojection(coneIndices{coneType},2), ...
                obj.unwrappedMDSprojection(coneIndices{coneType},3), ...
                70, 'filled',  ...
                'MarkerFaceColor',coneColorsFace(coneType,:), ...
                'MarkerEdgeColor',coneColorsEdge(coneType,:), ...
                'LineWidth', 1 ...
                );  
            if (coneType == 1)
                hold(drawingAxes, 'on');
            end
        end
        
        scatter3(drawingAxes, obj.unwrappedLMcenter(1), obj.unwrappedLMcenter(2), obj.unwrappedLMcenter(3), 'ms', 'filled');
        scatter3(drawingAxes, obj.unwrappedScenter(1), obj.unwrappedScenter(2), obj.unwrappedScenter(3), 'cs', 'filled');
        scatter3(drawingAxes, obj.unwrappedPrivot(1), obj.unwrappedPrivot(2), obj.unwrappedPrivot(3), 'ws', 'filled');
        plot3(drawingAxes, [obj.unwrappedLMcenter(1) obj.unwrappedScenter(1)],[obj.unwrappedLMcenter(2) obj.unwrappedScenter(2)], [obj.unwrappedLMcenter(3) obj.unwrappedScenter(3)], 'w-');
        if (viewIndex == 3)
            plot3(drawingAxes, [0 0], spatialExtent*[-1 1], [0 0], 'w-', 'LineWidth', 1);
            plot3(drawingAxes, [0 0], [0 0], spatialExtent*[-1 1], 'w-', 'LineWidth', 1);
        end
        hold(drawingAxes, 'off');
        grid(drawingAxes, 'on'); 
        box(drawingAxes, 'off'); 
        axis(drawingAxes, 'off')
        view(drawingAxes, viewingAngles);
        set(drawingAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
        set(drawingAxes, 'XTickLabel', {}, 'YTickLabel', {});
        if (~isempty(XLims))
            set(drawingAxes, 'XLim', XLims);
        end
        set(drawingAxes, 'YLim', YLims);
        set(drawingAxes, 'ZLim', ZLims);
        
        switch viewIndex
            case 1     
            case 2
            case 3
                axis(drawingAxes, 'square');
                xlabel(drawingAxes, 'reconstructed mosaic', 'Color', [1 1 1], 'FontSize', 14);
        end
    end % viewIndex

    % Plot the spatial mosaic scaled so that the learned LM cone coords
    % match to scale with those of the true LM cones
    coneMarkerSize = 9;
    
    for k = 1:size(obj.core1Data.trueConeXYLocations,1)
        if (obj.core1Data.trueConeTypes(k) == 2) && (ismember(k, obj.unwrappedLconeIndices))
            plot(mosaicAxes,[obj.core1Data.trueConeXYLocations(k,1) obj.unwrappedMDSprojection(k,2)], ...
                 [obj.core1Data.trueConeXYLocations(k,2) obj.unwrappedMDSprojection(k,3)], '-', 'Color', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:), 'LineWidth', 2);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, obj.core1Data.trueConeXYLocations(k,1), obj.core1Data.trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColorsFace(obj.core1Data.trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:), 'LineWidth', 1); 
            
        elseif (obj.core1Data.trueConeTypes(k) == 3) && (ismember(k, obj.unwrappedMconeIndices))
            plot(mosaicAxes, [obj.core1Data.trueConeXYLocations(k,1) obj.unwrappedMDSprojection(k,2)], ...
                 [obj.core1Data.trueConeXYLocations(k,2) obj.unwrappedMDSprojection(k,3)], '-', 'Color', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:), 'LineWidth', 2);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, obj.core1Data.trueConeXYLocations(k,1), obj.core1Data.trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColorsFace(obj.core1Data.trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:), 'LineWidth', 1);
            
        elseif (obj.core1Data.trueConeTypes(k) == 4) && (ismember(k, obj.unwrappedSconeIndices))
            plot(mosaicAxes, [obj.core1Data.trueConeXYLocations(k,1) obj.unwrappedMDSprojection(k,2)], ...
                 [obj.core1Data.trueConeXYLocations(k,2) obj.unwrappedMDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:));
            hold(mosaicAxes,'on')
            plot(mosaicAxes, obj.core1Data.trueConeXYLocations(k,1), obj.core1Data.trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerFaceColor', coneColorsFace(obj.core1Data.trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneColorsEdge(obj.core1Data.trueConeTypes(k)-1,:), 'LineWidth', 1);

        else
            % incorrectly indentified cone
            plot(mosaicAxes, [obj.core1Data.trueConeXYLocations(k,1) obj.unwrappedMDSprojection(k,2)], ...
                 [obj.core1Data.trueConeXYLocations(k,2) obj.unwrappedMDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', [0.8 0.8 0.8]);
            hold(mosaicAxes,'on')
            plot(mosaicAxes, obj.core1Data.trueConeXYLocations(k,1), obj.core1Data.trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, 'MarkerEdgeColor', [0.7 0.7 0.7], 'MarkerFaceColor', [0.8 0.8 0.8], 'LineWidth', 1);
        end  
    end
    
    plot(mosaicAxes, [0 0], spatialExtent*[-1 1], 'w-', 'LineWidth', 1);
    plot(mosaicAxes, spatialExtent*[-1 1], [0 0], 'w-', 'LineWidth', 1);
    hold(mosaicAxes,'off')
    set(mosaicAxes, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(mosaicAxes, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(mosaicAxes, 'XTickLabel', {}, 'YTickLabel', {});
    set(mosaicAxes, 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0]);
    grid(mosaicAxes, 'on'); 
    box(mosaicAxes, 'off'); 
    axis(mosaicAxes, 'square')
    axis(mosaicAxes, 'off')
    xlabel(mosaicAxes, 'actual mosaic', 'Color', [1 1 1], 'FontSize', 14);
    
end

