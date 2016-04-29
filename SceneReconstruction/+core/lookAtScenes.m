function lookAtScenes(sceneSetName)

    [sceneData, sceneNames] = core.fetchTheIsetbioSceneDataSet(sceneSetName);
    fprintf('Fetched %d scenes\n', numel(sceneData));
    
    retainedSceneNames = {};
    for sceneIndex = 1: numel(sceneData)
        
        % Get the scene
        scene = sceneData{sceneIndex};
        oi = oiCreate('human');
        
        
        % additions
        % No optics
        optics = oiGet(oi, 'optics');
        offaxismethod = opticsGet(optics, 'off axis method')
        model = opticsGet(optics, 'model')
        fNumber = opticsGet(optics, 'fnumber')
        focalLength = opticsGet(optics, 'focallength')
        transmittance = opticsGet(optics, 'transmittance')
        
        % Effectively no optics
        optics  = opticsSet(optics, 'fNumber', 0.5)
        optics = opticsSet(optics, 'off axis method', 'skip');
        optics = opticsSet(optics, 'model', 'diffractionlimited');
        
        fNumber = opticsGet(optics, 'fnumber')
        offaxismethod = opticsGet(optics, 'off axis method')
        
        model = opticsGet(optics, 'model')
        oi = oiSet(oi, 'optics', optics);
        % --------------
        
        
        sensor = sensorCreate('human');
        sensor = sensorSet(sensor, 'size', [128 128]);
        
        % No inert pigments
        humanLens = sensorGet(sensor, 'human lens');
        humanMacula = sensorGet(sensor, 'human macular');
        humanCone = sensorGet(sensor, 'human cone');
        
        lensTransmittance = lensGet(humanLens, 'transmittance');
        macularTransmittance = macularGet(humanMacula, 'transmittance');
        peakOpticalDensities = coneGet(humanCone, 'pod')
        
        wave = sensorGet(sensor, 'wave');
        figure(22); clf
        subplot(2,2,1);
        plot(wave, lensTransmittance, 'r-');
        hold on;
        plot(wave, macularTransmittance, 'b-');
        
        coneQE = sensorGet(sensor, 'spectral qe');
        subplot(2,2,2);
        plot(wave, coneQE);
        
        
        humanLens = lensSet(humanLens, 'density', 0);
        humanMacula = macularSet(humanMacula, 'density', 0);
        humanCone = coneSet(humanCone, 'pod', [0.5; 0.5; 0.5]);
        
        
        lensTransmittance = lensGet(humanLens, 'transmittance');
        macularTransmittance = macularGet(humanMacula, 'transmittance');
        subplot(2,2,3);
        plot(wave, lensTransmittance, 'r-');
        hold on;
        plot(wave, macularTransmittance, 'b-');
        drawnow;
        
        sensor = sensorSet(sensor, 'human lens', humanLens);
        sensor = sensorSet(sensor, 'human macular', humanMacula);
        sensor = sensorSet(sensor, 'human cone', humanCone');
        
        coneQE = sensorGet(sensor, 'spectral qe');
        subplot(2,2,4);
        plot(wave, coneQE);

        
        oi = oiCompute(oi, scene);
        spatialSample = 3/2.0;
        oi = oiSpatialResample(oi, spatialSample, 'um', 'linear', false);
        
        
        
        
        coneTypes = sensorGet(sensor, 'cone type');
        sensor = coneAbsorptions(sensor, oi);
        isomerizationRate = sensorGet(sensor, 'photon rate');
        LconeIndices = find(coneTypes == 2);
        SconeIndices = find(coneTypes == 4);
        LconeIsomerizationRate = 0*isomerizationRate;
        SconeIsomerizationRate = 0*isomerizationRate;
     
        LconeIsomerizationRate(LconeIndices) = isomerizationRate(LconeIndices);
        SconeIsomerizationRate(SconeIndices) = isomerizationRate(SconeIndices);
        
        figure(1);
        subplot(2,2,1);
        imshow(sceneGet(scene, 'RGB'));
        pixelSize = sceneGet(scene, 'spatial resolution', 'um');
        title(sprintf('pixel size: %2.1f microns', pixelSize(1)));
        subplot(2,2,2);
        imshow(oiGet(oi, 'RGB'));
        pixelSize = oiGet(oi, 'spatial resolution', 'um');
        title(sprintf('pixel size: %2.1f microns', pixelSize(1)));
        subplot(2,2,3);
        imagesc(LconeIsomerizationRate);
        set(gca, 'CLim', [min(isomerizationRate(:)) max(isomerizationRate(:))]);
        axis 'image'
        title('Lcone isomerization');
        subplot(2,2,4);
        imagesc(SconeIsomerizationRate);
        set(gca, 'CLim', [min(isomerizationRate(:)) max(isomerizationRate(:))]);
        axis 'image'
        title('Scone isomerization');
        colormap(jet(1024));
        drawnow;
        pause
        
        keep = input('Retain scene ?[1=yes] : ');
        
        if (keep == 1)
            retainedSceneNames{numel(retainedSceneNames)+1} = sceneNames{sceneIndex}
        end
    end
    
    retainedSceneNames
    
end
