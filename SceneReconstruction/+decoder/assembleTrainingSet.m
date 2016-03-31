function assembleTrainingSet(sceneSetName, descriptionString, trainingDataPercentange)

    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    trainingTimeAxis = [];
    
    sceneSet = core.sceneSetWithName(sceneSetName);
    
    for sceneIndex = 1:numel(sceneSet) 
        scanFileName = core.getScanFileName(sceneSetName, descriptionString, sceneIndex);
        load(scanFileName, 'scanData', 'scene', 'oi', 'expParams');
        
        scansNum = numel(scanData);
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
        fprintf('Scene contains %d scans. Will use %d of these for training. \n', scansNum, trainingScans);
       
        % concatenate training datasets
        for scanIndex = 1:trainingScans
            
            totalTrainingScansNum = totalTrainingScansNum + 1;
            if (totalTrainingScansNum == 1)
                dt = scanData{scanIndex}.timeAxis(2)-scanData{scanIndex}.timeAxis(1);
                trainingTimeAxis                        = single(scanData{scanIndex}.timeAxis);
                trainingScanInsertionTimes              = trainingTimeAxis(1);
                trainingSceneIndexSequence              = repmat(single(sceneIndex), [1 numel(scanData{scanIndex}.timeAxis)]);
                sensorFOVxaxis                          = scanData{scanIndex}.sensorFOVxaxis;
                sensorFOVyaxis                          = scanData{scanIndex}.sensorFOVyaxis;
                sensorRetinalXaxis                      = scanData{scanIndex}.sensorRetinalXaxis;
                sensorRetinalYaxis                      = scanData{scanIndex}.sensorRetinalYaxis;
                trainingSensorPositionSequence          = single(scanData{scanIndex}.sensorPositionSequence);
                trainingSceneLMScontrastSequence        = single(scanData{scanIndex}.sceneLMScontrastSequence);
                trainingOpticalImageLMScontrastSequence = single(scanData{scanIndex}.oiLMScontrastSequence);
                trainingPhotoCurrentSequence            = single(scanData{scanIndex}.photoCurrentSequence);
                trainingSceneLMSbackground              = single(scanData{scanIndex}.sceneBackgroundExcitations);
                trainingOpticalImageLMSbackground       = single(scanData{scanIndex}.oiBackgroundExcitations);
            else
                trainingTimeAxis = cat(2, ...
                    trainingTimeAxis, single(scanData{scanIndex}.timeAxis + trainingTimeAxis(end) + dt));
                
                insertionPoints = numel(scanData{scanIndex}.timeAxis);
                trainingScanInsertionTimes = cat(2, trainingScanInsertionTimes, trainingTimeAxis(end-insertionPoints+1));
                
                trainingSceneIndexSequence = cat(2, ...
                    trainingSceneIndexSequence, repmat(single(sceneIndex), [1 numel(scanData{scanIndex}.timeAxis)]));
                
                trainingSensorPositionSequence = cat(1, ...
                    trainingSensorPositionSequence, single(scanData{scanIndex}.sensorPositionSequence));
                
                trainingSceneLMScontrastSequence = cat(4, ...
                    trainingSceneLMScontrastSequence,  single(scanData{scanIndex}.sceneLMScontrastSequence));
                
                trainingOpticalImageLMScontrastSequence = cat(4, ...
                    trainingOpticalImageLMScontrastSequence, single(scanData{scanIndex}.oiLMScontrastSequence));
                
                trainingPhotoCurrentSequence = cat(3, ...
                    trainingPhotoCurrentSequence,  single(scanData{scanIndex}.photoCurrentSequence));
                
                trainingSceneLMSbackground = cat(2, ...
                    trainingSceneLMSbackground, single(scanData{scanIndex}.sceneBackgroundExcitations));
                    
                trainingOpticalImageLMSbackground = cat(2, ...
                    trainingOpticalImageLMSbackground, single(scanData{scanIndex}.oiBackgroundExcitations));
            end 
        end % scanIndex - training
        

        % concatenate testing datasets
        for scanIndex = trainingScans+1:scansNum 
            totalTestingScansNum = totalTestingScansNum + 1;
            if (totalTestingScansNum == 1)
                dt = scanData{scanIndex}.timeAxis(2)-scanData{scanIndex}.timeAxis(1);
                testingTimeAxis = single(scanData{scanIndex}.timeAxis);
                testingScanInsertionTimes              = trainingTimeAxis(1);
                testingSceneIndexSequence              = repmat(single(sceneIndex), [1 numel(scanData{scanIndex}.timeAxis)]);
                testingSensorPositionSequence          = single(scanData{scanIndex}.sensorPositionSequence);
                testingSceneLMScontrastSequence        = single(scanData{scanIndex}.sceneLMScontrastSequence);
                testingOpticalImageLMScontrastSequence = single(scanData{scanIndex}.oiLMScontrastSequence);
                testingPhotoCurrentSequence            = single(scanData{scanIndex}.photoCurrentSequence);
                testingSceneLMSbackground              = single(scanData{scanIndex}.sceneBackgroundExcitations);
                testingOpticalImageLMSbackground       = single(scanData{scanIndex}.oiBackgroundExcitations);
            else
                testingTimeAxis = cat(2, ...
                    testingTimeAxis, single(scanData{scanIndex}.timeAxis + testingTimeAxis(end) + dt));
                
                insertionPoints = numel(scanData{scanIndex}.timeAxis);
                testingScanInsertionTimes = cat(2, testingScanInsertionTimes, testingTimeAxis(end-insertionPoints+1));
               
                testingSceneIndexSequence = cat(2, ...
                    testingSceneIndexSequence, repmat(single(sceneIndex), [1 numel(scanData{scanIndex}.timeAxis)]));
                
                testingSensorPositionSequence = cat(1, ...
                    testingSensorPositionSequence, single(scanData{scanIndex}.sensorPositionSequence));
                
                testingSceneLMScontrastSequence = cat(4, ...
                    testingSceneLMScontrastSequence,  single(scanData{scanIndex}.sceneLMScontrastSequence));
                
                testingOpticalImageLMScontrastSequence = cat(4, ...
                    testingOpticalImageLMScontrastSequence, single(scanData{scanIndex}.oiLMScontrastSequence));
                
                testingPhotoCurrentSequence = cat(3, ...
                    testingPhotoCurrentSequence,  single(scanData{scanIndex}.photoCurrentSequence));
                
                testingSceneLMSbackground = cat(2, ...
                    testingSceneLMSbackground, single(scanData{scanIndex}.sceneBackgroundExcitations));
                    
                testingOpticalImageLMSbackground = cat(2, ...
                    testingOpticalImageLMSbackground, single(scanData{scanIndex}.oiBackgroundExcitations));
    
            end
        end % scanIndex - testing
    end % sceneIndex
    
    
    debugForTransients = false;
        if (debugForTransients)
            figure(33); colormap(gray(1024));
            CLims = [-1 1];
            for k = 1:2:size(trainingSceneLMScontrastSequence,4)
                for cone = 1:3
                subplot(1,4,cone);
                imagesc(sensorFOVxaxis, sensorFOVyaxis, squeeze(trainingSceneLMScontrastSequence(:,:,cone, k))); axis 'xy'; axis 'image';
                axis 'xy'; axis 'image';
                set(gca, 'XLim', [sensorFOVxaxis(1) sensorFOVxaxis(end)]);
                set(gca, 'YLim', [sensorFOVyaxis(1) sensorFOVyaxis(end)]);
                set(gca, 'CLim', CLims);
                end
                subplot(1,4,4);
                imagesc(sensorRetinalXaxis, sensorRetinalYaxis, squeeze(trainingPhotoCurrentSequence(:,:,k))); 
                axis 'xy'; axis 'image';
                set(gca, 'XLim', [sensorFOVxaxis(1) sensorFOVxaxis(end)]);
                set(gca, 'YLim', [sensorFOVyaxis(1) sensorFOVyaxis(end)]);
                set(gca,  'CLim', [-80 -20]);
                drawnow;
                pause(0.1);
                
            end
        end
        
        
    disp('Sizes of training sequence')
    size(trainingScanInsertionTimes)
    size(trainingSceneLMSbackground)
    size(trainingOpticalImageLMSbackground)
    
    
    disp('Sizes of testing sequences')
    size(testingScanInsertionTimes)
    size(testingSceneLMSbackground)
    size(testingOpticalImageLMSbackground)
    
    
    fprintf('Training matrices\n');
    fprintf('Total training scans: %d\n', totalTrainingScansNum)
    fprintf('Size(timeAxis)         : %d %d\n', size(trainingTimeAxis,1), size(trainingTimeAxis,2));
    fprintf('Size(sceneIndex)       : %d %d\n', size(trainingSceneIndexSequence,1), size(trainingSceneIndexSequence,2));
    fprintf('Size(sensor positions) : %d %d\n', size(trainingSensorPositionSequence,1), size(trainingSensorPositionSequence,2));
    fprintf('Size(scene LMS)        : %d %d %d %d\n', size(trainingSceneLMScontrastSequence,1), size(trainingSceneLMScontrastSequence,2), size(trainingSceneLMScontrastSequence,3), size(trainingSceneLMScontrastSequence,4));
    fprintf('Size(optical image LMS): %d %d %d %d\n', size(trainingOpticalImageLMScontrastSequence,1), size(trainingOpticalImageLMScontrastSequence,2), size(trainingOpticalImageLMScontrastSequence,3), size(trainingOpticalImageLMScontrastSequence,4));
    fprintf('Size(photocurrents)    : %d %d %d\n', size(trainingPhotoCurrentSequence,1), size(trainingPhotoCurrentSequence,2), size(trainingPhotoCurrentSequence,3));
                  
    fprintf('Testing matrices\n');
    fprintf('Total testing scans:  %d\n', totalTestingScansNum)
    fprintf('Size(timeAxis)         : %d %d\n', size(testingTimeAxis,1), size(testingTimeAxis,2));
    fprintf('Size(sceneIndex)       : %d %d\n', size(testingSceneIndexSequence,1), size(testingSceneIndexSequence,2));
    fprintf('Size(sensor positions) : %d %d\n', size(testingSensorPositionSequence,1), size(testingSensorPositionSequence,2));
    fprintf('Size(scene LMS)        : %d %d %d %d\n', size(testingSceneLMScontrastSequence,1), size(testingSceneLMScontrastSequence,2), size(testingSceneLMScontrastSequence,3), size(testingSceneLMScontrastSequence,4));
    fprintf('Size(optical image LMS): %d %d %d %d\n', size(testingOpticalImageLMScontrastSequence,1), size(testingOpticalImageLMScontrastSequence,2), size(testingOpticalImageLMScontrastSequence,3), size(testingOpticalImageLMScontrastSequence,4));
    fprintf('Size(photocurrents)    : %d %d %d\n', size(testingPhotoCurrentSequence,1), size(testingPhotoCurrentSequence,2), size(testingPhotoCurrentSequence,3));
    
    if (1==2)
       visualizer.renderSceneAndOpticalLMScontrastAndPhotocurrentSequences(sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, trainingTimeAxis, trainingPhotoCurrentSequence, trainingSceneLMScontrastSequence,trainingOpticalImageLMScontrastSequence); 
    end
    
    % Decide which cones to keep
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = ...
        decoder.cherryPickConesToIncludeInDecoding(scanData{scanIndex}.scanSensor, expParams.decoderParams.thresholdConeSeparationForInclusionInDecoder);
    
    fprintf('Size of training photocurrent sequence')
    size(trainingPhotoCurrentSequence)
    % Reshape training cone responses to decoder format
    [trainingResponses, originalTrainingPhotoCurrentSequence] = ...
        decoder.reformatResponseSequence('ToDesignMatrixFormat', trainingPhotoCurrentSequence);
     
    fprintf('Size of trainingResponses\n');
    size(trainingResponses)
    
    fprintf('Size of trainingSceneLMScontrastSequence');
    size(trainingSceneLMScontrastSequence)
    
    % Reshape training stimulus to decoder format
    [trainingStimulus, originalTrainingStimulusSize] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', trainingSceneLMScontrastSequence);
    
    fprintf('Size of trainingStimulus');
    size(trainingStimulus)

    [trainingStimulusOI, ~] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', trainingOpticalImageLMScontrastSequence);
    
    % Compute training design matrix and stimulus vector
    [Xtrain, Ctrain, oiCtrain] = decoder.computeDesignMatrixAndStimulusVector(trainingResponses, trainingStimulus, trainingStimulusOI, expParams.decoderParams);
    
    whos 'Xtrain'
    whos 'Ctrain'
    
    % Save design matrices and stimulus vectors
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    fprintf('\nSaving training design matrix and stim vector ''%s''... ', fileName);
    save(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtrain'; clear 'Ctrain'; clear 'oiCtrain'
    
    % Reshape testing cone responses to decoder format
    testingResponses = reshape(testingPhotoCurrentSequence, ...
        [size(testingPhotoCurrentSequence,1)*size(testingPhotoCurrentSequence,2) size(testingPhotoCurrentSequence,3)]);
    
    % Reshape testing stimulus to decoder format
    [testingStimulus, originalTestingStimulusSize] = ...
        decoder.stimulusSequenceToDecoderFormat(testingSceneLMScontrastSequence, 'toDecoderFormat', []);
    
    [testingStimulusOI, ~] = ...
        decoder.stimulusSequenceToDecoderFormat(testingOpticalImageLMScontrastSequence, 'toDecoderFormat', []);
    
    % Compute testing design matrix and stimulus vector
    [Xtest, Ctest, oiCtest] = decoder.computeDesignMatrixAndStimulusVector(testingResponses, testingStimulus, testingStimulusOI, expParams.decoderParams);
    whos 'Xtest'
    whos 'Ctest'
    
    % Save design matrices and stimulus vectors
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    fprintf('\nSaving test design matrix and stim vector to ''%s''... ', fileName);
    save(fileName, 'Xtest', 'Ctest', 'oiCtest', 'testingTimeAxis', 'testingSceneIndexSequence', 'testingSensorPositionSequence', 'testingScanInsertionTimes',  'testingSceneLMSbackground', 'testingOpticalImageLMSbackground', 'originalTestingStimulusSize', 'expParams', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtest'; clear 'Ctest'; clear 'oiCtest';
end
