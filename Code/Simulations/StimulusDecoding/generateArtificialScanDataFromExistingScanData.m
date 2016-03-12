function generateArtificialScanDataFromExistingScanData()

    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    osType = 'biophysics-based';
    adaptingFieldType = 'NoAdaptationField';
    originalConfiguration = 'manchester';
    
    scansDir = getScansDir(rootPath, originalConfiguration, adaptingFieldType, osType);
    
    
    scanIndex = 1;
    imsource = {'manchester_database', 'scene1'};
    
    fileName = fullfile(scansDir, sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex));
    load(fileName, 'scansNum', 'scanSensor', 'photoCurrents', 'scanPlusAdaptationFieldLMSexcitationSequence', ...
                'LMSexcitationXdataInRetinalMicrons', 'LMSexcitationYdataInRetinalMicrons', ...
                'sensorParams', 'sensorAdaptationFieldParams', ...
                'startingSaccade', 'endingSaccade', 'forcedSceneMeanLuminance');

            
    newScanSensor = scanSensor;
    scansNum = 1;
    
    % reset sensor positions and isomerization rate
    newScanSensor = sensorSet(newScanSensor, 'photon rate', zeros(size(isomerizationRate,1), size(isomerizationRate,2), 1));
    newScanSensor = sensorSet(newScanSensor, 'positions', zeros(1,2));
    
    
    size(photoCurrents)
    figure(1)
    
    totalTime = sensorGet(scanSensor, 'total time')
    timeStep = sensorGet(scanSensor, 'time interval')
    timeBinsNum = round(totalTime/timeStep)
    timeAxis = (0:timeBinsNum-1)*timeStep;
    
    isomerizationRate = sensorGet(scanSensor, 'photon rate');
    subplot(2,1,1);
    plot(timeAxis, squeeze(photoCurrents(10,10,:)), 'k-');
    subplot(2,1,2);
    plot(timeAxis, squeeze(isomerizationRate(10,10,:)), 'k-');
    set(gca, 'YTick', [1:10]*1e4);
    
    
    
end

