function adaptingFieldScene = generateAdaptingFieldScene(scene, adaptingFieldParams)

    switch (adaptingFieldParams.type)
        case 'SpecifiedReflectanceIlluminatedBySpecifiedIlluminant'
            
            switch (adaptingFieldParams.surfaceReflectance.type)
                case 'MacBethPatchNo'
                    adaptingFieldScene = generateMacBethBasedAdaptingFieldScene(...
                        scene, adaptingFieldParams.illuminantName, adaptingFieldParams.surfaceReflectance.patchNo, adaptingFieldParams.meanLuminance);
                otherwise
                    error('Unknown adapting field surface reflectance type: ''%s''.\n', adaptingFieldParams.surfaceReflectance.type)
            end % switch (adaptingFieldParams.surfaceReflectance.type)
            
        otherwise
            error('Unknown adapting field scene type: ''%s''.\n', adaptingFieldParams.type);
            
    end %  switch (adaptingFieldParams.type)

end

function adaptingFieldScene = generateMacBethBasedAdaptingFieldScene(originalScene, illuminantName, patchNo, desiredPatchLuminance)

    adaptingFieldScene = originalScene;
    
    % set the adapting scene's name
    adaptingFieldScene = sceneSet(adaptingFieldScene, 'name', sprintf('%s - adaptation field', sceneGet(originalScene, 'name')));
    
    % Retrieve scene wavelength sampling 
    wavelengthSampling = sceneGet(originalScene,'wave');
    
    % Load all the reflectances of the MacBeth color chart
    fName = fullfile(isetRootPath,'data','surfaces','macbethChart.mat');
    macbethChart = ieReadSpectra(fName, wavelengthSampling);
    
    % Get the reflectance of the desired patch
    reflectance = squeeze(macbethChart(:,patchNo));
    
    % Get the illuminant photons
    illuminant = illuminantCreate(illuminantName,wavelengthSampling);
    illuminantPhotons = illuminantGet(illuminant, 'photons');
    
    % Compute radiance
    photonsEmitted   = reflectance.*illuminantPhotons;
    patchLuminance = ieLuminanceFromPhotons(photonsEmitted, wavelengthSampling);
    
    % Adjust photons emitted to obtain desired luminance
    f = desiredPatchLuminance / patchLuminance;
    photonsEmitted = photonsEmitted * f;
    illuminant = illuminantSet(illuminant, 'photons', illuminantPhotons*f);
    
    % Set the scene radiance to photonsEmitted (uniform field) - directly
    % (without going through isetbio)
    adaptingFieldScene.data.photons = ...
            repmat(reshape(photonsEmitted, [1 1 numel(photonsEmitted)]), [sceneGet(adaptingFieldScene, 'rows') sceneGet(adaptingFieldScene, 'cols') 1]);
    
    % Finally set the scene illuminant
    sceneSet(adaptingFieldScene, 'illuminant', illuminant);
    
    % Plot MacBeth reflectances (debug-only)
    plotMacBethReflectances = false;
    if (plotMacBethReflectances)
        figure(1); clf;
        for k = 1:size(macbethChart,2)
            subplot(6,4,k);
            macbethPatchReflectance = squeeze(macbethChart(:,k));
            if (k == patchNo)
                plot(wavelengthSampling, macbethPatchReflectance, 'r-');
            else
                plot(wavelengthSampling, macbethPatchReflectance, 'k-'); 
            end
            set(gca, 'YLim', [0 max(macbethPatchReflectance)]);
            title(sprintf('patch no: %d', k));
        end
        drawnow
    end
end
