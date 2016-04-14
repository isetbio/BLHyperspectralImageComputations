function displayDisparityMatrix(obj, dispMatrixAxes)
    % Disparity matrix
    if (~isempty(obj.disparityMatrix))
        visD = (obj.disparityMatrix).*tril(ones(size(obj.disparityMatrix)));
        hdensityPlot = pcolor(dispMatrixAxes, visD);
        set(hdensityPlot, 'EdgeColor', 'none');
        colormap(hot);
        box(dispMatrixAxes, 'off'); 
        axis(dispMatrixAxes, 'square');
        axis(dispMatrixAxes, 'ij');
        minR = 0;
        maxR = max(max(obj.disparityMatrix));
        if (maxR == minR)
            maxR = minR + 1;
        end
        if isempty(obj.disparityRange)
            obj.disparityRange = [minR maxR];
        else
            if (maxR > obj.disparityRange(2))
                obj.disparityRange(2) = maxR;
            end
        end
    
        set(dispMatrixAxes, 'CLim', obj.disparityRange);
        set(dispMatrixAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [],'XTickLabel', {}, 'YTickLabel', {});
        colormap(hot);
    end
end

