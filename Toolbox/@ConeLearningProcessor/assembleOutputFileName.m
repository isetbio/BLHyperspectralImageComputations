function filename = assembleOutputFileName(obj)

    if isempty(fieldnames(obj.precorrelationFilterSpecs))
        filename = sprintf('MosaicReconstruction_%sAdaptation_%s_%sDisparityMetric_NoPrecorrFilter',...
                obj.adaptationModel, obj.photocurrentNoise, obj.disparityMetric);
    else
        if (strcmp(obj.precorrelationFilterSpecs.type, 'monophasic'))
            filename = sprintf('MosaicReconstruction_%sAdaptation_%s_%sDisparityMetric_%sPrecorrFilter_%dms',...
                obj.adaptationModel, obj.photocurrentNoise, obj.disparityMetric, obj.precorrelationFilterSpecs.type, obj.precorrelationFilterSpecs.timeConstantInMilliseconds);
        elseif (strcmp(obj.precorrelationFilterSpecs.type, 'biphasic'))
            filename = sprintf('MosaicReconstruction_%sAdaptation_%s_%sDisparityMetric_%sPrecorrFilter_%dms_%dms',...
                obj.adaptationModel, obj.photocurrentNoise, obj.disparityMetric, obj.precorrelationFilterSpecs.type, obj.precorrelationFilterSpecs.timeConstant1InMilliseconds, obj.precorrelationFilterSpecs.timeConstant2InMilliseconds);
        else
            filename = sprintf('MosaicReconstruction_%sAdaptation_%s_%sDisparityMetric_UnknownPrecorrFilter',...
                obj.adaptationModel, obj.photocurrentNoise, obj.disparityMetric);
        end
    end

end

