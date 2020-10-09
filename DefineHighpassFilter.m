function [K] = DefineHighpassFilter(nScans,TR)

% define high-pass filter for SPM
% TODO: adapt this for multi-run - this will mean that K will be a
% struct-array of length nRuns
K(1).RT = TR;
K(1).row = 1:nScans; % apply to all images 
K(1).HParam = 128; % cutoff in seconds (i.e. 1/HParam = cutoff frequency)

% make spm generate filtering matrix - stored in K.X0
K = spm_filter(K);


end