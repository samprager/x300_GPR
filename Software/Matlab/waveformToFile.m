function waveformToFile(I,Q,filename,format)
n = numel(I);
scale = double(intmax('int16'));
scale_i = scale/max(I);
scale_q = scale/max(Q);
data_i = int16(scale_i*I);
data_q = int16(scale_q*Q); 
   
data = reshape([data_i;data_q],1,2*n);
fileID = fopen(filename,'w');
frewind(fileID);
fwrite(fileID,data,'int16');
fclose(fileID);

end