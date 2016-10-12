
a = barkerCode(11,64);
b = [zeros(1,32),barkerCode(11,32)];

n = 1:numel(a);
figure; plot(n,a,n,b);

B = fft(b);
A = fft(a);

mfilt = ifft(B.*conj(A));
figure; plot(mfilt);

bc = barkerCode(11);
interp_factor = 10;
bup = zeros(1,11*interp_factor);
for i=1:11
    ind = 1+(i-1)*interp_factor;
    bup(ind:ind+interp_factor) = bc(i);
    bc(i)
end
fc = 10e5;
fs = 245e6;
T = numel(bup)/(fs);
t = linspace(0,T,numel(bup));
s = [cos(2*pi*fc*t + pi*(1-(bup+1)/2))];
figure; plot(t,s,t,bup);

stx = [s,zeros(1,100)];
srx = [zeros(1,100),s];
Stx = fft(stx);
Srx = fft(srx);
sfilt = ifft(Srx.*conj(Stx));
figure; plot(sfilt);