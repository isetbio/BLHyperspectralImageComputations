function computePrecorrelationFilter(obj)

    if isempty(fieldnames(obj.precorrelationFilterSpecs))
        % delta function, i.e. no filtering
        obj.precorrelationFilter = [1];
    else
        if (strcmp(obj.precorrelationFilterSpecs.type, 'monophasic'))
            obj.precorrelationFilter = monoPhasicIR(...
                obj.precorrelationFilterSpecs.timeConstantInMilliseconds, ...
                obj.precorrelationFilterSpecs.supportInMilliseconds);

        elseif (strcmp(obj.precorrelationFilterSpecs.type, 'biphasic'))
            obj.precorrelationFilter = biPhasicIR(...
                obj.precorrelationFilterSpecs.timeConstant1InMilliseconds, ...
                obj.precorrelationFilterSpecs.timeConstant2InMilliseconds, ...
                obj.precorrelationFilterSpecs.biphasicRatio, ...
                obj.precorrelationFilterSpecs.supportInMilliseconds);
        else
            error('Unknown filter type (''%s'').\n', obj.precorrelationFilterSpecs.type);
        end
    end

end

function IR = monoPhasicIR(timeConstantInMilliseconds, supportInMilliseconds)
    n = 4;
    p1 = 1;
    t = (0:1:supportInMilliseconds)/1000;
    tau = timeConstantInMilliseconds/1000;
    t1 = t / tau;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1));
    IR = IR / sum(abs(IR)); 
end

function IR = biPhasicIR(timeConstant1InMilliseconds, timeConstant2InMilliseconds, biphasicRatio, supportInMilliseconds)
    n = 4;
    p1 = 1;
    p2 = biphasicRatio;
    t = (0:1:supportInMilliseconds)/1000;
    tau1 = timeConstant1InMilliseconds/1000;
    tau2 = timeConstant2InMilliseconds/1000;
    t1 = t / tau1;
    t2 = t / tau2;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1))  - p2 * (t2.^n) .* exp(-n*(t2-1));
    IR = IR / sum(abs(IR));
end
