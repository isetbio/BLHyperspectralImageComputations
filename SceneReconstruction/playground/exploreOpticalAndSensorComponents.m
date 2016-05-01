function exploreOpticalAndSensorComponents

    customOpticsParams = struct(...
        'offAxisIlluminationFallOff', false, ...      % true  (default off-axis) or false (none)
        'opticalTransferFunctionBased', false, ...    % true  (default, shift-invariant OTF) or false (diffraction-limited)
        'customFNumber', 1 ...                        % empty (for default fNumber) or an fNumber
        );
    
    customSensorParams = struct(...
        'customLensOpticalDensity', 0, ...             % empty (for default lens density) or a lens density number in [0..1]
        'customMacularOpticalDensity', 0, ...          % empty (for default macular density) or a macular density number in [0..1]
        'customConeOpticalDensities', [0.5 0.5 0.5], ...    % empty (for default peak optical pigment densities) or a [3x1] vector in [0 .. 0.5]
        'size', [128 128] ...
        );
    
%     customOpticsParams = struct(...
%         'offAxisIlluminationFallOff', true, ...      % true  (default off-axis) or false (none)
%         'opticalTransferFunctionBased', true, ...    % true  (default, shift-invariant OTF) or false (diffraction-limited)
%         'customFNumber', [] ...                        % empty (for default fNumber) or an fNumber
%         );
%     
%     customSensorParams = struct(...
%         'customLensOpticalDensity', [], ...             % empty (for default lens density) or a lens density number in [0..1]
%         'customMacularOpticalDensity', [], ...          % empty (for default macular density) or a macular density number in [0..1]
%         'customConeOpticalDensities', [], ...    % empty (for default peak optical pigment densities) or a [3x1] vector in [0 .. 0.5]
%         'size', [128 128] ...
%         );
    
    
    % Generate custom human optics
    oi = oiCreate('human');
    oi = customizeOptics(oi, customOpticsParams);
 
    % Generate custom human sensor
    sensor = sensorCreate('human');
    sensor = customizeSensor(sensor, customSensorParams);
    
    % Load some scene 
    scene = loadScene();
    
    % Compute optical image
    oi = oiCompute(oi, scene);
    
    % Resample optical image to 1/2 cone spacing
    spatialSample = 3/2.0;
    oi = oiSpatialResample(oi, spatialSample, 'um', 'linear', false);
    
    % Compute cone isomerizations
    sensor = coneAbsorptions(sensor, oi, sensor);
    
    % Plot results
    plotResults(scene, oi, sensor)
end

function plotResults(scene, oi, sensor)
    figure(1); clf;
    
    subplot(3,3,1);
    imshow(sceneGet(scene, 'RGB'));
    title('scene');
    
    subplot(3,3,2);
    imshow(oiGet(oi, 'RGB'));
    title('optical image');
    
    subplot(3,3,4)
    title('optics transmittance')
    
    subplot(3,3,5)
    
    subplot(3,3,7);
    lensTransmittance = lensGet(sensorGet(sensor, 'human lens'), 'transmittance');
    macularTransmittance = macularGet(sensorGet(sensor, 'human macular'), 'transmittance');
    wavelengthAxis = sensorGet(sensor, 'wave');
    plot(wavelengthAxis, lensTransmittance, 'r-');
    hold on;
    plot(wavelengthAxis, macularTransmittance, 'b-');
    hold off;
    set(gca, 'YLim', [0 1.1]);
    title('Lens and macular transmittance functions');
     
     
    subplot(3,3,8);
    coneQuantalEfficiencies = sensorGet(sensor, 'spectral qe');
    wavelengthAxis = sensorGet(sensor, 'wave');
    plot(wavelengthAxis, coneQuantalEfficiencies);
    title('Cone quantal efficiencies');
       
    
    % Get isomerization maps for each cone
    [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap] = retrieveIsomerizationMaps(sensor);
    maxIsomerizations = max([max(LconeIsomerizationMap(:)) max(MconeIsomerizationMap(:)) max(SconeIsomerizationMap(:))]);
    minIsomerizations = min([min(LconeIsomerizationMap(:)) min(MconeIsomerizationMap(:)) min(SconeIsomerizationMap(:))]);
    
    subplot(3,3,3);
    imagesc(LconeIsomerizationMap);
    set(gca, 'CLim', [minIsomerizations maxIsomerizations]);
    axis 'image'
    title('L-cone isomerization map');
    
    
    subplot(3,3,6);
    imagesc(MconeIsomerizationMap);
    set(gca, 'CLim', [minIsomerizations maxIsomerizations]);
    axis 'image'
    title('M-cone isomerization map');
    
    subplot(3,3,9);
    imagesc(SconeIsomerizationMap);
    set(gca, 'CLim', [minIsomerizations maxIsomerizations]);
    axis 'image'
    title('S-cone isomerization map');
    
end



