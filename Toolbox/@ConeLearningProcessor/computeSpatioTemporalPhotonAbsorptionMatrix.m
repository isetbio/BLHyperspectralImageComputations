function exportFile = computeSpatioTemporalPhotonAbsorptionMatrix(obj, varargin)

    parser = inputParser;
    parser.addParamValue('conesAcross',  10, @isnumeric);
    parser.addParamValue('coneApertureInMicrons', 3.0, @isfloat);
    parser.addParamValue('coneIntegrationTimeInMilliseconds', 50, @isfloat );
    parser.addParamValue('coneLMSdensities', [0.6 0.3 0.1], @isfloat);
    parser.addParamValue('eyeMicroMovementsPerFixation', 100, @isnumeric);
    parser.addParamValue('sceneSet', @isstruct);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    parserResults = parser.Results;
    pNames = fieldnames(parserResults);
    for k = 1:length(pNames)
        eval(sprintf('obj.%s = parserResults.%s;', pNames{k}, pNames{k}))
    end
           
    exportFile = computePhotonAbsorptions(obj);
end

function exportFile = computePhotonAbsorptions(obj)
    % Unload inputs
    conesAcross = obj.conesAcross;
    if (conesAcross == 10) || (conesAcross == 15)
        eyeMovementOverlapFactor = 0.5;
    elseif (conesAcross == 20)
        eyeMovementOverlapFactor = 0.6;
    end
    
    % Sensor params
    sensorParamsStruct = struct(...
                       'name', 'humanLMS', ...
                'conesAcross', conesAcross, ...
               'coneAperture', obj.coneApertureInMicrons*1e-6, ... % specified in meters
               'LMSdensities', obj.coneLMSdensities, ...
         'heightToWidthRatio', 1.0, ...
        'coneIntegrationTime', obj.coneIntegrationTimeInMilliseconds*1e-3, ... % specified in seconds
                  'noiseFlag', 0 ...
    );

    % Eye movement params
    eyeMovementParamsStruct = struct(...
                      'name', 'saccadicEyeMovements', ...
        'samplesPerFixation', obj.eyeMicroMovementsPerFixation, ... 
                'sampleTime', 0.001, ...  % 1 milliseconds
           'tremorAmplitude', 0.0073, ...  % default value
             'overlapFactor', eyeMovementOverlapFactor ...  % 50 % overlap
    );

    currentSceneIndex = 0;
    
    for dbIndex = 1:numel(obj.sceneSet)
        sset = obj.sceneSet{dbIndex};
        
        for sceneIndex = 1:numel(sset.sceneNames)
            
            currentSceneIndex = currentSceneIndex + 1;
            allSceneNames{currentSceneIndex} = sset.sceneNames{sceneIndex};
            
            % Instantiate a new sceneProcessor
            verbosity = 10;
            sceneProcessor = ISETbioSceneProcessor(sset.dataBaseName, sset.sceneNames{sceneIndex}, verbosity);
            
            % Compute optical image (if necessary)
            sceneProcessor.computeOpticalImage(...
                              'forceRecompute', false, ...
            'visualizeResultsAsIsetbioWindows', false, ...
                    'visualizeResultsAsImages', false ...
            );
        
            randomSeedForSensor = 42385654;
            visualizeResultsAsIsetbioWindows = false;
            showEyeMovementCoverage = false;
                
            % Compute the time-varying activation of the sensor mosaic
            XTphotonAbsorptionMatrices{currentSceneIndex} = ...
                single(sceneProcessor.computeSensorActivation(...
                              'forceRecompute', true, ...
                                  'randomSeed', randomSeedForSensor, ...   % pass empty to generate new sensor or some seed to generate same sensor
                                'sensorParams', sensorParamsStruct , ...
                           'eyeMovementParams', eyeMovementParamsStruct, ...
            'visualizeResultsAsIsetbioWindows', visualizeResultsAsIsetbioWindows, ...
                     'showEyeMovementCoverage', showEyeMovementCoverage, ...
                            'saveSensorToFile', false ...
                )); 
            
            eyeMovements{currentSceneIndex} = single(sensorGet(sceneProcessor.sensor,'positions'));
            
            % extract other information for saving
            opticalImageRGBrendering{currentSceneIndex} = oiGet(sceneProcessor.opticalImage, 'rgb image');
            opticalSampleSeparation{currentSceneIndex}  = oiGet(sceneProcessor.opticalImage, 'distPerSamp','microns');
                
            sensorSampleSeparation = sensorGet(sceneProcessor.sensor,'pixel size','um');
            sensorRowsCols         = sensorGet(sceneProcessor.sensor, 'size');
            trueConeXYLocations    = sensorGet(sceneProcessor.sensor, 'xy');
            trueConeTypes          = sensorGet(sceneProcessor.sensor, 'cone type');
                
            % information for computing linear cone adaptation signal
            sensorConversionGain = pixelGet(sensorGet(sceneProcessor.sensor,'pixel'),'conversionGain');
            sensorExposureTime   = sensorGet(sceneProcessor.sensor,'exposure time');   
            sensorTimeInterval   = sensorGet(sceneProcessor.sensor, 'time interval');
        
            % clear current sceneProcessor
            varlist = {'sceneProcessor'};
            clear(varlist{:});    
        end % sceneIndex
    end % dbIndex
    
    % save data
    exportFile = sprintf('PhotonAbsorptionMatrices_%dx%d.mat', sensorParamsStruct.conesAcross,sensorParamsStruct.conesAcross);
    save(exportFile,...
        'allSceneNames', 'XTphotonAbsorptionMatrices', 'eyeMovements', ...
        'opticalImageRGBrendering', 'opticalSampleSeparation', ...
        'trueConeXYLocations', 'trueConeTypes', 'sensorRowsCols','sensorSampleSeparation', ...
        'sensorConversionGain', 'sensorExposureTime', 'sensorTimeInterval', ...
        'randomSeedForSensor',  'sensorParamsStruct', 'eyeMovementParamsStruct', ...
        '-v7.3');
    
    fprintf('Photonabsorption matrices saved in %s.\n', exportFile);
end

