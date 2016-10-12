function w = getBlackmanHarris(N)
    a0 = .35875; a1 = .48829; a2 = .14128; a3 = .01168;
    n = [0:1:(N-1)]';
    w = a0-a1*cos(2*pi*n/(N-1))+a2*cos(4*pi*n/(N-1))-a3*cos(6*pi*n/(N-1));
end