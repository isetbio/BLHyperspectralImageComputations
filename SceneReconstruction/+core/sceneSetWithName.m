function sceneSet = sceneSetWithName(sceneSetName)

    switch (sceneSetName)
        case 'harvard_manchester'
            sceneNames = {...
                'img1', 'img2', 'img4', 'img6', ...
                'imga1', 'imga2', 'imga4', 'imga5', 'imga6', 'imga7', 'imga8', ...
                'imgb1', 'imgb2', 'imgb3', 'imgb5', 'imgb6', ...
                'imgc1', 'imgc2', 'imgc3', 'imgc4', 'imgc5', 'imgc6', 'imgc7', 'imgc8', 'imgc9', ...
                'imgd0', 'imgd1', 'imgd2', 'imgd3', 'imgd4', 'imgd5', 'imgd6', 'imgd7', 'imgd8', 'imgd9', ...
                'imge0', 'imge1', 'imge2', 'imge3', 'imge4', 'imge5', 'imge6', 'imge7', ...
                'imgf1', 'imgf2', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
                'imgg0', 'imgg2', 'imgg5', 'imgg8', 'imgg9', ...
                'imgh0', 'imgh1', 'imgh2', 'imgh3' ...
            };

            sceneNames = {...
                'img1', 'img6', ...
                'imga1', 'imga8', ...
                'imgb1', 'imgb5', 'imgb6', ...
                'imgc7', 'imgc8', 'imgc9', ...
                'imgd5', 'imgd8', 'imgd9', ...
                'imge0', 'imge1', 'imge2', 'imge3', 'imge5', 'imge6', ...
                'imgf2', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
                'imgg0', 'imgg9', ...
            };
    
            sceneSet1 = {};
            for k = 1:numel(sceneNames)
                sceneSet1{numel(sceneSet1)+1} = {'harvard_database', sceneNames{k}};    
            end
            
            sceneSet2 = {...
                {'manchester_database', 'scene1'} ...
                {'manchester_database', 'scene2'} ...
                {'manchester_database', 'scene3'} ...
                {'manchester_database', 'scene6'} ...
                {'manchester_database', 'scene7'} ...
                {'manchester_database', 'scene8'} ... 
                {'manchester_database', 'scene4'} ...
            };
            sceneSet = cat(2, sceneSet1, sceneSet2);
            
        case 'manchester'
            sceneSet = {...
                {'manchester_database', 'scene1'} ...
                {'manchester_database', 'scene2'} ...
                {'manchester_database', 'scene3'} ...
                {'manchester_database', 'scene6'} ...
                {'manchester_database', 'scene7'} ...
                {'manchester_database', 'scene8'} ... 
                {'manchester_database', 'scene4'} ...
            };
        
        otherwise
            if (strfind(sceneSetName, 'manchester_harvard_'))
                harvardImageIndex = str2num(sceneSetName(numel('manchester_harvard_')+1:numel(sceneSetName)));
                harvardSceneNames = {...
                    'img1', 'img6', ...
                    'imga1', 'imga8', ...
                    'imgb1', 'imgb5', 'imgb6', ...
                    'imgc7', 'imgc8', 'imgc9', ...
                    'imgd5', 'imgd8', 'imgd9', ...
                    'imge0', 'imge1', 'imge2', 'imge3', 'imge5', 'imge6', ...
                    'imgf2', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
                    'imgg0', 'imgg9', ...
                };
                sceneSet1 = {};
                for k = 1:numel(sceneSet1)
                    sceneSet1{k} = {'harvard_database', sceneSet1{k}};    
                end
                if (harvardImageIndex > 0)
                    sceneSet1{numel(sceneSet1)+1} = {'harvard_database', harvardSceneNames{harvardImageIndex}}; 
                end
                
                sceneSet2 = {...
                    {'manchester_database', 'scene1'} ...
                    {'manchester_database', 'scene2'} ...
                    {'manchester_database', 'scene3'} ...
                    {'manchester_database', 'scene6'} ...
                    {'manchester_database', 'scene7'} ...
                    {'manchester_database', 'scene8'} ... 
                    {'manchester_database', 'scene4'} ...
                };
                sceneSet = cat(2, sceneSet1, sceneSet2);
            
            else
                error('Unknown scene set name: ''%s''.\n', sceneSetName);
            end
    end
    
end