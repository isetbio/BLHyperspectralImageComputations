% Stanford database - specific method to load the reflectance map
function loadReflectanceMap(obj)
   
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    load(fullfile(sourceDir, obj.sceneData.reflectanceDataFileName), 'photons');

    % Compute radiance energy
    radianceEnergy = Quanta2Energy(obj.illuminant.wave, double(photons));
    
    % defaults
    customIlluminant = [];
    
    % Apply different illuminant for faces images (search name for male/female substring)
    if (strfind(lower(obj.sceneData.name), 'male'))
        fprintf('Face image. Applying D65 illuminant.\n');
        customIlluminant = ieReadSpectra('D65.mat',obj.illuminant.wave);
        
        % avoid using parts of the illuminant with very low energy
        illuminantEnergyThreshold = 0.001;
        
        % check the custom illuminant for near-zero values
        zeroIndices = find(customIlluminant < illuminantEnergyThreshold*max(customIlluminant));
        if (~isempty(zeroIndices))
            spectralIndices = setdiff((1:numel(obj.illuminant.wave)), zeroIndices);
            radianceEnergy = radianceEnergy(:,:, spectralIndices);
            obj.illuminant.wave = obj.illuminant.wave(spectralIndices);
            obj.illuminant.spd = obj.illuminant.spd(spectralIndices);
            customIlluminant = customIlluminant(spectralIndices);
            
            % also check the default illuminant for near-zero values
            zeroIndices = find(obj.illuminant.spd < illuminantEnergyThreshold*max(obj.illuminant.spd));
            if (~isempty(zeroIndices))
                spectralIndices = setdiff((1:numel(obj.illuminant.spd)), zeroIndices);
                radianceEnergy = radianceEnergy(:,:, spectralIndices);
                obj.illuminant.wave = obj.illuminant.wave(spectralIndices);
                obj.illuminant.spd = obj.illuminant.spd(spectralIndices);
                customIlluminant = customIlluminant(spectralIndices);
            end
        end
        
        % make custom illuminant have same mean as default illuminant
        customIlluminant = customIlluminant / max(customIlluminant) * max(obj.illuminant.spd);
    end
    
    obj.generatePassThroughRadianceDataStruct(radianceEnergy, customIlluminant);
end

