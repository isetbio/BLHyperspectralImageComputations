function computeEyeMovementVideoData(obj, sceneIndex, timeBins)

    % Get eye movements for this scene scan
    currentEyeMovements = obj.core1Data.eyeMovements{sceneIndex}(timeBins,:);
    obj.videoData.opticalImage.currentEyeMovementsInMicrons(:,1) = currentEyeMovements(:,1) * obj.core1Data.sensorSampleSeparation(1);
    obj.videoData.opticalImage.currentEyeMovementsInMicrons(:,2) = currentEyeMovements(:,2) * obj.core1Data.sensorSampleSeparation(2);

    % sensor outline (outline is double the actual size for ease of visualization)
    obj.videoData.opticalImage.sensorOutlineInMicrons(:,1) = [-1 -1 1 1 -1] * obj.core1Data.sensorRowsCols(2) * obj.core1Data.sensorSampleSeparation(1);
    obj.videoData.opticalImage.sensorOutlineInMicrons(:,2) = [-1 1 1 -1 -1] * obj.core1Data.sensorRowsCols(1) * obj.core1Data.sensorSampleSeparation(2);
end

