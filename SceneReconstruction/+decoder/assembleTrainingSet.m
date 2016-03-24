function assembleTrainingSet(sceneSetName, descriptionString, trainingDataPercentange)

    sceneSet = core.sceneSetWithName(sceneSetName);
    scansDataDir = core.getScansDataDir(descriptionString);
    
    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    
    trainingTimeAxis = [];
    
    for sceneIndex = 1:numel(sceneSet) 
        
        imsource  = sceneSet{sceneIndex};
        sceneName = sprintf('%s_%s', imsource{1}, imsource{2});
        fprintf('Loading scan data for ''%s''. Please wait ... ', sceneName);
        fileName = fullfile(scansDataDir, sprintf('%s_scan_data.mat', sceneName));
        load(fileName, 'scanData', 'scene', 'oi', 'expParams');
        
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
                trainingSceneIndexSequence              = single(sceneIndex);
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
                    trainingSceneIndexSequence, single(sceneIndex));
                
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
        

        debugForTransients = false;
        if (debugForTransients)
            figure(33); colormap(gray(1024));
            CLims = [0 max(trainingSceneLMScontrastSequence(:))/2];
            for k = 1:2:size(trainingSceneLMScontrastSequence,4)
                for cone = 1:3
                subplot(1,4,cone);
                imagesc(squeeze(trainingSceneLMScontrastSequence(:,:,cone, k))); axis 'xy'; axis 'image';
                set(gca, 'XTick', [], 'YTick', [], 'CLim', CLims);
                end
                subplot(1,4,4);
                imagesc(squeeze(trainingPhotoCurrentSequence(:,:,k))); axis 'xy'; axis 'image';
                set(gca, 'XTick', [], 'YTick', [], 'CLim', [-100 -10]);
                drawnow
            end
        end
        
        % concatenate testing datasets
        for scanIndex = trainingScans+1:scansNum 
            totalTestingScansNum = totalTestingScansNum + 1;
            if (totalTestingScansNum == 1)
                dt = scanData{scanIndex}.timeAxis(2)-scanData{scanIndex}.timeAxis(1);
                testingTimeAxis = single(scanData{scanIndex}.timeAxis);
                testingScanInsertionTimes              = trainingTimeAxis(1);
                testingSceneIndexSequence              = single(sceneIndex);
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
                    testingSceneIndexSequence, single(sceneIndex));
                
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
    
    disp('training')
    size(trainingScanInsertionTimes)
    size(trainingSceneLMSbackground)
    size(trainingOpticalImageLMSbackground)
    
    
    disp('testing')
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
       displaySequences(trainingTimeAxis, trainingPhotoCurrentSequence, trainingSceneLMScontrastSequence,trainingOpticalImageLMScontrastSequence); 
    end
    
    % Decide which cones to keep
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = ...
        decoder.cherryPickConesToIncludeInDecoding(scanData{scanIndex}.scanSensor, expParams.decoderParams.thresholdConeSeparationForInclusionInDecoder);
    
    % Reshape training cone responses to decoder format
    trainingResponses = reshape(trainingPhotoCurrentSequence, ...
        [size(trainingPhotoCurrentSequence,1)*size(trainingPhotoCurrentSequence,2) size(trainingPhotoCurrentSequence,3)]);
    
    % Reshape training stimulus to decoder format
    [trainingStimulus, originalTrainingStimulusSize] = ...
        decoder.stimulusSequenceToDecoderFormat(trainingSceneLMScontrastSequence, 'toDecoderFormat', []);
    
    % Compute training design matrix and stimulus vector
    [Xtrain, Ctrain] = decoder.computeDesignMatrixAndStimulusVector(trainingResponses, trainingStimulus, expParams.decoderParams);
    
    whos 'Xtrain'
    whos 'Ctrain'
    
    
    
    % Save design matrices and stimulus vectors
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    fprintf('\nSaving training design matrix and stim vector ''%s''... ', fileName);
    save(fileName, 'Xtrain', 'Ctrain', 'trainingTimeAxis', 'trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'originalTrainingStimulusSize', 'expParams', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtrain'; clear 'Ctrain'
    
    % Reshape testing cone responses to decoder format
    testingResponses = reshape(testingPhotoCurrentSequence, ...
        [size(testingPhotoCurrentSequence,1)*size(testingPhotoCurrentSequence,2) size(testingPhotoCurrentSequence,3)]);
    
    % Reshape testing stimulus to decoder format
    [testingStimulus, originalTestingStimulusSize] = ...
        decoder.stimulusSequenceToDecoderFormat(testingSceneLMScontrastSequence, 'toDecoderFormat', []);
    
    % Compute testing design matrix and stimulus vector
    [Xtest, Ctest] = decoder.computeDesignMatrixAndStimulusVector(testingResponses, testingStimulus, expParams.decoderParams);
    whos 'Xtest'
    whos 'Ctest'
    
    % Save design matrices and stimulus vectors
    decodingDataDir = core.getDecodingDataDir(descriptionString);
    fileName = fullfile(decodingDataDir, sprintf('%s_testingDesignMatrices.mat', sceneSetName));
    fprintf('\nSaving test design matrix and stim vector to ''%s''... ', fileName);
    save(fileName, 'Xtest', 'Ctest', 'testingTimeAxis', 'testingScanInsertionTimes', 'testingSceneLMSbackground', 'originalTestingStimulusSize', 'expParams', '-v7.3');
    fprintf('Done.\n');
    clear 'Xtest'; clear 'Ctest'
    
    return;
    
    % visualize the cone mosaic
    scanIndex = 1; figNo = 1;
    visualizer.renderConeMosaic(figNo, scanData{scanIndex}.scanSensor, expParams);
        
end



function displaySequences(timeAxis, photoCurrentSequence, sceneLMScontrastSequence, opticalImageLMScontrastSequence)
    figure(1); clf;
    colormap(gray(1024));
    
    for k = 101:size(photoCurrentSequence,3)
        subplot(2,4,1);
        imagesc(squeeze(sceneLMScontrastSequence(:,:,1,k)));
        title('L cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,2);
        imagesc(squeeze(sceneLMScontrastSequence(:,:,2,k)));
        title('M cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,3);
        imagesc(squeeze(sceneLMScontrastSequence(:,:,3,k)));
        title('S cone contrast');
        set(gca, 'CLim', [-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,5);
        imagesc(squeeze(opticalImageLMScontrastSequence(:,:,1,k)));
        title('L cone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,6);
        imagesc(squeeze(opticalImageLMScontrastSequence(:,:,2,k)));
        title('M cone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        subplot(2,4,7);
        imagesc(squeeze(opticalImageLMScontrastSequence(:,:,3,k)));
        title('scone contrast (optical image)');
        set(gca, 'CLim', 0.5*[-1 1]);
        axis 'xy'; axis 'image'

        photoCurrentRange = [-80 -20];
        subplot(2,4,4);
        imagesc(squeeze(photoCurrentSequence(:,:,k)));
        title(sprintf('photocurrent (time: %2.4f sec)', timeAxis(k)/1000));
        set(gca, 'CLim', photoCurrentRange);
        axis 'xy'; axis 'image'

        subplot(2,4,8);
        timeBins = k+(-100:100);
        el = 0;
        for ir = 10+(-1:1)
            for ic = 10+(-1:1)
                el = el + 1;
                plot(timeAxis(timeBins), squeeze(photoCurrentSequence(ir,ic,timeBins)), 'k-');
                if (el == 1)
                    hold on
                    plot(timeAxis(k)*[1 1], [-100 100], 'r-');
                end
            end
        end
        hold off;
        title(sprintf('photocurrent traces (time: %2.4f-%2.4f sec)', trainingTimeAxis(timeBins(1))/1000,trainingTimeAxis(timeBins(end))/1000));
        set(gca, 'YLim', photoCurrentRange, 'XLim', [trainingTimeAxis(timeBins(1)) trainingTimeAxis(timeBins(end))]);
        axis 'square'

        drawnow
     end
end
