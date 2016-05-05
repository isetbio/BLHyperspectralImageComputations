function renderSceneAndOpticalLMScontrastAndPhotocurrentSequences(sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, timeAxis, photoCurrentSequence, sceneLMScontrastSequence, opticalImageLMScontrastSequence)
    figure(111); clf;
    colormap(gray(1024));
    
    for k = 101:size(photoCurrentSequence,3)
        subplot(2,4,1);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(sceneLMScontrastSequence(:,:,1,k)));
        title('L cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,2);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(sceneLMScontrastSequence(:,:,2,k)));
        title('M cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,3);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(sceneLMScontrastSequence(:,:,3,k)));
        title('S cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,5);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(opticalImageLMScontrastSequence(:,:,1,k)));
        title('L cone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,6);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(opticalImageLMScontrastSequence(:,:,2,k)));
        title('M cone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,7);
        imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(opticalImageLMScontrastSequence(:,:,3,k)));
        title('scone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        photoCurrentRange = [min(photoCurrentSequence(:)) max(photoCurrentSequence(:))];
        subplot(2,4,4);
        imagesc(sensorRetinalXaxis, sensorRetinalYaxis, squeeze(photoCurrentSequence(:,:,k)));
        title(sprintf('photocurrent (time: %2.4f sec)', timeAxis(k)/1000));
        set(gca, 'CLim', photoCurrentRange);
        axis 'xy'; axis 'image'

        subplot(2,4,8);
        timeBins = k+(-100:100);
        el = 0;
        for ir = 10+(-1:1)
            for ic = 10+(-1:1)
                el = el + 1;
                plot(timeAxis(timeBins), squeeze(photoCurrentSequence(ir,ic,timeBins)), 'k-');
                if (el == 1)
                    hold on
                    plot(timeAxis(k)*[1 1], [-100 100], 'r-');
                end
            end
        end
        hold off;
        title(sprintf('photocurrent traces (time: %2.4f-%2.4f sec)', timeAxis(timeBins(1))/1000,timeAxis(timeBins(end))/1000));
        set(gca, 'YLim', photoCurrentRange, 'XLim', [timeAxis(timeBins(1)) timeAxis(timeBins(end))]);
        axis 'square'

        drawnow
     end
end