ExpandPath();

%% Define current design
% Trial:  10s Tone, then 13s nothing, then 2s expected shock (but not
% delivered). After the (expected) shock, there is a 30s baseline before
% the next tone is presented. Tones come in two variants: 1kHz
% (conditioned) and 15kHz (novel). The two tones are presented in
% alternative fashion, 10 presentations each.
TR = 1;
microtime = 30;

% all timings are in seconds
t_start = 117; % baseline_before_first_trial
% total number of volumes measured
nScans = 1220; % 30 * (60 / TR);  % first nr is in minutes 

% neural_box_cars
duration_tone = 10;
duration_trace = 13;
duration_shock = 2;

% the following might vary in the future:
duration_aftershock = 30;

% assuming equal nr of presentations for both tones
nPresentations_perTone = 10; 

% if 0, then tone == 15kHz; if 1, then 1kHz
isTone1kHz = ones(1,nPresentations_perTone*2); isTone1kHz(1:2:end) = 0;
isTone1kHz = logical(isTone1kHz);


%% convert design parameters into onsets
ISI = duration_tone + duration_trace + duration_shock + duration_aftershock;
ISIcummulative = ISI .* (0:((nPresentations_perTone-1)*2+1)); 
onsets_tone_all = t_start + ISIcummulative;

onsets_1kHz_tone = onsets_tone_all(isTone1kHz);
onsets_15kHz_tone = onsets_tone_all(~isTone1kHz);

onsets_1kHz_trace = onsets_1kHz_tone + duration_tone;
onsets_15kHz_trace = onsets_15kHz_tone + duration_tone;

onsets_1kHz_shock = onsets_1kHz_tone + duration_tone + duration_trace;
onsets_15kHz_shock = onsets_15kHz_tone + duration_tone + duration_trace;

%% generate neural boxcars
% 6 neural processes:
% tone, trace, shock x 2 tone-frequencies

% define time-line
t = -1 + 1:(TR/microtime):(nScans*TR);
t = t(1:(nScans * microtime));

neural_1kHz_tone = onsets2boxcar(t, onsets_1kHz_tone, duration_tone);
neural_15kHz_tone = onsets2boxcar(t, onsets_15kHz_tone, duration_tone);

neural_1kHz_trace = onsets2boxcar(t, onsets_1kHz_trace, duration_trace);
neural_15kHz_trace = onsets2boxcar(t, onsets_15kHz_trace, duration_trace);

neural_1kHz_shock = onsets2boxcar(t, onsets_1kHz_shock, duration_shock);
neural_15kHz_shock = onsets2boxcar(t, onsets_15kHz_shock, duration_shock);


%% plot Neural signals
ylimits = [0, 1.1];
figure(1); clf;
nCols = 4; nRows = 1;
subplot(nCols, nRows ,1)
plot(t, [neural_1kHz_tone; neural_15kHz_tone])
ylim(ylimits)
legend({'1kHz','15kHz'})
title('tone')

subplot(nCols,nRows,2)
plot(t, [neural_1kHz_trace; neural_15kHz_trace])
ylim(ylimits)
legend({'1kHz','15kHz'})
title('trace')

subplot(nCols,nRows,3)
plot(t, [neural_1kHz_shock;neural_15kHz_shock])
ylim(ylimits)
legend({'1kHz','15kHz'})
title('shock')

subplot(nCols,nRows,4)
zoomTime = 200; % in seconds
zoomRange = (t_start/TR*microtime) : ...
    (t_start/TR*microtime+zoomTime*microtime);
plot(t(zoomRange), ...
    [neural_1kHz_tone(zoomRange); ...
    neural_15kHz_tone(zoomRange); ...
    neural_1kHz_trace(zoomRange); ...
    neural_15kHz_trace(zoomRange); ...
    neural_1kHz_shock(zoomRange); ...
    neural_15kHz_shock(zoomRange); ...
    ])
ylim(ylimits)
legend({'1kHz tone','15kHz tone', ...
    '1kHz trace','15kHz trace', ...
    '1kHz shock','15kHz shock'})
title('Zoom around first few trials')

%% convert to BOLD prediction
P = [6 16 1 1 6 0 32]; % HRF double-gamma parameters used by SPM

