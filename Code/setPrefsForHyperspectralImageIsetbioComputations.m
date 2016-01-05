function setPrefsForHyperspectralImageIsetbioComputations

    originalDataBaseDir = '/Users1/HyperSpectralImages';  % valid on Manta
    isetbioScenesDir = '/Users1/Shared/Matlab/Analysis/isetbioHyperspectralImages';
    opticalImagesCacheDir  = '/Users1/Shared/Matlab/Analysis/BLHyperspectralImageComputations/OpticalImagesCache';
   
    % Specify project-specific preferences
    p = struct( ...
        'projectName', 'HyperSpectralImageIsetbioComputations', ...
        'isetbioSceneDataBaseDir',  isetbioScenesDir, ... % where to put the scene files (before they are uploaded to archiva)
        'originalDataBaseDir',  originalDataBaseDir,...   % where the original data live
        'remoteDataToolboxConfig', '/Users/nicolas/Documents/1.code/2.matlabDevs/ProjectPrefs/rdt-config-isetbio-nicolas.json', ...
        'opticalImagesCacheDir', opticalImagesCacheDir ...
        );
    
    generatePreferenceGroup(p);
end

function generatePreferenceGroup(p)
    % remove any existing preferences for this project
    if ispref(p.projectName)
        rmpref(p.projectName);
    end
    
    % generate and save the project-specific preferences
    preferences = setdiff(fieldnames(p), 'projectName');
    for k = 1:numel(preferences)
        setpref(p.projectName, preferences{k}, p.(preferences{k}));
    end
    fprintf('Generated and saved preferences specific to the ''%s'' project.\n', p.projectName);
end
