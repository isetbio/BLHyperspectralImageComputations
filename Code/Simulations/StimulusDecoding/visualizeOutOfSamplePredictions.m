function visualizeOutOfSamplePredictions(rootPath, decodingExportSubDirectory, osType, adaptingFieldType, configuration)
    
    minargs = 5;
    maxargs = 5;
    narginchk(minargs, maxargs);
    
    scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType);
    decodingDirectory = getDecodingSubDirectory(scansDir, decodingExportSubDirectory); 
    
    % Load out-of-sample predictions
    outOfSamplePredictionDataFileName = fullfile(decodingDirectory, sprintf('OutOfSamplePredicition.mat'));
    load(outOfSamplePredictionDataFileName, 'cTestPrediction', 'cTest');
    

    
    decodingFiltersFileName = fullfile(decodingDirectory, sprintf('DecodingFilters.mat'));
    decodingFiltersVarList = {...
        'cTrainPrediction', ...
        'cTrain', ...
        'wVector', ...
        'filterSpatialXdataInRetinalMicrons', ...
        'filterSpatialYdataInRetinalMicrons'...
     };
    
    % Load decoding filter
    fprintf('\nLoading ''%s'' ...', decodingFiltersFileName);
    for k = 1:numel(decodingFiltersVarList)
        load(decodingFiltersFileName, decodingFiltersVarList{k});
    end
    
    
    decodingDataFileName = fullfile(decodingDirectory, sprintf('DecodingData.mat'));
    testingVarList = {...
        'scanSensor', ...
        'keptLconeIndices', 'keptMconeIndices', 'keptSconeIndices', ...
        };
    fprintf('\nLoading ''%s'' ...', decodingDataFileName);
    for k = 1:numel(testingVarList)
        load(decodingDataFileName, testingVarList{k});
    end
    
    filterConeIDs = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    coneTypes = sensorGet(scanSensor, 'coneType');
    xyConePos = sensorGet(scanSensor, 'xy');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    
    
    
    
    stimulusTotalFeatures = size(cTest,2)
    stimulusSpatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons)
    
    inputStimulus = zeros(size(cTest,1), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    reconstructedStimulus = zeros(size(cTest,1), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    
    inputStimulusInSample = zeros( size(cTrain,1), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    reconstructedStimulusInSample = zeros( size(cTrain,1), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    

    for timeBin = 1:size(cTest,1)   
        inputStimulus(timeBin, :,:,:) = reshape(squeeze(cTest(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
        reconstructedStimulus(timeBin, :,:,:) = reshape(squeeze(cTestPrediction(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
    end
    
    for timeBin = 1:size(cTrain,1)   
        inputStimulusInSample(timeBin, :,:,:) = reshape(squeeze(cTrain(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
        reconstructedStimulusInSample(timeBin, :,:,:) = reshape(squeeze(cTrainPrediction(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
    end
    
    
    RGBvals = [1 0.2 0.5; 0.2 0.8 0.4; 0.5 0.2 1];
     
    minC = -3;
    maxC = 8;

    testPositionXcoord = numel(filterSpatialXdataInRetinalMicrons)/2;
    testPositionYcoord = numel(filterSpatialYdataInRetinalMicrons)/2;
    
    
    
    plotPerformanceGraphs = false;
    if (plotPerformanceGraphs)
        
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.045, ...
                   'widthMargin',    0.045, ...
                   'leftMargin',     0.05, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.06, ...
                   'topMargin',      0.01);

        hFig = figure(9); clf; set(hFig, 'Position', [100 100 820 768], 'Color', [1 1 1]);

        for k = 1:2
            if (k == 1)
                inputLconeContrast = squeeze(inputStimulusInSample(:,testPositionYcoord,testPositionXcoord,1));
                inputMconeContrast = squeeze(inputStimulusInSample(:,testPositionYcoord,testPositionXcoord,2));
                inputSconeContrast = squeeze(inputStimulusInSample(:,testPositionYcoord,testPositionXcoord,3));
            else
                inputLconeContrast = squeeze(reconstructedStimulusInSample(:,testPositionYcoord,testPositionXcoord,1));
                inputMconeContrast = squeeze(reconstructedStimulusInSample(:,testPositionYcoord,testPositionXcoord,2));
                inputSconeContrast = squeeze(reconstructedStimulusInSample(:,testPositionYcoord,testPositionXcoord,3));
            end

            subplot('position',subplotPosVectors(k,1).v);
            hold on
            plot(inputLconeContrast, inputMconeContrast, 'k.');
            plot([minC  maxC], [minC  maxC], 'r-', 'LineWidth', 1);
            plot([minC  maxC], [0 0], 'r-', 'LineWidth', 1);
            plot([0 0], [minC  maxC], 'r-', 'LineWidth', 1);
            hold off
            set(gca, 'XLim', [minC  maxC], 'YLim', [minC  maxC], 'FontSize', 16);
            set(gca, 'XTick', (-10: 2: 10), 'YTick', (-10 :2: 10));
            ylabel('M-cone contrast', 'FontSize', 20);
            axis 'square'
            box on
            if (k == 1)
                text(0.1, 7.5, 'input', 'FontSize', 20, 'FontWeight', 'bold');
            else
                xlabel('L-cone contrast', 'FontSize', 20);
                text(0.1, 7.5,'reconstructed', 'FontSize', 20, 'FontWeight', 'bold');
            end

            subplot('position',subplotPosVectors(k,2).v);
            hold on
            plot(inputLconeContrast, inputSconeContrast, 'k.');
            plot([minC  maxC], [minC  maxC], 'r-', 'LineWidth', 1);
            plot([minC  maxC], [0 0], 'r-', 'LineWidth', 1);
            plot([0 0], [minC  maxC], 'r-', 'LineWidth', 1);
            hold off
            set(gca, 'XLim', [minC  maxC], 'YLim', [minC  maxC], 'FontSize', 16);
            set(gca, 'XTick', (-10:2: 10), 'YTick', (-10 :2: 10));

            ylabel('S-cone contrast', 'FontSize', 20);
            axis 'square'
            box on
            if (k == 1)
                text(0.1, 7.5, 'input', 'FontSize', 20, 'FontWeight', 'bold');
            else
                xlabel('L-cone contrast', 'FontSize', 20);
                text(0.1, 7.5, 'reconstructed', 'FontSize', 20, 'FontWeight', 'bold');
            end
        end
    
        pngFileName = sprintf('%s/ConeContrastCorrelations.png',decodingDirectory);
        NicePlot.exportFigToPNG(pngFileName, hFig, 300);

        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 3, ...
                   'heightMargin',   0.02, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.05, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.045, ...
                   'topMargin',      0.01);
           
        hFig = figure(10); clf; set(hFig, 'Position', [100 100 1024 768], 'Color', [1 1 1]);
        for k = 1:2
            for coneContrastIndex = 1:3   
                subplot('position',subplotPosVectors(k,coneContrastIndex).v);
                if (k == 1)
                    inputContrast = squeeze(inputStimulusInSample(:,testPositionYcoord,testPositionXcoord,coneContrastIndex));
                    reconstructedContrast = squeeze(reconstructedStimulusInSample(:,testPositionYcoord,testPositionXcoord,coneContrastIndex));
                else
                    inputContrast = squeeze(inputStimulus(:,testPositionYcoord,testPositionXcoord,coneContrastIndex));
                    reconstructedContrast = squeeze(reconstructedStimulus(:,testPositionYcoord,testPositionXcoord,coneContrastIndex));
                end

                nonZeroInputContrastIndices = find(abs(inputContrast) > 0.01);
                hold on;
                plot(inputContrast(nonZeroInputContrastIndices), reconstructedContrast(nonZeroInputContrastIndices) , 'k.');
                plot([minC  maxC], [minC  maxC], 'r-', 'LineWidth', 1);
                plot([minC  maxC], [0 0], 'r-', 'LineWidth', 1);
                plot([0 0], [minC  maxC], 'r-', 'LineWidth', 1);
                hold off
                set(gca, 'XLim', [minC  maxC], 'YLim', [minC  maxC], 'FontSize', 16);
                set(gca, 'XTick', (-10:2: 10), 'YTick', (-10 :2: 10));

                if (coneContrastIndex > 1)
                    set(gca, 'YTickLabel', {});
                else
                   ylabel('reconstructed contrast', 'FontSize', 20); 
                end

                if (k == 2)
                    xlabel('input contrast', 'FontSize', 20);
                end

                if (k == 1)
                    sampleSting = 'in-sample';
                else
                    sampleSting = 'out-of-sample';
                end

                if (coneContrastIndex==1)
                    title(sprintf('%s L-cone',sampleSting), 'FontSize', 22);
                elseif (coneContrastIndex==2)
                    title(sprintf('%s M-cone',sampleSting), 'FontSize', 22);
                elseif (coneContrastIndex==3)
                    title(sprintf('%s S-cone',sampleSting), 'FontSize', 22);
                end
                axis 'square'
                box on
            end
        end
        pngFileName = sprintf('%s/OS_Biophys_InSampleOutOfSamplePerformance.png',decodingDirectory);
        NicePlot.exportFigToPNG(pngFileName, hFig, 300);


    
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', numel(filterSpatialYdataInRetinalMicrons)/2, ...
                   'colsNum', numel(filterSpatialXdataInRetinalMicrons)/2, ...
                   'heightMargin',   0.005, ...
                   'widthMargin',    0.005, ...
                   'leftMargin',     0.01, ...
                   'rightMargin',    0.01, ...
                   'bottomMargin',   0.01, ...
                   'topMargin',      0.01);

        for coneContrastIndex = 1:3
            hFig = figure(10+coneContrastIndex); clf; set(hFig, 'Position', [100 100 768 768], 'Color', [1 1 1]);
            for stimRow = 1:numel(filterSpatialYdataInRetinalMicrons)/2
                for stimCol = 1:numel(filterSpatialXdataInRetinalMicrons)/2
                    subplot('position',subplotPosVectors(stimRow,stimCol).v);
                    inputContrast = squeeze(inputStimulus(:,stimRow,stimCol,coneContrastIndex));
                    reconstructedContrast = squeeze(reconstructedStimulus(:,stimRow,stimCol,coneContrastIndex));
                    nonZeroInputContrastIndices = find(abs(inputContrast) > 0.01);
                    hold on;
                    plot(inputContrast(nonZeroInputContrastIndices), reconstructedContrast(nonZeroInputContrastIndices) , 'k.');
                    plot([minC   maxC], [minC  maxC], 'r-');
                    plot([minC   maxC], [0 0], 'r-');
                    plot([0 0], [minC   maxC], 'r-');
                    hold off
                    set(gca, 'XLim', [minC   maxC], 'YLim', [minC   maxC], 'XTick', [], 'YTick', []);
                    axis 'square'
                    axis 'off'
                    drawnow
                end % stimCol
            end % stimRow

            pngFileName = sprintf('%s/OS_Biophys_ConContrast_%d_InSampleOutOfSamplePerformanceAllPositions.png',decodingDirectory, coneContrastIndex);
            NicePlot.exportFigToPNG(pngFileName, hFig, 300);
        end % coneContrastIndex
    
    end % plotPerformanceGraphs
    
   
    
    
    Lcontrasts = squeeze(inputStimulus(:,:,:,1));
    Lcontrasts = Lcontrasts(:);
    Mcontrasts = squeeze(inputStimulus(:,:,:,2));
    Mcontrasts = Mcontrasts(:);
    Scontrasts = squeeze(inputStimulus(:,:,:,3));
    Scontrasts = Scontrasts(:);
    
    perentage = 99;
    L95contrastPos = prctile(abs(Lcontrasts(Lcontrasts>0)), perentage);
    M95contrastPos = prctile(abs(Mcontrasts(Mcontrasts>0)), perentage);
    S95contrastPos = prctile(abs(Scontrasts(Scontrasts>0)), perentage);
   
    L95contrastNeg = prctile(abs(Lcontrasts(Lcontrasts<0)), perentage);
    M95contrastNeg = prctile(abs(Mcontrasts(Mcontrasts<0)), perentage);
    S95contrastNeg = prctile(abs(Scontrasts(Scontrasts<0)), perentage);
    
    contrastRangeDisplayed = [-max([L95contrastNeg M95contrastNeg S95contrastNeg]) max([L95contrastPos M95contrastPos S95contrastPos])]
    
    stimulusTestPositionInRetinalMicrons(1) = filterSpatialXdataInRetinalMicrons(testPositionXcoord);
    stimulusTestPositionInRetinalMicrons(2) = filterSpatialYdataInRetinalMicrons(testPositionYcoord);
    
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 4, ...
               'heightMargin',   0.04, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.045, ...
               'rightMargin',    0.001, ...
               'bottomMargin',   0.05, ...
               'topMargin',      0.02);
           
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1024 768], 'Color', [1 1 1]);
    colormap(bone(1024));
    
    inputLstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedLstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,2).v, 'Color', [0.5 0.5 0.5]);
    residualLstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,3).v, 'Color', [0.5 0.5 0.5]);
    
    inputMstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedMstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,2).v, 'Color', [0.5 0.5 0.5]);
    residualMstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,3).v, 'Color', [0.5 0.5 0.5]);
    
    inputSstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedSstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,2).v, 'Color', [0.5 0.5 0.5]);
    residualSstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,3).v, 'Color', [0.5 0.5 0.5]);
    
    stimulusTemporalLContrastProfilesAtTestPositionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,4).v, 'Color', [1 1 1]);
    stimulusTemporalMContrastProfilesAtTestPositionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,4).v, 'Color', [1 1 1]);
    stimulusTemporalSContrastProfilesAtTestPositionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,4).v, 'Color', [1 1 1]);
    
    inputLMSconeContrastTemporalProfilesInTestPosition = squeeze(inputStimulus(:, testPositionYcoord, testPositionXcoord, :));
    reconstructedLMSconeContrastTemporalProfilesInTestPosition = squeeze(reconstructedStimulus(:, testPositionYcoord, testPositionXcoord, :));
    
    
    videoFilename = sprintf('%s/ReconstructionAnimation.m4v', decodingDirectory);
    fprintf('Will export video to %s\n', videoFilename);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    timeAxis = 0:size(cTest,1);
    generateVideoForThisManyMinutes = 10;
    
    for timeBin = 1:min([size(cTest,1)  100*60*generateVideoForThisManyMinutes])
        
        inputLconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,1));
        reconstructedLconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,1));
        residualLconeContrastFrame = inputLconeContrastFrame-reconstructedLconeContrastFrame;
        
        inputMconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,2));
        reconstructedMconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,2));
        residualMconeContrastFrame = inputMconeContrastFrame-reconstructedMconeContrastFrame;
        
        inputSconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,3));
        reconstructedSconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,3));
        residualSconeContrastFrame = inputSconeContrastFrame-reconstructedSconeContrastFrame;
        
        if (timeBin == 1)
            densityPlotHandleInputLstim = makeStimulusConeMosaicComboPlot(inputLstimAxes, 'input L-contrast', inputLconeContrastFrame, false, true, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputLstim, 'CData', inputLconeContrastFrame);
        end
        
        if (timeBin == 1)
            densityPlotHandleInputMstim = makeStimulusConeMosaicComboPlot(inputMstimAxes, 'input M-contrast', inputMconeContrastFrame, false, true, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputMstim, 'CData', inputMconeContrastFrame);
        end
        
        if (timeBin == 1)
            densityPlotHandleInputSstim = makeStimulusConeMosaicComboPlot(inputSstimAxes, 'input S-contrast', inputSconeContrastFrame, true, true, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputSstim, 'CData', inputSconeContrastFrame);
        end
        
        
        if (timeBin == 1)
            densityPlotHandleReconstructedLstim = makeStimulusConeMosaicComboPlot(reconstructedLstimAxes, 'reconstructed L-contrast', reconstructedLconeContrastFrame, false, false, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedLstim, 'CData', reconstructedLconeContrastFrame);
        end
        

        if (timeBin == 1)
            densityPlotHandleReconstructedMstim = makeStimulusConeMosaicComboPlot(reconstructedMstimAxes, 'reconstructed M-contrast', reconstructedMconeContrastFrame, false, false, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedMstim, 'CData', reconstructedMconeContrastFrame);
        end
        

        if (timeBin == 1)
            densityPlotHandleReconstructedSstim = makeStimulusConeMosaicComboPlot(reconstructedSstimAxes, 'reconstructed S-contrast', reconstructedSconeContrastFrame, true, false, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedSstim, 'CData', reconstructedSconeContrastFrame);
        end
        
        

        if (timeBin == 1)
            residualPlotHandleReconstructedLstim = makeStimulusConeMosaicComboPlot(residualLstimAxes, 'residual', residualLconeContrastFrame, false, false, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedLstim, 'CData', residualLconeContrastFrame);
        end
        

        if (timeBin == 1)
            residualPlotHandleReconstructedMstim = makeStimulusConeMosaicComboPlot(residualMstimAxes, 'residual', residualMconeContrastFrame, false, false, true, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedMstim, 'CData', residualMconeContrastFrame);
        end
        

        if (timeBin == 1)
            residualPlotHandleReconstructedSstim = makeStimulusConeMosaicComboPlot(residualSstimAxes, 'residual', residualSconeContrastFrame, true, false, false, stimulusTestPositionInRetinalMicrons, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  contrastRangeDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedSstim, 'CData', residualSconeContrastFrame);
        end
        
        
        % time displayed for temporal profiles
        timeBinRangeDisplayed = max([1 timeBin-150]) : timeBin;

            
        inputAndReconstructedLconeContrast = [ ...
                squeeze(inputLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,1)) ...
                squeeze(reconstructedLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,1))
                ];

        inputAndReconstructedMconeContrast = [ ...
                squeeze(inputLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,2)) ...
                squeeze(reconstructedLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,2))
                ];


        inputAndReconstructedSconeContrast = [ ...
                squeeze(inputLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,3)) ...
                squeeze(reconstructedLMSconeContrastTemporalProfilesInTestPosition(timeBinRangeDisplayed,3))
                ];
     
            
        % L cone contrast
        RGBval = squeeze(RGBvals(1,:));
        if (timeBin == 1)
            stimulusTemporalLContrastProfilesHandles = makeTemporalContrastProfiles(stimulusTemporalLContrastProfilesAtTestPositionAxes, '', RGBval,  timeAxis(timeBinRangeDisplayed), inputAndReconstructedLconeContrast);
        else
            for k = 1:2
                set(stimulusTemporalLContrastProfilesHandles(k), 'XData', timeAxis(timeBinRangeDisplayed), 'YData', squeeze(inputAndReconstructedLconeContrast(:,k)));
            end
            set(stimulusTemporalLContrastProfilesHandles(3), 'XData', [], 'YData', []);
            set(stimulusTemporalLContrastProfilesHandles(4), 'XData', [], 'YData', []);
            set(stimulusTemporalLContrastProfilesAtTestPositionAxes, 'XLim', [timeAxis(timeBinRangeDisplayed(1)) timeAxis(timeBinRangeDisplayed(end))], 'YLim', contrastRangeDisplayed);
        end

        % M cone contrast
        RGBval = squeeze(RGBvals(2,:));
        if (timeBin == 1)
            stimulusTemporalMContrastProfilesHandles = makeTemporalContrastProfiles(stimulusTemporalMContrastProfilesAtTestPositionAxes, '', RGBval,  timeAxis(timeBinRangeDisplayed), inputAndReconstructedMconeContrast);
        else
            for k = 1:2
                set(stimulusTemporalMContrastProfilesHandles(k), 'XData', timeAxis(timeBinRangeDisplayed), 'YData', squeeze(inputAndReconstructedMconeContrast(:,k)));
            end
            set(stimulusTemporalMContrastProfilesHandles(3), 'XData', [], 'YData', []);
            set(stimulusTemporalMContrastProfilesHandles(4), 'XData', [], 'YData', []);
            set(stimulusTemporalMContrastProfilesAtTestPositionAxes, 'XLim', [timeAxis(timeBinRangeDisplayed(1)) timeAxis(timeBinRangeDisplayed(end))], 'YLim', contrastRangeDisplayed);
        end

        % S cone contrast
        RGBval = squeeze(RGBvals(3,:));
        if (timeBin == 1)
            stimulusTemporalSContrastProfilesHandles = makeTemporalContrastProfiles(stimulusTemporalSContrastProfilesAtTestPositionAxes, '', RGBval,  timeAxis(timeBinRangeDisplayed), inputAndReconstructedSconeContrast);
        else
            for k = 1:2
                set(stimulusTemporalSContrastProfilesHandles(k), 'XData', timeAxis(timeBinRangeDisplayed), 'YData', squeeze(inputAndReconstructedSconeContrast(:,k)));
            end
            % 500 msec time bar
            set(stimulusTemporalSContrastProfilesHandles(3), 'XData', timeAxis(timeBinRangeDisplayed(end-1))+[0 -50], 'YData', contrastRangeDisplayed(1)*[1 1]);
            set(stimulusTemporalSContrastProfilesHandles(4), 'XData', timeAxis(timeBinRangeDisplayed(end-1))*[1 1],   'YData', contrastRangeDisplayed(1)+[0 2]);
            set(stimulusTemporalSContrastProfilesAtTestPositionAxes, 'XLim', [timeAxis(timeBinRangeDisplayed(1)) timeAxis(timeBinRangeDisplayed(end))], 'YLim', contrastRangeDisplayed);
            set(stimulusTemporalSContrastProfilesAtTestPositionAxes, 'XLim', [timeAxis(timeBinRangeDisplayed(1)) timeAxis(timeBinRangeDisplayed(end))], 'YLim', contrastRangeDisplayed);
        end
            
        
        drawnow;
        if (timeBin > 154)
            writerObj.writeVideo(getframe(hFig));
        end
    end
    
    writerObj.close();

    
    
