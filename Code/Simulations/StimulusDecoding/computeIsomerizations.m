% Method to generate custom sensor and compute isomerizations rates
% for a bunch of images, each scanned by eye movements 
function computeIsomerizations

    % reset
    %ieInit; close all;
    
    addNeddedToolboxesToPath();
    
    % Set up remote data toolbox client
    client = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig'));
    
    % Spacify images
    imageSources = {...
        {'manchester_database', 'scene1'} ...
        {'manchester_database', 'scene2'} ...
        {'manchester_database', 'scene3'} ...
        {'manchester_database', 'scene4'} ...
    %    {'stanford_database', 'StanfordMemorial'} ...
        };
    
    % Get directory location where optical images are to be saved
    getpref('HyperSpectralImageIsetbioComputations','opticalImagesCacheDir');
    
    % simulation time step. same for eye movements and for sensor, outersegment
    timeStepInMilliseconds = 0.1;
    fixationOverlapFactor = 0.2;            % overlapFactor of 1, results in sensor positions that just abut each other, 2 more dense 0.5 less dense
    saccadesPerScan = 10;                   % parse the eye movement data into scans, each scan having this many saccades
    saccadicScanMode = 'sequential';        % 'randomized' or 'sequential', to visit eye position grid sequentially
    debug = true;                           % set to true, to see the eye scanning and the responses
    
    coneCols = 15;
    coneRows = 20;
    
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        % custom cone aperture
        'LMSdensities', [0.6 0.4 0.1], ...       % custom percentages of L,M and S cones
        'spatialGrid', [coneRows coneCols], ...  % generate a coneCols x coneRows cone mosaic
        'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...  % time step of simulation (0.1 millisecond or smaller)
        'integrationTimeInMilliseconds', 50, ...
        'randomSeed', 1552784, ...
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', timeStepInMilliseconds, ...
            'fixationDurationInMilliseconds', 300, ...
            'fixationOverlapFactor', fixationOverlapFactor, ...     
            'saccadicScanMode',  saccadicScanMode ...
        ) ...
    );
    
    
    for imageIndex = 1:numel(imageSources)
        % retrieve scene
        fprintf('Fetching data. Please wait ...\n');
        imsource = imageSources{imageIndex};
        client.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
        [artifactData, artifactInfo] = client.readArtifact(imsource{2}, 'type', 'mat');
        if ismember('scene', fieldnames(artifactData))
            fprintf('Fetched scene contains uncompressed scene data.\n');
            scene = artifactData.scene;
        else
            fprintf('Fetched scene contains compressed scene data.\n');
            %scene = sceneFromBasis(artifactData);
            scene = uncompressScene(artifactData);
        end
        fprintf('Done fetching data.\n');
        
        % Set mean luminance of all scenes to 400 cd/m2
        scene = sceneAdjustLuminance(scene, 200);
        
        % Obtain the Stockman fundamentals for the wavelength sampling using in current scene
        wavelengthSampling    = sceneGet(scene,'wave');
        StockmanFundamentals = ieReadSpectra('stockman', wavelengthSampling);
    
        % insert an adapting field in the lower-left corner of the scene
        adaptingFieldSize = [161 161];                    % adapting field size: 51 microns, 51 microns wide
        adaptingFieldIlluminant = 'from scene';         % either 'from scene', or the name of a known illuminant, such as 'D65'
        adaptingFieldLuminance = 100;                   % desired luminance in cd/m2   - sceneGet(scene, 'mean luminance')
        scene = insertAdaptingField(scene, adaptingFieldSize, adaptingFieldLuminance, adaptingFieldIlluminant);

        % Show scene
        vcAddAndSelectObject(scene); sceneWindow;
       
        % Compute optical image with human optics
        oi = oiCreate('human');
        oi = oiCompute(oi, scene);
        
        % Retrieve retinal microns&degrees per pixel
        retinalMicronsPerPixel = oiGet(oi, 'wres','microns');
        retinalDegreesPerPixel = oiGet(oi, 'angularresolution');
        retinalMicronsPerDegreeX = retinalMicronsPerPixel / retinalDegreesPerPixel(1);
        retinalMicronsPerDegreeY = retinalMicronsPerPixel / retinalDegreesPerPixel(2);
    
        % Show optical image
        vcAddAndSelectObject(oi); oiWindow;
        
        % create custom human sensor
        sensor = sensorCreate('human');
        sensor = customizeSensor(sensor, sensorParams, oi);
        
        % compute isomerization rage for all positions
        sensor = coneAbsorptions(sensor, oi);
        
        % extract the full isomerization rate sequence across all positions
        isomerizationRate = sensorGet(sensor, 'photon rate');
        sensorPositions   = sensorGet(sensor,'positions');
        
        % extract the LMS cone stimulus sequence encoded by sensor at all visited positions
        LMSstimulusSequence = computeLMSstimulusSequence(sensor, scene, [retinalMicronsPerDegreeX retinalMicronsPerDegreeY], wavelengthSampling, StockmanFundamentals);
        if (~debug)
            % we do not need the scene any more so clear it
            clear 'scene'
        end
        
        % parse the data into scans, each scan having saccadesPerScansaccades
        positionsPerFixation = round(sensorParams.eyeMovementScanningParams.fixationDurationInMilliseconds / sensorParams.eyeMovementScanningParams.samplingIntervalInMilliseconds); 
        fixationsNum = size(sensorGet(sensor,'positions'),1) / positionsPerFixation;
        scansNum = floor(fixationsNum/saccadesPerScan);
        fprintf('Data sets generated for this image: %d\n', scansNum);
        
        % reset sensor positions and isomerization rate
        sensor = sensorSet(sensor, 'photon rate', []);
        sensor = sensorSet(sensor, 'positions', []);
        
        for scanIndex = 1:scansNum    
            % define a new sequence of saccades
            startingSaccade = 1+(scanIndex-1)*10;
            endingSaccade = startingSaccade + 9;
            positionIndices = 1 + ((startingSaccade-1)*positionsPerFixation : endingSaccade*positionsPerFixation-1);
            fprintf('Analyzed positions: %d-%4d\n', positionIndices(1), positionIndices(end));
            
            % generate new sensor with given sub-sequence
            scanSensor = sensor;
            scanSensor = sensorSet(scanSensor, 'photon rate', isomerizationRate(:,:,positionIndices));
            scanSensor = sensorSet(scanSensor, 'positions',   sensorPositions(positionIndices,:));
            
            % save the scanSensor
            fileName = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            save(fileName, 'scanSensor', 'startingSaccade', 'endingSaccade');
            
            if (debug)
                osB = osBioPhys();
                osB.osSet('noiseFlag', 1);
                osB.osCompute(scanSensor);
                figNum = 200+scanIndex;
                osWindow(figNum, 'biophys-based outer segment', osB, scanSensor, oi, scene);
                pause
            end
        end
        
        % save the optical image and the number of data sets
        fileName = sprintf('%s_%s_opticalImage.mat', imsource{1}, imsource{2});
        save(fileName, 'oi', 'scansNum');
    end % imageIndex
