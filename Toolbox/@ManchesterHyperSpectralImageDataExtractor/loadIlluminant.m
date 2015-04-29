function loadIlluminant(obj)

    % Assemble sourceDirectory path
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);

    % Load the reflectanceToRadiance scaling factors ('radiance')
    % Spectral radiance factors required to convert scene reflectance to radiances in Watts/steradian/m^2/nm
    % This is the scene illuminant.
    radiance = [];
    radianceFileName = fullfile(sourceDir, obj.sceneData.name, obj.sceneData.spectralRadianceDataFileName);
    load(radianceFileName);
    if (isempty(radiance))
        error('No field named ''radiance'' in file ''%s''.\n', radianceFileName);
    end
    obj.illuminant.wave = squeeze(radiance(:,1));
    obj.illuminant.spd  = squeeze(radiance(:,2));
    clear 'radiance';
end

