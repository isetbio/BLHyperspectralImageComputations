function [contrastSequence, resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons] = subSampleSpatially(originalContrastSequence, subSampledSpatialGrid, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, displaySceneSampling, figHandle)
    
    if (numel(subSampledSpatialGrid) ~= 2)
        subSampledSpatialGrid
        error('Expecting a 2 element vector');
    end
    
    if ((subSampledSpatialGrid(1) == 1) && (subSampledSpatialGrid(2) == 1))
        xRange = numel(spatialXdataInRetinalMicrons) * (spatialXdataInRetinalMicrons(2)-spatialXdataInRetinalMicrons(1));
        yRange = numel(spatialYdataInRetinalMicrons) * (spatialYdataInRetinalMicrons(2)-spatialYdataInRetinalMicrons(1));
        fprintf('Original spatial data %d x %d, covering an area of %2.2f x %2.2f microns.\n', numel(spatialXdataInRetinalMicrons), numel(spatialYdataInRetinalMicrons), xRange, yRange);
        fprintf('Will downsample to [1 x 1].\n');
        contrastSequence = mean(originalContrastSequence,1);
        resampledSpatialXdataInRetinalMicrons = 0;
        resampledSpatialYdataInRetinalMicrons = 0;
    else

        resampledSpatialXdataInRetinalMicrons = linspace(spatialXdataInRetinalMicrons(1), spatialXdataInRetinalMicrons(end), subSampledSpatialGrid(1));
        resampledSpatialYdataInRetinalMicrons = linspace(spatialYdataInRetinalMicrons(1), spatialYdataInRetinalMicrons(end), subSampledSpatialGrid(2));
        contrastSequence = zeros(numel(resampledSpatialXdataInRetinalMicrons)*numel(resampledSpatialYdataInRetinalMicrons), size(originalContrastSequence,2));

        [Xo,Yo] = meshgrid(spatialXdataInRetinalMicrons,spatialYdataInRetinalMicrons);
        [Xr,Yr] = meshgrid(resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons);
        method = 'linear';
        
        
        for tBin = 1:size(originalContrastSequence,2)
           originalFrame = reshape(squeeze(originalContrastSequence(:,tBin)), [numel(spatialYdataInRetinalMicrons) numel(spatialXdataInRetinalMicrons)]);
           resampledFrame = interp2(Xo,Yo,originalFrame,Xr,Yr,method);
           contrastSequence(:,tBin) = resampledFrame(:);
           
           if (displaySceneSampling)
               figure(figHandle);
               colormap(gray(512));
               cLim = [0 max([max(abs(originalFrame(:))) max(abs(resampledFrame(:)))])];
               if (tBin == 1)
                   gca1 = subplot(1,3,2);
                   p1 = imagesc(spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, originalFrame, cLim);
                   axis 'image'
                   gca2 = subplot(1,3,3);
                   p2 = imagesc(resampledSpatialXdataInRetinalMicrons, resampledSpatialYdataInRetinalMicrons, resampledFrame, cLim);
                   axis 'image'
               else
                   set(p1, 'CData', originalFrame);  set(gca1, 'CLim', cLim);
                   set(p2, 'CData', resampledFrame); set(gca2, 'CLim', cLim);
               end
               drawnow
           end
       end % tBin
       
    end
end