end


function StockmanLMSexcitationSequence = computeLMSstimulusSequence(sensor, scene, retinalMicronsPerDegree,  wavelengthSampling, StockmanFundamentals)
    StockmanLMSexcitationSequence = [];
    
    % compute sensor positions (due to eye movements) in microns
    sensorSampleSeparationInMicrons = sensorGet(sensor,'pixel size','um');
    pos = sensorGet(sensor,'positions');
    isomerizationRate = sensorGet(sensor, 'photon rate');
    
    sensorPositionsInRetinalMicrons = pos * 0;
    sensorPositionsInRetinalMicrons(:,1) = -pos(:,1)*sensorSampleSeparationInMicrons(1);
    sensorPositionsInRetinalMicrons(:,2) =  pos(:,2)*sensorSampleSeparationInMicrons(2);

    % compute sensor cone sampling grid
    sensorRowsCols = sensorGet(sensor, 'size');
    dx = sensorRowsCols(2) * sensorSampleSeparationInMicrons(2);
    dy = sensorRowsCols(1) * sensorSampleSeparationInMicrons(1);
    sensorSizeInMicrons = [dx dy];
    [R,C] = meshgrid(1:sensorRowsCols(1), 1:sensorRowsCols(2)); R = R'; C = C';
    sensorXsamplingGridInMicrons = (C(:)-0.5) * sensorSampleSeparationInMicrons(1);
    sensorYsamplingGridInMicrons = (R(:)-0.5) * sensorSampleSeparationInMicrons(2);
    
    % get cone types
    coneTypes = sensorGet(sensor, 'cone type')-1;
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    
    % Create the scene XY grid in retinal microns, instead of scene microns, because the sensor is specified in retinal microns
    sceneSpatialSupportInMicrons = sceneGet(scene,'spatial support','microns');
    degreesPerSample = sceneGet(scene,'deg per samp');
    micronsPerSample = sceneGet(scene,'distPerSamp','microns');
    sceneSpatialSupportInDegrees(:,:,1) = sceneSpatialSupportInMicrons(:,:,1) / micronsPerSample(1) * degreesPerSample;
    sceneSpatialSupportInDegrees(:,:,2) = sceneSpatialSupportInMicrons(:,:,2) / micronsPerSample(2) * degreesPerSample;

    % Spatial support in retinal microns
    sceneSpatialSupportInRetinalMicrons(:,:,1) = sceneSpatialSupportInDegrees(:,:,1) * retinalMicronsPerDegree(1);
    sceneSpatialSupportInRetinalMicrons(:,:,2) = sceneSpatialSupportInDegrees(:,:,2) * retinalMicronsPerDegree(2);
    sceneXgridInRetinalMicrons = squeeze(sceneSpatialSupportInRetinalMicrons(:,:,1)); 
    sceneYgridInRetinalMicrons = squeeze(sceneSpatialSupportInRetinalMicrons(:,:,2));
    sceneXdataInRetinalMicrons = squeeze(sceneXgridInRetinalMicrons(1,:));  % x-positions from 1st row in retinal microns
    sceneYdataInRetinalMicrons = squeeze(sceneYgridInRetinalMicrons(:,1));  % y-positions from 1st col in retinal microns
            
    % Obtain the scene Stockman LMS excitation maps with a spatial
    % resolution = 0.5 microns
    sceneResamplingResolutionInRetinalMicrons = 0.5
    [sceneStockmanLMSexitations, sceneXgridInRetinalMicrons, sceneYgridInRetinalMicrons] = resampleScene(sceneGet(scene, 'lms'), sceneXdataInRetinalMicrons, sceneYdataInRetinalMicrons, sceneResamplingResolutionInRetinalMicrons);
    
    % Obtain an RGB rendition of the scene with a spatial resolution three times that of the original
    [sceneRGB, sceneXgridInRetinalMicrons, sceneYgridInRetinalMicrons] = resampleScene(sceneGet(scene, 'rgb image'), sceneXdataInRetinalMicrons, sceneYdataInRetinalMicrons, sceneResamplingResolutionInRetinalMicrons);
        
    sceneXdataInRetinalMicrons = squeeze(sceneXgridInRetinalMicrons(1,:));  % x-positions from 1st row in retinal microns
    sceneYdataInRetinalMicrons = squeeze(sceneYgridInRetinalMicrons(:,1));  % y-positions from 1st col in retinal microns
    
    % Compute photon isomerization and scene LMS excitation ranges
    ClimRange   = [min(sceneStockmanLMSexitations(:)) max(sceneStockmanLMSexitations(:))];
    photonRange = [min(isomerizationRate(:)) max(isomerizationRate(:))];

    coneApertureInMicrons = pixelGet(sensorGet(sensor, 'pixel'), 'size')/1e-6;
    th = [0:10:360]/360*2*pi;
    coneApertureXcoords = cos(th)*coneApertureInMicrons(1)/2;
    coneApertureYcoords = sin(th)*coneApertureInMicrons(2)/2;
        
    hFig = figure(11);
    clf;
    set(hFig, 'Position', [10 10 780 1300]);
    plotHandles = [];
    colormap(gray);

    for posIndex = 1:3000:size(sensorPositionsInRetinalMicrons,1)
        
        currentSensorIsomerizationRate = squeeze(isomerizationRate(:,:,posIndex));
        
        % Get current sensor position
        currentSensorPositionInRetinalMicrons = sensorPositionsInRetinalMicrons(posIndex,:);
        
        
        % We need to determine the scene portion that lies under the sensor's current position
        % So find scene pixels falling within the sensor outline
        % However, there is some jitter noise here because the sampling resolution of the optical image 
        % is not much finer than the cone photoreceptor spacing 
        
        sceneSpatialSamplingInRetinalMicrons = sceneXdataInRetinalMicrons(2)-sceneXdataInRetinalMicrons(1);
        pixelIndices = find(...
            (sceneXgridInRetinalMicrons >= currentSensorPositionInRetinalMicrons(1) - round(sensorSizeInMicrons(1)*0.6)) & ...
            (sceneXgridInRetinalMicrons <= currentSensorPositionInRetinalMicrons(1) + round(sensorSizeInMicrons(1)*0.6)) & ...
            (sceneYgridInRetinalMicrons >= currentSensorPositionInRetinalMicrons(2) - round(sensorSizeInMicrons(2)*0.6)) & ...
            (sceneYgridInRetinalMicrons <= currentSensorPositionInRetinalMicrons(2) + round(sensorSizeInMicrons(2)*0.6)) );
        [rows, cols] = ind2sub(size(sceneXgridInRetinalMicrons), pixelIndices);
            

        if isempty(StockmanLMSexcitationSequence)
            rowRange = min(rows):1:max(rows);
            colRange = min(cols):1:max(cols);
        else
            rowRange = min(rows) + (0:size(StockmanLMSexcitationSequence,2)-1);
            colRange = min(cols) + (0:size(StockmanLMSexcitationSequence,3)-1);
        end
        
        sensorViewStockmanLMSexcitations = sceneStockmanLMSexitations(rowRange,colRange,:);
        StockmanLMSexcitationSequence(posIndex,:,:,:) = sensorViewStockmanLMSexcitations;
        
        xGridSubsetInRetinalMicrons = sceneXgridInRetinalMicrons(rowRange, colRange);
        yGridSubsetInRetinalMicrons = sceneYgridInRetinalMicrons(rowRange, colRange);
        sensorViewXdata = squeeze(xGridSubsetInRetinalMicrons(1,:));
        sensorViewYdata = squeeze(yGridSubsetInRetinalMicrons(:,1));

        % Do the plotting
        % Set the figure name
        set(hFig, 'Name', sprintf('pos: %d / %d', posIndex,size(sensorPositionsInRetinalMicrons,1)));
       
        % compute the cone positions on the retinal image based on the current sensor position
        coneXpos = currentSensorPositionInRetinalMicrons(1) - sensorSizeInMicrons(1)/2 +  sensorXsamplingGridInMicrons;
        coneYpos = currentSensorPositionInRetinalMicrons(2) - sensorSizeInMicrons(2)/2 +  sensorYsamplingGridInMicrons;
        
        % Plot fundamentals used to encode the scene
        subplot(4,2,1);
        if (posIndex == 1)
            plot(wavelengthSampling, StockmanFundamentals(:,1), 'rs-', 'MarkerFaceColor', [1 0.8 0.8]);
            hold on;
            plot(wavelengthSampling, StockmanFundamentals(:,2), 'gs-', 'MarkerFaceColor', [0.8 1.0 0.8]);
            plot(wavelengthSampling, StockmanFundamentals(:,3), 'bs-', 'MarkerFaceColor', [0.8 0.8 1.0]);
            hold off;
            
            xlabel('scene wavelength (nm)');
            ylabel('sensitivity');
            legend('L cone', 'M cone', 'S cone');
            title(sprintf('Stockman cone fundamentals'));
            axis 'square'
        end
            
        % Plot RGB rendition of the sensor's view of the scene
        plotHandleIndex = 1;
        subplot(4,2,2);
        plotHandleIndex = plotHandleIndex + 1;
        if (posIndex == 1)
            plotHandles(plotHandleIndex) = image(sensorViewXdata, sensorViewYdata, sceneRGB(rowRange, colRange,:));
            colorbar();
            hold on;
        else
            set(plotHandles(plotHandleIndex), 'XData', sensorViewXdata, 'YData', sensorViewYdata, 'CData', sceneRGB(rowRange, colRange,:));
        end

        superimposeConeMosaic = false;
        if (superimposeConeMosaic)
            % superimpose the cone mosaic
            for coneRow = 1:sensorRowsCols(1)
                for coneCol = 1:sensorRowsCols(2)
                   coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
                   plotHandleIndex = plotHandleIndex + 1;
                   % plot circles denoting  cone outer segments
                   if (posIndex == 1)
                       plotHandles(plotHandleIndex) = plot(coneXpos(coneIndex)+coneApertureXcoords, coneYpos(coneIndex)+coneApertureYcoords, '-', 'Color', squeeze(coneColors(coneTypes(coneIndex),:)));
                   else
                       set(plotHandles(plotHandleIndex), 'XData', coneXpos(coneIndex)+coneApertureXcoords, 'YData', coneYpos(coneIndex)+coneApertureYcoords);
                   end
                end
            end
        end
        
        if (posIndex == 1)
            hold off;
            set(gca, 'CLim', [0 1]);
            axis 'image'
            if (superimposeConeMosaic)
                title('scene & encoding cone mosaic');
            else
                title('scene');
            end
        end
        
        for targetCone = 1:3
            % compute targetCone mosaic isomerization image
            [mosaicIsomerizationImageXdata, mosaicIsomerizationImageYdata, mosaicIsomerizationImage] = generateMosaicIsomerizationRateImage(currentSensorIsomerizationRate, sensorRowsCols, sensorSampleSeparationInMicrons, coneTypes, targetCone);
            
            % plot scene cone excitation maps
            subplot(4,2,targetCone*2+1);
            plotHandleIndex = plotHandleIndex + 1;
            if (posIndex == 1)
                plotHandles(plotHandleIndex) = imagesc(sensorViewXdata, sensorViewYdata, squeeze(sensorViewStockmanLMSexcitations(:,:,targetCone)));
                hold on;
            else
                set(plotHandles(plotHandleIndex), 'XData', sensorViewXdata, 'YData', sensorViewYdata, 'CData', squeeze(sensorViewStockmanLMSexcitations(:,:,targetCone)));
            end
       
            % superimpose circles denoting the cone outer segments
            for coneRow = 1:sensorRowsCols(1)
            for coneCol = 1:sensorRowsCols(2)
               coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
               plotHandleIndex = plotHandleIndex + 1;
               
               if (coneTypes(coneIndex) == targetCone)
                    if (posIndex == 1)
                        plotHandles(plotHandleIndex) = plot(coneXpos(coneIndex)+coneApertureXcoords, coneYpos(coneIndex)+coneApertureYcoords, '-', 'Color', squeeze(coneColors(targetCone,:)));
                    else
                        set(plotHandles(plotHandleIndex), 'XData', coneXpos(coneIndex)+coneApertureXcoords, 'YData', coneYpos(coneIndex)+coneApertureYcoords);
                    end
               end
            end % coneCol
            end % coneRow
            
            
            % title and c-limits
            if (posIndex == 1)
                % X,Y limits and ticks
                set(gca, 'XLim', mean(sensorViewXdata) + (max(sensorViewXdata)-min(sensorViewXdata))*[-0.5 0.5], ...
                         'YLim', mean(sensorViewYdata) + (max(sensorViewYdata)-min(sensorViewYdata))*[-0.5 0.5], ...
                         'XTick', (-2000:20:2000), 'YTick', (-2000:20:2000), 'XTickLabel', {}, 'YTickLabel', {});
                xlabel('retinal space (microns)');
                ylabel('retinal space (microns)');
                hold off;
                set(gca, 'CLim', ClimRange);
                h = colorbar();
                set(h,'YTick',(0:0.5:20), 'YTickLabel', sprintf('%2.1f\n', (0:0.5:20)));
                ylabel(h, sprintf('Stockman excitation'))
                axis 'image'
                if (targetCone == 1)
                    title(sprintf('Stockman L-cone excitation &\n L-cone mosaic'));
                elseif (targetCone == 2)
                    title(sprintf('Stockman M-cone excitation &\n M-cone mosaic'));
                else
                    title(sprintf('Stockman S-cone excitation &\n S-cone mosaic'));
                end
            end
        
            % compute sensor cone excitation maps
            subplot(4,2,targetCone*2+2);
            plotHandleIndex = plotHandleIndex + 1;
            if (posIndex == 1)
                plotHandles(plotHandleIndex) = imagesc(mosaicIsomerizationImageXdata, mosaicIsomerizationImageYdata, mosaicIsomerizationImage);
                if (targetCone < 3)
                    set(gca, 'CLim', photonRange);
                else
                    set(gca, 'CLim', [photonRange(1) 0.1*photonRange(2)]);
                end
                sensorViewWidth = max(sensorViewXdata)-min(sensorViewXdata);
                sensorViewHeight = max(sensorViewYdata)-min(sensorViewYdata);
                marginX = 0.5*(sensorViewWidth - (max(mosaicIsomerizationImageXdata)-min(mosaicIsomerizationImageXdata)));
                marginY = 0.5*(sensorViewHeight - (max(mosaicIsomerizationImageYdata)-min(mosaicIsomerizationImageYdata)));
                set(gca, 'XTick', 0:20:1000, 'YTick', 0:20:1000, 'XTickLabel', {}, 'YTickLabel', {}, ...
                    'XLim', [min(mosaicIsomerizationImageXdata)-marginX max(mosaicIsomerizationImageXdata)+marginX], ...
                    'YLim', [min(mosaicIsomerizationImageYdata)-marginY max(mosaicIsomerizationImageYdata)+marginY]);
                h = colorbar();
                ylabel(h, sprintf('R*/sec'))
                axis 'image'
                xlabel('retinal space (microns)');
                ylabel('retinal space (microns)');
                if (targetCone == 1)
                    title('L cone mosaic isomerization map');
                elseif (targetCone == 2)
                    title('M cone mosaic isomerization map');
                else
                    title('S cone mosaic isomerization map');
                end
            else
                set(plotHandles(plotHandleIndex), 'CData', mosaicIsomerizationImage);
            end
        end % targetCone
        
        drawnow;
        disp('Hit enter to proceed');
        pause
    end % posIndex
