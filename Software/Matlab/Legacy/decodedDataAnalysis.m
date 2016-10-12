filename = '/Users/sam/outputs/en4_dataout_lin.bin';
filenameC = '/Users/sam/outputs/en4_dataout_lin_blkC.bin';
filenameIQ = '/Users/sam/outputs/en4_dataout_lin_blkIQ.bin';

Fs = 245.76e6;
chirpBW = 3*15.360000e6;
%chirpT = 16.667e-6;
%nsamples = Fs*chirpT;
nsamples = 4096;
chirpT = nsamples/Fs;

rel_perm = 4;
vel = 3e8/sqrt(rel_perm);

minAdcRes = (3e8)/(2*Fs);
minChirpRes = (3e8)/(2*chirpBW);

use_decoded = 0;

if(use_decoded)
    fileID_C = fopen(filenameC,'r');
    fileID_IQ = fopen(filenameIQ,'r');
    dataU = fread(fileID_C,'uint32');
    dataL = fread(fileID_IQ,'uint32');
    fclose(fileID_C);
    fclose(fileID_IQ);
else
    [dataU,dataL] = decodeDataUL(filename,'uint32');
end

shift_il = 0; shift_ql =0;
shift_iu = 0; shift_qu = 0;
scale_il = 1; scale_ql = 1;
scale_iu = 1; scale_qu = 1;
add_waves = 0;
use_window = 0;
mod_demod = 0;
plot_demod_stages = 0;
plot_peak_results = 0;

% Extract IQ data as signed 16 bit integers
[I_l,Q_l] = decodeDataIQ(dataL);
[I_u,Q_u] = decodeDataIQ(dataU);
[partial_offset,single_pulse_end,adcctr,glblctr] = decodeEmbeddedCounter(dataU,dataL);

%chirpmin = partial_offset+1; chirpmax = partial_offset+4350;
chirpmin = partial_offset+1; chirpmax = single_pulse_end-1;

win = getBlackmanHarris(chirpmax-chirpmin+1);
%win = getHamming(chirpmax-chirpmin+1);

I_lshift = add_waves*I_l(chirpmin:chirpmax)+scale_il*[zeros(shift_il,1);I_l(chirpmin:chirpmax-shift_il)];
Q_lshift = add_waves*Q_l(chirpmin:chirpmax)+scale_ql*[zeros(shift_ql,1);Q_l(chirpmin:chirpmax-shift_ql)];
I_ushift = scale_iu*[zeros(shift_iu,1);I_u(chirpmin:chirpmax-shift_iu)];
Q_ushift = scale_qu*[zeros(shift_qu,1);Q_u(chirpmin:chirpmax-shift_qu)];

I_lwin = I_lshift.*win;
I_uwin = I_ushift.*win;
Q_lwin = Q_lshift.*win;
Q_uwin = Q_ushift.*win;

figure;
subplot (4,1,1); plot(I_lshift);
axis tight; title('Decoded Lower I Shift');
subplot (4,1,2); plot(I_ushift);
axis tight; title('Decoded Upper I Shift');
subplot(4,1,3); plot(Q_lshift);
axis tight; title('Decoded Lower Q Shift');
subplot(4,1,4); plot(Q_ushift);
axis tight; title('Decoded Upper Q Shift');

