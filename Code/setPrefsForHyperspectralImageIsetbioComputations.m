function setPrefsForHyperspectralImageIsetbioComputations

<<<<<<< HEAD
    originalDataBaseDir = '/Users1/HyperSpectralImages';  % valid on Manta
    opticalImagesCacheDir  = '/Users1/Shared/Matlab/Analysis/BLHyperspectralImageComputations/OpticalImagesCache';
   
=======
    %originalDataBaseDir = '/Volumes/SDXC_64GB/Matlab/Analysis/HyperSpectralImages/ManchesterData';
    originalDataBaseDir = '/Users1/HyperSpectralImages';
    isetbioDataBaseDir  = '/Users1/Shared/Matlab/Analysis/isetbioHyperspectralImages';
   % isetbioDataBaseDir  = '/Volumes/Data/Users1/Shared/Matlab/Analysis/isetbioHyperspectralImages';

>>>>>>> edc229ee339e7ac3e8bb7fb0bb21f4fd0517b477
    % Specify project-specific preferences
    p = struct( ...
        'projectName', 'HyperSpectralImageIsetbioComputations', ...
        'originalDataBaseDir',  originalDataBaseDir,...
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
