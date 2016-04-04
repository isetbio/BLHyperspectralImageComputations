function designSensor

    coneP = coneCreate;
    coneP = coneSet(coneP,'spatial density',[0.1 0.5 0.2 0.1]);
    
    
    
    sensor  = sensorCreate('human');
    pixel   = sensorGet(sensor,'pixel');
    coneAperture  = [3.0 3.0] * 1e-6;
    pixel   = pixelSet(pixel, 'size', coneAperture);
    sensor   = sensorSet(sensor, 'pixel', pixel);

    sensor = sensorCreateConeMosaic(sensor,coneP);

    pixel   = sensorGet(sensor,'pixel')
    coneAperture  = pixelGet(pixel,'size')   % This should get added to coneCreate/Set/Get
    sz      = sensorGet(sensor,'size')

end