if (use_window)
    figure;
    subplot (4,1,1); plot(I_ushift);axis tight; title('Decoded Upper I shift');
    subplot (4,1,2); plot(I_uwin);axis tight; title('Windowed Upper I Shift');
    subplot(4,1,3); obw(real(I_ushift),Fs);title(['Upper I Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,4); obw(real(I_uwin),Fs);title(['Windowed Upper I Channel: ',get(get(gca,'title'),'string')]);
    I_lshift = I_lwin;
    I_ushift = I_uwin;
    Q_lshift = Q_lwin;
    Q_ushift = Q_uwin;
end

% Plot a PSD with 90% Occupied BW of IQ data
x_l = I_lshift+1i*Q_lshift;
x_u = I_ushift+1i*Q_ushift;
figure;
subplot(4,1,1); obw(real(x_l),Fs);
title(['I Lower Channel: ',get(get(gca,'title'),'string')]);
subplot(4,1,2); obw(real(x_u),Fs);
title(['I Upper Channel: ',get(get(gca,'title'),'string')]);
subplot(4,1,3);  obw(imag(x_l),Fs);
title(['Q Lower Channel: ',get(get(gca,'title'),'string')]);
subplot(4,1,4);  obw(imag(x_u),Fs);
title(['Q Upper Channel: ',get(get(gca,'title'),'string')]);

if(mod_demod)
    fmods = [0:Fs/128:(Fs/4+Fs/32+Fs/64+Fs/128)];
    %fmods = 40e6
    figure;
    for m = 1:numel(fmods)
    fmod = fmods(m);

    tmod = linspace(0,numel(I_ushift)./Fs,numel(I_ushift))';
    IQ_umod = cos(2*pi*fmod*tmod).*I_ushift-sin(2*pi*fmod*tmod).*Q_ushift;
    IQ_lmod = cos(2*pi*fmod*tmod).*I_lshift-sin(2*pi*fmod*tmod).*Q_lshift;

    I_udemod = cos(2*pi*fmod*tmod).*IQ_umod;
    Q_udemod = -sin(2*pi*fmod*tmod).*IQ_umod;

    I_ldemod = cos(2*pi*fmod*tmod).*IQ_lmod;
    Q_ldemod = -sin(2*pi*fmod*tmod).*IQ_lmod;

    mod_fft_len = numel(I_ldemod);
    freq_rng = floor(mod_fft_len/4)+1;
    lpf_rec = zeros(mod_fft_len,1);
    lpf_rec(1:freq_rng) = 1;
    lpf_rec(end-freq_rng:end) = 1;

    fftI_udemod = fft(I_udemod,mod_fft_len);
    I_udemod_filt = real(ifft(lpf_rec.*fftI_udemod));
    fftQ_udemod = fft(Q_udemod,mod_fft_len);
    Q_udemod_filt = real(ifft(lpf_rec.*fftQ_udemod));

    IQ_udemod = I_udemod + 1i*Q_udemod;
    fftIQ_udemod = fft(IQ_udemod,mod_fft_len);
    IQ_udemod_filt = ifft(lpf_rec.*fftIQ_udemod);

    %IQ_ldemod = exp(-1i*2*pi*fmod*tmod).*IQ_lmod;
    IQ_ldemod = I_ldemod + 1i*Q_ldemod;
    fftIQ_ldemod = fft(IQ_ldemod,mod_fft_len);
    IQ_ldemod_filt = ifft(lpf_rec.*fftIQ_ldemod);

    fftI_ldemod = fft(I_ldemod,mod_fft_len);
    I_ldemod_filt = real(ifft(lpf_rec.*fftI_ldemod));
    %I_ldemod_filt = I_ldemod;

    fftQ_ldemod = fft(Q_ldemod,mod_fft_len);
    Q_ldemod_filt = real(ifft(lpf_rec.*fftQ_ldemod));
    %Q_ldemod_filt = Q_ldemod;

    %figure; 
    fvec = linspace(0,246,numel(fftI_udemod));
    subplot(4,1,1); plot(fvec,abs(fftI_udemod)); title(sprintf('upper I full fft (fmod=%i)',fmod));
    subplot(4,1,2); plot(fvec,abs(fftQ_udemod));title('upper Q full fft');
    subplot(4,1,3); plot(fvec,abs(fftI_ldemod)); title('lower I full fft');
    subplot(4,1,4); plot(fvec,abs(fftQ_ldemod)); title('lower Q full fft');

    M(m) = getframe(gcf);
    end
    movie(gcf,M,10);

    if (plot_demod_stages)
        figure; subplot(4,1,1); plot(abs(fftIQ_udemod)); title('upper full fft');
        subplot(4,1,2); plot(abs(lpf_rec.*fftIQ_udemod));
        subplot(4,1,3); plot(abs(fftIQ_ldemod)); title('lower full fft');
        subplot(4,1,4); plot(abs(lpf_rec.*fftIQ_ldemod));

        figure; subplot(6,1,1); plot(abs(fftI_udemod)); title('upper I full fft');
        subplot(6,1,2); plot(abs(lpf_rec.*fftI_udemod));
        subplot(6,1,3); plot(abs(fft(I_ushift)));  title('upper I shift full fft');
        subplot(6,1,4); plot(abs(fftQ_udemod));  title('upper Q full fft');
        subplot(6,1,5); plot(abs(lpf_rec.*fftQ_udemod));
        subplot(6,1,6); plot(abs(fft(Q_ushift)));  title('upper Q shift full fft');

        %

        figure; subplot(6,1,1); plot(abs(fftI_ldemod)); title('lower I full fft');
        subplot(6,1,2); plot(abs(lpf_rec.*fftI_ldemod));
        subplot(6,1,3); plot(abs(fft(I_lshift)));  title('lower I shift full fft');
        subplot(6,1,4); plot(abs(fftQ_ldemod));  title('lower Q full fft');
        subplot(6,1,5); plot(abs(lpf_rec.*fftQ_ldemod));
        subplot(6,1,6); plot(abs(fft(Q_lshift)));  title('lower Q shift full fft');
    end

    %x_udemod = IQ_udemod_filt;
    x_udemod = I_udemod_filt+1i*Q_udemod_filt;
    %x_ldemod = IQ_ldemod_filt;
    x_ldemod = I_ldemod_filt+1i*Q_ldemod_filt;
    figure;

    subplot(4,1,1); obw(real(x_ldemod),Fs);
    title(['I Demod Lower Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,2); obw(real(x_udemod),Fs);
    title(['I Demod Upper Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,3);  obw(imag(x_ldemod),Fs);
    title(['Q Demod Lower Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,4);  obw(imag(x_udemod),Fs);
    title(['Q Demod Upper Channel: ',get(get(gca,'title'),'string')]);

    I_lshift = I_ldemod_filt;
    Q_lshift = Q_ldemod_filt;
end

fftlen = 8192*2;
thresholdDB = 30;
%     [I_mixfft,Ifshift,Itshift] = getFreqShift(I2shift,Ishift,Fs,chirpBW,chirpT,fftlen);
%     [Q_mixfft,Qfshift,Qtshift] = getFreqShift(Q2shift,Qshift,Fs,chirpBW,chirpT,fftlen);
[I_mixfft,Ifshift,Itshift,Iind] = getFreqShiftPeaks(I_ushift,I_lshift,Fs,chirpBW,chirpT,fftlen,thresholdDB);
[Q_mixfft,Qfshift,Qtshift,Qind] = getFreqShiftPeaks(Q_ushift,Q_lshift,Fs,chirpBW,chirpT,fftlen,thresholdDB);

Isdelay = Fs*Itshift;
Qsdelay = Fs*Qtshift;

Irange = vel*Itshift/2;
Qrange = vel*Qtshift/2;

total_peaks = max(numel(Iind),numel(Qind));
fprintf('\nI ch: %i peaks, Q ch: %i peaks, Rel. Permittivity = %i\n',numel(Iind),numel(Qind),rel_perm);
for i=1:total_peaks
    fprintf('\nPeak %i:\n',i);
    if(i<=numel(Iind))
        fprintf('I ch. Shift: %i samples (%f Mhz, %f usec) [fft ind = %i]\n',round(Isdelay(i)),Ifshift(i)/1e6,Itshift(i)*1e6,Iind(i));
        fprintf('I ch. Range: %f m\n',Irange(i));
    else 
        fprintf('I ch. N/A\n');
    end
    
    if(i<=numel(Qind))
        fprintf('Q ch. Shift: %i samples (%f Mhz, %f usec) [fft ind = %i]\n',round(Qsdelay(i)),Qfshift(i)/1e6,Qtshift(i)*1e6,Qind(i));
        fprintf('Q ch. Range: %f m\n',Qrange(i));
    else 
        fprintf('Q ch. N/A\n');
    end  
end

iSampledelay = round(Fs*Itshift)-1;
qSampledelay = round(Fs*Qtshift)-1;

if (plot_peak_results)
    fvec = linspace(0,Fs/2e6,numel(I_mixfft));
    figure; subplot(2,1,1); hold on;
    plot(fvec,abs(I_mixfft).^2);
    grid on; %axis tight;
    title('fft Imix');
    subplot(2,1,2); hold on;
    plot(fvec,abs(Q_mixfft).^2);
    grid on; %axis tight;
    title('fft Qmix');

    figure;
    alpha = [61/64,123/128];
    beta  = [13/32,51/128];
    legendmtx = {'abs','a:61/64,b:13/32'};
    subplot(2,1,1); hold on;
    plot(fvec,abs(I_mixfft));
    for i=1:numel(alpha)
        plot(fvec,magest(I_mixfft,alpha(i),beta(i)));
    end
    grid on; title('fft magest Imix'); legend(legendmtx),hold off;

    subplot(2,1,2); hold on;
    plot(fvec,abs(Q_mixfft));
    for i=1:numel(alpha)
        plot(fvec,magest(Q_mixfft,alpha(i),beta(i)));
    end
    grid on; title('fft magest Qmix');  legend(legendmtx); hold off;
end

cor_thresh = 5e11;
I_cor = (ifft(fft(I_lshift).*conj(fft(I_ushift))));
I_cor_thresh = I_cor;
I_cor_thresh(I_cor_thresh<cor_thresh) = 0;
[I_cor_val, I_cor_ind] = findpeaks(I_cor_thresh);
figure; 
subplot(2,1,1); hold on; plot(abs(I_cor)); scatter(I_cor_ind,I_cor_val); title('Icorr'); hold off;
subplot(2,1,2); plot(abs(I_mixfft));
fprintf('I correlation peak ind: %s\n',sprintf('%i. ',I_cor_ind));

Q_cor = (ifft(fft(Q_lshift).*conj(fft(Q_ushift))));
Q_cor_thresh = Q_cor;
Q_cor_thresh(Q_cor_thresh<cor_thresh) = 0;
[Q_cor_val, Q_cor_ind] = findpeaks(Q_cor_thresh);
figure; 
subplot(2,1,1); hold on; plot(abs(Q_cor)); scatter(Q_cor_ind,Q_cor_val);title('Qcorr'); hold off;
subplot(2,1,2); plot(abs(Q_mixfft));
fprintf('Q correlation peak ind: %s\n',sprintf('%i. ',Q_cor_ind));

cor_thresh = 2e12;
IQ_cor = (ifft(fft(I_lshift+1i*Q_lshift).*conj(fft(I_ushift+1i*Q_ushift))));
IQ_cor_thresh = abs(IQ_cor);
IQ_cor_thresh(IQ_cor_thresh<cor_thresh) = 0;
[IQ_cor_val, IQ_cor_ind] = findpeaks(IQ_cor_thresh);
figure; 
subplot(2,1,1); hold on; plot(abs(IQ_cor)); scatter(IQ_cor_ind,IQ_cor_val);title('IQcorr'); hold off;
subplot(2,1,2); hold on; plot(abs(I_mixfft)); plot(abs(Q_mixfft));
fprintf('IQ correlation peak ind: %s\n',sprintf('%i. ',IQ_cor_ind));

%     st_sample_i = slowTimeTransform(I2shift,Ishift,freq);
%     st_sample_q = slowTimeTransform(Q2shift,Qshift,freq);

%     st_sample_i = slowTimeTransform(zeros(1,numel(Ishift)),Ishift,freq);
%     st_sample_q = slowTimeTransform(zeros(1,numel(Qshift)),Qshift,freq);