end


function plotHandles = makeTemporalContrastProfiles(axesToDrawOn, titleString, colorRGB, timeAxis, stimulusContrastTemporalProfiles)
    hold(axesToDrawOn, 'on');
    plotHandles(1) = plot(axesToDrawOn, timeAxis, squeeze(stimulusContrastTemporalProfiles(:,1)), '-', 'Color',  colorRGB, 'LineWidth', 2.0);
    plotHandles(2) = plot(axesToDrawOn, timeAxis, squeeze(stimulusContrastTemporalProfiles(:,2)), '-', 'Color',  [0 0 0], 'LineWidth', 2.0);
    % horizontal (time scale bar)
    plotHandles(3) = plot(axesToDrawOn, timeAxis(1)+[0 100], [-1 -1], 'k-', 'Color', [0.4 0.4 0.4], 'LineWidth', 2.0);
    % vertical (contast bar)
    plotHandles(4) = plot(axesToDrawOn, timeAxis(1)+[1 1],   [0 -1],  'k-', 'Color', [0.4 0.4 0.4], 'LineWidth', 2.0);
    hold(axesToDrawOn, 'off');
    hL = legend(axesToDrawOn, 'input', 'reconstructed');
    set(hL, 'FontSize', 20, 'Location', 'NorthWest', 'box', 'off');
    maxContrast = 2;
    set(axesToDrawOn, 'XTickLabels', {}, 'FontSize', 16, 'XLim', [1 2], 'YLim', maxContrast*[-1 1]);
    axis(axesToDrawOn, 'square');
    axis(axesToDrawOn, 'off');
    title(axesToDrawOn, titleString, 'FontSize', 20);
