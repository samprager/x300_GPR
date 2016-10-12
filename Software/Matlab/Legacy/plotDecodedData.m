%filenameC = '../outputs/single_chirpC.bin';
%filenameIQ = '../outputs/single_chirpIQ.bin';
%filenameC = '../outputs/adc_chirpC.bin';
%filenameIQ = '../outputs/adc_chirpIQ.bin';
filenameC = '/Users/sam/outputs/en4_dataout_45C.bin';
filenameIQ = '/Users/sam/outputs/en4_dataout_45IQ.bin';

has_counter = 0;
Fs = 245.76e6;
chirpBW = 3*15.360000e6;
chirpT = 16.667e-6;
nsamples = Fs*chirpT;

minAdcRes = (3e8)/(2*Fs);
minChirpRes = (3e8)/(2*chirpBW);

fileID_C = fopen(filenameC,'r');
fileID_IQ = fopen(filenameIQ,'r');
%fseek(fileID,2,'bof');
counter=fread(fileID_C,'uint32');
data = fread(fileID_IQ,'uint32');

fclose(fileID_C);
fclose(fileID_IQ);

% Extract IQ data as signed 16 bit integers
data_iq = dec2hex(data);
I = double(typecast(uint16(hex2dec(data_iq(:,1:4))),'int16')); 
Q = double(typecast(uint16(hex2dec(data_iq(:,5:end))),'int16'));

counter_jumps = [];
if (has_counter == 1)
    % determine size and location of skips/drops
    num_drops = counter(end)-counter(1)-numel(counter)+1;
    for i=2:numel(counter)
        if (counter(i) ~= counter(i-1)+1)
            counter_jumps = [counter_jumps, i];
        end
    end
    counter_jumps = [counter_jumps, numel(counter)];

    % Plot decoded counter
    front_delay = 203; back_delay = 95; % samples that can be discarded

    %chirpmin = 1; chirpmax = counter_jumps(1); 
    chirpmin = counter_jumps(2); chirpmax = counter_jumps(3);
    %chirpmin = counter_jumps(3)+front_delay; chirpmax = counter_jumps(4)-back_delay;

    figure; 
    subplot(3,1,1); hold on; 
    plot(counter); axis tight; title('Decoded 32 bit Counter');
    y1=get(gca,'ylim'); x1 = [chirpmin,chirpmax];
    line([x1;x1],[y1',y1'],'Color','r');hold off;
    % Plot decoded data
    subplot (3,1,2); plot(I(chirpmin:chirpmax)); 
    axis tight; title('Decoded I'); 

    subplot(3,1,3); plot(Q(chirpmin:chirpmax)); 
    axis tight; title('Decoded Q');

    % Plot complete data set with locations of counter jumps 
    figure; 
    subplot(3,1,1); hold on;
    plot(counter); title('Counter jump/skip locations');
    scatter(counter_jumps,counter(counter_jumps)); axis tight; hold off;
    subplot (3,1,2); hold on; 
    plot(I); title('Decoded I');
    scatter(counter_jumps,I(counter_jumps)); axis tight; hold off;

    subplot(3,1,3); hold on;
    plot(Q); title('Decoded Q');
    scatter(counter_jumps,Q(counter_jumps)); axis tight; hold off;


    % Plot a PSD with 90% Occupied BW of IQ data
    x = I(chirpmin:chirpmax)+1i*Q(chirpmin:chirpmax);
    figure; 
    subplot(2,1,1); obw(real(x),Fs); 
    title(['I Channel: ',get(get(gca,'title'),'string')]);

    subplot(2,1,2);  obw(imag(x),Fs);
    title(['Q Channel: ',get(get(gca,'title'),'string')]);

    %figure; obw(x,Fs); title(['x = I+jQ: ',get(get(gca,'title'),'string')]);
    %figure; plot(20*log10(abs(fftshift(fft(x))))); title('fft of I+i*Q');
    I_fft = fft(real(x));
    I_fft = I_fft(1:end/2);
    Q_fft = (fft(imag(x)));
    Q_fft = Q_fft(1:end/2);
    x1 = linspace(0,Fs/2e6,numel(I_fft));
    x2 = linspace(0,Fs/2e6,numel(Q_fft));
    figure; 
    subplot(2,1,1); plot(x1,10*log10(abs(2*I_fft/Fs))); 
    grid on; title('fft I');%axis tight; 
    subplot(2,1,2);plot(x2,20*log10(abs(Q_fft))); 
    grid on; title('fft Q');%axis tight; 

    figure; hold on;
    plot(I);plot(Q,'r');
    title('I and Q Channels');legend('I','Q');axis tight; hold off;

