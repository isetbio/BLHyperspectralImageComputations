% Harvard database - specific method to populate the sceneDataStruct
function populateSceneDataStruct(obj)
    fprintf('In Harvard DataBase populateSceneDataStruct.\n');
     
    % Assemble sourceDir
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    
    obj.sceneData.referenceObjectData           = generateReferenceObjectDataStructForHarvardScenes(obj);
    obj.sceneData.knownReflectionData           = generateKnownReflectionDataStructForHarvardScenes(obj);
    obj.sceneData.reflectanceDataFileName       = obj.sceneData.name;
    obj.sceneData.spectralRadianceDataFileName  = '';
            
end

function knownReflectionData = generateKnownReflectionDataStructForHarvardScenes(obj)
	knownReflectionData = [];
    
    MacBethWhiteCheckerIndex = 4;
    colorSPD = sprintf('mccBabel-%d.spd',MacBethWhiteCheckerIndex);
    load(colorSPD);
    eval(sprintf('wave = mccBabel_%d(:,1);', MacBethWhiteCheckerIndex));
    eval(sprintf('reflectanceSPD = mccBabel_%d(:,2);', MacBethWhiteCheckerIndex,MacBethWhiteCheckerIndex));
    eval(sprintf('clear ''mccBabel_%d'';',MacBethWhiteCheckerIndex));
    
    reflectanceSPD = (SplineCmf(WlsToS(wave), reflectanceSPD', WlsToS((obj.sceneData.customIlluminant.wave)')));

    
    if (strcmp(obj.sceneData.subset, 'CZ_hsdbi'))
        switch obj.sceneData.name 
            case 'img3'
                % A4 paper on wall
                knownReflectionData.region = [682 115 718 157];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
            case 'img4'
                % white plastic bag on lower right
                knownReflectionData.region = [919 957 977 1012];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'img5'
                % white paper on wall
                knownReflectionData.region = [1216 357 1367 447];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'img6'
                % first white label
                knownReflectionData.region = [603 716 613 746];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imga3'
                % no white object in the scene
               
            case 'imga4'
                % white page on table
                knownReflectionData.region = [243 70 267 78];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imga8'
                % white page on table
                knownReflectionData.region = [1067 406 1081 414];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgc3'
                % white grout on the wall
                knownReflectionData.region = [639 323 640 416];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgc6'
                % white page on the wall
                knownReflectionData.region = [529 256 550 318];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgd0'
                % white binder
                knownReflectionData.region = [612 761 689 792];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
             
            case 'imgd1'
            % white label on package 
                knownReflectionData.region = [462 871 471 902];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgd6'
            % white envelope on the floor 
                knownReflectionData.region = [418 943 496 960];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;    
                
            case 'imgg0'   
            % white border on Stanford brochure
                knownReflectionData.region = [413 315 529 328];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;    
                
            case 'imgg1'   
            % white brick
                knownReflectionData.region = [676 22 726 56];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave; 
                
            case 'imgg2'   
            % Xrite white balance card
                knownReflectionData.region = [775 581 931 672];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave; 
                
            case 'imgg3'
            % Xrite white balance card
                knownReflectionData.region = [268 741 614 980];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
           case 'imgg4'
            % White envelope
                knownReflectionData.region = [1276 729 1278 761];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
           case 'imgg5'
           % Xrite white balance card
                knownReflectionData.region = [875 905  1024 1014];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
              
            case 'imgg6'
           % no white object on scene
           
            case 'imgg7'
            % Xrite white balance card
                knownReflectionData.region = [601 384  760 464];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
             
            case 'imgg8'
            % Xrite white balance card
                knownReflectionData.region = [518 341  780 496];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgg9'
            % Xrite white balance card
                knownReflectionData.region = [1126 473 1294 766];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'imgh4' 
            % no white object on scene    
            
            case 'imgh5' 
            % no white object on scene 
            
            case 'imgh6' 
            % no white object on scene 
            
            case 'imgh7' 
            % white outlet on the wall
                knownReflectionData.region = [202 189 217 254];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
        end
    end
    
end

