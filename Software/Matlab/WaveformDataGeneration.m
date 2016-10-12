chirp_type = 'log';
win_types = {'_blk','_hann','_ham','_bhar',''};
% win_type = '_bhar';
for types = win_types
win_type = char(types);
fs = 245.76e6;
n = 4096-512;
f0 = 10e6; f1 = 65e6; f_ricker =122e6;
t = linspace(0,n/fs,n);
ti  = linspace(-n/(1*fs),n/(1*fs),n);
f = 10;
scale = double(intmax('int16'));

switch win_type
    case '_blk'
        win = getBlackman(n)';
    case '_bhar'
        win = getBlackmanHarris(n)';
    case '_ham'
        win = getHamming(n)';
    case '_hann'
        win = getHann(n)';
    otherwise
        win = 1;
end

Q_gaus = gauspuls(ti,50E6,.1).*win;
I_gaus = gauspuls(ti,50E6,.1).*win;
I_quad =chirp(t,f0,t(end),f1,'q',[],'convex').*win;
Q_quad =chirp(t,f0,t(end),f1,'q',-90,'convex').*win;
I_log =chirp(t,f0,t(end),f1,'logarithmic').*win;
Q_log =chirp(t,f0,t(end),f1,'logarithmic',-90).*win;
I_lin =chirp(t,f0,t(end),f1,'linear').*win;
Q_lin =chirp(t,f0,t(end),f1,'linear',-90).*win;
I_rick = rickerWavelet(t,f_ricker,t(end/2)).*win;
Q_rick = rickerWavelet(t,f_ricker,t(end/2)).*win;

I_test = zeros(1,n);
Q_test = zeros(1,n);
I_test(ceil(end/2)) = 1;
Q_test(ceil(end/2)) = 1;

% I = cos(2*pi*f*t);
% Q = sin(2*pi*f*t);

switch chirp_type
    case 'rick'
       data_i = int16(scale*I_rick);
       data_q = int16(scale*Q_rick); 
    case 'gaus'
       data_i = int16(scale*I_gaus);
       data_q = int16(scale*Q_gaus); 
    case 'lin'
       data_i = int16(scale*I_lin);
       data_q = int16(scale*Q_lin); 
    case 'log'
       data_i = int16(scale*I_log);
       data_q = int16(scale*Q_log); 
    case 'quad'
       data_i = int16(scale*I_quad);
       data_q = int16(scale*Q_quad); 
    case 'test'
        data_i = int16(scale*I_test);
        data_q = int16(scale*Q_test);
end

data = reshape([data_i;data_q],1,2*n);
fileID = fopen('/Users/sam/outputs/waveform_data.bin','w');
frewind(fileID);
fwrite(fileID,data,'int16');
fclose(fileID);

data_i_lin = int16(scale*I_lin);
data_q_lin = int16(scale*Q_lin); 
data_i_log = int16(scale*I_log);
data_q_log = int16(scale*Q_log); 
data_i_quad = int16(scale*I_quad);
data_q_quad = int16(scale*Q_quad); 
data_i_gaus = int16(scale*I_gaus);
data_q_gaus = int16(scale*Q_gaus); 
data_i_rick = int16(scale*I_rick);
data_q_rick = int16(scale*Q_rick); 

data_lin = reshape([data_i_lin;data_q_lin],1,2*n);
data_log = reshape([data_i_log;data_q_log],1,2*n);
data_quad = reshape([data_i_quad;data_q_quad],1,2*n);
data_gaus = reshape([data_i_gaus;data_q_gaus],1,2*n);
data_rick = reshape([data_i_rick;data_q_rick],1,2*n);

fname = sprintf('/Users/sam/outputs/waveform_data_lin%s.bin',win_type);
fileID = fopen(fname,'w');
frewind(fileID);
fwrite(fileID,data_lin,'int16');
fclose(fileID);

fname = sprintf('/Users/sam/outputs/waveform_data_log%s.bin',win_type);
fileID = fopen(fname,'w');
frewind(fileID);
fwrite(fileID,data_log,'int16');
fclose(fileID);

fname = sprintf('/Users/sam/outputs/waveform_data_quad%s.bin',win_type);
fileID = fopen(fname,'w');
frewind(fileID);
fwrite(fileID,data_quad,'int16');
fclose(fileID);

fname = sprintf('/Users/sam/outputs/waveform_data_gaus%s.bin',win_type);
fileID = fopen(fname,'w');
frewind(fileID);
fwrite(fileID,data_gaus,'int16');
fclose(fileID);

fname = sprintf('/Users/sam/outputs/waveform_data_rick%s.bin',win_type);
fileID = fopen(fname,'w');
frewind(fileID);
fwrite(fileID,data_rick,'int16');
fclose(fileID);

end
% figure; plot(I);title('I');
% figure; plot(Q);title('Q');
% figure; obw(Q_lin,fs);

%%
packet_size = 552;
header_size = 24+16;
num_packets = (n*4)/(packet_size-header_size)
full_pkts = floor(num_packets)
partial_pkt_size = n*4-full_pkts*(packet_size-header_size)+header_size