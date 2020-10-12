ExpandPath();

tic
%% define efficiency estimation settings
nSims = 10000;


%% define settings related to ISI
roundISI2oneSec = 1;

%% Scanner settings
TR = 1;
microtime = 40;

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

nTones = 2 * nPresentations_perTone;

%% Define contrast(s) of interest
C_all_equal = eye(6);
C_tones = [1 -1 0 0 0 0]; % difference in tones
C_traces = [0 0 1 -1 0 0];
C_shocks = [0 0 0 0 1 -1];
% tone vs shock
C_ToneVsShock_1kHz = [1 0 0 0 -1 0];
C_ToneVsShock_15kHz = [0 1 0 0 0 -1];
C_Diff_ToneVSShock = [1 -1 0 0 -1 1];
% tone vs trace
C_ToneVsTrace_1kHz = [1 0 -1 0 0 0];
C_ToneVsTrace_15kHz = [0 1 0 -1 0 0];
C_Diff_ToneVStrace = [1 -1 -1 1 0 0];


% store names of contrast
listC_names = {'mean','D:tones','D:traces','D:shocks',...
    '1kHz D:tone-shock','15kHz D:tone-shock', '1-15kHz D:tone-shock', ...
    '1kHz D:tone-trace','15kHz D:tone-trace', '1-15kHz D:tone-trace'};
listC = {C_all_equal, C_tones, C_traces, C_shocks, ...
    C_ToneVsShock_1kHz,C_ToneVsShock_15kHz, C_Diff_ToneVSShock, ...
    C_ToneVsTrace_1kHz,C_ToneVsTrace_15kHz, C_Diff_ToneVStrace };

assert(length(listC_names) == length(listC));

toc

tic
nTones = 2 * nPresentations_perTone;
t = -1 + 1:(TR/microtime):(nScans*TR); t = t(1:(nScans * microtime));

min_aftershock = 1;
lambda = 1.5; T = 3; % from Mumford et al., 2014tile

for iSim = nSims:-1:1
    % decide which stimulus should have which frequency:
    isTone1kHz = ones(1,nPresentations_perTone*2);
    isTone1kHz(1:2:end) = 0; % alternating
    isTone1kHz = logical(isTone1kHz);
    
    
    
    switch iSim
        case 1
            duration_aftershock = repmat(30,size(isTone1kHz));
        case 2
            duration_aftershock = ones(1,length(isTone1kHz));
        case 3
            duration_aftershock = ones(1,length(isTone1kHz)*2);
            isTone1kHz = repmat(isTone1kHz,1,2);
            
        otherwise
            % double the number of trials
            isTone1kHz = repmat(isTone1kHz,1,2);
            isTone1kHz = isTone1kHz(randperm(length(isTone1kHz)));
            % create ITI
            duration_aftershock = rExponential(length(isTone1kHz),...
                lambda,T, min_aftershock);
            
            if roundISI2oneSec
                duration_aftershock = round(duration_aftershock);
            end
            
            % round jitter to nearest microtime
            duration_aftershock = round(duration_aftershock * microtime/TR)*TR/microtime;
    end
    ISI = duration_tone + duration_trace + duration_shock + duration_aftershock;
    
    listIsTone1kHz{iSim} = isTone1kHz;
    listDurationAftershock{iSim} = duration_aftershock;
    listISI{iSim} = ISI;
    
    ISIcummulative = ISI .* (0:(length(isTone1kHz)-1));
    listTotalLength{iSim} = ISIcummulative(end);
    
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
    listX{iSim} = X;
    %% Apply filters:
    % pre-whiten designmatrix
    %     WX = W*X;
    WX = X;
    % apply high-pass filter
    % apply filtering matrix to data
    KWX = spm_filter(K,WX);
    listKWX{iSim} = KWX;
    %% calculate efficiency for all contrasts
    for iC = 1:numel(listC)
        currentEff{iC} =  efficiency(KWX,listC{iC});
    end
    
    listEff{iSim} = currentEff;
    
end

toc