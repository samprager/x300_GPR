function r = rickerWavelet(t,fp,tc)
    wp = 2*pi*fp;
    ts = t-tc;
    r = (1-.5*wp^2*ts.^2).*exp(-.25*wp^2*ts.^2);
end
