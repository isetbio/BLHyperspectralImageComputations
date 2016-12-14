function sensorXYZ = loadXYZCMFs()
    d = load('T_xyz1931.mat');
    sensorXYZ.S = d.S_xyz1931;
    sensorXYZ.T = d.T_xyz1931;
end