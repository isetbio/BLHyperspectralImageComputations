function DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, MDSprojection, coneIndices, spatialExtent)
        
    LconeIndices = coneIndices{1};
    MconeIndices = coneIndices{2}; 
    SconeIndices = coneIndices{3};

    hold on
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2) && (ismember(k, LconeIndices))
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'r-');
        elseif (trueConeTypes(k) == 3) && (ismember(k, MconeIndices))
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'g-');
        elseif (trueConeTypes(k) == 4) && (ismember(k, SconeIndices))
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'b-');
        else
            % incorrectly indentified cone
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'ks', 'MarkerFaceColor', 'k');
            plot([trueConeXYLocations(k,1) MDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) MDSprojection(k,3)], 'k-');
        end  
    end
    set(gca, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(gca, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(gca, 'FontSize', 12);
    grid on; box on; axis 'square'
    xlabel(sprintf('spatial X-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(sprintf('spatial Y-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
end