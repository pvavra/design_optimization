ExpandPath();

tic
%% define efficiency estimation settings
nSims = 10;

%% Scanner settings
TR = 1;
microtime = 340;

% all timings are in seconds
t_start = 117; % baseline_before_first_trial
% total number of volumes measured
nScans = 1220; % 30 * (60 / TR);  % first nr is in minutes

% HRF double-gamma parameters used by SPM
P = [6 16 1 1 6 0 32];


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

%% Define contrast(s) of interest
C_all_equal = eye(6);
C_tones = [1 -1 0 0 0 0]; % difference in tones
C_traces = [0 0 1 -1 0 0];
C_shocks = [0 0 0 0 -1 0];
% store names of contrast
listC_names = {'mean','tones','traces','shocks'};
listC = {C_all_equal, C_tones, C_traces, C_shocks};

toc

tic
nTones = 2 * nPresentations_perTone;
t = -1 + 1:(TR/microtime):(nScans*TR); t = t(1:(nScans * microtime));

min_aftershock = 5; 
lambda = 1.5; T = 3; % from Mumford et al., 2014

for iSim = nSims:-1:1
    
    % decide which stimulus should have which frequency:
    isTone1kHz = ones(1,nPresentations_perTone*2);
    isTone1kHz(1:2:end) = 0; % alternating
    isTone1kHz = logical(isTone1kHz);
    if iSim > 1 % keep first iteration == original design
        % shuffle order randomly
        isTone1kHz = isTone1kHz(randperm(length(isTone1kHz)));
    end
    listIsTone1kHz{iSim} = isTone1kHz;
    
    
    
    if iSim == 1
        duration_aftershock = repmat(30,size(isTone1kHz));
    else
        duration_aftershock = rExponential(length(isTone1kHz),...
            lambda,T, min_aftershock);
        % round jitter to nearest microtime
        duration_aftershock = round(duration_aftershock * microtime/TR)*TR/microtime;
    end
    listDurationAftershock{iSim} = duration_aftershock;
    % if 0, then tone == 15kHz; if 1, then 1kHz
    
    
    ISI = duration_tone + duration_trace + duration_shock + duration_aftershock;
    listISI{iSim} = ISI;
    
    ISIcummulative = ISI .* (0:((nPresentations_perTone-1)*2+1));
    
    
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
    %     WX = W*X;
    WX = X;
    % apply high-pass filter
    % apply filtering matrix to data
    KWX = spm_filter(K,WX);
    
    %% calculate efficiency for all contrasts
    for iC = 1:numel(listC)
        currentEff{iC} =  efficiency(KWX,listC{iC});
    end
    
    listEff{iSim} = currentEff;
    
end

toc