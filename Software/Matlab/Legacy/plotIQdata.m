%filename = '../outputs/single_chirp.bin'; bitformat = 'uint32';
%filename = '../outputs/adc_chirp.bin'; bitformat = 'uint32';
%filename = '../outputs/chirp_shifted.bin'; bitformat = 'uint32';
%filename = '../C/Listener/outdata.bin'; bitformat = 'uint32';
filename = '/Users/sam/outputs/en4_dataout.bin'; bitformat = 'uint32';
byteoffset = 0;
packetsize = 528;
headersize = 16;

has_counter = 0;
if (strcmp(bitformat,'uint8')||strcmp(bitformat,'int8'))
    bytesperword = 1;
elseif (strcmp(bitformat,'uint16')||strcmp(bitformat,'int16'))
    bytesperword = 2;
elseif (strcmp(bitformat,'uint32')||strcmp(bitformat,'int32'))
    bytesperword = 4;
end
fileID = fopen(filename,'r');
fseek(fileID,byteoffset,'bof');
A=fread(fileID,bitformat);
fclose(fileID);
size(A)
numbytes = (packetsize-headersize)/bytesperword;
format long;


if (has_counter)
    % find beginning of first 512 bit sub-packet
    subp_found = 0; 
    ind = 1;
    counter_offset = 0;
    % First case: counter is upper 32 bits of each 64 bit word
    if A(1) == A(2*8-1)+7
        subp_found = 1;
        ind = 1;
    else
        subp_found = 0; ind = 3;
        while (subp_found ==0 && ind <= 64/bytesperword)
            temp = A(ind);
            if ((A(ind) ~= A(ind-2)-1)&&(A(ind+2) == A(ind)-1))
                subp_found = 1;
            else
                ind = ind+2;
            end
        end
    end

    % counter offset supports counter in either lower or upper 32b of 64b word 
    if (subp_found == 1)
        counter_offset = 0;
    % Second case: counter is lower 32 bits of each 64 bit word    
    else 
        counter_offset = 1;
        if A(2) == A(2*8)+7
            subp_found = 1;
            ind = 2;
        else 
            subp_found = 0;
            ind = 4;
            while (subp_found ==0 && ind <= 64/bytesperword)
                temp = A(ind);
                if ((A(ind) ~= A(ind-2)-1)&&(A(ind+2) == A(ind)-1))
                    subp_found = 1;
                else
                    ind = ind+2;
                end
            end
        end
    end
else
% Manually find beginning of first 512 bit sub-packet
    subp_found = 0; 
    ind = 2;
    counter_offset = 1;
end
ind = 2;
counter_offset = 1;
% get rid of partial sub-packets at beginning
A_round = A(ind-counter_offset:end);
% now get rid of partial sub-packets at end -- assume 512b sub-packets
shave_end = mod(numel(A_round),64/(bytesperword));

% divide 64 bit words into 32 bit counter and 32 bit samples
data = A_round(2-counter_offset:2:end-shave_end-counter_offset);
counter = A_round(1+counter_offset:2:end-shave_end-1+counter_offset);

% ordering correction: reshape sub-packets to be sequential
counter = reshape(flipud(reshape(counter(1:end),8*(8/(2*bytesperword)),[])),[],1);
data = reshape(flipud(reshape(data(1:end),8*(8/(2*bytesperword)),[])),[],1);


adcctr1 = data(1:4352:end);
adcctr2 = data(4352:4352:end);
adcctr = zeros(numel(adcctr1)+numel(adcctr2),1);
adcctr(1:2:end) = adcctr1;
adcctr(2:2:end) = adcctr2;

glblctr1 = counter(1:4352:end);
glblctr2 = counter(4352:4352:end);
glblctr = zeros(numel(glblctr1)+numel(glblctr2),1);
glblctr(1:2:end) = glblctr1;
glblctr(2:2:end) = glblctr2;

% figure; plot(adcctr); title('Decoded ADC Counter');
% figure; plot(glblctr); title('Decoded Global Counter');

% Add sub-packets to data -- currently unused. Due to current byte ordering
% inclusion of sub-packets causes jump discontinuities 