end


function densityPlotHandle = makeStimulusConeMosaicComboPlot(axesToDrawOn, titleString, stimulus, showXlabel, showYlabel, showConePositions, stimulusTestPosition, stimulusSpatialSupportXInRetinalMicrons, stimulusSpatialSupportYInRetinalMicrons,  contrastRangeDisplayed, ...
             filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos)
         
    % density plot of stimulus
    densityPlotHandle = imagesc(stimulusSpatialSupportXInRetinalMicrons, stimulusSpatialSupportYInRetinalMicrons, stimulus, 'parent', axesToDrawOn);
    set(axesToDrawOn, 'CLim', contrastRangeDisplayed);
    hold(axesToDrawOn, 'on');
    
    if (showConePositions)
        % superimpose mosaic
        for coneIndex = 1:numel(filterConeIDs)
            % figure out the color of the filter entry
            if ismember(filterConeIDs(coneIndex), lConeIndices)
                 RGBval = [1 0.2 0.5];
            elseif ismember(filterConeIDs(coneIndex), mConeIndices)
                RGBval = [0.2 1 0.5];
            elseif ismember(filterConeIDs(coneIndex), sConeIndices)
                RGBval = [0.5 0.2 1];
            else
                error('No such cone type')
            end
            plot(axesToDrawOn, xyConePos(filterConeIDs(coneIndex), 1), xyConePos(filterConeIDs(coneIndex), 2), 'o', 'MarkerEdgeColor', 0.5*(RGBval + [0.5 0.5 0.5]), 'MarkerFaceColor', RGBval, 'MarkerSize', 8);
        end
    end
    
    if (~isempty(stimulusTestPosition))
        outlineX = 0.25+stimulusTestPosition(1) + [-1 -1 1 1 -1 -1]*0.5*(stimulusSpatialSupportXInRetinalMicrons(2)-stimulusSpatialSupportXInRetinalMicrons(1));
        outlineY = 0.25+stimulusTestPosition(2) + [-1 1 1 -1 -1 1]*0.5*(stimulusSpatialSupportYInRetinalMicrons(2)-stimulusSpatialSupportYInRetinalMicrons(1));
        plot(axesToDrawOn, outlineX, outlineY, 'y-', 'LineWidth', 2.0);
    end
    
    hold(axesToDrawOn, 'off');
    set(axesToDrawOn, 'XTick', [-100:20:100], 'YTick', [-100:20:100]);
    if (showXlabel)
        xlabel(axesToDrawOn, 'microns', 'FontSize', 20);
    else
        set(axesToDrawOn, 'XTickLabels', {});
    end
    
    if (showYlabel)
        ylabel(axesToDrawOn, 'microns', 'FontSize', 20);
    else
        set(axesToDrawOn, 'YTickLabels', {});
    end
   
    
    axis(axesToDrawOn, 'xy');
    axis(axesToDrawOn, 'equal');
    set(axesToDrawOn, 'FontSize', 16, 'XLim', [min(stimulusSpatialSupportXInRetinalMicrons) max(stimulusSpatialSupportXInRetinalMicrons)], 'YLim', [min(stimulusSpatialSupportYInRetinalMicrons) max(stimulusSpatialSupportYInRetinalMicrons)]);
    title(axesToDrawOn, titleString, 'FontSize', 20);
end