% following are on microtime-timescale
bold_1kHz_tone = neural2bold(neural_1kHz_tone, TR, microtime, P);
bold_15kHz_tone = neural2bold(neural_15kHz_tone, TR, microtime, P);
bold_1kHz_trace = neural2bold(neural_1kHz_trace, TR, microtime, P);
bold_15kHz_trace = neural2bold(neural_15kHz_trace, TR, microtime, P);
bold_1kHz_shock = neural2bold(neural_1kHz_shock, TR, microtime, P);
bold_15kHz_shock = neural2bold(neural_15kHz_shock, TR, microtime, P);

% actual design matrix:
X = [bold_1kHz_tone; ...
    bold_15kHz_tone; ...
    bold_1kHz_trace; ...
    bold_15kHz_trace; ...
    bold_1kHz_shock; ...
    bold_15kHz_shock; ...
    ]';
X = downsample(X,microtime); assert(size(X,1) == nScans);

colnames = {'1kHz tone','15kHz tone', ...
    '1kHz trace','15kHz trace', ...
    '1kHz shock','15kHz shock'};

C = (X'*X); % covariance matrix

c = corr(X);

%% plot BOLD predicted signals
figure(2); clf;
nCols = 4; nRows = 1;
subplot(nCols, nRows ,1)
plot(t, [bold_1kHz_tone; bold_15kHz_tone])
legend({'1kHz','15kHz'})
title('tone')

subplot(nCols,nRows,2)
plot(t, [bold_1kHz_trace; bold_15kHz_trace])
legend({'1kHz','15kHz'})
title('trace')

subplot(nCols,nRows,3)
plot(t, [bold_1kHz_shock;bold_15kHz_shock])
legend({'1kHz','15kHz'})
title('shock')

subplot(nCols,nRows,4)
zoomTime = 200; % in seconds
zoomRange = (t_start/TR*microtime) : ...
    (t_start/TR*microtime+zoomTime*microtime);
plot(t(zoomRange), ...
    [bold_1kHz_tone(zoomRange); ...
    bold_15kHz_tone(zoomRange); ...
    bold_1kHz_trace(zoomRange); ...
    bold_15kHz_trace(zoomRange); ...
    bold_1kHz_shock(zoomRange); ...
    bold_15kHz_shock(zoomRange); ...
    ])
legend({'1kHz tone','15kHz tone', ...
    '1kHz trace','15kHz trace', ...
    '1kHz shock','15kHz shock'})
title('Zoom around first few trials')


%% plot neural vs bold for first few trials
figure(3); clf;
nCols = 2; nRows = 1;

subplot(nCols,nRows,1)
plot(t(zoomRange), ...
    [neural_1kHz_tone(zoomRange); ...
    neural_15kHz_tone(zoomRange); ...
    neural_1kHz_trace(zoomRange); ...
    neural_15kHz_trace(zoomRange); ...
    neural_1kHz_shock(zoomRange); ...
    neural_15kHz_shock(zoomRange); ...
    ],'--')
hold on
plot(t(zoomRange), ...
    [bold_1kHz_tone(zoomRange); ...
    bold_15kHz_tone(zoomRange); ...
    bold_1kHz_trace(zoomRange); ...
    bold_15kHz_trace(zoomRange); ...
    bold_1kHz_shock(zoomRange); ...
    bold_15kHz_shock(zoomRange); ...
    ])

subplot(nCols,nRows,2)
zoomTime = 200; % in seconds
zoomRange = (t_start/TR*microtime) : microtime: ...
    ((t_start+zoomTime)/TR*microtime);
indexRange = round(t_start/TR):round((t_start+zoomTime)/TR);
plot(zoomRange, ...
    X(indexRange,:), 'x')
legend({'1kHz tone','15kHz tone', ...
    '1kHz trace','15kHz trace', ...
    '1kHz shock','15kHz shock'})
title('ACTUAL predicted signal (now on the same timescale as TR)')


%% Plot correlation among predictors of design matrix
figure(4); clf;
imagesc(c, [-1 1]);
xticklabels(colnames)
xtickangle(45)
yticklabels(colnames)
colormap gray
colorbar
