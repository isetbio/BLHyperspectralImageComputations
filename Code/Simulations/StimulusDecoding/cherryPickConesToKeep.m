function  [keptLconeIndices, keptMconeIndices, keptSconeIndices] = cherryPickConesToKeep(scanSensor, thresholdConeSeparation)

    % Select a subset of the cones based on the thresholdConeSeparation
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
 
    % Eliminate cones separately for each of the L,M and S cone mosaics
    keptLconeIndices = identifyConesWhoseSeparationExceedsThreshold(coneTypes,  lConeIndices, thresholdConeSeparation, Inf);
    keptMconeIndices = identifyConesWhoseSeparationExceedsThreshold(coneTypes,  mConeIndices, thresholdConeSeparation, round(numel(mConeIndices)/numel(lConeIndices)*numel(keptLconeIndices)));
    keptSconeIndices = identifyConesWhoseSeparationExceedsThreshold(coneTypes,  sConeIndices, thresholdConeSeparation*1.3, round(numel(sConeIndices)/numel(lConeIndices)*numel(keptLconeIndices)));
    
    fprintf('original Lcones: %d, satisfying min separation and density: %d\n', numel(lConeIndices), numel(keptLconeIndices));
    fprintf('original Mcones: %d, satisfying min separation and density: %d\n', numel(mConeIndices), numel(keptMconeIndices));
    fprintf('original Scones: %d, satisfying min separation and density: %d\n', numel(sConeIndices), numel(keptSconeIndices));
   
end



function keptConeIndices = identifyConesWhoseSeparationExceedsThreshold(coneTypes, theConeIndices, thresholdDistance, maxNumberOfCones)
    if (thresholdDistance <= 0)
        keptConeIndices = theConeIndices;
        return;
    end

    coneRowPositions = zeros(1, numel(theConeIndices));
    coneColPositions = zeros(1, numel(theConeIndices));
    for theConeIndex = 1:numel(theConeIndices)
        [coneRowPositions(theConeIndex), coneColPositions(theConeIndex)] = ind2sub(size(coneTypes), theConeIndices(theConeIndex));
    end

    originalConeRowPositions = coneRowPositions;
    originalConeColPositions = coneColPositions;

    % Lets keep the cone that is closest to the center.
    [~, idx] = min(sqrt(coneRowPositions.^2 + coneColPositions.^2));
    keptConeIndices(1) = idx;
    keptConeRows(1) = coneRowPositions(idx);
    keptConeCols(1) = coneColPositions(idx);

    remainingConeIndices = setdiff(1:numel(theConeIndices), keptConeIndices);

    scanNo = 1;
    while (~isempty(remainingConeIndices))

        for keptConeIndex = 1:numel(keptConeIndices) 
            % compute all distances between cones in the kept indices and all other cones
            distances = sqrt( (coneRowPositions - keptConeRows(keptConeIndex)).^2 + (coneColPositions - keptConeCols(keptConeIndex)).^2);
            coneIndicesThatAreTooClose = find(distances <= thresholdDistance);

            remainingConeIndices = setdiff(remainingConeIndices, remainingConeIndices(coneIndicesThatAreTooClose));
            coneRowPositions = originalConeRowPositions(remainingConeIndices);
            coneColPositions = originalConeColPositions(remainingConeIndices);
        end
        if (~isempty(remainingConeIndices))
            % Select next cone to keep
            keptConeIndices = [keptConeIndices remainingConeIndices(1)];
            keptConeRows(numel(keptConeIndices)) = originalConeRowPositions(remainingConeIndices(1));
            keptConeCols(numel(keptConeIndices)) = originalConeColPositions(remainingConeIndices(1));
            scanNo = scanNo + 1;
        end
    end

    keptConeIndices = theConeIndices(keptConeIndices);
    
    % Further elimination, so we have no more than maxNumberOfCones
    if (numel(keptConeIndices) > maxNumberOfCones)
        conesToEliminate = numel(keptConeIndices)-maxNumberOfCones;
        eliminatedCones = [];
        
        while (numel(eliminatedCones) < conesToEliminate)
            [distances, coneIDs] = computeDistances(keptConeIndices, keptConeRows, keptConeCols);
            
            % eliminate the cone with the min distance to all other cones
            [~,ix] = min(distances);
            keptConeRows(coneIDs(ix)) = Inf;
            eliminatedCones(numel(eliminatedCones)+1) = coneIDs(ix);
        end
        
        goodConeIndices = setdiff((1:numel(keptConeIndices)), eliminatedCones);
        keptConeIndices = keptConeIndices(goodConeIndices);
    end
end


function [distances, coneIds] = computeDistances(keptConeIndices, keptConeRows, keptConeCols)
    distances = zeros(1, numel(keptConeIndices)*(numel(keptConeIndices)-1)/2) + Inf;
    coneIds = zeros(1, numel(keptConeIndices)*(numel(keptConeIndices)-1)/2);
    k = 0;
    for iCone = 1:numel(keptConeIndices)
        r = keptConeRows(iCone);
        c = keptConeCols(iCone);
        for jCone = iCone+1:numel(keptConeIndices)
            rr = keptConeRows(jCone);
            cc = keptConeCols(jCone);
            k = k + 1;
            distances(k) = sqrt((r-rr)^2+(c-cc)^2);
            coneIds(k) = iCone;
        end
    end
end