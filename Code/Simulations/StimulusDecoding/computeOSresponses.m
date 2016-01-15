function computeOSresponses()

    ieInit; close all;
    
    % Spacify images
    imageSources = {...
        {'manchester_database', 'scene1'} ...
        {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
        {'manchester_database', 'scene4'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    testAllImages(imageSources);
    
%     for imageIndex = 1:numel(imageSources)
%         testOneImage(imageSources{imageIndex});
%     end
end

function testAllImages(imageSources)

    % Initialize our book-keeping
    for imageIndex = 1:numel(imageSources)
        imSource = imageSources{imageIndex};
        fileName = sprintf('%s_%s_opticalImage.mat', imSource{1}, imSource{2});
        load(fileName,'scansNum');
        scansVisited{imageIndex} = zeros(1, scansNum);
    end
    
    
    isomerizationRate = [];
    sensorPositions = [];
    
    % concatenate isomerizationRates across all scans and all images
    moreScansLeft = true;
    while (moreScansLeft == 1)
        for imageIndex = 1:numel(imageSources)
            moreScansForImage(imageIndex) = false;
            v = scansVisited{imageIndex};
            nonVisitedScanIndices = find(v==0);
            if (~isempty(nonVisitedScanIndices))
                
                % found an unvisited scan
                scanIndexToUse = nonVisitedScanIndices(1);
                
                % update our book-keeping
                v(scanIndexToUse) = 1;
                scansVisited{imageIndex} = v;
                moreScansForImage(imageIndex) = true;
                
                % [imageIndex scanIndexToUse]
                % load the sensor for this imageIndex and this scanIndex
                imSource = imageSources{imageIndex};
                scanSensor = [];
                fileName = sprintf('%s_%s_scan%d.mat', imSource{1}, imSource{2}, scanIndexToUse);
                load(fileName, 'scanSensor');
                
                % concatenate new with previous isomerization rates
                if (isempty(isomerizationRate))
                    isomerizationRate = sensorGet(scanSensor, 'photon rate');
                    %sensorPositions = sensorGet(scanSensor, 'positions');
                else
                    isomerizationRate = cat(3, isomerizationRate, sensorGet(scanSensor, 'photon rate'));
                    %sensorPositions = cat(1, sensorPositions, sensorGet(scanSensor, 'positions'));
                end
            end
        end
        moreScansLeft = any(moreScansForImage);
    end  % moreScansLeft
    
    fprintf('Setting isomerization rates in the full sensor. \n');
    % make full sensor and load it with the concatenated isomerization
    % rates % across all scenes and scans 
    fullSensor = scanSensor;
    fullSensor = sensorSet(fullSensor, 'photon rate', isomerizationRate);
    fullSensor = sensorSet(fullSensor, 'positions',   sensorPositions);
            
    % run the biophysical model
    osB = osBioPhys();
    osB.osSet('noiseFlag', 1);
    
    fprintf('Computing currents\n');
    osB.osCompute(fullSensor);
    current = osB.osGet('ConeCurrentSignal');
    time = (0:size(current,3)-1)*sensorGet(fullSensor, 'time interval');
    
    fprintf('Plotting\n');
    h = figure(1); clf;
    set(h, 'Position', [10 10 1670 600]);
    subplot(2,1,1);
    plot(time, squeeze(isomerizationRate(1,1,:)), 'k-');
    ylabel('isomerization rate (R*/sec)');
    subplot(2,1,2);
    plot(time, squeeze(current(1,1,:)), 'k-');
    set(gca, 'YLim', [-100 0]);
    xlabel('time (seconds)');
    ylabel('amplitude (pAmps)');    
end


function testOneImage(imSource)
    % load the optical image
    fileName = sprintf('%s_%s_opticalImage.mat', imSource{1}, imSource{2});
    load(fileName, 'oi', 'scansNum');
    
    % concatenate isomerizationRates across all scans and all images
    isomerizationRate = [];
    sensorPositions = [];
    
    for scanIndex = 1:scansNum
        % load each scan set
        scanSensor = [];
        fileName = sprintf('%s_%s_scan%d.mat', imSource{1}, imSource{2}, scanIndex);
        load(fileName, 'scanSensor', 'startingSaccade', 'endingSaccade');
        
        if (isempty(isomerizationRate))
           isomerizationRate = sensorGet(scanSensor, 'photon rate');
           %sensorPositions = sensorGet(scanSensor, 'positions');
        else
           isomerizationRate = cat(3, isomerizationRate, sensorGet(scanSensor, 'photon rate'));
           %sensorPositions = cat(1, sensorPositions, sensorGet(scanSensor, 'positions'));
        end
    end
    
    fullSensor = scanSensor;
    fullSensor = sensorSet(fullSensor, 'photon rate', isomerizationRate);
    fullSensor = sensorSet(fullSensor, 'positions',   sensorPositions);
            
    % run biophysical model - after concatenating isomerization rates
    % across all scenes and scans 
    osB = osBioPhys();
    osB.osSet('noiseFlag', 1);
    osB.osCompute(fullSensor);
    current = osB.osGet('ConeCurrentSignal');
    time = (0:size(current,3)-1)*sensorGet(fullSensor, 'time interval');
    
    h = figure(1); clf;
    set(h, 'Position', [10 10 1670 600]);
    subplot(2,1,1);
    plot(time, squeeze(isomerizationRate(1,1,:)), 'k-');
    ylabel('isomerization rate (R*/sec)');
    subplot(2,1,2);
    plot(time, squeeze(current(1,1,:)), 'k-');
    set(gca, 'YLim', [-100 0]);
    xlabel('time (seconds)');
    ylabel('amplitude (pAmps)');
        % osWindow(figNum, 'biophys-based outer segment', osB, sensor, oi);
end

