function out = onsets2boxcar(time, onsets, duration)
out = zeros(size(time));


if length(duration) == 1
    duration = repmat(duration, size(onsets));
end


for i = 1:length(onsets)
    
    % find the closest timepoint on the microtime scale
    mindiff = min(abs(time - onsets(i)));
    if mindiff == 0 % perfect match
        index_start = find(time == onsets(i));        
        assert(length(index_start) == 1);
    else
        error('not implemented yet :/');
    end
    
    % find corresponding endpoint
    mindiff = min(abs(time - onsets(i)+duration(i)));
    if mindiff == 0 % perfect match
        index_end = find(time == onsets(i)+duration(i));        
        assert(length(index_end) == 1);
    else
        error('not implemented yet :/');
    end
    
    
    % which timepoints should have boxcar set to 1
    indexRange = index_start:index_end;
    
    out(indexRange) = 1;
end

end