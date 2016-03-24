function [coneFundamentals, displaySPDs, wave] = LMSRGBconversionData(displayName, gain)
    sensorLMS = core.loadStockmanSharpe2DegFundamentals();
    wave = SToWls(sensorLMS.S);
    validWaveIndices = 2:numel(wave)-50;
    wave = wave(validWaveIndices);
    coneFundamentals = (sensorLMS.T)';
    coneFundamentals = coneFundamentals(validWaveIndices,:);
    
    d = displayCreate(displayName, 'wave', wave);
    % The higher the gain, the more LMS contrast we can render without going out of gamut
    displaySPDs = d.spd*gain;
end