end

function [mosaicExcitationImageXdata, mosaicExcitationImageYdata, mosaicExcitationImage] = generateMosaicIsomerizationRateImage(sensorIsomerizationRate, sensorRowsCols, sensorSampleSeparationInMicrons, coneTypes, targetCone)

    upSampleFactor = 5;
    zeroPadRows = 0;
    zeroPadCols = 0;
    
    mosaicExcitationImage = zeros((sensorRowsCols(1)+2*zeroPadRows+1)*upSampleFactor, (sensorRowsCols(2)+2*zeroPadCols+1)*upSampleFactor);
    for coneRow = 1:sensorRowsCols(1)
        for coneCol = 1:sensorRowsCols(2)
           coneIndex = sub2ind(size(coneTypes), coneRow, coneCol);
           if (coneTypes(coneIndex) == targetCone)
                mosaicExcitationImage((coneRow+zeroPadRows)*upSampleFactor-0*round(upSampleFactor/2), (coneCol+zeroPadCols)*upSampleFactor-0*round(upSampleFactor/2)) = sensorIsomerizationRate(coneRow, coneCol);
           end
        end
    end
    
    x = -(upSampleFactor-1)/2:(upSampleFactor-1)/2;
    [X,Y] = meshgrid(x,x);
    sigma = upSampleFactor/2.5;
    gaussianKernel = exp(-0.5*(X/sigma).^2).*exp(-0.5*(Y/sigma).^2);
    gaussianKernel = gaussianKernel / max(gaussianKernel(:));
    
    mosaicExcitationImageXdata = (0:size(mosaicExcitationImage,2)-1)/(size(mosaicExcitationImage,2)-1);
    mosaicExcitationImageXdata = mosaicExcitationImageXdata * (sensorRowsCols(2)+zeroPadCols*2+1)*sensorSampleSeparationInMicrons(1);
    mosaicExcitationImageYdata = (0:size(mosaicExcitationImage,1)-1)/(size(mosaicExcitationImage,1)-1);
    mosaicExcitationImageYdata = mosaicExcitationImageYdata * (sensorRowsCols(1)+zeroPadRows*2+1)*sensorSampleSeparationInMicrons(2);
    mosaicExcitationImage = conv2(mosaicExcitationImage, gaussianKernel, 'same');  
