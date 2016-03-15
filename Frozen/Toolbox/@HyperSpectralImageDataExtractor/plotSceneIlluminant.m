% Method to plot the scene illuminnat
function plotSceneIlluminant(obj)
    h = figure(1);
    set(h, 'Position', [10 920 560 420]);
    plot(obj.radianceData.wave, obj.radianceData.illuminant, 'ks-');
    xlabel('wavelength (nm)');
    ylabel('Energy (Watts/steradian/m^2/nm');
    title('Scene illuminant');
end