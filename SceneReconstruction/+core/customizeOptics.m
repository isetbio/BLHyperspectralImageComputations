function oi = customizeOptics(oi, opticsParams)
        
    % Get the optics
    optics = oiGet(oi, 'optics');
    
    % Cusom off-axis method
    if ((isempty(opticsParams.offAxisIlluminationFallOff)) || (opticsParams.offAxisIlluminationFallOff == true))
         % do nothing
    else
        optics = opticsSet(optics, 'off axis method', 'skip');
    end
       
    % custom optics model
    if ((isempty(opticsParams.opticalTransferFunctionBased)) || (opticsParams.opticalTransferFunctionBased == true))
        % do nothing
    else
        optics = opticsSet(optics, 'model', 'diffraction limited');
    end
    
    % custom fNumber
    if (isempty(opticsParams.customFNumber))
        % do nothing
    else
        optics  = opticsSet(optics, 'fNumber', opticsParams.customFNumber);
    end
    
    % set back the customized optics
    oi = oiSet(oi,'optics', optics);
end

