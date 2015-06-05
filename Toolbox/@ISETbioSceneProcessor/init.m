function init(obj)
    % reset all properties
    
    % the isetbio structs
    obj.scene = [];
    obj.opticalImage = [];
    obj.sensor = [];
    
    % the images
    obj.sensorActivationImage = [];
    
    % close down current instance of ISETBIO and start a fresh session
    ieInit;
    
    % close any open figures
    close all
    pause(0.1);
end

