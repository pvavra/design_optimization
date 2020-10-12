chosen_design = indices_sorted(2);

breaks = listISI{chosen_design} - duration_tone;
isStimulusA = listIsTone1kHz{chosen_design};

after_Shock = breaks - duration_trace - duration_shock;
labels = {'1kHz','15kHz'};


for j = length(isStimulusA):-1:1
    switch isStimulusA(j)
        case true
            stimuli(j) = labels(1);
            stimulusIndices(j) = 1;
        otherwise
            stimuli(j) = labels(2);
            stimulusIndices(j) = 2;
    end
end


t = table(stimuli',stimulusIndices',breaks',...
    'VariableNames',{'Stimulus','StimulusIndex','BreakAfterToneOffset'});

writetable(t, 'optimal_design.tsv',...
    'FileType','text',...
    'Delimiter','tab',...
    'QuoteStrings',true);
    

