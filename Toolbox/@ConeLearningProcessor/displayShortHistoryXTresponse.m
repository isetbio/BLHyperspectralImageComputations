function displayShortHistoryXTresponse(obj, xtResponseAxes)

    % Short history XT response
    hXTrespPlot = pcolor(xtResponseAxes,obj.videoData.shortHistoryXTResponse);
    set(hXTrespPlot, 'EdgeColor', 'none');
    colormap(hot);
    box(xtResponseAxes, 'on'); 
    axis(xtResponseAxes, 'ij')
    set(xtResponseAxes, 'CLim', obj.responseRange);
    set(xtResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTickLabel', {}, 'YTickLabel', {});
    
end

