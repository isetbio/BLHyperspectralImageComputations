function PlotMacbethChartReflectances

   for y = 0:3
       for x = 0:5
           k = (3-y)+x*4+1;
           colorSPD = sprintf('mccBabel-%d.spd',k);
           load(colorSPD);
           eval(sprintf('wave = mccBabel_%d(:,1);', k));
           eval(sprintf('reflectances(%d,:) = mccBabel_%d(:,2);', k,k));
           eval(sprintf('clear ''mccBabel_%d'';',k));
       end
   end

   colorMatchingData = load('T_xyz1931.mat');
   sensorXYZ = struct(...
            'S', colorMatchingData.S_xyz1931, ...
            'T', colorMatchingData.T_xyz1931 ...
            );
        
   D65 = load('D65.mat');
   theIlluminant = (SplineCmf(WlsToS(D65.wavelength), D65.data', WlsToS(wave)));

   
   h = figure(100);
   set(h, 'Position', [10 10 1135 553]);
   clf;
   
   colorIndex = [1:24];
   
   for k = 1:numel(colorIndex)
        theReflectance = reflectances(k,:);
        theRadiance = theReflectance .* theIlluminant;
        theRadiance = reshape(theRadiance, [1 1 numel(theRadiance)]);
        multispectralImage = repmat(theRadiance, [100,100,1]);
       
        % multispectral to XYZ
        XYZimage = MultispectralToSensorImage(multispectralImage, WlsToS(wave), sensorXYZ.T, sensorXYZ.S);
        % to cal Format
        [XYZcalFormat, nCols, mRows] = ImageToCalFormat(XYZimage);
        % compute sRGB image
        LinearSRGBcalFormat(k, :,:) = XYZToSRGBPrimary(XYZcalFormat);
   end
   
   LinearSRGBcalFormat = LinearSRGBcalFormat / max(LinearSRGBcalFormat(:));
   
   for y = 0:3
       for x = 0:5
            k = (3-y)+x*4+1;
            gammaCorrectedSRGBcalFormat = sRGB.gammaCorrect(squeeze(LinearSRGBcalFormat(k,:,:)));
            SRGBimage = CalFormatToImage(gammaCorrectedSRGBcalFormat, nCols, mRows);
            subplot(4, 6, (3-y)*6 + x + 1);
            imshow(SRGBimage, [0 1]);
            title(sprintf('mccBabel-%d', k));
       end
   end
   
end

