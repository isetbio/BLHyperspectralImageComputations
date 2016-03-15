function demoReinhardtToneMap

   % specify some input luminance values
   minLuminance = 0.01; maxLuminance = 10000; distinctLuminanceValues = 500;
   luminanceVector = linspace(minLuminance , maxLuminance, distinctLuminanceValues);
   
   % free parameter - alpha (specifies how steep the tone mapping is). Select a range for it
   minAlpha = 0.01; maxAlpha = 100.0; alphasNum = 15;
   alphas = logspace(log10(minAlpha),log10(maxAlpha),alphasNum);
   
   % new figure
   h = figure(1); clf; set(h, 'Position', [100 100 1230 900]);
   
   for alphaIndex = 1:numel(alphas)  
       % get an alpha value
       alpha = alphas(alphaIndex);
       
       % tone map input luminance according to this alpha
       delta = 0.0001; % small delta to avoid taking log(0) when encountering pixels with zero luminance
       sceneKey = exp((1/numel(luminanceVector))*sum(log(luminanceVector + delta)));
       mean(luminanceVector)
       scaledInputLuminanceVector = alpha / sceneKey * luminanceVector;
       toneMappedLuminanceVector = scaledInputLuminanceVector ./ (1.0+scaledInputLuminanceVector);
       toneMappedLuminanceVector = toneMappedLuminanceVector / max(toneMappedLuminanceVector) * max(luminanceVector);
       
       % Plot tonemapped luminance vs input luminance
       subplot(3,5,alphaIndex);
       plot(luminanceVector, toneMappedLuminanceVector, 'r-', 'LineWidth', 2.0);
       hold on;
       plot([0 max(luminanceVector)], [0 max(luminanceVector)], 'k-');
       hold off;
       set(gca, 'XLim', [0 max(luminanceVector)], 'YLim', [0 max(luminanceVector)]);
       axis 'square'
       xlabel('input luminance');
       ylabel('tone mapped luminance');
       title(sprintf('alpha = %2.2f\n', alpha));
   end
end