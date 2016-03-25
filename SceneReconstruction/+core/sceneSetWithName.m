function sceneSet = sceneSetWithName(sceneSetName)

    switch (sceneSetName)
        case 'manchester'
            sceneSet = {...
                {'manchester_database', 'scene1'} ...
                {'manchester_database', 'scene2'} ...
                 {'manchester_database', 'scene3'} ...
                 {'manchester_database', 'scene6'} ...
                 {'manchester_database', 'scene7'} ...
                 {'manchester_database', 'scene8'} ... %{'manchester_database', 'scene4'} ...
            };
        otherwise
            error('Unknown scene set name: ''%s''.\n', sceneSetName);
    end
    
    if (1==2)
        for k = 1:numel(sceneSet)
            imsource = sceneSet{k};
            fprintf('%2d. ''%s'' / ''%s''\n', k, imsource{1}, imsource{2}); 
        end
        fprintf('\n');
    end
    
end
