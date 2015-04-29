% Method that computes the radianceMap from the imported reflectance and
% the illuminant. This method also computes the luminance and xy chroma of
% the reference object and contrasts this to the values measured and
% catalogued in the database.
function inconsistentSpectralData = generateRadianceDataStruct(obj)
    
    inconsistentSpectralData = false;
    obj.referenceObjectData
    % make sure that wave numbers match for paint material and the radiance
    if (~isempty(fieldnames(obj.referenceObjectData.paintMaterial))) && (any(abs(obj.illuminant.wave(:) - obj.referenceObjectData.paintMaterial.wave(:)) > 0))
        inconsistentSpectralData = true;
        fprintf(2,'Wave numbers for scene radiance and refenence surface do not match.\n');
        return;
    end
    
    % make sure the wave sampling is consistent between illuminant and reflectanceMap
    if (numel(obj.illuminant.wave) ~= size(obj.reflectanceMap,3))
        inconsistentSpectralData = true;
        fprintf(2,'Spectral bands of reflectanceMap (%d) does not agree with spectral samples (%d) of the illuminant.\n', size(obj.reflectanceMap,3), numel(obj.illuminant.wave));
        return
    end
    
    % Compute radianceMap from the reflectanceMap and the illuminant
    radianceMap = bsxfun(@times, obj.reflectanceMap, reshape(obj.illuminant.spd, [1 1 numel(obj.illuminant.spd)]));
    
    % Divide power per nm by spectral bandwidth
    radianceMap = radianceMap / (obj.illuminant.wave(2)-obj.illuminant.wave(1));
     
    % Compute and store XYZ image
    obj.sceneXYZmap = MultispectralToSensorImage(radianceMap, WlsToS(obj.illuminant.wave), obj.sensorXYZ.T, obj.sensorXYZ.S);
    
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
        'wave',         obj.illuminant.wave, ...
        'illuminant',   obj.illuminant.spd, ... 
        'radianceMap',  radianceMap ...                                                
    );
end

