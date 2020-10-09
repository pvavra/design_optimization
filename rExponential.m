function samples = rExponential(n, lambda,T,shift)
% returns n samples which are have an exponential distribution with decay
% rate lambda

s = rand(1,n) * (1-exp(-T/lambda));
samples = -log(1-s)*lambda + shift;
end

