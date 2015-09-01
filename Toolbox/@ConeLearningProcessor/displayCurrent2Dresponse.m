function displayCurrent2Dresponse(obj, current2DResponseAxes)

    hCurrRespPlot = pcolor(current2DResponseAxes, obj.videoData.current2DResponse);
    set(hCurrRespPlot, 'EdgeColor', 'none');
    axis(current2DResponseAxes, 'square');
    axis(current2DResponseAxes, 'ij');
    axis(current2DResponseAxes, 'on');
    box(current2DResponseAxes, 'on');
    minR = min(min(obj.videoData.current2DResponse));
    maxR = max(max(obj.videoData.current2DResponse));
    
    if isempty(obj.responseRange)
        obj.responseRange = [minR maxR];
    else
        if (minR < obj.responseRange(1))
            obj.responseRange(1) = minR;
        end
        if (maxR > obj.responseRange(2))
            obj.responseRange(2) = maxR;
        end
    end

    if (obj.responseRange(2) > obj.responseRange(1))
        set(current2DResponseAxes, 'CLim', obj.responseRange);
    end
    set(current2DResponseAxes, 'XLim', [1 size(obj.videoData.current2DResponse,2)], 'YLim', [1 size(obj.videoData.current2DResponse,1)]);
    set(current2DResponseAxes, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'XTick', [], 'YTick', [], 'XTickLabel', {}, 'YTickLabel', {});
    
    
    currentTimeHours = floor(obj.fixationTimeInMilliseconds/(1000*60*60));
    currentTimeMinutes = floor((obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60)) / (1000*60));
    currentTimeSeconds = floor((obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60))/1000);
    currentTimeMilliSeconds = obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60) - currentTimeSeconds*1000;
    if (obj.fixationsNum < 1000)
        title(current2DResponseAxes,  sprintf('fixation #%03.3f\n(%02.0f : %02.0f : %02.0f : %03.0f)', obj.fixationsNum, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    else
        title(current2DResponseAxes,  sprintf('fixation #%03.0f\n(%02.0f : %02.0f : %02.0f : %03.0f)', obj.fixationsNum, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    end
    
    %xlabel(current2DResponseAxes, sprintf('mosaic activation'), 'Color', [1 1 1], 'FontSize', 16); 
end