function [LconeIsomerizationMap, MconeIsomerizationMap, SconeIsomerizationMap] = retrieveIsomerizationMaps(sensor)
    isomerizationRate = sensorGet(sensor, 'photon rate');
    coneTypes = sensorGet(sensor, 'cone type');
    LconeIndices = find(coneTypes == 2);
    MconeIndices = find(coneTypes == 3);
    SconeIndices = find(coneTypes == 4);
    LconeIsomerizationMap = 0*isomerizationRate;
    MconeIsomerizationMap = 0*isomerizationRate;
    SconeIsomerizationMap = 0*isomerizationRate;
     
    LconeIsomerizationMap(LconeIndices) = isomerizationRate(LconeIndices);
    MconeIsomerizationMap(MconeIndices) = isomerizationRate(MconeIndices);
    SconeIsomerizationMap(SconeIndices) = isomerizationRate(SconeIndices);
end

function sensor = customizeSensor(sensor, sensorParams)

    % Generate defaultSensor
    defaultSensor = sensorCreate('human');
    
    humanLens = sensorGet(sensor, 'human lens');
    humanMacula = sensorGet(sensor, 'human macular');
    humanCone = sensorGet(sensor, 'human cone');
    
    if (isfield(sensorParams, 'customLensOpticalDensity'))
        defaultLens = sensorGet(defaultSensor, 'human lens');
        defaultLensDensity = lensGet(defaultLens, 'density');
        if isempty(sensorParams.customLensOpticalDensity)    
            humanLens = lensSet(humanLens, 'density', defaultLensDensity);
        else
            humanLens = lensSet(humanLens, 'density', sensorParams.customLensOpticalDensity);
        end
    end
    
    if (isfield(sensorParams, 'customMacularOpticalDensity'))
        defaultMacular = sensorGet(defaultSensor, 'human macular');
        defaultMacularDensity = macularGet(defaultMacular, 'density');
        if isempty(sensorParams.customMacularOpticalDensity)    
            humanMacula = macularSet(humanMacula, 'density', defaultMacularDensity);
        else
            humanMacula = macularSet(humanMacula, 'density', sensorParams.customMacularOpticalDensity);
        end
    end
    
    if (isfield(sensorParams, 'customConeOpticalDensities'))
        defaultHumanCone = sensorGet(defaultSensor, 'human cone');
        defaultPODs = coneGet(defaultHumanCone, 'pods');
        if isempty(sensorParams.customConeOpticalDensities)    
            humanCone = coneSet(humanCone, 'pods', defaultPODs);
        else
            humanCone = coneSet(humanCone, 'pods', reshape(sensorParams.customConeOpticalDensities, [3 1]));
        end
    end
    
    if (isfield(sensorParams, 'size'))
        sensor = sensorSet(sensor, 'size', sensorParams.size);
    end
    
    sensor = sensorSet(sensor, 'human lens', humanLens);
    sensor = sensorSet(sensor, 'human macular', humanMacula);
    sensor = sensorSet(sensor, 'human cone', humanCone);
        
    
end


function oi = customizeOptics(oi, opticsParams)

    % Get the default optics
    defaultOI = oiCreate('human');
    defaultOptics = oiGet(defaultOI, 'optics');
            
    % Get the optics
    optics = oiGet(oi, 'optics');

    % off-axis illumination falloff
    if (isfield(opticsParams, 'employOffAxisIlluminationFallOff'))
        if (opticsParams.offAxisIlluminationFallOff == false)
            optics = opticsSet(optics, 'off axis method', 'skip');
        else
            defaultOffAxisMethod = opticsGet(defaultOptics, 'off axis method');
            optics = opticsSet(optics, 'off axis method', defaultOffAxisMethod);
        end
    end
    
    % optics model: shift invariant (OTF) or diffraction limited
    if (isfield(opticsParams, 'opticalTransferFunctionBased'))
        if (opticsParams.opticalTransferFunctionBased == false)
            optics = opticsSet(optics, 'model', 'diffraction limited');
        else
            optics = opticsSet(optics, 'model', 'shift invariant');
        end
    end
    
    % fNumber: custom or default 
    if (isfield(opticsParams, 'customFNumber'))
        if isempty(opticsParams.customFNumber) 
            defaultFNumber = opticsGet(defaultOptics, 'fNumber');
            optics = opticsSet(optics, 'fNumber', defaultFNumber);
        else
            optics  = opticsSet(optics, 'fNumber', opticsParams.customFNumber);
        end
    end
    
    % set back the customized optics
    oi = oiSet(oi,'optics', optics);
end


function sceneData = loadScene()
    % Set up remote data toolbox client
    remoteDataToolboxClient = RdtClient(getpref('HyperSpectralImageIsetbioComputations','remoteDataToolboxConfig')); 
    imsource = {'manchester_database', 'scene1'};
    remoteDataToolboxClient.crp(sprintf('/resources/scenes/hyperspectral/%s', imsource{1}));
    [d, artifactInfo] = remoteDataToolboxClient.readArtifact(imsource{2}, 'type', 'mat');
    if ismember('scene', fieldnames(d))
        sceneData = d.scene;
    else
        fprintf(' Scene contains compressed data. Uncompressing ...');
        sceneData = sceneFromBasis(d);
    end
    fprintf('Done fetching scene data.\n');
end