% Method that computes the radianceMap from the imported reflectance and
% the illuminant. This method also computes the luminance and xy chroma of
% the reference object and contrasts this to the values measured and
% catalogued in the database.
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
    % This is the scene illuminant.
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
    
    % make sure the wave sampling is consistent between illuminant and reflectances
    if (numel(wave) ~= size(reflectances,3))
        error('Spectral bands of reflectances (%d) does not agree with spectral samples (%d) of the illuminant', size(reflectances,3), numel(wave));
    end
    
    % Compute radianceMap from reflectances and illuminant
    radianceMap = bsxfun(@times, reflectances, reshape(illuminant, [1 1 numel(illuminant)]));
    
    % Divide power per nm by spectral bandwidth
    radianceMap = radianceMap / (wave(2)-wave(1));
     
    % Compute and store XYZ image
    obj.sceneXYZmap = MultispectralToSensorImage(radianceMap, WlsToS(wave), obj.sensorXYZ.T, obj.sensorXYZ.S);
    
    % Compute and store luminance map
    obj.sceneLuminanceMap = obj.wattsToLumens * squeeze(obj.sceneXYZmap(:,:,2));
    
    % Compute scene luminance range and mean
    minSceneLuminance  = min(obj.sceneLuminanceMap(:));
    maxSceneLuminance  = max(obj.sceneLuminanceMap(:));
    meanSceneLuminance = mean(obj.sceneLuminanceMap(:));
    
    % Compute luminance of reference object
    computedfromRadianceReferenceLuminance = obj.computeROIluminance();
    
    % Compute x,y chromaticities of reference object
    computedFromRadianceReferenceChromaticity = obj.computeROIchromaticity();
    
    fprintf('\nReference object x,y chromaticities:\n\tcomputed: (%1.4f, %1.4f) \n\treported: (%1.4f, %1.4f)\n' , computedFromRadianceReferenceChromaticity(1), computedFromRadianceReferenceChromaticity(2), obj.referenceObjectData.spectroRadiometerReadings.xChroma, obj.referenceObjectData.spectroRadiometerReadings.yChroma);
    fprintf('\nReference object mean luminance (cd/m2):\n\tcomputed: %2.2f\n\treported: %2.2f\n' , computedfromRadianceReferenceLuminance, obj.referenceObjectData.spectroRadiometerReadings.Yluma);
    fprintf('\nScene radiance  (Watts/steradian/m2/nm):\n\tMin: %2.2f\n\tMax: %2.2f\n', min(radianceMap(:)), max(radianceMap(:)));
    fprintf('\nScene luminance (cd/m2):\n\tMin  : %2.2f\n\tMax  : %2.2f\n\tMean : %2.2f\n\tRatio: %2.0f:1\n', minSceneLuminance, maxSceneLuminance, meanSceneLuminance, maxSceneLuminance/minSceneLuminance);
    
    % Return radianceData struct
    obj.radianceData = struct(...
        'sceneName',    obj.sceneData.name, ...
        'wave',         wave, ...
        'illuminant',   illuminant, ... 
        'radianceMap',  radianceMap ...                                                
    );
end

