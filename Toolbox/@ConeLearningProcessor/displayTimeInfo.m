function displayTimeInfo(obj,timeDisplayAxes)

    set(timeDisplayAxes, 'Color', [0 0 0], 'XColor', [0 0 0], 'YColor', [0 0 0], 'XTick', [], 'YTick', []);
    
    currentTimeHours = floor(obj.fixationTimeInMilliseconds/(1000*60*60));
    currentTimeMinutes = floor((obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60)) / (1000*60));
    currentTimeSeconds = floor((obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60))/1000);
    currentTimeMilliSeconds = obj.fixationTimeInMilliseconds - currentTimeHours*(1000*60*60) - currentTimeMinutes*(1000*60) - currentTimeSeconds*1000;
    if (obj.fixationsNum < 1000)
        title(timeDisplayAxes,  sprintf('fixation #%03.3f\n(%02.0f : %02.0f : %02.0f : %03.0f)', obj.fixationsNum, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    else
        title(timeDisplayAxes,  sprintf('fixation #%03.0f\n(%02.0f : %02.0f : %02.0f : %03.0f)', obj.fixationsNum, currentTimeHours, currentTimeMinutes, currentTimeSeconds, currentTimeMilliSeconds), 'FontSize', 16, 'Color', [1 .8 .4]);
    end

end

