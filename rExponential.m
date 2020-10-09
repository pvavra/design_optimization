function samples = rExponential(n, lambda)
% returns n samples which are have an exponential distribution with decay
% rate lambda

s = rand(1,n);
samples = -log(s+1);
end

