function displayOpticalImageAndEyeMovements(obj, opticalImageAxes, eyeMovementIndex)

    imagesc(obj.videoData.opticalImage.xposInMicrons, obj.videoData.opticalImage.yposInMicrons, obj.videoData.opticalImage.image, 'parent', opticalImageAxes);
    hold(opticalImageAxes, 'on');
    plot(opticalImageAxes,-obj.videoData.opticalImage.currentEyeMovementsInMicrons(1:eyeMovementIndex,1), obj.videoData.opticalImage.currentEyeMovementsInMicrons(1:eyeMovementIndex,2), 'w.-', 'LineWidth', 2.0);
    plot(opticalImageAxes,-obj.videoData.opticalImage.currentEyeMovementsInMicrons(1:eyeMovementIndex,1), obj.videoData.opticalImage.currentEyeMovementsInMicrons(1:eyeMovementIndex,2), 'k.');
    plot(opticalImageAxes,-obj.videoData.opticalImage.currentEyeMovementsInMicrons(eyeMovementIndex,1) + obj.videoData.opticalImage.sensorOutlineInMicrons(:,1), obj.videoData.opticalImage.currentEyeMovementsInMicrons(eyeMovementIndex,2) + obj.videoData.opticalImage.sensorOutlineInMicrons(:,2), 'w-', 'LineWidth', 1.0);
    hold(opticalImageAxes, 'off');
    axis(opticalImageAxes,'image');
    axis(opticalImageAxes,'off');
    box(opticalImageAxes,'off');
    set(opticalImageAxes, 'CLim', [0 1], 'XColor', [1 1 1], 'YColor', [1 1 1]); 
    set(opticalImageAxes, 'XLim', [obj.videoData.opticalImage.xposInMicrons(1) obj.videoData.opticalImage.xposInMicrons(end)]*(0.81), ...
                          'YLim', [obj.videoData.opticalImage.yposInMicrons(1) obj.videoData.opticalImage.yposInMicrons(end)]*(0.81), 'XTick', [], 'YTick', []);
end

