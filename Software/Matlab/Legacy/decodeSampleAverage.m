function [avgI_u,avgQ_u,avgI_l,avgQ_l] = decodeSampleAverage(dataU,dataL)

DATA_FIRST_COMMAND = hex2dec('46525354');       %Ascii FRST
DATA_LAST_COMMAND = hex2dec('4c415354');      %Ascii LAST
x_min = 1;
for i=1:numel(dataU)
    if(dataU(i)==DATA_FIRST_COMMAND)
        x_min = i;
        break;
    elseif(dataL(i)==DATA_FIRST_COMMAND)
        x_min = i;
        break;
    end
end   

for i=(x_min+1):numel(dataU)
    if((dataU(i)==DATA_LAST_COMMAND)&&(dataL(i) == (dataL(x_min)+(i-x_min))))
        break;
    elseif((dataL(i)==DATA_LAST_COMMAND)&&(dataU(i) == (dataU(x_min)+(i-x_min)))) 
        break;
    end
end
x_max = i;

num_data_pts = x_max-x_min;
[avgI_l,avgQ_l] = decodeDataIQ(dataL(x_min+1:x_max-1));
[avgI_u,avgQ_u]  = decodeDataIQ(dataU(x_min+1:x_max-1));
s_index = x_max+1;
e_index = x_max+1+num_data_pts;
n_acq = 1;
while(e_index<numel(dataL))
    [tmpI_l,tmpQ_l] = decodeDataIQ(dataL(s_index+1:e_index-1));
    [tmpI_u,tmpQ_u] = decodeDataIQ(dataU(s_index+1:e_index-1));
    avgI_l = avgI_l + tmpI_l;
    avgQ_l = avgQ_l + tmpQ_l;
    avgI_u = avgI_u + tmpI_u;
    avgQ_u = avgQ_u + tmpQ_u;
    
    n_acq = n_acq+1;
    s_index = e_index+1;
    e_index = e_index+1+num_data_pts;
end

avgI_l = avgI_l./n_acq;
avgQ_l = avgQ_l./n_acq;
avgI_u = avgI_u./n_acq;
avgQ_u = avgQ_u./n_acq;

end