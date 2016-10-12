function [Sf,fshift,tshift,ind] = getFreqShiftPeaks(sDAC,sADC,Fs,chirpBW,chirpT,fftlen,threshDB)
Sf = [];
fshift = 0;
tshift = 0;

if (numel(sDAC)~= numel(sADC))
    fprintf('Error: Input signals must have equal length\n');
    return;
end

lpf_cutoff = round((chirpBW/Fs)*fftlen);
chirpSlope = chirpBW/chirpT;     
sMix = sDAC.*sADC;
SfMix = fft(sMix,fftlen);
Sf = SfMix(1:end/2);
Sf_sq = zeros(numel(Sf),1);
size(Sf);
Sf_sq(1:lpf_cutoff)= abs(Sf(1:lpf_cutoff)).^2;
medval = (median(abs(Sf)))^2;
threshval = medval*(10^(threshDB/10));
Sf_thresh = Sf_sq;
Sf_thresh(Sf_thresh<threshval)=0;
[val, ind] = findpeaks(Sf_thresh);
fshift = (ind-1)*Fs/fftlen;
tshift = fshift/chirpSlope;
%figure; hold on; plot(abs(Sf).^2); plot(Sf_sq); plot(Sf_thresh); scatter(ind,val);
end