else
    
    shift_i = 0; shift_q =0;
    scale_i = 1; scale_q = 1;
    add_waves = 0;
    shift_i2 = 0; shift_q2 = 0;
    data_iq2 = dec2hex(counter);
    I2 = double(typecast(uint16(hex2dec(data_iq2(:,1:4))),'int16')); 
    Q2 = double(typecast(uint16(hex2dec(data_iq2(:,5:end))),'int16'));
   
    partial_offset = 1;
    for i=2:numel(I)
        if ((data(i)==data(i-1)+1)&& (counter(i)~=counter(i-1)+1))
            partial_offset = i+1;
            break;
        elseif((counter(i)==counter(i-1)+1)&& (data(i)~=data(i-1)+1))   
            partial_offset = i+1;
            break;
        end
    end
    
    for i=(partial_offset):numel(I)
        if ((data(i)==(data(partial_offset-1)+(i-partial_offset+1)))&&(counter(i)==(counter(partial_offset-1)+(i-partial_offset+1))))
            break;
        end
    end
    single_pulse_end = i;
    
    adcctr1 = data(partial_offset:4352:end);
    adcctr2 = data(partial_offset+4351:4352:end);
    adcctr = zeros(numel(adcctr1)+numel(adcctr2),1);
    adcctr(1:2:end) = adcctr1;
    adcctr(2:2:end) = adcctr2;

    glblctr1 = counter(partial_offset:4352:end);
    glblctr2 = counter(partial_offset+4351:4352:end);
    glblctr = zeros(numel(glblctr1)+numel(glblctr2),1);
    glblctr(1:2:end) = glblctr1;
    glblctr(2:2:end) = glblctr2;
    
    %win = getBlackmanHarris(chirpmax-chirpmin+1);
    %win = getHamming(chirpmax-chirpmin+1);
    win = 1;
    
    %chirpmin = partial_offset+1; chirpmax = partial_offset+4350;
    chirpmin = partial_offset+1; chirpmax = single_pulse_end-1; %numel(I);
    
    Ishift = add_waves*I(chirpmin:chirpmax)+scale_i*[zeros(shift_i,1);I(chirpmin:chirpmax-shift_i)];
    Qshift = add_waves*Q(chirpmin:chirpmax)+scale_q*[zeros(shift_q,1);Q(chirpmin:chirpmax-shift_q)];
    I2shift = [zeros(shift_i2,1);I2(chirpmin:chirpmax-shift_i2)];
    Q2shift = [zeros(shift_q2,1);Q2(chirpmin:chirpmax-shift_q2)];
    
    figure;
    subplot (4,1,1); plot(Ishift); 
    axis tight; title('Decoded IShift'); 
    % Plot decoded data
    subplot (4,1,2); plot(I2shift); 
    axis tight; title('Decoded I2shift');

    subplot(4,1,3); plot(Qshift); 
    axis tight; title('Decoded QShift');
    subplot(4,1,4); plot(Q2shift); 
    axis tight; title('Decoded Q2Shift');

   
    Iwin = Ishift.*win;
    I2win = I2shift.*win;
    Qwin = Qshift.*win;
    Q2win = Q2shift.*win;
    
    Ishift = Iwin;
    I2shift = I2win;
    Qshift = Qwin;
    Q2shift = Q2win;
    
    figure;
    subplot (4,1,1); plot(I2shift); 
    axis tight; title('Decoded I2Shift'); 
    subplot (4,1,2); plot(I2win); 
    axis tight; title('Windowed I2shift');
    subplot(4,1,3); obw(real(I2shift),Fs); 
    title(['I2 Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,4); obw(real(I2win),Fs); 
    title(['Windowed I2 Channel: ',get(get(gca,'title'),'string')]);
    
    % Plot a PSD with 90% Occupied BW of IQ data
    x = Ishift+1i*Qshift;
    x2 = I2shift+1i*Q2shift;
    figure; 
    subplot(4,1,1); obw(real(x),Fs); 
    title(['I Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,2); obw(real(x2),Fs); 
    title(['I2 Channel: ',get(get(gca,'title'),'string')]);

    subplot(4,1,3);  obw(imag(x),Fs);
    title(['Q Channel: ',get(get(gca,'title'),'string')]);
    subplot(4,1,4);  obw(imag(x2),Fs);
    title(['Q2 Channel: ',get(get(gca,'title'),'string')]);

%figure; obw(x,Fs); title(['x = I+jQ: ',get(get(gca,'title'),'string')]);
%figure; plot(20*log10(abs(fftshift(fft(x))))); title('fft of I+i*Q');
    fftlen = 8192*2;    
    thresholdDB = 30;
%     [I_mixfft,Ifshift,Itshift] = getFreqShift(I2shift,Ishift,Fs,chirpBW,chirpT,fftlen);
%     [Q_mixfft,Qfshift,Qtshift] = getFreqShift(Q2shift,Qshift,Fs,chirpBW,chirpT,fftlen);
    [I_mixfft,Ifshift,Itshift,ind] = getFreqShiftPeaks(I2shift,Ishift,Fs,chirpBW,chirpT,fftlen,thresholdDB);
    [Q_mixfft,Qfshift,Qtshift,ind] = getFreqShiftPeaks(Q2shift,Qshift,Fs,chirpBW,chirpT,fftlen,thresholdDB);
   
    Isdelay = Fs*Itshift;
    Qsdelay = Fs*Qtshift;
        
    fprintf('I Shift ch. Freq Shift: %f Mhz\n',Ifshift/1e6);
    fprintf('Q Shift ch. Freq Shift: %f Mhz\n',Qfshift/1e6);
    fprintf('I Shift ch. time Shift: %f usec\n',Itshift*1e6);
    fprintf('Q Shift ch. time Shift: %f usec\n',Qtshift*1e6);
    fprintf('I Shift ch. sample delay: %f (%i samples)\n',Isdelay,round(Isdelay));
    fprintf('Q Shift ch. sample delay: %f (%i samples)\n',Qsdelay,round(Qsdelay));
    
    iSampledelay = round(Fs*Itshift)-1;
    qSampledelay = round(Fs*Qtshift)-1;
     
%     fvec = linspace(0,Fs/2e6,numel(If_mixfft));
%     figure; 
%     subplot(2,1,1); hold on;
%     plot(I2(chirpmin:chirpmax-iSampledelay));
%     plot(IShift(1+iSampledelay:end),'r');
%     title('Delay Shifted I and I2 Channels');legend('I2','I');axis tight; hold off;
%     subplot(2,1,2); hold on;
%     plot(Q2(chirpmin:chirpmax-qSampledelay)); 
%     plot(QShift(1+qSampledelay:end),'r');
%     title('Delay Shifted Q and Q2 Channels');legend('Q2','Q');axis tight; hold off;
    
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
     
     
%     st_sample_i = slowTimeTransform(I2shift,Ishift,freq);
%     st_sample_q = slowTimeTransform(Q2shift,Qshift,freq);

%     st_sample_i = slowTimeTransform(zeros(1,numel(Ishift)),Ishift,freq);
%     st_sample_q = slowTimeTransform(zeros(1,numel(Qshift)),Qshift,freq);

end