function loadReflectanceMap(obj)

    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    
    [calibrationFactors, ...
     referenceSpectumLocationR, ...
     referenceSpectumLocationB, ...
     referenceSpectumLocationP, ...
     referenceSpectumLocationG] = loadCalibrationFactors(obj);
    
    % Estimate of the illuminant incident at the reference location: multiply the reference spectrum by 1.12 at each wavelength.
    obj.illuminant.spd = referenceSpectumLocationR * 1.12;
    
    illuminationModel = loadIlluminationModel(obj);
    figure(124);
    clf;
    plot(illuminationModel.wave, illuminationModel.spd6D, 'r-');
    hold on;
    plot(obj.illuminant.wave, obj.illuminant.spd, 'ks');
    
    
    for k = 1:numel(obj.illuminant.wave)
        wavelength = obj.illuminant.wave(k);
        spectralBandDataFile = fullfile(sourceDir, obj.sceneData.reflectanceDataFileName, sprintf('%d', wavelength));
        % read raw data
        imageData = double(readImageData(spectralBandDataFile, 2020, 2020));
        % apply calibration factor
        if (k == 1)
            multispectralImage = zeros(size(imageData,1), size(imageData,2), numel(obj.illuminant.wave));
        end
        multispectralImage(:,:,k) = calibrationFactors(k) * imageData;
    end

    obj.generatePassThroughRadianceDataStruct(multispectralImage, [obj.illuminant.wave(1) obj.illuminant.wave(end)]);

end


function illuminationModel = loadIlluminationModel(obj)
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    fID = fopen(fullfile(sourceDir, 'IlluminationModel6Components.txt'));
    datacell = textscan(fID, '%d%f%f%f%f%f%f');
    illuminationModel.wave = double(datacell{1});
    illuminationModel.spd6D = double(datacell{2}) + double(datacell{3}) + double(datacell{4}) + double(datacell{5}) + double(datacell{6}) + double(datacell{7}); 
    fclose(fID);
    
end


function [calibrationFactors, ...
          referenceSpectumLocationR, ...
          referenceSpectumLocationB, ...
          referenceSpectumLocationP, ...
          referenceSpectumLocationG] = loadCalibrationFactors(obj)
      
    switch (obj.sceneData.reflectanceDataFileName)
        case 'BearFruitGrayB'
            calibrationFile = 'BlueCalibrationFactors.txt';
        case 'BearFruitGrayG'
            calibrationFile = 'GreenCalibrationFactors.txt';
        case 'BearFruitGrayR'
            calibrationFile = 'RedCalibrationFactors.txt';
        case 'BearFruitGrayY'
            calibrationFile = 'YellowCalibrationFactors.txt';
        otherwise
            error('No calibration file for scene %s.\n', obj.sceneData.reflectanceDataFileName);
    end
    
    sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
    fID = fopen(fullfile(sourceDir, calibrationFile));
    
    % reader data
    datacell = textscan(fID, '%d%f%f%f%f%f', 'HeaderLines', 2, 'CollectOutput', 1);
    fclose(fID);
    
    % get wavelengths and check for consistency
    wavelengths = double(datacell{1});
    if (any(wavelengths(:)-obj.illuminant.wave(:)))
        error('Wavelengths in correction factor vector do not agree with wavelength vector in radiance files');
    end
    
    % get the factors
    factors = datacell{2};
    calibrationFactors = squeeze(factors(:,1));
    referenceSpectumLocationR = squeeze(factors(:,2));
    referenceSpectumLocationB = squeeze(factors(:,3));
    referenceSpectumLocationP = squeeze(factors(:,4));
    referenceSpectumLocationG = squeeze(factors(:,5));
end

function imageData = readImageData(filename, width, height)
    fID = fopen(filename, 'r', 'b');
    imageData = fread(fID, [width,height], 'ushort')';
    imageData(imageData < 0) = 0;
    fclose(fID);
end

