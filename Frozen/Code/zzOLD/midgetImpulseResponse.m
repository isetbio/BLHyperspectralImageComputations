function IR = midgetImpulseResponse
    t = (0:1:300)/1000;
    p1 = 1;
    p2 = 0.15;
    n  = 4;
    tau1 = 2*30/1000;
    tau2 = 80/1000;
    t1 = t/tau1;
    t2 = t/tau2;
    IR = p1 * (t1.^n) .* exp(-n*(t1-1))  - p2 * (t2.^n) .* exp(-n*(t2-1));
    figure(1);
    plot(t, IR, 'k.-');
    drawnow
end

