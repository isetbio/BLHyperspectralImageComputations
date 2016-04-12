function test

sensorLMS = core.loadStockmanSharpe2DegFundamentals();
wave = SToWls(sensorLMS.S);
fundamentals = (sensorLMS.T)';
fundamentals = fundamentals(2:end-50,:);
wave = wave(2:end-50);
d = displayCreate('LCD-Apple', 'wave', wave);
gain = 10;
phosphors = d.spd*gain;


contrast = 0.20
LMSback = [0.3135608, 0.2671208, 0.1670198];
Linc  = [LMSback(1)*(1+contrast ) LMSback(2) LMSback(3)];
Ldec  = [LMSback(1)*(1-contrast ) LMSback(2) LMSback(3)];
LincRGB  = lms2rgb(phosphors,fundamentals,Linc);
LdecRGB  = lms2rgb(phosphors,fundamentals,Ldec);
[min(LincRGB) max(LincRGB)]
[min(LdecRGB) max(LdecRGB)]

Minc  = [LMSback(1) LMSback(2)*(1+contrast ) LMSback(3)];
Mdec  = [LMSback(1) LMSback(2)*(1-contrast ) LMSback(3)];
MincRGB  = lms2rgb(phosphors,fundamentals,Minc);
MdecRGB  = lms2rgb(phosphors,fundamentals,Mdec);
[min(MincRGB) max(MincRGB)]
[min(MdecRGB) max(MdecRGB)]

contrast = 0.8
Sinc  = [LMSback(1) LMSback(2) LMSback(3)*(1+contrast )];
Sdec  = [LMSback(1) LMSback(2) LMSback(3)*(1-contrast )];
SincRGB  = lms2rgb(phosphors,fundamentals,Sinc);
SdecRGB  = lms2rgb(phosphors,fundamentals,Sdec);
[min(SincRGB) max(SincRGB)]
[min(SdecRGB) max(SdecRGB)]


LincRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(LincRGB, [1 1 3]));
LdecRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(LdecRGB, [1 1 3]));
MincRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(MincRGB, [1 1 3]));
MdecRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(MdecRGB, [1 1 3]));
SincRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(SincRGB, [1 1 3]));
SdecRGBimage = zeros(64,64,3) + bsxfun(@times, ones(64,64,3), reshape(SdecRGB, [1 1 3]));



stimImage = zeros(256,256,3) + bsxfun(@times, ones(256,256,3), reshape(LMSback, [1 1 3]));
stimImage(16+(1:64), 48+(1:64), :) = LincRGBimage;
stimImage(16+(1:64), 132+(1:64), :) = LdecRGBimage;

stimImage(96+(1:64), 48+(1:64), :) = MincRGBimage;
stimImage(96+(1:64), 132+(1:64), :) = MdecRGBimage;

stimImage(178+(1:64), 48+(1:64), :) = SincRGBimage;
stimImage(178+(1:64), 132+(1:64), :) = SdecRGBimage;

figure(1); clf;
imshow(stimImage.^(1/2.2));
set(gca, 'CLim', [0 1])
axis 'ij'; axis 'image';


drawnow;
end


function [rgb] = lms2rgb(phosphors,fundamentals,lms)
%phosphors is an n by 3 matrix containing 
% *** the three spectral power distributions of the display device
% *** fundamentals is an n x 3 matrix containing
% *** the lms are the cone spectral sensitivities.
    rgb = inv(fundamentals'*phosphors) * reshape(lms, [3 1]);
end

function [lms] = rgb2lms(phosphors,fundamentals,rgb)
    lms = (fundamentals'*phosphors) * reshape(rgb, [3 1]);
end



function imageXYZ = lms2xyz(imageLMS, LMSscaling)
    XYZtoLMSmatrix = [...
        0.17156  0.52901 -0.02199; ...
       -0.15955  0.48553  0.04298; ...
        0.01916 -0.03989  1.03993];
    
    [tmpLMS, nCols, mRows] = ImageToCalFormat(imageLMS);
    
    tmpXYZ =  inv(XYZtoLMSmatrix) * diag(LMSscaling)  * tmpLMS;
    imageXYZ = CalFormatToImage(tmpXYZ, nCols, mRows);
end

function imageLMS = xyz2lms(imageXYZ, LMSscaling)
    XYZtoLMSmatrix = [...
        0.17156  0.52901 -0.02199; ...
       -0.15955  0.48553  0.04298; ...
        0.01916 -0.03989  1.03993];
    
    [tmpXYZ, nCols, mRows] = ImageToCalFormat(imageXYZ);
  
    tmpLMS = diag(LMSscaling) * XYZtoLMSmatrix  * tmpXYZ;
    imageLMS = CalFormatToImage(tmpLMS, nCols, mRows);
end

