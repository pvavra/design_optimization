addpath('/opt/spm12')
tic
%% define efficiency estimation settings
nSims = 10;

%% Scanner settings
TR = 1;
microtime = 30;

% all timings are in seconds
t_start = 117; % baseline_before_first_trial
% total number of volumes measured
nScans = 1220; % 30 * (60 / TR);  % first nr is in minutes

%% define prewhitening and high-pass filter matrices
rho=0.4;
V = makeV(rho,nScans);

% get whitening matrix W - using same code as spm_spm.m (lines 441)
W = spm_sqrtm(spm_inv(V));
W = W.*(abs(W) > 1e-6);

% get spm filter
K = DefineHighpassFilter(nScans,TR);

%% Define design - fixed aspects
% Trial:  10s Tone, then 13s nothing, then 2s expected shock (but not
% delivered). After the (expected) shock, there is a 30s baseline before
% the next tone is presented. Tones come in two variants: 1kHz
% (conditioned) and 15kHz (novel). The two tones are presented in
% alternative fashion, 10 presentations each.

% neural_box_cars
duration_tone = 10;
duration_trace = 13;
duration_shock = 2;

% assuming equal nr of presentations for both tones
nPresentations_perTone = 10;

nTones = 2 * nPresentations_perTone ;


toc
tic
nTones = 2 * nPresentations_perTone;
t = -1 + 1:(TR/microtime):(nScans*TR); t = t(1:(nScans * microtime));
for iSim = nSims:-1:1
     
    duration_aftershock(iSim) = 4 ; % TODO Vary from iteration to iteration
    
    % if 0, then tone == 15kHz; if 1, then 1kHz
    
    isTone1kHz = ones(1,nPresentations_perTone*2);
    isTone1kHz(1:2:end) = 0; % alternating
    isTone1kHz = logical(isTone1kHz); % TODO add (iSim)
    
    
    ISI = duration_tone + duration_trace + duration_shock + duration_aftershock;
    ISIcummulative = ISI .* (0:((nPresentations_perTone-1)*2+1)); % TODO Add (iSim)
    
    
    %% design -> onsets
    onsets_tone_all = t_start + ISIcummulative;
    
    onsets_1kHz_tone = onsets_tone_all(isTone1kHz);
    onsets_15kHz_tone = onsets_tone_all(~isTone1kHz);
    
    onsets_1kHz_trace = onsets_1kHz_tone + duration_tone;
    onsets_15kHz_trace = onsets_15kHz_tone + duration_tone;
    
    onsets_1kHz_shock = onsets_1kHz_tone + duration_tone + duration_trace;
    onsets_15kHz_shock = onsets_15kHz_tone + duration_tone + duration_trace;
    
    
    %% onsets -> design matrix
    
    
    neural_1kHz_tone = onsets2boxcar(t, onsets_1kHz_tone, duration_tone);
    neural_15kHz_tone = onsets2boxcar(t, onsets_15kHz_tone, duration_tone);
    
    neural_1kHz_trace = onsets2boxcar(t, onsets_1kHz_trace, duration_trace);
    neural_15kHz_trace = onsets2boxcar(t, onsets_15kHz_trace, duration_trace);
    
    neural_1kHz_shock = onsets2boxcar(t, onsets_1kHz_shock, duration_shock);
    neural_15kHz_shock = onsets2boxcar(t, onsets_15kHz_shock, duration_shock);
    
    % following are on microtime-timescale
    bold_1kHz_tone = neural2bold(neural_1kHz_tone, TR, microtime, P);
    bold_15kHz_tone = neural2bold(neural_15kHz_tone, TR, microtime, P);
    bold_1kHz_trace = neural2bold(neural_1kHz_trace, TR, microtime, P);
    bold_15kHz_trace = neural2bold(neural_15kHz_trace, TR, microtime, P);
    bold_1kHz_shock = neural2bold(neural_1kHz_shock, TR, microtime, P);
    bold_15kHz_shock = neural2bold(neural_15kHz_shock, TR, microtime, P);
    
    X = [bold_1kHz_tone; ...
        bold_15kHz_tone; ...
        bold_1kHz_trace; ...
        bold_15kHz_trace; ...
        bold_1kHz_shock; ...
        bold_15kHz_shock; ...
        ]';
    X = downsample(X,microtime); assert(size(X,1) == nScans);
    
    %% Apply filters:
    % pre-whiten designmatrix
    WX = W*X;
    % apply high-pass filter
    % apply filtering matrix to data
    KWX = spm_filter(K,WX);
    
    %% Define contrast(s) of interest
    C = eye(size(X,2));
    eff(iSim) = efficiency(KWX,C);
    
end

toc