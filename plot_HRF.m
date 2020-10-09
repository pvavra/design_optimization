

microtime = 30;
TR = 1;
P = [6 16 1 1 6 0 32];


hrf = spm_hrf(TR/microtime,P,microtime);
figure(99)
hold off
plot(hrf)
hold on
plot(hrf,'rx')
