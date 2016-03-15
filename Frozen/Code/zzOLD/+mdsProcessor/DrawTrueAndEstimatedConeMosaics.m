function DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, MDSprojection, coneIndices, coneEdgeColors, coneFaceColors, spatialExtent)
        
    LconeIndices = coneIndices{1};
    MconeIndices = coneIndices{2}; 
    SconeIndices = coneIndices{3};

    coneMarkerSize = 9;
    
    hold on
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2) && (ismember(k, LconeIndices))
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', coneEdgeColors(trueConeTypes(k)-1,:));
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, ...
                'MarkerFaceColor', coneFaceColors(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneEdgeColors(trueConeTypes(k)-1,:), 'LineWidth', 1); 
            
        elseif (trueConeTypes(k) == 3) && (ismember(k, MconeIndices))
            
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', coneEdgeColors(trueConeTypes(k)-1,:));
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, ...
                'MarkerFaceColor', coneFaceColors(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneEdgeColors(trueConeTypes(k)-1,:), 'LineWidth', 1); 

        elseif (trueConeTypes(k) == 4) && (ismember(k, SconeIndices))
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', coneEdgeColors(trueConeTypes(k)-1,:));
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, ...
                'MarkerFaceColor', coneFaceColors(trueConeTypes(k)-1,:), 'MarkerEdgeColor', coneEdgeColors(trueConeTypes(k)-1,:), 'LineWidth', 1); 
        else
            % incorrectly indentified cone
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], '-', 'LineWidth', 2, 'Color', [0.2 0.2 0.2]);
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'o', 'MarkerSize', coneMarkerSize, ...
                'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1); 
        end  
    end
    set(gca, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(gca, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(gca, 'FontSize', 12);
    grid on; box on; axis 'square'
    xlabel(sprintf('spatial X-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(sprintf('spatial Y-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
end