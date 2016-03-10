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
    
    
    
    timeBins = 1:size(cTest,1);
    stimulusTotalFeatures = size(cTest,2)
    stimulusSpatialFeaturesNum = numel(filterSpatialYdataInRetinalMicrons)*numel(filterSpatialXdataInRetinalMicrons)
    
    inputStimulus = zeros(numel(timeBins), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    reconstructedStimulus = zeros(numel(timeBins), numel(filterSpatialYdataInRetinalMicrons), numel(filterSpatialXdataInRetinalMicrons), 3);
    
    for timeBin = 1:size(cTest,1)   
        inputStimulus(timeBin, :,:,:) = reshape(squeeze(cTest(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
        reconstructedStimulus(timeBin, :,:,:) = reshape(squeeze(cTestPrediction(timeBin,:)), [numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons) 3]);
    end
    
    
    Lcontrasts = squeeze(inputStimulus(:,:,:,1));
    Lcontrasts = Lcontrasts(:);
    Mcontrasts = squeeze(inputStimulus(:,:,:,2));
    Mcontrasts = Mcontrasts(:);
    Scontrasts = squeeze(inputStimulus(:,:,:,3));
    Scontrasts = Scontrasts(:);
    
    L90contrast = prctile(abs(Lcontrasts), 97);
    M90contrast = prctile(abs(Mcontrasts), 97);
    S90contrast = prctile(abs(Scontrasts), 97);
    maxContrastDisplayed = max([L90contrast M90contrast S90contrast])
   
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 3, ...
               'colsNum', 6, ...
               'heightMargin',   0.04, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.04, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.01);
           
    videoFilename = sprintf('%s/ReconstructionAnimation.m4v', decodingDirectory);
    fprintf('Will export video to %s\n', videoFilename);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1900 1050]);
    colormap(gray(1024));
    
    inputLstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedLstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,2).v, 'Color', [0.5 0.5 0.5]);
    residualLstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,3).v, 'Color', [0.5 0.5 0.5]);
    
    inputMstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedMstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,2).v, 'Color', [0.5 0.5 0.5]);
    residualMstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,3).v, 'Color', [0.5 0.5 0.5]);
    
    inputSstimAxes         = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,1).v, 'Color', [0.5 0.5 0.5]);
    reconstructedSstimAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,2).v, 'Color', [0.5 0.5 0.5]);
    residualSstimAxes      = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,3).v, 'Color', [0.5 0.5 0.5]);
    
    stimulusTemporalLContrastProfilesAtLconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,4).v, 'Color', [1 1 1]);
    stimulusTemporalMContrastProfilesAtLconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,4).v, 'Color', [1 1 1]);
    stimulusTemporalSContrastProfilesAtLconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,4).v, 'Color', [1 1 1]);
    
    stimulusTemporalLContrastProfilesAtMconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,5).v, 'Color', [1 1 1]);
    stimulusTemporalMContrastProfilesAtMconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,5).v, 'Color', [1 1 1]);
    stimulusTemporalSContrastProfilesAtMconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,5).v, 'Color', [1 1 1]);
    
    stimulusTemporalLContrastProfilesAtSconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(1,6).v, 'Color', [1 1 1]);
    stimulusTemporalMContrastProfilesAtSconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(2,6).v, 'Color', [1 1 1]);
    stimulusTemporalSContrastProfilesAtSconeRichRegionAxes = axes('parent', hFig, 'unit','normalized','position',subplotPosVectors(3,6).v, 'Color', [1 1 1]);
    
    [X,Y] = meshgrid(filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons);
    DX = filterSpatialXdataInRetinalMicrons(2)-filterSpatialXdataInRetinalMicrons(1);
    DY = filterSpatialYdataInRetinalMicrons(2)-filterSpatialYdataInRetinalMicrons(1);
    
    richLconeRegionXpos =  7.5;
    richLconeRegionYpos = -7.5;
    [~, closestConeIndex] = min(sum((abs(bsxfun(@minus, xyConePos, [richLconeRegionXpos richLconeRegionYpos])).^2), 2));
    fprintf('Coords of closest cone: %2.1f %2.1f\n', xyConePos(closestConeIndex,1), xyConePos(closestConeIndex,2));
    [~, idx] = min(sqrt((X(:) - xyConePos(closestConeIndex,1)).^2 + (Y(:) - xyConePos(closestConeIndex,2)).^2));
    [LconeRichRegionRowPos, LconeRichRegionColPos] = ind2sub([numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)], idx)
    LconeTargetOutline(:,1) = filterSpatialXdataInRetinalMicrons(LconeRichRegionColPos) + [-0.5 -0.5 0.5 0.5 -0.5]*DX;
    LconeTargetOutline(:,2) = filterSpatialYdataInRetinalMicrons(LconeRichRegionRowPos) + [-0.5 0.5 0.5 -0.5 -0.5]*DY;
    
    richMconeRegionXpos = -15.5;
    richMconeRegionYpos = -8.5;
    [~, closestConeIndex] = min(sum((abs(bsxfun(@minus, xyConePos, [richMconeRegionXpos richMconeRegionYpos])).^2), 2));
    fprintf('Coords of closest cone: %2.1f %2.1f\n', xyConePos(closestConeIndex,1), xyConePos(closestConeIndex,2));
    [~, idx] = min(sqrt((X(:) - xyConePos(closestConeIndex,1)).^2 + (Y(:) - xyConePos(closestConeIndex,2)).^2));
    [MconeRichRegionRowPos, MconeRichRegionColPos] = ind2sub([numel(filterSpatialYdataInRetinalMicrons) numel(filterSpatialXdataInRetinalMicrons)], idx)
    MconeTargetOutline(:,1) = filterSpatialXdataInRetinalMicrons(MconeRichRegionColPos) + [-0.5 -0.5 0.5 0.5 -0.5]*DX;
    MconeTargetOutline(:,2) = filterSpatialYdataInRetinalMicrons(MconeRichRegionRowPos) + [-0.5 0.5 0.5 -0.5 -0.5]*DY;
 
    
    SconeRichRegionRowPos = 10;
    SconeRichRegionColPos = 10;
    SconeTargetOutline(:,1) = filterSpatialXdataInRetinalMicrons(SconeRichRegionColPos) + [-0.5 -0.5 0.5 0.5 -0.5]*DX;
    SconeTargetOutline(:,2) = filterSpatialYdataInRetinalMicrons(SconeRichRegionRowPos) + [-0.5 0.5 0.5 -0.5 -0.5]*DY;
    
    
    inputLMSconeContrastTemporalProfilesInLconeRichRegion = squeeze(inputStimulus(:, LconeRichRegionRowPos, LconeRichRegionColPos, :));
    inputLMSconeContrastTemporalProfilesInMconeRichRegion = squeeze(inputStimulus(:, MconeRichRegionRowPos, MconeRichRegionColPos, :));
    inputLMSconeContrastTemporalProfilesInSconeRichRegion = squeeze(inputStimulus(:, SconeRichRegionRowPos, SconeRichRegionColPos, :));
    
    reconstructedLMSconeContrastTemporalProfilesInLconeRichRegion = squeeze(reconstructedStimulus(:, LconeRichRegionRowPos, LconeRichRegionColPos, :));
    reconstructedLMSconeContrastTemporalProfilesInMconeRichRegion = squeeze(reconstructedStimulus(:, MconeRichRegionRowPos, MconeRichRegionColPos, :));
    reconstructedLMSconeContrastTemporalProfilesInSconeRichRegion = squeeze(reconstructedStimulus(:, SconeRichRegionRowPos, SconeRichRegionColPos, :));
    
    
    timeAxis = 0:size(cTest,1);
    
    startingTimeBin = 101;
    for timeBin = startingTimeBin:size(cTest,1)-100  
        
        inputLconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,1));
        reconstructedLconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,1));
        residualLconeContrastFrame = inputLconeContrastFrame-reconstructedLconeContrastFrame;
        
        inputMconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,2));
        reconstructedMconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,2));
        residualMconeContrastFrame = inputMconeContrastFrame-reconstructedMconeContrastFrame;
        
        inputSconeContrastFrame = squeeze(inputStimulus(timeBin,:,:,3));
        reconstructedSconeContrastFrame = squeeze(reconstructedStimulus(timeBin, :,:,3));
        residualSconeContrastFrame = inputSconeContrastFrame-reconstructedSconeContrastFrame;
        
        
        if (timeBin == startingTimeBin)
            densityPlotHandleInputLstim = makeStimulusConeMosaicComboPlot(inputLstimAxes, 'input image (L-cone contrast)', inputLconeContrastFrame, LconeTargetOutline, false, true, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputLstim, 'CData', inputLconeContrastFrame);
        end
        
        if (timeBin == startingTimeBin)
            densityPlotHandleInputMstim = makeStimulusConeMosaicComboPlot(inputMstimAxes, 'input image (M-cone contrast)', inputMconeContrastFrame, MconeTargetOutline, false, false, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputMstim, 'CData', inputMconeContrastFrame);
        end
        
        if (timeBin == startingTimeBin)
            densityPlotHandleInputSstim = makeStimulusConeMosaicComboPlot(inputSstimAxes, 'input image (S-cone contrast)', inputSconeContrastFrame, SconeTargetOutline, false, false, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleInputSstim, 'CData', inputSconeContrastFrame);
        end
        
        
        if (timeBin == startingTimeBin)
            densityPlotHandleReconstructedLstim = makeStimulusConeMosaicComboPlot(reconstructedLstimAxes, 'reconstructed image (L-cone contrast)', reconstructedLconeContrastFrame, LconeTargetOutline, false, true, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedLstim, 'CData', reconstructedLconeContrastFrame);
        end
        

        if (timeBin == startingTimeBin)
            densityPlotHandleReconstructedMstim = makeStimulusConeMosaicComboPlot(reconstructedMstimAxes, 'reconstructed image (M-cone contrast)', reconstructedMconeContrastFrame, MconeTargetOutline, false, false, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedMstim, 'CData', reconstructedMconeContrastFrame);
        end
        

        if (timeBin == startingTimeBin)
            densityPlotHandleReconstructedSstim = makeStimulusConeMosaicComboPlot(reconstructedSstimAxes, 'reconstructed image (S-cone contrast)', reconstructedSconeContrastFrame, SconeTargetOutline, false, false, false, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(densityPlotHandleReconstructedSstim, 'CData', reconstructedSconeContrastFrame);
        end
        
        

        if (timeBin == startingTimeBin)
            residualPlotHandleReconstructedLstim = makeStimulusConeMosaicComboPlot(residualLstimAxes, 'residual image (L-cone contrast)', residualLconeContrastFrame, LconeTargetOutline, true, true,  true, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedLstim, 'CData', residualLconeContrastFrame);
        end
        

        if (timeBin == startingTimeBin)
            residualPlotHandleReconstructedMstim = makeStimulusConeMosaicComboPlot(residualMstimAxes, 'residual image (M-cone contrast)', residualMconeContrastFrame, MconeTargetOutline, false, false, true, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedMstim, 'CData', residualMconeContrastFrame);
        end
        

        if (timeBin == startingTimeBin)
            residualPlotHandleReconstructedSstim = makeStimulusConeMosaicComboPlot(residualSstimAxes, 'residual image (S-cone contrast)', residualSconeContrastFrame, SconeTargetOutline, false, false, true, filterSpatialXdataInRetinalMicrons, filterSpatialYdataInRetinalMicrons,  maxContrastDisplayed, filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos);
        else
            set(residualPlotHandleReconstructedSstim, 'CData', residualSconeContrastFrame);
        end
        
        
        % time displayed for temporal profiles
        timeBinRangeDisplayed = timeBin + (-100:100);
        
        for region = 1:3
            if (region == 1)
                % Lcone rich region
                inputAndReconstructedLconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,1)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,1))
                        ];

                inputAndReconstructedMconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,2)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,2))
                        ];
                   

                inputAndReconstructedSconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,3)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInLconeRichRegion(timeBinRangeDisplayed,3))
                        ];
            
                temporalProfileAxesL = stimulusTemporalLContrastProfilesAtLconeRichRegionAxes;
                temporalProfileAxesM = stimulusTemporalMContrastProfilesAtLconeRichRegionAxes;
                temporalProfileAxesS = stimulusTemporalSContrastProfilesAtLconeRichRegionAxes;
                titleString = 'L-cone rich region';
                
            elseif (region == 2)
                % Mcone rich region
                inputAndReconstructedLconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,1)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,1))
                        ];

                inputAndReconstructedMconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,2)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,2))
                        ];

                inputAndReconstructedSconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,3)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInMconeRichRegion(timeBinRangeDisplayed,3))
                        ];
            
                temporalProfileAxesL = stimulusTemporalLContrastProfilesAtMconeRichRegionAxes;
                temporalProfileAxesM = stimulusTemporalMContrastProfilesAtMconeRichRegionAxes;
                temporalProfileAxesS = stimulusTemporalSContrastProfilesAtMconeRichRegionAxes;
                titleString = 'M-cone rich region';
                
            elseif (region == 3)
                % Scone rich region
                inputAndReconstructedLconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,1)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,1))
                        ];

                inputAndReconstructedMconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,2)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,2))
                        ];

                inputAndReconstructedSconeContrast = [ ...
                        squeeze(inputLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,3)) ...
                        squeeze(reconstructedLMSconeContrastTemporalProfilesInSconeRichRegion(timeBinRangeDisplayed,3))
                        ];
            
                temporalProfileAxesL = stimulusTemporalLContrastProfilesAtSconeRichRegionAxes;
                temporalProfileAxesM = stimulusTemporalMContrastProfilesAtSconeRichRegionAxes;
                temporalProfileAxesS = stimulusTemporalSContrastProfilesAtSconeRichRegionAxes;
                
                titleString = 'S-cone rich region';
            end
            
         
            % L cone contrast
            RGBval = [1 0.2 0.5];
            if (timeBin == startingTimeBin)
                stimulusTemporalLContrastProfilesHandle(region,:) = makeTemporalContrastProfiles(temporalProfileAxesL, titleString, RGBval,  (-100:100), inputAndReconstructedLconeContrast);
            else
                for k = 1:2
                    set(stimulusTemporalLContrastProfilesHandle(region,k), 'YData', squeeze(inputAndReconstructedLconeContrast(:,k)));
                end
                maxC = max([max(abs(inputAndReconstructedLconeContrast(:)))  maxContrastDisplayed]);
                set(temporalProfileAxesL, 'YLim', maxC*[-0.6 1.0]);
            end
        
            % M cone contrast
            RGBval = [0.2 1 0.5];
            if (timeBin == startingTimeBin)
                stimulusTemporalMContrastProfilesHandle(region,:) = makeTemporalContrastProfiles(temporalProfileAxesM, '', RGBval,  (-100:100), inputAndReconstructedMconeContrast);
            else
                for k = 1:2
                    set(stimulusTemporalMContrastProfilesHandle(region,k), 'YData', squeeze(inputAndReconstructedMconeContrast(:,k)));
                end
                maxC = max([max(abs(inputAndReconstructedMconeContrast(:)))  maxContrastDisplayed]);
                set(temporalProfileAxesM, 'YLim', maxC*[-0.6 1.0]);
            end
        
            % S cone contrast
            RGBval =  [0.5 0.2 1];
            if (timeBin == startingTimeBin)
                stimulusTemporalSContrastProfilesHandle(region,:) = makeTemporalContrastProfiles(temporalProfileAxesS, '', RGBval,  (-100:100), inputAndReconstructedSconeContrast);
            else
                for k = 1:2
                    set(stimulusTemporalSContrastProfilesHandle(region,k), 'YData', squeeze(inputAndReconstructedSconeContrast(:,k)));
                end
                maxC = max([max(abs(inputAndReconstructedSconeContrast(:)))  maxContrastDisplayed]);
                set(temporalProfileAxesS, 'YLim', maxC*[-0.6 1.0]);
            end
            
        end % region
        
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    
    writerObj.close();
    

    h = figure(11);
    set(h, 'Name', 'Out of sample predictions');
    clf;
    subplot(1,3,1);
    plot(cTest(timeBins,1), cTestPrediction(timeBins,1), 'r.');
    set(gca, 'XLim', cLimits(1,:), 'YLim', cLimits(1,:));
    axis 'square';
    subplot(1,3,2);
    plot(cTest(timeBins,2), cTestPrediction(timeBins,2), 'g.');
    set(gca, 'XLim', cLimits(2,:), 'YLim', cLimits(2,:));
    axis 'square';
    subplot(1,3,3);
    plot(cTest(timeBins,3), cTestPrediction(timeBins,3), 'b.');
    set(gca, 'XLim', cLimits(3,:), 'YLim', cLimits(3,:));
    axis 'square';
    
