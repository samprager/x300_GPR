filename = '/Users/sam/outputs/en4_dataout_lin.bin'; % rx signal
filename2 = '/Users/sam/outputs/en4_dataout_lin_blk.bin'; % signal to xcorrelate rx signal with


Fs = 245.76e6; chirpBW = 3*15.360000e6; nsamples = 4096;
chirpT = nsamples/Fs;

rel_perm = 4;
vel = 3e8/sqrt(rel_perm);
logscale = 1;

[dataU,dataL] = decodeDataUL(filename,'uint32');
[dataU2,dataL2] = decodeDataUL(filename2,'uint32');

%[I_uwin,Q_uwin,I_lwin, Q_lwin] = decodeSample(dataU,dataL,'last');
[I_uwin,Q_uwin,I_lwin, Q_lwin] = decodeSample(dataU,dataL,'average');

%[I_uwin2,Q_uwin2,I_lwin2, Q_lwin2] = decodeSample(dataU2,dataL2,'last');
[I_uwin2,Q_uwin2,I_lwin2, Q_lwin2] = decodeSample(dataU2,dataL2,'average');

fftlen = 4096;

I_rx = fft(I_lwin,fftlen); 
I_tx = fft(I_uwin2,fftlen);
Q_rx = fft(Q_lwin,fftlen); 
Q_tx = fft(Q_uwin2,fftlen);
IQ_rx = fft(I_lwin+1i*Q_lwin,fftlen); 
IQ_tx = fft(I_uwin2+1i*Q_uwin2,fftlen);


I_cor = ifft(I_rx(1:end/2).*conj(I_tx(1:end/2)));
Q_cor = ifft(Q_rx(1:end/2).*conj(Q_tx(1:end/2)));
IQ_cor = ifft(IQ_rx(1:end/2).*conj(IQ_tx(1:end/2)));

cor_thresh = 4e11;
I_cor_thresh = abs(I_cor);
I_cor_thresh(I_cor_thresh<cor_thresh) = 0;
[I_cor_val, I_cor_ind] = findpeaks(I_cor_thresh);

cor_thresh = 5e9;
Q_cor_thresh = abs(Q_cor);
Q_cor_thresh(Q_cor_thresh<cor_thresh) = 0;
[Q_cor_val, Q_cor_ind] = findpeaks(Q_cor_thresh);

cor_thresh = 5e11;
IQ_cor_thresh = abs(IQ_cor);
IQ_cor_thresh(IQ_cor_thresh<cor_thresh) = 0;
[IQ_cor_val, IQ_cor_ind] = findpeaks(IQ_cor_thresh);

% Constant false alaram rate threshold
windowSize = 40;
cfar_const = 2;
I_cfar_thresh = cfar_const*cfar(I_cor,windowSize);
Q_cfar_thresh = cfar_const*cfar(Q_cor,windowSize);
IQ_cfar_thresh = cfar_const*cfar(IQ_cor,windowSize);

I_cfar = abs(I_cor);
I_cfar(I_cfar<I_cfar_thresh) = 0;
[I_cfar_val, I_cfar_ind] = findpeaks(I_cfar);
Q_cfar = abs(Q_cor);
Q_cfar(Q_cfar<Q_cfar_thresh) = 0;
[Q_cfar_val, Q_cfar_ind] = findpeaks(Q_cfar);
IQ_cfar = abs(IQ_cor);
IQ_cfar(IQ_cfar<IQ_cfar_thresh) = 0;
[IQ_cfar_val, IQ_cfar_ind] = findpeaks(IQ_cfar);



% Plot IQ data

% figure;
% subplot (4,1,1); plot(I_lwin); axis tight; title('Decoded Lower I Shift');
% subplot (4,1,2); plot(I_uwin); axis tight; title('Decoded Upper I Shift');
% subplot(4,1,3); plot(Q_lwin); axis tight; title('Decoded Lower Q Shift');
% subplot(4,1,4); plot(Q_uwin); axis tight; title('Decoded Upper Q Shift');
% 
% figure;
% subplot (4,1,1); plot(I_lwin2); axis tight; title('Decoded Lower I2 Shift');
% subplot (4,1,2); plot(I_uwin2); axis tight; title('Decoded Upper I2 Shift');
% subplot(4,1,3); plot(Q_lwin2); axis tight; title('Decoded Lower Q2 Shift');
% subplot(4,1,4); plot(Q_uwin2); axis tight; title('Decoded Upper Q2 Shift');



% Plot a PSD with 90% Occupied BW of IQ data

