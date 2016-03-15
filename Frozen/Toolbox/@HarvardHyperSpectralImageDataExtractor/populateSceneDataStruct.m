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

    if (strcmp(obj.sceneData.subset, 'CZ_hsdb'))
        switch obj.sceneData.name 
            case 'img1'
                % snow region
                xx = 595;
                yy = 336;
                knownReflectionData.region = [xx yy xx + 20 yy+20];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
            case 'img2'
                % snow region
                xx = 458;
                yy = 679;
                knownReflectionData.region = [xx yy xx + 20 yy+20];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
               
           case 'imga2'
                % track region
                xx = 886;
                yy = 451;
                knownReflectionData.region = [xx yy xx + 20 yy+20];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
           case 'imgc7'
               % snow region
                xx = 132;
                yy = 895;
                knownReflectionData.region = [xx yy xx + 20 yy+20];
                knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
                knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
                
          case 'imgh1' 
              % Xrite white balance card
              xx = 1250;
              yy = 550;
              knownReflectionData.region = [xx yy xx + 20 yy+20];
              knownReflectionData.nominalReflectanceSPD = reflectanceSPD;
              knownReflectionData.wave = obj.sceneData.customIlluminant.wave;
        end
        
    elseif (strcmp(obj.sceneData.subset, 'CZ_hsdbi'))
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
    
    
    
    % arbitrary, since there was none
    referenceObjectXYpos = [];
    referenceObjectROI = [];
    
    
    % custom clipping (this should be different for different images,
    % depending on motion artifacts that we want to exclude)
    obj.sceneData.clippingRegion.x1 = 1;
    obj.sceneData.clippingRegion.x2 = Inf;
    obj.sceneData.clippingRegion.y1 = 1;
    obj.sceneData.clippingRegion.y2 = Inf;
    
    % Nicolas' description of what the images depict
    imageInfo = [];
    [obj.sceneData.subset ' / ' obj.sceneData.name]
    
    if (strcmp(obj.sceneData.subset, 'CZ_hsdbi'))
        
        distanceToCamera = 4.0;  % in meters
        illuminantName = 'D65';
        
        switch obj.sceneData.name 
            case 'img3'
                imageInfo = 'Office area. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
            case 'img4'
                imageInfo = 'Bicycle against wall. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
            case 'img5'
                imageInfo = 'Desk with computer monitor and red book. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
            case 'img6'
                imageInfo = 'Shelves with storage bins. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
            case 'imga3'
                imageInfo = 'Chair on green carpet floor. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
             
           case 'imga4'
                imageInfo = 'Office area with green carpet floor. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
           case 'imga8'
                imageInfo = 'Office ares with red chair. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
           case 'imgc3'
                imageInfo = 'Wall. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgc6'
                imageInfo = 'Walls and windows. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgd0'
                imageInfo = 'Shelf with books, Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgd1'
                imageInfo = 'Storage room. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgd5'
                imageInfo = 'Mailroom scene. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                
           case 'imgd6'
                imageInfo = 'Carpeted floor with plant. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg0'
                imageInfo = 'Cork wall with pinned documents. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';     
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg1'
                imageInfo = 'Carpeted corridor with chairs. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';  
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg2'
                imageInfo = 'Office area with Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg3'
                imageInfo = 'Office wall with Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg4'
                imageInfo = 'Mailroom. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg5'
                imageInfo = 'Desk area with Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg6'
                imageInfo = 'Orange wood wall and yellow chair. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.'; 
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg7'
                imageInfo = 'Sitting area with red chairs and Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg8'
                imageInfo = 'Room with blackboard, chair and Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgg9'
                imageInfo = 'Office are with recycling bins. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgh4'
                imageInfo = 'Yellow Chairs. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgh5'
                imageInfo = 'Lounge with leather and fabric chairs. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgh6'
                imageInfo = 'Yellow desk and chair. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.';    
                meanSceneLuminanceInCdPerM2 = 200;
                 
           case 'imgh7'
                imageInfo = 'Wooden wall and floor. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to 4.0m, arbitrarily. Illuminant set to D65 with 200 cd/m2 mean luminance.'; 
                meanSceneLuminanceInCdPerM2 = 200;
           end
     end
     
    if (strcmp(obj.sceneData.subset, 'CZ_hsdb'))
        switch obj.sceneData.name 
            case 'img1'
                meanSceneLuminanceInCdPerM2 = 500;
                distanceToCamera = 40.0;  % in meters
                illuminantName = 'D75'; 
                imageInfo = sprintf('Snowed building roof. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
            
            case 'img2'
                meanSceneLuminanceInCdPerM2 = 500;
                distanceToCamera = 100.0;  % in meters
                illuminantName = 'D75';
                imageInfo = sprintf('Snowed street view with trees, buildings. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
            
                
            case 'imga1'
                meanSceneLuminanceInCdPerM2 = 1000;
                distanceToCamera = 100.0;  % in meters
                illuminantName = 'D65';
                imageInfo = sprintf('Buildings with trees in front. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
            
                
            case 'imga2'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Corner of a building, truck, strong shadows. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
            
                
            case 'imga5'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Room ceiling. Indoors. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);

            case 'imga6'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Asphalt walkway with bushes and sitting benches. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
            case 'imga7'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building wall. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);

            case 'imgb1'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Brick and stone building wall. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
            case 'imgb2'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building, trees, and parking area with cars. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
                
            case 'imgb3'
                distanceToCamera = 40.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Buildings, trees, and parking area with cars. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
                
            case 'imgb4'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Bushes, tree branches. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 600;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;
                
            case 'imgb5'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Beautiful and intricate stone bulding door. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
            case 'imgb6'
                distanceToCamera = 5.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Grassy area with brown soil, tree trunk and stone plaque. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
             
                
            case 'imgb7'
                distanceToCamera = 50.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Building with tree branches in front. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 736;
                obj.sceneData.clippingRegion.y2 = Inf;
               
            case 'imgb8'
                distanceToCamera = 80.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Buildings with tree branches in front. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
             
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 762;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;
                
            case 'imgb9'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building with brick walkway. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                
            case 'imgc1'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D75';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building wall. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                 
            case 'imgc2'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Room floor and wall. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);

            case 'imgc4'
                distanceToCamera = 60.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('House with backyard. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
              
            case 'imgc5'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building wall and pavement. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
  
            case 'imgc7'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('House deck with wood chairs and fence. Trees, snow. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                 
            case 'imgc8'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('University hall with glass walls, chairs. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);
                 
            case 'imgc9'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('House roof and siding, tree branches. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 976;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = 855;
                
            case 'imgd2'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Desk. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                 
            case 'imgd3'
                distanceToCamera = 3.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Shelves. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                 
            case 'imgd4'
                distanceToCamera = 1.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Desk with water bottle, book. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

            case 'imgd7'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Wall tiled with pinned documents. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                 
            case 'imgd8'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Room corner with orange wall and tall plant. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
            
            case 'imgd9'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Room corner with short plant. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
            
                 
            case 'imge0'
                distanceToCamera = 15.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Buildings, large wooden barrel. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 306;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;  
                
            case 'imge1'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Part of building with intricate roof decoration. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 472;
                obj.sceneData.clippingRegion.x2 = 1144;
                obj.sceneData.clippingRegion.y1 = 187;
                obj.sceneData.clippingRegion.y2 = 983;  
                
            case 'imge2'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Tree trunk. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 383;
                obj.sceneData.clippingRegion.x2 = 1013;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;  
              
            case 'imge3'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Building with windows and tree shadows. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
    
                
            case 'imge4'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building door and columns. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imge5'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building with windows, tree branches. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
            case 'imge6'
                distanceToCamera = 30.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building entrance, tree branches. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
            case 'imge7'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Metal statue against building stone wall. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 626;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf; 
                
            case 'imgf1'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building with red car in shadow. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imgf2'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Building with trees in front. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                

            case 'imgf3'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Building with large windows. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 791;
                obj.sceneData.clippingRegion.x2 = Inf;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf; 
                
            case 'imgf4'
                distanceToCamera = 40.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Large building against blue sky. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imgf5'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 500;
                imageInfo = sprintf('Bicycles against building wall. Overcast day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
            case 'imgf6'
                distanceToCamera = 10.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Grassy area with bush and red fire hose. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imgf7'
                distanceToCamera = 20.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Building entrace. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
            case 'imgf8'
                distanceToCamera = 4.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 1000;
                imageInfo = sprintf('Building with red fruit-carrying bush in front of it. Sunny day. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                obj.sceneData.clippingRegion.x1 = 1;
                obj.sceneData.clippingRegion.x2 = 1230;
                obj.sceneData.clippingRegion.y1 = 1;
                obj.sceneData.clippingRegion.y2 = Inf;     
                
            case 'imgh0'
                distanceToCamera = 1.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Magazine shelves. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imgh1'
                distanceToCamera = 1.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Desktop computer with Xrite white balance card. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
            case 'imgh2'
                distanceToCamera = 1.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Shelf with books. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            
                
            case 'imgh3'
                distanceToCamera = 2.0;  % in meters
                illuminantName = 'D65';
                meanSceneLuminanceInCdPerM2 = 200;
                imageInfo = sprintf('Rotating chair and bookshelves. Indoors. Field of view set manually after personnal communication with Ayan Chakrabarti <ayanc@ttic.edu>. Camera distance set to %2.0fm, arbitrarily. Illuminant set to %s with %2.0f cd/m2 mean luminance.', distanceToCamera, illuminantName, meanSceneLuminanceInCdPerM2);            

                
        end
    end
    
    % spatial size information
    referenceObjectShape = 'computed from first principles';
    referenceObjectSizeInMeters = 2.0*distanceToCamera * tan(horizFOV/2/180*pi);    % in meters
    referenceObjectSizeInPixels = sensorPixelsAlongWidth;
    
    
    % custom illuminant
    obj.sceneData.customIlluminant.name         = illuminantName;
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
         'info', imageInfo ...
    ); 

end
