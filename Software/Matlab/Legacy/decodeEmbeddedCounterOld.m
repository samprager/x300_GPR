function [x_min,x_max,adcctr,glblctr] = decodeEmbeddedCounterOld(dataU,dataL)

x_min = 1;
for i=2:numel(dataU)
    if ((dataU(i)==dataU(i-1)+1)&& (dataL(i)~=dataL(i-1)+1))
        x_min = i+1;
        break;
    elseif((dataL(i)==dataL(i-1)+1)&& (dataU(i)~=dataU(i-1)+1))
        x_min = i+1;
        break;
    end
end

for i=x_min:numel(dataU)
    if ((dataU(i)==(dataU(x_min-1)+(i-x_min+1)))&&(dataL(i)==(dataL(x_min-1)+(i-x_min+1))))
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