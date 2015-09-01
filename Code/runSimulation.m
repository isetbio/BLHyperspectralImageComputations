function runSimulation
    
    addConeLearningToolboxesToPath();
    
    sceneSet{1}.dataBaseName = 'manchester_database';
    sceneSet{1}.sceneNames = {'scene1', 'scene2', 'scene3', 'scene4', 'scene6', 'scene7', 'scene8'};
    
    
    sceneSet{2}.dataBaseName = 'harvard_database';
    sceneSet{2}.sceneNames = {...
        'img1', 'img2', 'img3', 'img4', 'img6', ...
        'imga1', 'imga2', 'imga4', 'imga5', 'imga6', 'imga7', 'imga8', ...
        'imgb1', 'imgb2', 'imgb3', 'imgb5', 'imgb6', 'imgb7', 'imgb8', ...
        'imgc1', 'imgc2', 'imgc3', 'imgc4', 'imgc5', 'imgc6', 'imgc7', 'imgc8', 'imgc9', ...
        'imgd0', 'imgd1', 'imgd2', 'imgd3', 'imgd4', 'imgd5', 'imgd6', 'imgd7', 'imgd8', 'imgd9', ...
        'imge0', 'imge1', 'imge2', 'imge3', 'imge4', 'imge5', 'imge6', 'imge7', ...
        'imgf1', 'imgf2', 'imgf3', 'imgf4', 'imgf5', 'imgf6', 'imgf7', 'imgf8', ...
        'imgg0', 'imgg2', 'imgg5', 'imgg8', 'imgg9', ...
        'imgh0', 'imgh1', 'imgh2', 'imgh3' ...
        };

    
    coneLearningProcessor = ConeLearningProcessor();
    
    recomputePhotoAbsorptionMatrices = dalse;
    if (recomputePhotoAbsorptionMatrices)
        coneAbsorptionsFile = coneLearningProcessor.computeSpatioTemporalPhotonAbsorptionMatrix(...
                              'conesAcross', 10, ...
                    'coneApertureInMicrons', 3.0, ...
        'coneIntegrationTimeInMilliseconds', 50.0, ...
                         'coneLMSdensities', [0.6 0.3 0.1], ...
             'eyeMicroMovementsPerFixation', 100, ...
                                 'sceneSet', sceneSet ...
        );
    else
        coneAbsorptionsFile = 'PhotonAbsorptionMatrices_10x10.mat';
    end
    
    coneLearningProcessor.generateConeLearningProgressVideo(...
        coneAbsorptionsFile, ...
        'fixationsPerSceneRotation', 12,...
             'adaptationModelToUse', 'linear', ...               % 'none' or 'linear'
                        'noiseFlag', 'RiekeNoise',...            % 'noNoise' or 'RiekeNoise'
             'precorrelationFilter', monoPhasicIR(50, 300), ...  % monoPhasicIR(50, 300) or biPhasicIR(30, 80, 300)
                  'disparityMetric', 'log', ...                  % 'log' or 'linear'
                   'mdsWarningsOFF', true, ...                   % set to true to avoid wanrings about MDS not convering
    'coneLearningUpdateInFixations', 1.0 ...                     % update cone mosaic learning every this many fixations
   );
    
end


function IR = monoPhasicIR(timeConstantInMilliseconds, supportInMilliseconds)
    n = 4;
    p1 = 1;
    t = (0:1:supportInMilliseconds)/1000;
    tau = timeConstantInMilliseconds/1000;
    t1 = t / tau;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1));
    IR = IR / sum(abs(IR)); 
end

function IR = biPhasicIR(timeConstant1InMilliseconds, timeConstant2InMilliseconds, supportInMilliseconds)
    n = 4;
    p1 = 1;
    p2 = 0.15;
    t = (0:1:supportInMilliseconds)/1000;
    tau1 = timeConstant1InMilliseconds/1000;
    tau2 = timeConstant2InMilliseconds/1000;
    t1 = t / tau1;
    t2 = t / tau2;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1))  - p2 * (t2.^n) .* exp(-n*(t2-1));
    IR = IR / sum(abs(IR));
end


function addConeLearningToolboxesToPath()
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
end