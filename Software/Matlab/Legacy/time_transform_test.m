fclock = 245.76e6;
nsamples = 4;
nadcsamples = 118;
sig_len = nadcsamples + nsamples;
freq = 79.99875e6;
dac_sig_i = sig_len*[cos(2*pi*freq*([0:(nsamples-1)]./fclock)),zeros(1,nadcsamples)];
dac_sig_q = sig_len*[sin(2*pi*freq*([0:(nsamples-1)]./fclock)),zeros(1,nadcsamples)];

%dac_sig_i = sig_len*[ones(1,nsamples),zeros(1,nadcsamples)];
%dac_sig_q = sig_len*[ones(1,nsamples),zeros(1,nadcsamples)];

adc_shift = 100;
adc_sig_i = [zeros(1,adc_shift),dac_sig_i(1:end-adc_shift)];
adc_sig_q = [zeros(1,adc_shift),dac_sig_q(1:end-adc_shift)];

figure; hold on; plot(dac_sig_q);plot(adc_sig_q,'r');

% fast_time_sample = mod([0:(num_pulses*numel(adc_sig_i)-1)],sample_max);
% slow_time_sample = linspace(0,sample_max,num_pulses*numel(adc_sig_i));
% % t_trans_i = zeros(1,num_pulses*numel(adc_sig_i));
% % t_trans_q = zeros(1,num_pulses*numel(adc_sig_q));
% shift_count = 0;
% t_trans_i =  fast_time_sample-slow_time_sample+repmat(dac_sig_i+adc_sig_i,1,num_pulses);
% t_trans_q =  fast_time_sample-slow_time_sample+repmat(dac_sig_q+adc_sig_q,1,num_pulses);
% 
% st_sample_i = t_trans_i(1:slow_sample_d:end);
% st_sample_q = t_trans_q(1:slow_sample_d:end);
st_sample_i = slowTimeTransform(dac_sig_i,adc_sig_i,freq);
st_sample_q = slowTimeTransform(dac_sig_q,adc_sig_q,freq);


% figure;
% subplot(5,1,1); hold on; plot(repmat(dac_sig_i,1,num_pulses),'b');plot(repmat(adc_sig_i,1,num_pulses),'r');
% subplot(5,1,2); hold on; plot(repmat(dac_sig_q,1,num_pulses),'b');plot(repmat(adc_sig_q,1,num_pulses),'r');
% subplot(5,1,3); hold on; plot(fast_time_sample); plot(slow_time_sample,'r');
% subplot(5,1,4); plot(st_sample_i);
% subplot(5,1,5); plot(st_sample_q);