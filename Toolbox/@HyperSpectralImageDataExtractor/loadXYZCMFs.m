% Method to load the CIE '31 XYZ CMFs
function loadXYZCMFs(obj)
    colorMatchingData = load('T_xyz1931.mat');
    obj.sensorXYZ = struct;
    obj.sensorXYZ.S = colorMatchingData.S_xyz1931;
    obj.sensorXYZ.T = colorMatchingData.T_xyz1931;
    clear 'colorMatchingData';
end

