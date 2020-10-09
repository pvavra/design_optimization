n = 10000;
lambda = 1;

s = rExponential(n,lambda);

figure(77); clf;
% hist(s)

figure(66); clf;

x = linspace(0,10);
y = lambda*(1 - exp(-x/lambda));
plot(x,y)

