function C = computeContourData(spatialFilter, contourLevels, spatialSupportX, spatialSupportY, lConeIndices, mConeIndices, sConeIndices)
        
    dX = spatialSupportX(2)-spatialSupportX(1);
    dY = spatialSupportY(2)-spatialSupportY(1);
    contourXaxis = spatialSupportX(1)-dX:1:spatialSupportX(end)+dX;
    contourYaxis = spatialSupportY(1)-dY:1:spatialSupportY(end)+dY;
    [xx, yy] = meshgrid(contourXaxis,contourYaxis); 

    lConeWeights = []; mConeWeights = []; sConeWeights = [];
    lConeCoords = []; mConeCoords = []; sConeCoords = [];

    for iRow = 1:size(spatialFilter,1)
        for iCol = 1:size(spatialFilter,2) 
            coneLocation = [spatialSupportX(iCol) spatialSupportY(iRow)];
            xyWeight = [coneLocation(1) coneLocation(2) spatialFilter(iRow, iCol)];
            coneIndex = sub2ind(size(spatialFilter), iRow, iCol);
            if ismember(coneIndex, lConeIndices)
                lConeCoords(size(lConeCoords,1)+1,:) = coneLocation';
                lConeWeights(size(lConeWeights,1)+1,:) = xyWeight;
            elseif ismember(coneIndex, mConeIndices)
                mConeCoords(size(mConeCoords,1)+1,:) = coneLocation';
                mConeWeights(size(mConeWeights,1)+1,:) = xyWeight;
            elseif ismember(coneIndex, sConeIndices)
                sConeCoords(size(sConeCoords,1)+1,:) = coneLocation';
                sConeWeights(size(sConeWeights,1)+1,:) = xyWeight;
            end   
        end
    end
    lmConeWeights = [lConeWeights; mConeWeights];

    if (~isempty(lConeWeights))
        C.LconeMosaicSpatialWeightingKernel = smoothKernel(xx,yy,griddata(lConeWeights(:,1), lConeWeights(:,2), lConeWeights(:,3), xx, yy, 'v4'));  
        C.LconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.LconeMosaicSpatialWeightingKernel , contourLevels));
    end
    if (~isempty(mConeWeights))
        C.MconeMosaicSpatialWeightingKernel  = smoothKernel(xx,yy,griddata(mConeWeights(:,1), mConeWeights(:,2), mConeWeights(:,3), xx, yy, 'v4'));
        C.MconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.MconeMosaicSpatialWeightingKernel, contourLevels));
    end
    if (~isempty(sConeWeights))
        C.SconeMosaicSpatialWeightingKernel = smoothKernel(xx,yy,griddata(sConeWeights(:,1), sConeWeights(:,2), sConeWeights(:,3), xx, yy, 'v4'));
        C.SconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.SconeMosaicSpatialWeightingKernel, contourLevels));
    end
    if (~isempty(lmConeWeights))
        C.LMconeMosaicSpatialWeightingKernel = smoothKernel(xx,yy,griddata(lmConeWeights(:,1), lmConeWeights(:,2), lmConeWeights(:,3), xx, yy, 'v4'));
        C.LMconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.LMconeMosaicSpatialWeightingKernel, contourLevels));
    end
end
       
function smoothedKernel = smoothKernel(xx,yy,kernel)

    smoothedKernel  = kernel;
    return;
    
    maxBefore = max(abs(kernel(:)));
    sigma = 3.0;
    f = exp(-0.5*(xx/sigma).^2) .* exp(-0.5*(yy/sigma).^2);
    smoothedKernel = conv2(kernel, f, 'same');
    maxAfter = max(abs(smoothedKernel(:)))
    smoothedKernel = smoothedKernel/maxAfter*maxBefore;
    
    commonRange(1) = min([min(kernel(:)) min(smoothedKernel(:))]) 
    commonRange(2) = max([max(kernel(:)) max(smoothedKernel(:))]) 
    
    figure(10);
    clf;
    subplot(1,3,1);
    imagesc(kernel)
    set(gca, 'CLim', commonRange);
    axis 'image'
    subplot(1,3,2)
    imagesc(smoothedKernel)
    set(gca, 'CLim', commonRange);
    axis 'image'
    subplot(1,3,3);
    imagesc(f/max(f(:)))
    axis 'image'
    colormap(gray)
    drawnow
    pause
end


function Cout = getContourStruct(C)
    K = 0; n0 = 1;
    while n0<=size(C,2)
       K = K + 1;
       n0 = n0 + C(2,n0) + 1;
    end

    % initialize output struct
    el = cell(K,1);
    Cout = struct('level',el,'length',el,'x',el,'y',el);

    % fill the output struct
    n0 = 1;
    for k = 1:K
       Cout(k).level = C(1,n0);
       idx = (n0+1):(n0+C(2,n0));
       Cout(k).length = C(2,n0);
       Cout(k).x = C(1,idx);
       Cout(k).y = C(2,idx);
       n0 = idx(end) + 1; % next starting index
    end
end

    
    