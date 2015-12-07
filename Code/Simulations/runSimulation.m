function runSimulation
    
    addConeLearningToolboxesToPath();
    
    conesAcross = 15;
    recomputePhotonAbsorptionMatrices = false;
    
    sceneSet{1}.dataBaseName = 'manchester_database';
    sceneSet{1}.sceneNames = {'scene1', 'scene2', 'scene3', 'scene4', 'scene6', 'scene7', 'scene8'};
    
    sceneSet{2}.dataBaseName = 'harvard_database';
    sceneSet{2}.sceneNames = {...
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
    
    % Instantiate a ConeLearningProcessor
    coneLearningProcessor = ConeLearningProcessor();
    
    if (recomputePhotonAbsorptionMatrices)
        coneAbsorptionsFile = coneLearningProcessor.computeSpatioTemporalPhotonAbsorptionMatrix(...
                              'conesAcross', conesAcross, ...
                    'coneApertureInMicrons', 3.0, ...
                 'sampleTimeInMilliseconds', 1.0, ...
                         'coneLMSdensities', [0.6 0.3 0.1], ...
             'eyeMicroMovementsPerFixation', 100, ...
                                 'sceneSet', sceneSet ...
        );
        fprintf('\n\nAll done with computation of photon absorption matrices ...');
        return;
    else
        coneAbsorptionsFile = sprintf('PhotonAbsorptionMatrices_%dx%d.mat', conesAcross, conesAcross);
    end
    
    
    % precorrelation filter for photocurrent de-noising
    precorrelationFilterType = 'monophasic';  % 'monophasic' or 'biphasic'
    
    if (strcmp(precorrelationFilterType, 'monophasic'))
        % monophasic filter
        preCorrelationFilterSpecs = struct(...
                                'type', precorrelationFilterType, ...
           'timeConstantInMilliseconds', 125 ...
        );
    else 
        % biphasic filter
        preCorrelationFilterSpecs = struct(...
                                  'type', precorrelationFilterType, ...
           'timeConstant1InMilliseconds', 30, ...
           'timeConstant2InMilliseconds', 80, ...
                         'biphasicRatio', 0.15 ...   % ratio of second phase to first phase
        );
    end

    
    coneLearningProcessor.learnConeMosaic(coneAbsorptionsFile, ...
                   'fixationsPerSceneRotation', 8,...
                             'adaptationModel', 'linear', ...               % 'none' or 'linear'
                           'photocurrentNoise', 'RiekeNoise',...            % 'noNoise' or 'RiekeNoise'
'correlationComputationIntervalInMilliseconds', 1, ...                      % smallest value is 1 milliseconds
                   'precorrelationFilterSpecs', preCorrelationFilterSpecs, ...   % struct with filter params
                             'disparityMetric', 'linear', ...                  % 'log' or 'linear'
       'coneLearningUpdateIntervalInFixations', 1, ...                    % update cone mosaic learning every this many fixations
                              'mdsWarningsOFF', true, ...                   % set to true to avoid wanrings about MDS not converging
                     'displayComputationTimes', false, ...                  % set to true to see the time that each computation takes
                                'outputFormat', 'still' ...                 % 'video' or 'still'
   );
    
end


function addConeLearningToolboxesToPath()
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    cd ..
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
end