% % Create vectors for partial sub-packets at front and back of transmission
% Apart_front = []; 
% Apart_back = [];
% 
% % Require at least 2 32b words in front
% if (ind-counter_offset > 2)
%     Apart_front = A(1:ind-counter_offset-1);
%     if (mod(numel(Apart_front),2) == 1)
%         Apart_front = Apart_front(2:end);
%     end
% end
% 
% % Require at least 2 32b words at end
% if (shave_end>1)
%     Apart_back = A(end-shave_end+1:end);
%     if (mod(numel(Apart_back),2)==1)
%         Apart_back = Apart_back(1:end-1);
%     end
% end
% counter_front = flipud(Apart_front(1+counter_offset:2:end));
% data_front = flipud(Apart_front(2-counter_offset:2:end));
% counter_back = flipud(Apart_back(1+counter_offset:2:end));
% data_back = flipud(Apart_back(2-counter_offset:2:end));
% 
% counter = [counter_front;counter;counter_back];
% data = [data_front;data;data_back];


% Extract IQ data as signed 16 bit integers
data_iq = dec2hex(data);
I = double(typecast(uint16(hex2dec(data_iq(:,1:4))),'int16')); 
Q = double(typecast(uint16(hex2dec(data_iq(:,5:end))),'int16'));

data_iq2 = dec2hex(counter);
I2 = double(typecast(uint16(hex2dec(data_iq2(:,1:4))),'int16')); 
Q2 = double(typecast(uint16(hex2dec(data_iq2(:,5:end))),'int16'));

% determine size and location of skips/drops
if (has_counter)
    num_drops = counter(end)-counter(1)-numel(counter)+1;
    counter_jumps = [];
    for i=2:numel(counter)
        if (counter(i) ~= counter(i-1)+1)
            counter_jumps = [counter_jumps, i];
        end
    end
    counter_jumps = [counter_jumps, numel(counter)];
else     
    counter_jumps = [1, numel(counter)];
end


% Plot decoded counter
chirpmin = 3;  chirpmax = 4298; 
%chirpmin = counter_jumps(1); chirpmax = counter_jumps(2);

Fs = 245.76e6;
chirpBW = 15.360000e6;
chirpT = 16.667e-6;
nsamples = Fs*chirpT;

% Plot a PSD with 90% Occupied BW of IQ data
x = I(chirpmin:chirpmax)+1i*Q(chirpmin:chirpmax);
% figure; 
% subplot(2,1,1); obw(real(x),Fs); 
% title(['I Channel: ',get(get(gca,'title'),'string')]);
% 
% subplot(2,1,2);  obw(imag(x),Fs);
% title(['Q Channel: ',get(get(gca,'title'),'string')]);

%figure; obw(x,Fs); title(['x = I+jQ: ',get(get(gca,'title'),'string')]);
%figure; plot(20*log10(abs(fftshift(fft(x))))); title('fft of I+i*Q');

