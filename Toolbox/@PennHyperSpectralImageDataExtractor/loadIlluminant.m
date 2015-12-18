% Penn database - specific method to load the scene illuminant
function loadIlluminant(obj)
    fprintf('In Penn DataBase loadIlluminant.\n');

    obj.illuminant.wave = 400:10:700;
    obj.illuminant.spd = [];
end

