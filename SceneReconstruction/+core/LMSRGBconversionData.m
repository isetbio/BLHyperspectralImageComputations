function [coneFundamentals, displaySPDs, RGBtoXYZ, wave] = LMSRGBconversionData(displayName, gain)
    sensorLMS = core.loadStockmanSharpe2DegFundamentals();
    wave = SToWls(sensorLMS.S);
    validWaveIndices = 2:numel(wave)-50;
    wave = wave(validWaveIndices);
    coneFundamentals = (sensorLMS.T)';
    coneFundamentals = coneFundamentals(validWaveIndices,:);
    
    d = displayCreate(displayName, 'wave', wave);
    displaySPDs = displayGet(d, 'spd');
    displaySPDs = displaySPDs*gain;
    d = displaySet(d, 'spd', displaySPDs);
    RGBtoXYZ = displayGet(d, 'rgb2xyz');
end