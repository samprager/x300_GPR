function w = getHamming(N)
    a = .54; 
    b = 1-a;
    n = [0:1:(N-1)]';
    w = a-b*cos(2*pi*n/(N-1));
end