end

function [resampledScene, resampledSceneXgrid,  resampledSceneYgrid] = resampleScene(sceneData, sceneXdata, sceneYdata, sceneResamplingInterval)
    
    resampledColsNum = (round((sceneXdata(end)-sceneXdata(1))/sceneResamplingInterval)/2)*2;
    resampledRowsNum = (round((sceneYdata(end)-sceneYdata(1))/sceneResamplingInterval)/2)*2;
    
    resampledSceneXdata = (-resampledColsNum/2:resampledColsNum/2)*sceneResamplingInterval;
    resampledSceneYdata = (-resampledRowsNum/2:resampledRowsNum/2)*sceneResamplingInterval;
    
    [X,Y] = meshgrid(sceneXdata, sceneYdata);
    [resampledSceneXgrid, resampledSceneYgrid] = meshgrid(resampledSceneXdata, resampledSceneYdata);
   
    % preallocate memory
    sceneChannels = size(sceneData,3);
    resampledScene = zeros(numel(resampledSceneYdata), numel(resampledSceneXdata), sceneChannels);
    
    for channelIndex = 1:sceneChannels
        tic
        singleChannelData = squeeze(sceneData(:,:,channelIndex));
        resampledScene(:,:, channelIndex) = interp2(X,Y, singleChannelData, resampledSceneXgrid, resampledSceneYgrid, 'linear');
        toc
    end
    
