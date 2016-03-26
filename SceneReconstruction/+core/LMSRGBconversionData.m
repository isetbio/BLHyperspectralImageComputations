function [coneFundamentals, displaySPDs, RGBtoXYZ, wave] = LMSRGBconversionData(displayName, gain)
    sensorLMS = core.loadStockmanSharpe2DegFundamentals();
    wave = SToWls(sensorLMS.S);
    validWaveIndices = 2:numel(wave)-50;
    wave = wave(validWaveIndices);
    coneFundamentals = (sensorLMS.T)';
    coneFundamentals = coneFundamentals(validWaveIndices,:);
    
    
    d = displayCreate(displayName, 'wave', wave);
    beforeLum = displayGet(d, 'peak luminance')
    
    % The higher the gain, the more LMS contrast we can render without going out of gamut
    displaySPDs = displayGet(d, 'spd');
    displaySPDs = displaySPDs*gain;
    d = displaySet(d, 'spd', displaySPDs);
    afterLum = displayGet(d, 'peak luminance')
    
    RGBtoXYZ = displayGet(d, 'rgb2xyz');
    
end