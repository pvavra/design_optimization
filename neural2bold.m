function bold = neural2bold(neural,TR,microtime,P)
% need to get HRF on microtime resolution, not TR, for convolution
hrf_microtime = spm_hrf(TR/microtime,P,microtime);

bold = conv(neural,hrf_microtime);

% conv() returns a "too long" timeseries
bold = bold(1:length(neural));

end