end

function sensor = customizeSensor(sensor, sensorParams, opticalImage)
    
    if (isempty(sensorParams.randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(sensorParams.randomSeed);
    end
    
    eyeMovementScanningParams = sensorParams.eyeMovementScanningParams;
    
    % custom aperture
    pixel  = sensorGet(sensor,'pixel');
    pixel  = pixelSet(pixel, 'size', [1.0 1.0]*sensorParams.coneApertureInMicrons*1e-6);  % specified in meters);
    sensor = sensorSet(sensor, 'pixel', pixel);
    
    % custom LMS densities
    coneMosaic = coneCreate();
    coneMosaic = coneSet(coneMosaic, ...
        'spatial density', [0.0 ...
                           sensorParams.LMSdensities(1) ...
                           sensorParams.LMSdensities(2) ...
                           sensorParams.LMSdensities(3)] );
    sensor = sensorCreateConeMosaic(sensor,coneMosaic);
        
    % sensor wavelength sampling must match that of opticalimage
    sensor = sensorSet(sensor, 'wavelength', oiGet(opticalImage, 'wavelength'));
     
    % no noise on sensor
    sensor = sensorSet(sensor,'noise flag', 0);
    
    % custom size
    sensor = sensorSet(sensor, 'size', sensorParams.spatialGrid);

    % custom time interval
    sensor = sensorSet(sensor, 'time interval', sensorParams.samplingIntervalInMilliseconds/1000.0);
    
    % custom integration time
    sensor = sensorSet(sensor, 'integration time', sensorParams.integrationTimeInMilliseconds/1000.0);
    
    % custom eye movement
    eyeMovement = emCreate();
    
    % custom sample time
    eyeMovement  = emSet(eyeMovement, 'sample time', eyeMovementScanningParams.samplingIntervalInMilliseconds/1000.0);        
    
    % attach eyeMovement to the sensor
    sensor = sensorSet(sensor,'eyemove', eyeMovement);
            
    % generate the fixation eye movement sequence
    xNodes = round(0.35*oiGet(opticalImage, 'width',  'microns')/sensorGet(sensor, 'width', 'microns')*eyeMovementScanningParams.fixationOverlapFactor);
    yNodes = round(0.35*oiGet(opticalImage, 'height', 'microns')/sensorGet(sensor, 'height', 'microns')*eyeMovementScanningParams.fixationOverlapFactor);
    fx = sensorParams.spatialGrid(1)/eyeMovementScanningParams.fixationOverlapFactor;
    saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, sensorParams.coneApertureInMicrons, sensorParams.eyeMovementScanningParams.saccadicScanMode);
    
    eyeMovementsNum = size(saccadicTargetPos,1) * round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds);
    eyeMovementPositions = zeros(eyeMovementsNum,2);
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
    sensor = emGenSequence(sensor);

    % add saccadic targets
    eyeMovementPositions = sensorGet(sensor,'positions');

    for eyeMovementIndex = 1:eyeMovementsNum
        kk = 1+floor((eyeMovementIndex-1)/round(eyeMovementScanningParams.fixationDurationInMilliseconds / eyeMovementScanningParams.samplingIntervalInMilliseconds));
        eyeMovementPositions(eyeMovementIndex,:) = eyeMovementPositions(eyeMovementIndex,:) + saccadicTargetPos(kk,:);
    end
    
    sensor = sensorSet(sensor,'positions', eyeMovementPositions);
