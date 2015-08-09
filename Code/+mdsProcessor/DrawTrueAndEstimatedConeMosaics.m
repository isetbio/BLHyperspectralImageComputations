function DrawTrueAndEstimatedConeMosaics(trueConeTypes, trueConeXYLocations, rotatedMDSprojection, spatialExtent)
        
    hold on
    for k = 1:size(trueConeXYLocations,1)
        if (trueConeTypes(k) == 2)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'rs', 'MarkerFaceColor', 'r');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'r-');
        elseif (trueConeTypes(k) == 3)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'gs', 'MarkerFaceColor', 'g');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'g-');
        elseif (trueConeTypes(k) == 4)
            plot(trueConeXYLocations(k,1), trueConeXYLocations(k,2), 'bs', 'MarkerFaceColor', 'b');
            plot([trueConeXYLocations(k,1) rotatedMDSprojection(k,2)], ...
                 [trueConeXYLocations(k,2) rotatedMDSprojection(k,3)], 'b-');
        end  
    end
    set(gca, 'XLim', spatialExtent*[-1 1], 'YLim', spatialExtent*[-1 1]);
    set(gca, 'XTick', [-100:5:100], 'YTick', [-100:5:100]);
    set(gca, 'FontSize', 12);
    grid on; box on; axis 'square'
    xlabel(sprintf('spatial X-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(sprintf('spatial Y-dim (microns)'), 'FontSize', 14, 'FontWeight', 'bold');
end