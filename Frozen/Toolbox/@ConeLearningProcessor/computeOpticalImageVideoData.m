function computeOpticalImageVideoData(obj, sceneIndex)
    
    obj.videoData.opticalImage.image = obj.core1Data.opticalImageRGBrendering{sceneIndex};
    obj.videoData.opticalImage.xposInMicrons = (0:size(obj.videoData.opticalImage.image,2)-1) * obj.core1Data.opticalSampleSeparation{sceneIndex}(1);
    obj.videoData.opticalImage.yposInMicrons = (0:size(obj.videoData.opticalImage.image,1)-1) * obj.core1Data.opticalSampleSeparation{sceneIndex}(2);
    
    % center to (0,0)
    obj.videoData.opticalImage.xposInMicrons = obj.videoData.opticalImage.xposInMicrons - round(obj.videoData.opticalImage.xposInMicrons(end)/2);
    obj.videoData.opticalImage.yposInMicrons = obj.videoData.opticalImage.yposInMicrons - round(obj.videoData.opticalImage.yposInMicrons(end)/2);                
end

