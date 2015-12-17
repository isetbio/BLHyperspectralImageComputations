% Harvard database - specific method to load the scene illuminant
function loadIlluminant(obj)
    fprintf('In Stanford DataBase loadIlluminant.\n');
    
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    load(fullfile(sourceDir, obj.sceneData.reflectanceDataFileName), 'illuminant');

    % Correct by 1e9 to get correct scale of the illuminant in Watts/(sr m^2 nm)
    illuminant.data.photons = double(illuminant.data.photons)*1e9;
    
    obj.illuminant.wave = double(illuminant.spectrum.wave);
    obj.illuminant.spd = (Quanta2Energy(obj.illuminant.wave, double(illuminant.data.photons)))'; 
end