% figure;
% subplot(4,1,1); obw((I_lwin),Fs);title(['Lower I Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,2); obw((I_uwin),Fs);title(['Upper I Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,3); obw((Q_lwin),Fs);title(['Lower Q Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,4); obw((Q_uwin),Fs);title(['Upper Q Channel: ',get(get(gca,'title'),'string')]);
% 
% figure;
% subplot(4,1,1); obw((I_lwin2),Fs);title(['Lower I2 Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,2); obw((I_uwin2),Fs);title(['Upper I2 Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,3); obw((Q_lwin2),Fs);title(['Lower Q2 Channel: ',get(get(gca,'title'),'string')]);
% subplot(4,1,4); obw((Q_uwin2),Fs);title(['Upper Q2 Channel: ',get(get(gca,'title'),'string')]);

xlim = numel(I_cor)/8;
figure; 
if (logscale)
    subplot(3,1,1); hold on; plot(20*log10(abs(I_cor(1:xlim)))); scatter(I_cor_ind,20*log10(I_cor_val)); title('Icorr'); hold off;
    subplot(3,1,2); hold on; plot(20*log10(abs(Q_cor(1:xlim)))); scatter(Q_cor_ind,20*log10(Q_cor_val)); title('Qcorr'); hold off;
    subplot(3,1,3); hold on; plot(20*log10(abs(IQ_cor(1:xlim)))); scatter(IQ_cor_ind,20*log10(IQ_cor_val)); title('IQcorr'); hold off;
else
    subplot(3,1,1); hold on; plot(abs(I_cor(1:xlim))); scatter(I_cor_ind,I_cor_val); title('Icorr'); hold off;
    subplot(3,1,2); hold on; plot(abs(Q_cor(1:xlim))); scatter(Q_cor_ind,Q_cor_val); title('Qcorr'); hold off;
    subplot(3,1,3); hold on; plot(abs(IQ_cor(1:xlim))); scatter(IQ_cor_ind,IQ_cor_val); title('IQcorr'); hold off;
end

xlim = numel(I_cor);
figure; 
if (logscale)
    subplot(3,1,1); hold on; plot(20*log10(abs(I_cor(1:xlim)))); scatter(I_cfar_ind,20*log10(I_cfar_val)); plot(20*log10(I_cfar_thresh(1:xlim)));title('Icfar'); hold off;
    subplot(3,1,2); hold on; plot(20*log10(abs(Q_cor(1:xlim)))); scatter(Q_cfar_ind,20*log10(Q_cfar_val)); plot(20*log10(abs(Q_cfar_thresh(1:xlim)))); title('Qcfar'); hold off;
    subplot(3,1,3); hold on; plot(20*log10(abs(IQ_cor(1:xlim)))); scatter(IQ_cfar_ind,20*log10(IQ_cfar_val));plot(20*log10(abs(IQ_cfar_thresh(1:xlim)))); title('IQfar'); hold off;
else
    subplot(3,1,1); hold on; plot(abs(I_cor(1:xlim))); scatter(I_cfar_ind,I_cfar_val); plot(abs(I_cfar_thresh(1:xlim)));title('Icfar'); hold off;
    subplot(3,1,2); hold on; plot(abs(Q_cor(1:xlim))); scatter(Q_cfar_ind,Q_cfar_val); plot(abs(Q_cfar_thresh(1:xlim))); title('Qcfar'); hold off;
    subplot(3,1,3); hold on; plot(abs(IQ_cor(1:xlim))); scatter(IQ_cfar_ind,IQ_cfar_val); plot(abs(IQ_cfar_thresh(1:xlim))); title('IQcfar'); hold off;
end

fprintf('I correlation peak ind: %s\n',sprintf('%i. ',I_cor_ind));
fprintf('Q correlation peak ind: %s\n',sprintf('%i. ',Q_cor_ind));
fprintf('IQ correlation peak ind: %s\n',sprintf('%i. ',IQ_cor_ind));

%% 
if (numel(I_cor_ind)>0)
    compshift = 2*I_cor_ind(1);
else 
    compshift = 1;
end
complen = 4096-512;
I_in = fft(I_lwin(compshift:(complen+compshift-1)));
I_out = fft(I_uwin(1:complen));
H_I = I_in./I_out;
I_txcomp = I_out./H_I;

I_comp = ifft(I_txcomp);
waveformToFile(I_comp',I_comp','/Users/sam/outputs/waveform_data_comp.bin','bin');

figure; subplot(2,1,1); plot(I_comp);title('System Compensated Waveform'); subplot(2,1,2); obw(I_comp);
figure; subplot(2,1,1);plot(abs(H_I));title('System Response Function Mag from inversion'); subplot(2,1,2);plot(angle(H_I));title('System Response Function phase from inversion');
