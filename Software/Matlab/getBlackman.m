function w = getBlackman(N)
    alpha = .16;
    a0 = (1-alpha)/2; a1 = .5; a2 = alpha/2; a3 = .01168;
    n = [0:1:(N-1)]';
    w = a0-a1*cos(2*pi*n/(N-1))+a2*cos(4*pi*n/(N-1));
end