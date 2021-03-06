function assembleTrainingSet(sceneSetName, resultsDir, decodingDataDir, trainingDataPercentange, testingDataPercentage, preProcessingParams)

     
    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    trainingTimeAxis = [];
    
    sceneSet = core.sceneSetWithName(sceneSetName);
    
    for sceneIndex = 1:numel(sceneSet) 
        scanFileName = core.getScanFileName(sceneSetName, resultsDir, sceneIndex);
        load(scanFileName, 'scanData', 'scene', 'oi', 'expParams');
        
        scansNum = numel(scanData);
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
        testingScans  = round(testingDataPercentage/100.0*scansNum);
        if (trainingScans+testingScans > numel(scanData))
            testingScans = numel(scanData)-trainingScans;
        end
        
        fprintf('Scene contains %d scans. Will use %d of these for training and %d for testing. \n', scansNum, trainingScans, testingScans);
       
        % concatenate training datasets
        for scanIndex = 1:trainingScans
            
            totalTrainingScansNum = totalTrainingScansNum + 1;
            if (totalTrainingScansNum == 1)
                dt = scanData{scanIndex}.timeAxis(2)-scanData{scanIndex}.timeAxis(1);
                trainingTimeAxis                        = single(scanData{scanIndex}.timeAxis);
                trainingScanInsertionTimes              = trainingTimeAxis(1);
                trainingSceneIndexSequence              = repmat(single(sceneIndex), [1 numel(scanData{scanIndex}.timeAxis)]);
                coneTypes                               = sensorGet(scanData{scanIndex}.scanSensor, 'coneType');
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
        for scanIndex = trainingScans+(1:testingScans) 
            if (scanIndex > numel(scanData))
                continue
            end
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
        
    fprintf('\nTraining matrices\n');
    fprintf('\tTotal training scans: %d\n', totalTrainingScansNum)
    fprintf('\tSize(timeAxis)         : %d %d\n', size(trainingTimeAxis,1), size(trainingTimeAxis,2));
    fprintf('\tSize(sceneIndex)       : %d %d\n', size(trainingSceneIndexSequence,1), size(trainingSceneIndexSequence,2));
    fprintf('\tSize(sensor positions) : %d %d\n', size(trainingSensorPositionSequence,1), size(trainingSensorPositionSequence,2));
    fprintf('\tSize(scene LMS)        : %d %d %d %d\n', size(trainingSceneLMScontrastSequence,1), size(trainingSceneLMScontrastSequence,2), size(trainingSceneLMScontrastSequence,3), size(trainingSceneLMScontrastSequence,4));
    fprintf('\tSize(optical image LMS): %d %d %d %d\n', size(trainingOpticalImageLMScontrastSequence,1), size(trainingOpticalImageLMScontrastSequence,2), size(trainingOpticalImageLMScontrastSequence,3), size(trainingOpticalImageLMScontrastSequence,4));
    fprintf('\tSize(photocurrents)    : %d %d %d\n', size(trainingPhotoCurrentSequence,1), size(trainingPhotoCurrentSequence,2), size(trainingPhotoCurrentSequence,3));
                  
    fprintf('\nTesting matrices\n');
    fprintf('\tTotal testing scans:  %d\n', totalTestingScansNum)
    fprintf('\tSize(timeAxis)         : %d %d\n', size(testingTimeAxis,1), size(testingTimeAxis,2));
    fprintf('\tSize(sceneIndex)       : %d %d\n', size(testingSceneIndexSequence,1), size(testingSceneIndexSequence,2));
    fprintf('\tSize(sensor positions) : %d %d\n', size(testingSensorPositionSequence,1), size(testingSensorPositionSequence,2));
    fprintf('\tSize(scene LMS)        : %d %d %d %d\n', size(testingSceneLMScontrastSequence,1), size(testingSceneLMScontrastSequence,2), size(testingSceneLMScontrastSequence,3), size(testingSceneLMScontrastSequence,4));
    fprintf('\tSize(optical image LMS): %d %d %d %d\n', size(testingOpticalImageLMScontrastSequence,1), size(testingOpticalImageLMScontrastSequence,2), size(testingOpticalImageLMScontrastSequence,3), size(testingOpticalImageLMScontrastSequence,4));
    fprintf('\tSize(photocurrents)    : %d %d %d\n\n', size(testingPhotoCurrentSequence,1), size(testingPhotoCurrentSequence,2), size(testingPhotoCurrentSequence,3));
    
    if (1==2)
       visualizer.renderSceneAndOpticalLMScontrastAndPhotocurrentSequences(sensorFOVxaxis, sensorFOVyaxis, sensorRetinalXaxis, sensorRetinalYaxis, trainingTimeAxis, trainingPhotoCurrentSequence, trainingSceneLMScontrastSequence,trainingOpticalImageLMScontrastSequence); 
    end
    
    % Decide which cones to keep
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = ...
        core.cherryPickConesToIncludeInDecoding(scanData{scanIndex}.scanSensor, expParams.decoderParams.thresholdConeSeparationForInclusionInDecoder);
    
    % Reshape training cone responses to decoder format
    [trainingResponses, originalTrainingPhotoCurrentSequence] = ...
        decoder.reformatResponseSequence('ToDesignMatrixFormat', trainingPhotoCurrentSequence);
    
    % Reshape training stimulus to decoder format
    [trainingStimulus, originalTrainingStimulusSize] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', trainingSceneLMScontrastSequence);

    [trainingStimulusOI, ~] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', trainingOpticalImageLMScontrastSequence);
    
    % Preprocess raw signals
    rawTrainingResponsePreprocessing = [];
    [trainingResponses, rawTrainingResponsePreprocessing] = decoder.preProcessRawResponses(trainingResponses, preProcessingParams, rawTrainingResponsePreprocessing);
    
    % Compute training design matrix and stimulus vector
    [Xtrain, Ctrain, oiCtrain] = decoder.computeDesignMatrixAndStimulusVector(trainingResponses, trainingStimulus, trainingStimulusOI, expParams.decoderParams);
    s = whos('Xtrain');
    fprintf('<strong>Size(Xtrain): %d x %d (%2.2f GBytes)</strong>\n', s.size(1), s.size(2), s.bytes/1024/1024/1024);
    
    % Save cone types and spatiotemporal support
    spatioTemporalSupport = struct(...
       'sensorRetinalXaxis',  sensorRetinalXaxis, ...
       'sensorRetinalYaxis',  sensorRetinalYaxis, ...
       'sensorFOVxaxis', sensorFOVxaxis, ...                  % spatial support of decoded scene
       'sensorFOVyaxis', sensorFOVyaxis, ...
       'timeAxis',       expParams.decoderParams.latencyInMillseconds + (0:1:round(expParams.decoderParams.memoryInMilliseconds/expParams.decoderParams.temporalSamplingInMilliseconds)-1) * ...
                         expParams.decoderParams.temporalSamplingInMilliseconds);
                       
    % Save design matrices and stimulus vectors
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    p = getpref('HyperSpectralImageIsetbioComputations', 'sceneReconstructionProject');
    fprintf('Saving training design matrix and stim vector ''%s''... ', strrep(fileName, sprintf('%s/',p.computedDataDir),''));
    save(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', ...
        'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
        'trainingScanInsertionTimes', 'trainingSceneLMSbackground', ...
        'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams', 'preProcessingParams', 'rawTrainingResponsePreprocessing', 'coneTypes', 'spatioTemporalSupport', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtrain'; clear 'Ctrain'; clear 'oiCtrain'
    
    % Reshape testing cone responses to decoder format
    testingResponses = reshape(testingPhotoCurrentSequence, ...
        [size(testingPhotoCurrentSequence,1)*size(testingPhotoCurrentSequence,2) size(testingPhotoCurrentSequence,3)]);
    
    % Reshape testing stimulus to decoder format
    [testingStimulus, originalTestingStimulusSize] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', testingSceneLMScontrastSequence);
    
    [testingStimulusOI, ~] = ...
        decoder.reformatStimulusSequence('ToDesignMatrixFormat', testingOpticalImageLMScontrastSequence);
    
    % Preprocess raw signals
    if (preProcessingParams.useIdenticalPreprocessingOperationsForTrainingAndTestData)
        rawTestResponsePreprocessing = rawTrainingResponsePreprocessing;
    else
        rawTestResponsePreprocessing = [];
    end
    [testingResponses, rawTestResponsePreprocessing] = decoder.preProcessRawResponses(testingResponses, preProcessingParams, rawTestResponsePreprocessing);
    
    % Compute testing design matrix and stimulus vector
    [Xtest, Ctest, oiCtest] = decoder.computeDesignMatrixAndStimulusVector(testingResponses, testingStimulus, testingStimulusOI, expParams.decoderParams);
    s = whos('Xtest');
    fprintf('<strong>Size(Xtest): %d x %d (%2.2f GBytes)</strong>\n', s.size(1), s.size(2), s.bytes/1024/1024/1024);
    
    % Save design matrices and stimulus vectors
    fileName = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    fprintf('Saving test design matrix and stim vector to ''%s''... ', strrep(fileName, sprintf('%s/',p.computedDataDir),''));
    save(fileName, 'Xtest', 'Ctest', 'oiCtest', 'testingTimeAxis', ...
        'testingSceneIndexSequence', 'testingSensorPositionSequence', ...
        'testingScanInsertionTimes',  'testingSceneLMSbackground', ...
        'testingOpticalImageLMSbackground', 'originalTestingStimulusSize', ...
        'expParams', 'preProcessingParams', 'rawTestResponsePreprocessing', 'coneTypes', 'spatioTemporalSupport', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtest'; clear 'Ctest'; clear 'oiCtest';
    
    % Pre-process design matrices
    if (preProcessingParams.designMatrixBased > 0)
        decoder.preProcessDesignMatrices(sceneSetName, decodingDataDir);
    end
end