end


function plotHandles = makeTemporalContrastProfiles(axesToDrawOn, titleString, colorRGB, timeAxis, stimulusContrastTemporalProfiles)
    hold(axesToDrawOn, 'on');
    plotHandles(1) = plot(axesToDrawOn, timeAxis, squeeze(stimulusContrastTemporalProfiles(:,1)), '-', 'Color',  colorRGB, 'LineWidth', 2.0);
    plotHandles(2) = plot(axesToDrawOn, timeAxis, squeeze(stimulusContrastTemporalProfiles(:,2)), '-', 'Color',  [0 0 0], 'LineWidth', 2.0);
    plot(axesToDrawOn, [0 0], 100*[-1 1], 'k-');
    hold(axesToDrawOn, 'off');
    hL = legend(axesToDrawOn, 'input stimulus', 'reconstructed');
    set(hL, 'FontSize', 12);
    title(titleString, 'FontSize', 14);
    maxContrast = 2;
    set(axesToDrawOn, 'FontSize', 12, 'XLim', [-100 100], 'YLim', maxContrast*[-1 1]);
    axis(axesToDrawOn, 'square');
    box(axesToDrawOn, 'on');
    title(axesToDrawOn, titleString, 'FontSize', 14);
end


function densityPlotHandle = makeStimulusConeMosaicComboPlot(axesToDrawOn, titleString, stimulus, targetOutline, showXlabel, showYlabel, showConePositions, stimulusSpatialSupportXInRetinalMicrons, stimulusSpatialSupportYInRetinalMicrons,  maxContrastDisplayed, ...
             filterConeIDs, lConeIndices, mConeIndices, sConeIndices, xyConePos)
         
    % density plot of stimulus
    densityPlotHandle = imagesc(stimulusSpatialSupportXInRetinalMicrons, stimulusSpatialSupportYInRetinalMicrons, stimulus, 'parent', axesToDrawOn);
    hold(axesToDrawOn, 'on');
    plot(axesToDrawOn, targetOutline(:,1), targetOutline(:,2), 'c-', 'LineWidth', 2.0);
    
    
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
            plot(axesToDrawOn, xyConePos(filterConeIDs(coneIndex), 1), xyConePos(filterConeIDs(coneIndex), 2), 's', 'MarkerEdgeColor', RGBval, 'MarkerFaceColor', RGBval, 'MarkerSize', 4);
        end
    end
    
    hold(axesToDrawOn, 'off');
    
    if (showXlabel)
        xlabel(axesToDrawOn, 'microns', 'FontSize', 14);
    else
        set(axesToDrawOn, 'XTickLabels', {});
    end
    
    if (showYlabel)
        ylabel(axesToDrawOn, 'microns', 'FontSize', 14);
    else
        set(axesToDrawOn, 'YTickLabels', {});
    end
   
    set(axesToDrawOn, 'CLim', maxContrastDisplayed *[-1 1]);
    
    axis(axesToDrawOn, 'xy');
    axis(axesToDrawOn, 'equal');
    set(axesToDrawOn, 'FontSize', 12, 'XLim', [min(stimulusSpatialSupportXInRetinalMicrons) max(stimulusSpatialSupportXInRetinalMicrons)], 'YLim', [min(stimulusSpatialSupportYInRetinalMicrons) max(stimulusSpatialSupportYInRetinalMicrons)]);
    title(axesToDrawOn, titleString, 'FontSize', 14);
end

