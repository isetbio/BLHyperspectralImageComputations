function scene = standardizeScenePixelSize(scene, standardizedAngularResolition)

    originalFOV  = sceneGet(scene,'hfov');
    sceneColumns = sceneGet(scene, 'cols');
    originalAngularResolution = sceneGet(scene, 'w angular resolution');
    requiredFOV = standardizedAngularResolition * sceneColumns;
    scene = sceneSet(scene,'hfov', requiredFOV);
    resultingAngularResolution = sceneGet(scene, 'w angular resolution');
    resultingFOV = resultingAngularResolution * sceneColumns;
    fprintf('Original scene angular res: %2.4f deg/pixels, Adjusted to %2.4f deg/pixels (original FOV: %2.2fdeg, adjusted FOV: %2.2f deg)\n', originalAngularResolution, resultingAngularResolution, originalFOV, resultingFOV);
end

