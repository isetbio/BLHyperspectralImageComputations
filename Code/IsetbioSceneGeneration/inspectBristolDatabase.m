function inspectBristolDatabase

    spectralBands = [400:10:700];
    imageDir = '/Volumes/ColorShare1/hyperspectral-images-noahproject/bristol_database/brelstaff';
    imageNames = {'ashton2', 'ashton2b', 'ashton3', 'cold1', 'cold3', 'fern1', ...
                 'ferns2', 'fort04', 'fuschia', 'gleaves', ...
                 'inlab1', 'inlab2', 'inlab3', 'inlab4', 'inlab5', 'inlab7', ...
                 'jan10pm', 'jan13am', 'moss', 'pink7', ...
                 'plaza', 'red1', 'rleaves', 'rocks', 'rwood', 'valley', 'windy', 'yellow1', 'yleaves'...
                 };
    imageNames = {'ashton3'};
    
    for k = 1:numel(imageNames)
        fprintf('Now displaying components from ''%s''. \n', imageNames{k});
        greaycardLocationFile = fullfile(imageDir, imageNames{k}, 'greycard location.txt');
        fID = fopen(greaycardLocationFile,'r');
        greyCardLocationCoords = fscanf(fID, '%d', [1 2]);
        fclose(fID);
        
        gifImage = fullfile(imageDir, 'gifs', sprintf('%s.gif', imageNames{k}));
        h = figure(1);
        set(h, 'Position', [10 10 512 512]);
        imshow(gifImage);
        drawnow;
            
       
        for bandIndex = 1:numel(spectralBands)
            rawImageFile = fullfile(imageDir, imageNames{k}, sprintf('%s.%d', imageNames{k}, spectralBands(bandIndex)));
            
  
            fID = fopen(rawImageFile);
            
            header = char(fread(fID, [1 8], 'char'));
            if (~strcmp(header, 'DFIMAG10'))
                error('Header is wrong. Should start with DFIMAG10, instead it is: ', header);
            end
                
            headerLength = fread(fID, [1 4], 'char');
            imageWidth = fread(fID, [1 4], 'char');
            imageHeight = fread(fID, [1 4], 'char');
            imageType = fread(fID, [1 4], 'char');
            spare = fread(fID, [1 4], 'char');
            integrationTimeAndAperture = fread(fID, [1 4], 'char');

            A = (double(fread(fID, [256 256], 'uchar'))/256)';
            fclose(fID);

            h = figure(2);
            clf;
            set(h, 'Position', [600 10 400 400]);
            imshow(A)
            hold on;
            %plot(greyCardLocationCoords(1), greyCardLocationCoords(2), 'rs');
            axis 'image'
            drawnow;
            
        end
        
        
    end
end
