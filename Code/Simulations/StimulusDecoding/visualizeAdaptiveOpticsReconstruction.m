function visualizeAdaptiveOpticsReconstruction(rootPath, decodingSubDirectory, osType, adaptingFieldType)

    
    adaptiveOpticsConfiguration = 'adaptiveOpticsStimulation';
    adaptiveOpticsImSource = {'ao_database', 'condition1'};
    scansDir = getScansDir(rootPath, adaptiveOpticsConfiguration, adaptingFieldType, osType);
    
    adaptiveOpticsDecodingDirectory = getDecodingSubDirectory(scansDir, decodingSubDirectory);
    outOfSamplePredictionDataFileName = fullfile(adaptiveOpticsDecodingDirectory, sprintf('OutOfSamplePredicition.mat'));
    load(outOfSamplePredictionDataFileName, 'cTestPrediction', 'scanSensor', 'scanPhotoCurrents', 'filterSpatialXdataInRetinalMicrons', 'filterSpatialYdataInRetinalMicrons');
    
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    coneXYpositions = sensorGet(scanSensor, 'xy');
    coneMosaicSpatialXdataInRetinalMicrons = sort(unique(coneXYpositions(:,1)));
    coneMosaicSpatialYdataInRetinalMicrons = sort(unique(coneXYpositions(:,2)));
    
    
    reconstructedStimulus = zeros(size(cTestPrediction,1), numel(filterSpatialYdataInRetinalMicrons),  numel(filterSpatialXdataInRetinalMicrons), 3);
    
    for timeBin = 1:size(cTestPrediction,1)   
        reconstructedStimulus(timeBin, :,:,:) = reshape(squeeze(cTestPrediction(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
    end
    
    contrastRangeDisplayed = [-2 6];
    
    videoFilename = sprintf('%s/ReconstructionAnimation.m4v', adaptiveOpticsDecodingDirectory );
    fprintf('Will export video to %s\n', videoFilename);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    timeAxis = (0:(size(cTestPrediction,1)-1))*10/1000;

    totalTime = sensorGet(scanSensor, 'total time');
    timeStep  = sensorGet(scanSensor, 'time interval');
    timeBins  = round(totalTime/timeStep);
    

    scanSensorPhotonRate = sensorGet(scanSensor, 'photon rate');
    
    photonRateTimeAxis = -0.5 + (0:(size(scanSensorPhotonRate,3)-1))/1000;
 
   
    
    XYZtoLMS = [0.17156 0.52901 -0.02199; -0.15955 0.48553 0.04298; 0.01916 -0.03989 1.03993];
    LMStoXYZ = inv(XYZtoLMS);
    
    LMSfactors = [0.0950/0.271;  0.052/0.230; 0.1531/0.142];
    
    backgroundLMS = [0.271; 0.230; 0.142];

    
    XYZtoLMS * [0.14;0.14;0.15]
    

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 3, ...
               'heightMargin',   0.05, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.05);
           
    hFig = figure(1); clf; set(hFig, 'position', [100 100 1024 768], 'Color', [1 1 1]);
    colormap(gray(1024));
    
    photonRateMapAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedContrastTracesAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,2).v, 'Color', [0.5 0.5 0.5]);
    
    RGBrenderingAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,3).v, 'Color', [0.5 0.5 0.5]);
    reconstructedLconeImageAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedMconeImageAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,2).v, 'Color', [0.5 0.5 0.5]);
    reconstructedSconeImageAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,3).v, 'Color', [0.5 0.5 0.5]);
    
    
    for timeBin = 1:numel(timeAxis)-75
        
        reconstructedLconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,1));
        reconstructedMconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,2));
        reconstructedSconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,3));
        
        LexcitationImage = backgroundLMS(1) * (1.0 + reconstructedLconeContrastFrame);
        MexcitationImage = backgroundLMS(2) * (1.0 + reconstructedMconeContrastFrame);
        SexcitationImage = backgroundLMS(3) * (1.0 + reconstructedSconeContrastFrame);

        
        for row = 1:size(LexcitationImage,1)
            for col = 1:size(LexcitationImage,2)
                LMS = [LexcitationImage(row,col); MexcitationImage(row,col); SexcitationImage(row,col)] .* LMSfactors;
                XYZimage(row,col,:) = LMStoXYZ * LMS;
            end
        end

        maxXYZ = max(XYZimage(:));
        minXYZ = min(XYZimage(:));

        if (maxXYZ > 1.2)
            XYZimage = 1.2*XYZimage/maxXYZ;
            fprintf('XYZmax: %f\n', maxXYZ);
        end
        if (minXYZ < 0)
            fprintf('XYZmin: %f\n', minXYZ);
        end
        
        if (timeBin == 1)
            p1 = imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, reconstructedLconeContrastFrame, 'parent', reconstructedLconeImageAxes);
            axis(reconstructedLconeImageAxes, 'xy')
            axis(reconstructedLconeImageAxes, 'equal');
            set(reconstructedLconeImageAxes,'CLim', contrastRangeDisplayed, 'XLim', [min(filterSpatialXdataInRetinalMicrons) max(filterSpatialXdataInRetinalMicrons)], ...
                'YLim', [min(filterSpatialYdataInRetinalMicrons) max(filterSpatialYdataInRetinalMicrons)], 'XTickLabel', {}, 'YTickLabel', {});
            title(reconstructedLconeImageAxes, 'reconstructed L-contrast image', 'FontSize', 20);
        else
            set(p1, 'CData', reconstructedLconeContrastFrame);
        end
        
        
        if (timeBin == 1)
            p2 = imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, reconstructedMconeContrastFrame, 'parent', reconstructedMconeImageAxes);
            axis(reconstructedMconeImageAxes, 'xy')
            axis(reconstructedMconeImageAxes, 'equal');
            set(reconstructedMconeImageAxes,'CLim', contrastRangeDisplayed, 'XLim', [min(filterSpatialXdataInRetinalMicrons) max(filterSpatialXdataInRetinalMicrons)], ...
                'YLim', [min(filterSpatialYdataInRetinalMicrons) max(filterSpatialYdataInRetinalMicrons)], 'XTickLabel', {}, 'YTickLabel', {});
            title(reconstructedMconeImageAxes, 'reconstructed M-contrast image','FontSize', 20);
        else
            set(p2, 'CData', reconstructedMconeContrastFrame);
        end
        
        
        if (timeBin == 1)
            p3 = imagesc(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons, reconstructedMconeContrastFrame, 'parent', reconstructedSconeImageAxes);
            axis(reconstructedSconeImageAxes, 'xy')
            axis(reconstructedSconeImageAxes, 'equal');
            set(reconstructedSconeImageAxes,'CLim', contrastRangeDisplayed, 'XLim', [min(filterSpatialXdataInRetinalMicrons) max(filterSpatialXdataInRetinalMicrons)], ...
                'YLim', [min(filterSpatialYdataInRetinalMicrons) max(filterSpatialYdataInRetinalMicrons)], 'XTickLabel', {}, 'YTickLabel', {});
            title(reconstructedSconeImageAxes, 'reconstructed S-contrast image', 'FontSize', 20);
        else
            set(p3, 'CData', reconstructedSconeContrastFrame);
        end

        
        tnow = timeAxis(timeBin);
        [~, idx] = min(abs(tnow - photonRateTimeAxis));
        
        photonRateMap = squeeze(scanSensorPhotonRate(:,:,idx));
        
        if (timeBin == 1)
            p4 = imagesc(coneMosaicSpatialXdataInRetinalMicrons, coneMosaicSpatialYdataInRetinalMicrons, photonRateMap, 'parent', photonRateMapAxes);
            hold(photonRateMapAxes, 'on');
            for coneIndex = 1:numel(coneTypes)
                if ismember(coneIndex, lConeIndices)
                    RGBcolor = [1 0.2 0.5];
                elseif ismember(coneIndex, mConeIndices)
                    RGBcolor = [0.2 1 0.5];
                elseif ismember(coneIndex, sConeIndices)
                    RGBcolor = [0.5 0.2 1];
                end
                plot(photonRateMapAxes, coneXYpositions(coneIndex,1), coneXYpositions(coneIndex,2), 'ko', 'MarkerEdgeColor', RGBcolor, 'MarkerFaceColor', RGBcolor, 'MarkerSize', 11);
            end
            hold(photonRateMapAxes, 'off');
            axis(photonRateMapAxes, 'xy')
            axis(photonRateMapAxes, 'equal');
            axis(photonRateMapAxes, 'off');
            set(photonRateMapAxes, 'Color', [0.5 0.5 0.5], 'CLim', [24000 32000], 'XLim', [min(coneMosaicSpatialXdataInRetinalMicrons)-1.5 max(coneMosaicSpatialXdataInRetinalMicrons)+1.5], ...
                'YLim', [min(coneMosaicSpatialYdataInRetinalMicrons)-1.5 max(coneMosaicSpatialYdataInRetinalMicrons)+1.5], 'XTickLabel', {}, 'YTickLabel', {});
            title(photonRateMapAxes, 'stimulation map', 'FontSize', 20);
        else
            set(p4, 'CData', photonRateMap);
        end
        
        
        RGBim = XYZToSRGB(XYZimage)/255.0;
        if ((numel(find(RGBim>1)) > 0) || (numel(find(RGBim<0)) > 0))
        fprintf('numner of pixels with RGB > 1: %d <0: %d our of %d\n', numel(find(RGBim>1)), numel(find(RGBim<0)), numel(RGBim));
        end
        RGBim(RGBim<0) = 0;
        RGBim(RGBim>1) = 1;
        
        
        if (timeBin == 1)
            p5 = image(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,RGBim, 'parent', RGBrenderingAxes);
            axis(RGBrenderingAxes, 'xy')
            axis(RGBrenderingAxes, 'equal');
            set(RGBrenderingAxes,'CLim', [0 1], 'XLim', [min(filterSpatialXdataInRetinalMicrons) max(filterSpatialXdataInRetinalMicrons)], ...
                'YLim', [min(filterSpatialYdataInRetinalMicrons) max(filterSpatialYdataInRetinalMicrons)], 'XTickLabel', {}, 'YTickLabel', {});
            title(RGBrenderingAxes, 'RGB rendering', 'FontSize', 20);
        else
            set(p5, 'CData', RGBim);
        end
        
        N = numel(filterSpatialXdataInRetinalMicrons)*numel(filterSpatialYdataInRetinalMicrons);
        reconstructedLconstrasts = reshape(permute(squeeze(reconstructedStimulus(:, :,:,1)), [2 3 1]), [N size(reconstructedStimulus,1)]);
        reconstructedMconstrasts = reshape(permute(squeeze(reconstructedStimulus(:, :,:,2)), [2 3 1]), [N size(reconstructedStimulus,1)]);
        reconstructedSconstrasts = reshape(permute(squeeze(reconstructedStimulus(:, :,:,3)), [2 3 1]), [N size(reconstructedStimulus,1)]);

        
        startingBin = 20;
        if (timeBin == startingBin+1)
       
             p6 = plot(reconstructedContrastTracesAxes, timeAxis(1:size(reconstructedLconstrasts,2)), reconstructedLconstrasts, 'r-', 'Color', [1 0.2 0.5], 'LineWidth', 2.0);
             hold(reconstructedContrastTracesAxes, 'on');
             p7 = plot(reconstructedContrastTracesAxes, timeAxis(1:size(reconstructedLconstrasts,2)), reconstructedMconstrasts, 'g-', 'Color', [0.2 1 0.5], 'LineWidth', 2.0);
             p8 = plot(reconstructedContrastTracesAxes, timeAxis(1:size(reconstructedLconstrasts,2)), reconstructedSconstrasts, 'b-', 'Color', [0.5 0.2 1], 'LineWidth', 2.0);
             p9 = plot(reconstructedContrastTracesAxes, [0 0], [-1 1], 'k-');
             p10 = plot(reconstructedContrastTracesAxes, [timeAxis(1) timeAxis(end)], [0 0 ], 'k-');
             hold(reconstructedContrastTracesAxes, 'off');
             title(reconstructedContrastTracesAxes, 'reconstructed L/M/S contrast', 'FontSize', 20);
             set(reconstructedContrastTracesAxes, 'XColor', [1 1 1], 'YColor', [1 1 1]);
         elseif (timeBin>startingBin+1)
             set(reconstructedContrastTracesAxes, 'XLim', 0.150+[timeAxis(timeBin-startingBin) timeAxis(timeBin)], 'YLim', [-0.6 1.0]);  
             set(p9, 'XData', timeAxis(timeBin)*[1 1]);
        end
        
        drawnow;
        if (timeBin > 60)
        writerObj.writeVideo(getframe(hFig));
        end
    end
    

    writerObj.close();
     
end

