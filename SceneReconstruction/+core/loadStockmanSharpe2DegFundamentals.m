function sensorLMS = loadStockmanSharpe2DegFundamentals()
    d = load('T_cones_ss2.mat');
    sensorLMS.S = d.S_cones_ss2;
    sensorLMS.T = d.T_cones_ss2;
end
