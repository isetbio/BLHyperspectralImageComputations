function generateAndSaveColormaps

    spectralLUT = cbrewer('div', 'Spectral', 1024);
    spectralLUT = spectralLUT(size(spectralLUT,1):-1:1,:);
    save('CustomColormaps.mat', 'spectralLUT');

end