end

function saccadicTargetPos = generateSaccadicTargets(xNodes, yNodes, fx, coneApertureInMicrons, saccadicScanMode)
    [gridXX,gridYY] = meshgrid(-xNodes:xNodes,-yNodes:yNodes); 
    gridXX = gridXX(:); gridYY = gridYY(:); 
    
    if (strcmp(saccadicScanMode, 'randomized'))
        indices = randperm(numel(gridXX));
    elseif (strcmp(saccadicScanMode, 'sequential'))
        indices = 1:numel(gridXX);
    else
        error('Unkonwn position scan mode: ''%s''', saccadicScanMode);
    end

    % these are in units of cone separations
    saccadicTargetPos(:,1) = round(gridXX(indices)*fx); 
    saccadicTargetPos(:,2) = round(gridYY(indices)*fx);

    % for calibration purposes only
    desiredXposInMicrons = 828.8;
    desiredYposInMicrons = 603.0;
    % transform to units of cone separations
    saccadicTargetPos(:,1) = -round(desiredXposInMicrons/coneApertureInMicrons);
    saccadicTargetPos(:,2) =  round(desiredYposInMicrons/coneApertureInMicrons);
end


function scene = insertAdaptingField(scene, adaptingFieldSize, adaptingFieldLuminance, adaptingFieldIlluminant)

    % Retrieve scene wavelength sampling 
    wavelengthSampling  = sceneGet(scene,'wave');
    
    % Get the reflectance of the white patch in the MacBeth chart
    fName = fullfile(isetRootPath,'data','surfaces','macbethChart.mat');
    macbethChart = ieReadSpectra(fName, wavelengthSampling);
    patchNo = 4; % the brightest white patch
    macbethReflectance = squeeze(macbethChart(:,patchNo));
        
    % choose an illuminant: either the scene's or D65
    if (strcmp(adaptingFieldIlluminant, 'from scene'))
        illuminantToUse = sceneGet(scene, 'illuminant');
    else
        illuminantToUse = illuminantCreate(adaptingFieldIlluminant,wavelengthSampling);
    end
    
    % illuminate patch
    adaptationPhotonRate = macbethReflectance .* reshape(illuminantGet(illuminantToUse, 'photons'), size(macbethReflectance));
        
    % adjust adaptation field luminance to target luminance
    luminance = ieLuminanceFromPhotons(adaptationPhotonRate, wavelengthSampling);
    adaptationPhotonRate = adaptationPhotonRate / luminance * adaptingFieldLuminance;
    luminance = ieLuminanceFromPhotons(adaptationPhotonRate, wavelengthSampling)
        
    % Hack. Set the scene photons in the lower right  right portion of the image
    % by writing directly to scene.data.photons, i.e., without going through isetbio.
    adaptationFieldRows = sceneGet(scene, 'rows')+(-adaptingFieldSize(1)+1:0);
    adaptationFieldCols = sceneGet(scene, 'cols')+(-adaptingFieldSize(2)+1:0);
    scene.data.photons(adaptationFieldRows, adaptationFieldCols,:) = ...
            repmat(reshape(adaptationPhotonRate, [1 1 numel(adaptationPhotonRate)]), [adaptingFieldSize(1) adaptingFieldSize(2) 1]);
        
    % Add calibration stimulus
    calibrationStimRowsRange = (-0:0);
    calibrationStimColsRange = (-2:2);
    targetRowIndices = sceneGet(scene, 'rows') - round(adaptingFieldSize(2)/2) + calibrationStimRowsRange;
    targetColIndices = sceneGet(scene, 'cols') - round(adaptingFieldSize(1)/2) + calibrationStimColsRange;
    scene.data.photons(targetRowIndices, targetColIndices,:) = ...
        repmat(reshape(adaptationPhotonRate*50, [1 1 numel(adaptationPhotonRate)]), [numel(calibrationStimRowsRange) numel(calibrationStimColsRange) 1]);
        
   
end


function scene = uncompressScene(artifactData)
    basis      = artifactData.basis;
    comment    = artifactData.comment;
    illuminant = artifactData.illuminant;
    mcCOEF     = artifactData.mcCOEF;
    save('tmp.mat', 'basis', 'comment', 'illuminant', 'mcCOEF');
    wList = 380:5:780;
    scene = sceneFromFile('tmp.mat', 'multispectral', [],[],wList);
    scene = sceneSet(scene, 'distance', artifactData.dist);
    scene = sceneSet(scene, 'wangular', artifactData.fov);
    delete('tmp.mat');
end
    
function addNeddedToolboxesToPath()
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    addpath(genpath(pwd));
    cd ..
    cd ..
    cd ..
    cd 'Toolbox';
    addpath(genpath(pwd));
    cd(rootPath);
end

