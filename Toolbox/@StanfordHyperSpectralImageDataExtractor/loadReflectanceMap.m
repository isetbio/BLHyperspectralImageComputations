% Stanford database - specific method to load the reflectance map
function loadReflectanceMap(obj)
   
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    load(fullfile(sourceDir, obj.sceneData.reflectanceDataFileName), 'photons');
    
    % only keep spectral data in the range [380 - 780]
    obj.generatePassThroughRadianceDataStruct(Quanta2Energy(obj.illuminant.wave, double(photons)), [380 780]);
end

