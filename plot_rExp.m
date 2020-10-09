n = 10000;
lambda = 1.5;
T = 3;
shift = 0;
s = rExponential(n,lambda,T, shift);

figure(77); clf;
histogram(s,'Normalization','pdf')
hold on
title(sprintf('mean: %g',mean(s)))

% 
% figure(66); clf;
% 
x = linspace(0,max(s));
y = exp(-x/lambda);
plot(x,y)

