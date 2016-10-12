function [x_min,x_max,adcctr,glblctr] = decodeEmbeddedCounter(dataU,dataL)

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

adcctr1 = dataL(x_min:num_data_pts+2:end);
adcctr2 = dataL(x_min+num_data_pts+1:num_data_pts+2:end);
adcctr = zeros(numel(adcctr1)+numel(adcctr2),1);
adcctr(1:2:end) = adcctr1;
adcctr(2:2:end) = adcctr2;

glblctr1 = dataU(x_min:num_data_pts+2:end);
glblctr2 = dataU(x_min+num_data_pts+1:num_data_pts+2:end);
glblctr = zeros(numel(glblctr1)+numel(glblctr2),1);
glblctr(1:2:end) = glblctr1;
glblctr(2:2:end) = glblctr2;
end