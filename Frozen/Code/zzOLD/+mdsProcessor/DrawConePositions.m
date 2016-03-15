function DrawConePositions(MDSprojection, coneIndices, coneEdgeColors, coneFaceColors, cLM, cS, pivot, support, MDSdims, viewAngles)
    
    hold on;
    for coneType = 1:numel(coneIndices)
        scatter3(...
            MDSprojection(coneIndices{coneType},1), ...
            MDSprojection(coneIndices{coneType},2), ...
            MDSprojection(coneIndices{coneType},3), ...
            70, ...
            'filled', ...
            'MarkerEdgeColor',coneEdgeColors(coneType,:), ...
            'MarkerFaceColor',coneFaceColors(coneType,:), ...
            'LineWidth', 1 ...
            );  
    end
    scatter3(cLM(1), cLM(2), cLM(3), 'ms', 'filled');
    scatter3(cS(1), cS(2), cS(3), 'cs', 'filled');
    scatter3(pivot(1), pivot(2), pivot(3), 'ks', 'filled');
    plot3([cLM(1) cS(1)],[cLM(2) cS(2)], [cLM(3) cS(3)], 'k-');
    hold off;
    
    if (~isempty(support{1}))
        set(gca, 'XLim', support{1});
    end
    
    if (~isempty(support{2}))
        set(gca, 'YLim', support{2}*[-1 1]);
    end
    if (~isempty(support{3}))
        set(gca, 'ZLim', support{3}*[-1 1]);
    end
    
    set(gca, 'FontSize', 12);
    grid on; box on; axis 'square'
    xlabel(MDSdims{1}, 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(MDSdims{2}, 'FontSize', 14, 'FontWeight', 'bold');
    zlabel(MDSdims{3}, 'FontSize', 14, 'FontWeight', 'bold');

    view(viewAngles);
end