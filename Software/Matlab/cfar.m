function s = cfar(varargin)
s = [];
if nargin<2
    return;
else
    x = varargin{1};
    winSize = varargin{2};
end

if nargin<3
    mode = 'ca';
else
    mode = varargin{3};
end

n = numel(x);
s = zeros(size(x));
for i = 1:n
    lhs = abs(x(max(1,i-winSize/2-1):max(1,i-2)));
    rhs = abs(x(min(n,i+2):min(n,i+winSize/2+1)));
    if(strcmp(mode,'cago'))
        pwr = max(mean(lhs),mean(rhs));
    elseif(strcmp(mode,'caso'))
        pwr = min(mean(lhs),mean(rhs));
    else
        pwr = mean([lhs(:);rhs(:)]);
    end
    a = numel(lhs)+numel(rhs)
    s(i) = pwr;
end
end