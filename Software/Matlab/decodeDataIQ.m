function [I,Q] = decodeDataIQ(data)
data_iq = dec2hex(data);
I = double(typecast(uint16(hex2dec(data_iq(:,1:4))),'int16'));
Q = double(typecast(uint16(hex2dec(data_iq(:,5:end))),'int16'));

end