% Function to generate an isetbio scene object from raw hyper-spectral image data.
%
% Usage:
%       scene = sceneFromHyperSpectralImageData(...
%        'sceneName',            'theSceneName', ...
%        'wave',                 (400:10:720)', ...      % column vector (Nx1) with wavelength spectral axis
%        'illuminantEnergy',     illuminantVector, ...   % column vector (Nx1) with scene's illuminant energy in Watts/steradian/m^2/nm
%        'radianceEnergy',       radianceMap, ...        % (rows x cols x N) matrix of scene's radiant energy in Watts/steradian/m^2/nm
%        'sceneDistance',        1.4, ...                % distance from camera to the scene in meters
%        'scenePixelsPerMeter',  44.53*100 ...           % image pixels / scene meter 
%    );
%
% 4/27/2015  npc  Wrote it.
%


function scene = sceneFromHyperSpectralImageData(varargin)
    % Set all expected input arguments to empty
    sceneName      = '';
    wave           = [];
    illuminantEnergy = [];
    radianceEnergy = [];
    sceneDistance  = [];
    scenePixelsPerMeter = [];
    % Generate parser object to parse the input arguments and validate them
    parser = inputParser;
    parser.addParamValue('sceneName',           sceneName,              @ischar);
    parser.addParamValue('wave',                wave,                   @isvector);
    parser.addParamValue('illuminantEnergy',    illuminantEnergy,       @isvector);
    parser.addParamValue('radianceEnergy',      radianceEnergy,         @(x) (ndims(x)==3));
    parser.addParamValue('sceneDistance',       sceneDistance,          @isnumeric);
    parser.addParamValue('scenePixelsPerMeter', scenePixelsPerMeter,    @isnumeric);
    % Execute the parser to make sure input is good
    parser.parse(varargin{:});
    pNames = fieldnames(parser.Results);
    for k = 1:length(pNames)
       p.(pNames{k}) = parser.Results.(pNames{k});
       if (isempty(p.(pNames{k})))
           error('Required input argument ''%s'' was not passed', p.(pNames{k}));
       end
    end
    
    % Create scene object
    scene = sceneCreate('multispectral');
    
    % Set the name
    scene = sceneSet(scene,'name', p.sceneName);   
    
    % Set the spectal sampling
    scene = sceneSet(scene,'wave', p.wave);
    
    % Generate isetbio illuminant struct for the scene
    sceneIlluminant = illuminantCreate('d65', p.wave);
    sceneIlluminant = illuminantSet(sceneIlluminant,'name', sprintf('%s-illuminant', p.sceneName));
    sceneIlluminant = illuminantSet(sceneIlluminant,'photons', Energy2Quanta(p.wave, p.illuminantEnergy));
    % Set the scene's illuminant
    scene = sceneSet(scene,'illuminant',sceneIlluminant);
    
    % Set the scene radiance (in photons/steradian/m^2/nm)
    scene = sceneSet(scene,'photons', Energy2Quanta(p.wave, p.radianceEnergy));
    
    meanSceneLuminanceFromIsetbio = sceneGet(scene, 'mean luminance');
    fprintf('ISETBIO''s estimate of mean scene luminance: %2.2f cd/m2\n', meanSceneLuminanceFromIsetbio);
    
    % Set the scene distance
    scene = sceneSet(scene, 'distance', p.sceneDistance);
    
    % Set the angular width (in degrees)
    sceneWidthInMeters  = size(p.radianceEnergy,2) / p.scenePixelsPerMeter;
    sceneWidthInDegrees = 2.0 * atan( 0.5*sceneWidthInMeters / p.sceneDistance)/pi * 180; 
    scene = sceneSet(scene, 'wAngular', sceneWidthInDegrees);
end