function generateRadianceDataStruct(obj)
    
    % Assemble sourceDirectory path
    sourceDir = fullfile(getpref('HyperSpectralImageComputations', 'originalDataBaseDir'), obj.sceneData.database);

    % Load the scene reflectance data ('reflectances');
    reflectances = [];
    load(fullfile(sourceDir, obj.sceneData.name, obj.sceneData.reflectanceDataFileName));
    if (isempty(reflectances))
        error('Data file does not contain the expected ''reflectances'' field.');
    end
    
    % Note: The 'reflectances' were computed as the ratio of the recorded radiant spectrum to the recorded radiant spectrum from a neutral matt reference surface embedded in the scene, 
    % multiplied by the known spectral reflectance of the reference surface. Although the reference surface is well illuminated, some portions of the scene may have higher radiance, 
    % therefore the reflectances in those regions will exceed 1.   
    
    % Load the reflectanceToRadiance scaling factors ('radiance')
    % Spectral radiance factors required to convert scene reflectance to radiances in Watts/steradian/m^2/nm
    % This is akin to the scene illuminant in some arbitrary units
    radiance = [];
    load(fullfile(sourceDir, obj.sceneData.name, obj.sceneData.spectralRadianceDataFileName));
    if (isempty(radiance))
        error('Data file does not contain the expected ''radiance'' field.');
    end
    wave       = squeeze(radiance(:,1));
    illuminant = squeeze(radiance(:,2));
    
    % make sure that wave numbers match for ref_n7, radiance
    if (any(abs(wave-obj.referenceObjectData.paintMaterial.wave) > 0))
        error('wave numbers for scene radiance and refenence surface  do not match');
    end
    
    % Compute radianceMap from reflectances and illuminant
    radianceMap = bsxfun(@times, reflectances, reshape(illuminant, [1 1 numel(illuminant)]));
    
    % Divide power per nm by spectral bandwidth
    radianceMap = radianceMap / (wave(2)-wave(1));
    
    % Flag indicating whether to adjust the image radiance so that the reported 
    % and thecomputed luminances match.
    adjustRadianceToMatchReportedAndComputedRefLuminances = false;
    
    if (adjustRadianceToMatchReportedAndComputedRefLuminances) 
        % Compute XYZ image
        obj.sceneXYZmap = MultispectralToSensorImage(radianceMap, WlsToS(wave), obj.sensorXYZ.T, obj.sensorXYZ.S);
    
        % Store scene luminance map
        obj.sceneLuminanceMap = squeeze(obj.sceneXYZmap(:,:,2));
    
        % Compute reference luminance
        computedfromRadianceReferenceLuminance = obj.computeROIluminance();
    
        % compute radiance scale factor, so that the computed luminance of the
        % reference surface  matches the measured luminance of the reference surface
        radianceScaleFactor = referenceObjectData.spectroRadiometerReadings.Yluma/computedfromRadianceReferenceLuminance
    
        % Second pass: adjust scene radiance and illuminant
        radianceMap  = radianceMap * radianceScaleFactor;
        illuminant   = illuminant * radianceScaleFactor;
    end
    
    % Compute and store XYZ image
    obj.sceneXYZmap = MultispectralToSensorImage(radianceMap, WlsToS(wave), obj.sensorXYZ.T, obj.sensorXYZ.S);
    
    % Compute and store sluminance map
    obj.sceneLuminanceMap = obj.wattsToLumens * squeeze(obj.sceneXYZmap(:,:,2));
    
    % Compute scene luminance range and mean
    minSceneLuminance  = min(obj.sceneLuminanceMap(:));
    maxSceneLuminance  = max(obj.sceneLuminanceMap(:));
    meanSceneLuminance = mean(obj.sceneLuminanceMap(:));
    
    % Compute reference luminance
    computedfromRadianceReferenceLuminance = obj.computeROIluminance();
    
    % Compute reference x,y chromaticities
    computedFromRadianceReferenceChromaticity = obj.computeROIchromaticity();
    
    fprintf('\nReference object x,y chromaticities:\n\tcomputed: (%1.4f, %1.4f) \n\treported: (%1.4f, %1.4f)\n' , computedFromRadianceReferenceChromaticity(1), computedFromRadianceReferenceChromaticity(2), obj.referenceObjectData.spectroRadiometerReadings.xChroma, obj.referenceObjectData.spectroRadiometerReadings.yChroma);
    fprintf('\nReference object mean luminance (cd/m2):\n\tcomputed: %2.2f\n\treported: %2.2f\n' , computedfromRadianceReferenceLuminance, obj.referenceObjectData.spectroRadiometerReadings.Yluma);
    fprintf('\nScene radiance  (Watts/steradian/m2/nm):\n\tMin: %2.2f\n\tMax: %2.2f\n', min(radianceMap(:)), max(radianceMap(:)));
    fprintf('\nScene luminance (cd/m2):\n\tMin  : %2.2f\n\tMax  : %2.2f\n\tMean : %2.2f\n\tRatio: %2.0f:1\n', minSceneLuminance, maxSceneLuminance, meanSceneLuminance, maxSceneLuminance/minSceneLuminance);
    
    % Return data
    obj.radianceData = struct(...
        'sceneName',    obj.sceneData.name, ...
        'wave',         wave, ...
        'illuminant',   illuminant, ... 
        'radianceMap',  radianceMap ...                                                
    );
    
end

