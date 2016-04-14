function loadCameraSensitivityProfile(obj)

    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    calibFileName = fullfile(sourceDir, obj.sceneData.subset, 'calib.txt');
    
    fileID = fopen(calibFileName);
    C = textscan(fileID,'%f');
    fclose(fileID);

    obj.cameraSensitivityProfile = reshape( C{1}, [1 1 numel(C{1})]);

end