if (has_counter)
    % Plot complete data set with locations of counter jumps 
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
else    
%     figure; 
%     % Plot decoded data
%     subplot (4,1,1); plot(I(chirpmin:chirpmax)); 
%     axis tight; title('Decoded I'); 
%     subplot(4,1,2); plot(I2(chirpmin:chirpmax)); 
%     axis tight; title('Decoded I2');    
%     subplot (4,1,3); plot(Q(chirpmin:chirpmax)); 
%     axis tight; title('Decoded Q'); 
%     subplot(4,1,4); plot(Q2(chirpmin:chirpmax)); 
%     axis tight; title('Decoded Q2');
% 
%     figure; 
%     subplot(2,1,1); hold on;
%     plot(I(chirpmin:chirpmax));plot(I2(chirpmin:chirpmax),'r');
%     title('I and I2 Channels');legend('I','I2');axis tight; hold off;
%     subplot(2,1,2); hold on;
%     plot(Q(chirpmin:chirpmax));plot(Q2(chirpmin:chirpmax),'r');
%     title('Q and Q2 Channels');legend('Q','Q2');axis tight; hold off;
%     
%     figure; 
%     subplot(2,1,1); hold on;
%     plot(I);plot(I2,'r');
%     title('I and I2 Channels');legend('I','I2');axis tight; hold off;
%     subplot(2,1,2); hold on;
%     plot(Q);plot(Q2,'r');
%     title('Q and Q2 Channels');legend('Q','Q2');axis tight; hold off;
    
    % Plot a PSD with 90% Occupied BW of IQ data
    x2 = I2(chirpmin:chirpmax)+1i*Q2(chirpmin:chirpmax);
    figure; 
    subplot(2,1,1); obw(real(x2),Fs); 
    title(['I2 Channel: ',get(get(gca,'title'),'string')]);

    subplot(2,1,2);  obw(imag(x2),Fs);
    title(['Q2 Channel: ',get(get(gca,'title'),'string')]);
   
    
    [If,Ifshift,Itshift] = getFreqShift(I(chirpmin:chirpmax),I2(chirpmin:chirpmax),Fs,chirpBW,chirpT);
    [Qf,Qfshift,Qtshift] = getFreqShift(Q(chirpmin:chirpmax),Q2(chirpmin:chirpmax),Fs,chirpBW,chirpT);
   
    Isdelay = Fs*Itshift;
    Qsdelay = Fs*Qtshift;
        
    fprintf('I ch. Freq Shift: %f Mhz\n',Ifshift/1e6);
    fprintf('Q ch. Freq Shift: %f Mhz\n',Qfshift/1e6);
    fprintf('I ch. time Shift: %f usec\n',Itshift*1e6);
    fprintf('Q ch. time Shift: %f usec\n',Qtshift*1e6);
    fprintf('I ch. sample delay: %f (%i samples)\n',Isdelay,round(Isdelay));
    fprintf('Q ch. sample delay: %f (%i samples)\n',Qsdelay,round(Qsdelay));
    
    
    snum_i = 25;
    snum_q = 25;
    fftlen = ceil(Fs*nsamples/chirpBW);
    IShift = [zeros(snum_i,1);I(chirpmin:chirpmax-snum_i)];
    QShift = [zeros(snum_q,1);Q(chirpmin:chirpmax-snum_q)];
    [If,Ifshift,Itshift] = getFreqShift(I2(chirpmin:chirpmax),IShift,Fs,chirpBW,chirpT,fftlen);
    [Qf,Qfshift,Qtshift] = getFreqShift(Q2(chirpmin:chirpmax),QShift,Fs,chirpBW,chirpT,fftlen);
   
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
     
    fvec = linspace(0,Fs/2e6,numel(If));
    figure; 
    subplot(2,1,1); hold on;
    plot(I2(chirpmin:chirpmax-iSampledelay));
    plot(IShift(1+iSampledelay:end),'r');
    title('Delay Shifted I and I2 Channels');legend('I2','I');axis tight; hold off;
    subplot(2,1,2); hold on;
    plot(Q2(chirpmin:chirpmax-qSampledelay)); 
    plot(QShift(1+qSampledelay:end),'r');
    title('Delay Shifted Q and Q2 Channels');legend('Q2','Q');axis tight; hold off;
    

end
    
fftlen = 4096;
%fftlen = 2*floor(((Fs/chirpBW)*nsamples)/2); % 8192; 
alpha = 1; beta = 1;
xI = fft((I(chirpmin:chirpmax)+IShift).*I2(chirpmin:chirpmax),fftlen);
figure; subplot(4,1,1); plot(real(xI)); subplot(4,1,2); plot(imag(xI));
subplot(4,1,3); plot(abs(xI)); subplot(4,1,4); plot(magest(xI,alpha,beta));
xQ = fft((Q(chirpmin:chirpmax)+QShift).*Q2(chirpmin:chirpmax),fftlen);
figure; subplot(4,1,1); plot(real(xQ)); subplot(4,1,2); plot(imag(xQ));
subplot(4,1,3); plot(abs(xQ)); subplot(4,1,4); plot(magest(xQ,alpha,beta));
    
lenR = numel(xI)/2;
dR = (3e8)/(2*Fs);
tfactor = (chirpT/chirpBW)*linspace(0,Fs/2,numel(xI)/2);
rngs = tfactor*(3e8/2);
Irng = abs(xI(1:end/2));
R = decimate(rngs,max(1,floor(numel(rngs)/nsamples)));
Irvec = decimate(Irng,max(1,floor(numel(rngs)/nsamples)));
figure;plot(R,Irvec);
figure;plot(rngs,Irng);
%     figure; hold on;
%     plot(I);plot(Q,'r');
%     title('I and Q Channels');legend('I','Q');axis tight; hold off;
