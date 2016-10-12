function [I_u,Q_u,I_l,Q_l] = decodeSample(dataU,dataL,mode)

DATA_FIRST_COMMAND = hex2dec('46525354');       %Ascii FRST
DATA_LAST_COMMAND = hex2dec('4c415354');      %Ascii LAST

if (strcmp(mode,'average'))
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
    [I_l,Q_l] = decodeDataIQ(dataL(x_min+1:x_max-1));
    [I_u,Q_u]  = decodeDataIQ(dataU(x_min+1:x_max-1));
    s_index = x_max+1;
    e_index = x_max+1+num_data_pts;
    n_acq = 1;
    while(e_index<numel(dataL))
        [tmpI_l,tmpQ_l] = decodeDataIQ(dataL(s_index+1:e_index-1));
        [tmpI_u,tmpQ_u] = decodeDataIQ(dataU(s_index+1:e_index-1));
        I_l = I_l + tmpI_l;
        Q_l = Q_l + tmpQ_l;
        I_u = I_u + tmpI_u;
        Q_u = Q_u + tmpQ_u;
    
        n_acq = n_acq+1;
        s_index = e_index+1;
        e_index = e_index+1+num_data_pts;
    end
    I_l = I_l./n_acq;
    Q_l = Q_l./n_acq;
    I_u = I_u./n_acq;
    Q_u = Q_u./n_acq;
    return;

elseif (strcmp(mode,'first'))
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
    [I_l,Q_l] = decodeDataIQ(dataL(x_min+1:x_max-1));
    [I_u,Q_u]  = decodeDataIQ(dataU(x_min+1:x_max-1));
    return;
else
    x_max = numel(dataU);
    for i=numel(dataU):-1:1
        if(dataU(i)==DATA_LAST_COMMAND)
            x_max = i;
            break;
        elseif(dataL(i)==DATA_LAST_COMMAND)
            x_max = i;
            break;
        end
    end   

    for i=(x_max-1):-1:1
        if((dataU(i)==DATA_FIRST_COMMAND)&&(dataL(i) == (dataL(x_max)-(x_max-i))))
            break;
        elseif((dataL(i)==DATA_FIRST_COMMAND)&&(dataU(i) == (dataU(x_max)-(x_max-i)))) 
            break;
        end
    end
    x_min = i;
    [I_l,Q_l] = decodeDataIQ(dataL(x_min+1:x_max-1));
    [I_u,Q_u]  = decodeDataIQ(dataU(x_min+1:x_max-1));
    return;
end

end