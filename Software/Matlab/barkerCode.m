% Usage: b = barkerCode(n,N,sel)
% n : order of code (default is 2)
% N : desired size of output (zero padded)
% sel : select bit for code lengths with multiple barker codes (ie. 2,4)

function b = barkerCode(varargin)
if (nargin<1)
    disp('barkerCode() Error: requires at least one arg');
    return;
end

n = varargin{1};

if (nargin>1) 
    N = varargin{2};
else
    N = n;
end

if (nargin>2) 
    sel = varargin{3};
else
    sel = 0;
end

switch n
    case(2)
        if (sel == 0)
           c = [1,-1];
        else
           c = [1,1]; 
        end
    case(3)
        c = [1,1,-1];
    case(4)
        if (sel == 0)
           c = [1,1,-1,1];
        else
           c = [1,1,1,-1]; 
        end
    case(5)
        c = [1,1,1,-1,1];
    case(7)
        c = [1,1,1,-1,-1,1,-1];
    case(11)
        c = [1,1,1,-1,-1,-1,1,-1,-1,1,-1];
    case(13)
        c = [1,1,1,1,1,-1,-1,1,1,-1,1,-1,1];
    otherwise
        c = [1,-1];        
end

b = zeros(1,N);
b(1:numel(c)) = c;
end
