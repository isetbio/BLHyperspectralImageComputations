% Harvard database - specific method to load the reflectance map
function loadReflectanceMap(obj)
   
     sourceDir = fullfile(getpref('HyperSpectralImageIsetbioComputations', 'originalDataBaseDir'), obj.sceneData.database);
     load(fullfile(sourceDir, obj.sceneData.subset, obj.sceneData.reflectanceDataFileName));
     
     if (isempty(ref))
         error('Data file does not contain the expected ''ref'' field.');
     end
     
     if (isfield(obj.sceneData, 'clippingRegion')) && (~isempty(fieldnames(obj.sceneData.clippingRegion)))
        % clip image according to clipping region
        if isinf(obj.sceneData.clippingRegion.y2)
            obj.sceneData.clippingRegion.y2 = size(ref,1);
        end
        if isinf(obj.sceneData.clippingRegion.x2)
            obj.sceneData.clippingRegion.x2 = size(ref,2);
        end
        ref = ref(obj.sceneData.clippingRegion.y1:obj.sceneData.clippingRegion.y2, obj.sceneData.clippingRegion.x1:obj.sceneData.clippingRegion.x2, :);
     end
    
    
    obj.reflectanceMap = ref;
    
    % Apply camera sensitivity correction
    correction = 1./repmat(obj.cameraSensitivityProfile, [size(ref,1) size(ref,2) 1]);
    obj.reflectanceMap = obj.reflectanceMap .* correction;
    
    
    % Mask image if the motionMaskIsOn flag has been set
    if (obj.motionMaskIsOn)
        if (isempty(lbl))
         error('Data file does not contain the expected ''lbl'' field.');
        end
       obj.reflectanceMap = obj.reflectanceMap .* repmat(lbl, [1 1 size(ref,3)]);
    end
    
    clear 'ref';
    clear 'lbl';
end