% Method to generate a reference object data struct
function referenceObjectData = generateReferenceObjectDataStructForHarvardScenes(obj)

    % After emailing one of the Authors (Ayan Chakrabarti <ayanc@ttic.edu>) regarding 
    % the field of view of the Harvard imaging system, it appears that the best FOV estimate 
    % is 31.3 degrees along the diagonal. This means that the horizontal
    % field of view is 25.07 degrees.
    % They used a 60 mm lens, which should translate to a 32.5 degree diagonal field of view 
    % (for a standard DSLR / 35mm film camera). 
    %
    % FOV = 2 atan(
    % The sensor dimensions were
    % 6.71mm x 8.98mm (basically, at 6.45um per pixel). This gives a diagonal 
    % field of view of the sensor of 11.21 mm.
    % However, they also had a lens converter in front with a demagnifying element. 
    % Unfortunately, the specs of that element just say that it does a 3x demagnification. 
    % Interpreting that as a 3x increase in the effective sensor size, we'd go back to a diagonal of 33.63 mm.
    % This gives us a field of view (along the diagonal of the image) of about 31.3 degrees. 
    % But again, this is based on assumptions about what the 'demagnifier' element does, and 
    % on the hope that there isn't anything else that's non-standard in the camera's optical path.

    magnification = 3.0;
    diagonalFOV   = 31.3; % deg
    
    sensorWidthInMM  = 8.98*magnification;
    sensorHeightInMM = 6.71*magnification;
    sensorPixelsAlongWidth = 1392;
    
    phi = atan(sensorHeightInMM/sensorWidthInMM);
    horizFOV = diagonalFOV * cos(phi);
    distanceToCamera = 4.0;                      % in meters
    referenceObjectShape = 'computed from first principles';
    referenceObjectSizeInMeters = 2.0*distanceToCamera * tan(horizFOV/2/180*pi); %  8/100;        % in meters
    referenceObjectSizeInPixels = sensorPixelsAlongWidth;
    
    % arbitrary, since there was none
    referenceObjectXYpos = [];
    referenceObjectROI = [];
    
    % This should be set to different approx values for different images
    meanSceneLuminanceInCdPerM2 = 500;          
    
    % custom clipping (this should be different for different images,
    % depending on motion artifacts that we want to exclude)
    obj.sceneData.clippingRegion.x1 = 1;
    obj.sceneData.clippingRegion.x2 = Inf;
    obj.sceneData.clippingRegion.y1 = 1;
    obj.sceneData.clippingRegion.y2 = Inf;
    
    if (strcmp(obj.sceneData.subset, 'CZ_hsdb'))
        switch obj.sceneData.name 
            case 'imgb4'
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 600;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;
                
            case 'imgb7'
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 736;
                obj.sceneData.clippingRegion.y2 = Inf;
               
            case 'imgb8'
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 762;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;
                
            case 'imgc9'
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 976;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = 855;
                
            case 'imge0'
                obj.sceneData.clippingRegion.x1 = 306;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;  
                
            case 'imge1'
                obj.sceneData.clippingRegion.x1 = 472;
                obj.sceneData.clippingRegion.x2 = 1144;
                obj.sceneData.clippingRegion.y1 = 187;
                obj.sceneData.clippingRegion.y2 = 983;  
                
            case 'imge2'
                obj.sceneData.clippingRegion.x1 = 383;
                obj.sceneData.clippingRegion.x2 = 1013;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;  
                
            case 'imge7'
                obj.sceneData.clippingRegion.x1 = 626;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf; 
                
            case 'imgf3'
                obj.sceneData.clippingRegion.x1 = 791;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf; 
                
            case 'imgf8'
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 1230;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;     
                
        end
    end
    
    % custom illuminant
    obj.sceneData.customIlluminant.name         = 'D65';
    obj.sceneData.customIlluminant.wave         = 420:10:720;
    obj.sceneData.customIlluminant.meanSceneLum = meanSceneLuminanceInCdPerM2;

   
    referenceObjectData = struct(...
         'spectroRadiometerReadings', struct(...
            'xChroma',      nan, ...              
            'yChroma',      nan, ...              
            'Yluma',        nan,  ...           
            'CCT',          nan   ... 
            ), ...
         'paintMaterial', struct(), ...  % No paint material available
         'geometry', struct( ...         % Geometry of the reference object
            'shape',            referenceObjectShape, ...
            'distanceToCamera', distanceToCamera, ...            % meters
            'sizeInMeters',     referenceObjectSizeInMeters,...  % estimated manually from the picture
            'sizeInPixels',     referenceObjectSizeInPixels,...  % estimated manually from the picture
            'roiXYpos',         referenceObjectXYpos, ...        % pixels (center)
            'roiSize',          referenceObjectROI ...           % pixels (halfwidth, halfheight)
         ), ...
         'info', [] ...
    ); 

end
