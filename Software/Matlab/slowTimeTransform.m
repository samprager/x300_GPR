function result = slowTimeTransform(tx_signal,rx_signal,fsample)

tx_signal = tx_signal(:);
rx_signal = rx_signal(:);

rx_len = numel(tx_signal);
tx_len = numel(rx_signal);

if (tx_len > rx_len)
    rx_signal = [rx_signal;zeros(tx_len-rx_len,1)];
    rx_len = tx_len;
elseif(rx_len > tx_len)
    tx_signal = [tx_signal;zeros(rx_len-tx_len,1)];
    tx_len = rx_len;
end

num_pulses = tx_len;
slow_sample_d = num_pulses+1;
fast_time_sample = mod([0:(num_pulses*num_pulses-1)],num_pulses)';
slow_time_sample = linspace(0,num_pulses,num_pulses*num_pulses)';

t_trans =  fast_time_sample-slow_time_sample+repmat(tx_signal+rx_signal,num_pulses,1);
st_sample = t_trans(1:slow_sample_d:end);

result = st_sample;

figure;
subplot(3,1,1); hold on; plot(repmat(tx_signal,num_pulses,1),'b');plot(repmat(rx_signal,num_pulses,1),'r');
subplot(3,1,2); hold on; plot(fast_time_sample); plot(slow_time_sample,'r');
subplot(3,1,3); plot(st_sample);
