function batchImportHyperSpectralImages

    %% Get our project toolbox on the path
    myDir = fileparts(mfilename('fullpath'));
    pathDir = fullfile(myDir,'..','Toolbox','');
    AddToMatlabPathDynamically(pathDir);
   
    % set to true if you want to see the generated isetbio data
    showIsetbioData = true;
    
    whichDataBase = 'manchester_database';
    
    whichDataBase = 'harvard_database';
    % subset containing 50 (both outdoors and indoors) images under daylight ilumination
    whichSubset   = 'CZ_hsdb';
    
    % subset containing 25 images under artificial and mixed illumination 
    %whichSubset   = 'CZ_hsdbi';
    
    switch (whichDataBase)
        
        case 'harvard_database'
            
            applyMotionMask = false;
            setHarvardUniv = { ...
            %    struct('databaseName', whichDataBase, 'subsetDirectory', whichSubset, 'sceneName','img1', 'applyMotionMask', applyMotionMask, 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
                struct('databaseName', whichDataBase, 'subsetDirectory', whichSubset, 'sceneName','img2', 'applyMotionMask', true, 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
                };
            
            % Full set
            set = {setHarvardUniv{:}};
        
        case 'manchester_database'
        % Scenes with recorded information regarding geometry and illuminant.
        set1MancesterUniv = { ...
            struct('databaseName', 'manchester_database', 'sceneName','scene1', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene2', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene3', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene4', 'clipLuminance',12000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene5', 'clipLuminance',12000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...  % this will be skipped because of discrepancy b/n number of spectral bands in reflectance/illuminant
            struct('databaseName', 'manchester_database', 'sceneName','scene6', 'clipLuminance',14000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene7', 'clipLuminance',8000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene8', 'clipLuminance',8000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            };

        % Scenes with missing (but filled-in, by Nicolas) information regarding geometry and illuminant.
        set2MancesterUniv = { ...
            struct('databaseName', 'manchester_database', 'sceneName','scene9',  'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene10', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene11', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene12', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene13', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene14', 'clipLuminance', 9000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene15', 'clipLuminance', 12000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            struct('databaseName', 'manchester_database', 'sceneName','scene16', 'clipLuminance', 12000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
            };

        % Full set
        set = {set1MancesterUniv{:} set2MancesterUniv{:}};
        
    end
    
    
    
    exportIsetbioSceneObject = true;
    % Start the batch import and process
    for k = 1:numel(set)
        s = set{k};
        fprintf('\n<strong>--------------------------------------------------------------------------------------------</strong>\n');
        fprintf('<strong>%2d. Importing data files for scene ''%s'' of database ''%s''.</strong>\n', k, s.sceneName, s.databaseName);
        fprintf('<strong>--------------------------------------------------------------------------------------------</strong>\n');
        importHyperSpectralImage(set{k}, exportIsetbioSceneObject);
    end
end







