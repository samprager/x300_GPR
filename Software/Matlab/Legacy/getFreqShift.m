function [Sf,fshift,tshift] = getFreqShift(sDAC,sADC,Fs,chirpBW,chirpT,fftlen)
Sf = [];
fshift = 0;
tshift = 0;

if (numel(sDAC)~= numel(sADC))
    fprintf('Error: Input signals must have equal length\n');
    return;
end

chirpSlope = chirpBW/chirpT;     
sMix = sDAC.*sADC;
SfMix = fft(sMix,fftlen);
Sf = SfMix(1:ceil(end/2));
[val ind] = max(abs(Sf));
fshift = (ind-1)*(Fs/2)/numel(Sf);
tshift = fshift/chirpSlope;
end