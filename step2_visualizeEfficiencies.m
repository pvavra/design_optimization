ExpandPath();

n = length(listEff);


index_to_optimize = 7;

effs = cellfun(@(x) x{index_to_optimize}, listEff);
[effs_sorted, indices_sorted] = sort(effs,'descend');


nMax = 8;
indices_comparison = [1 3 indices_sorted(1:nMax)];



nPerFig = 5;

% make sure this matches the order of predictors in X:
colnames = {'1kHz tone','15kHz tone', ...
    '1kHz trace','15kHz trace', ...
    '1kHz shock','15kHz shock'};

nCols = 4;
for j = 1:length(indices_comparison)
    
    i=indices_comparison(j);
    fprintf('ceil: %g, mod: %g\n',ceil(j/nPerFig), mod(j-1,nPerFig))
    figure(ceil(j/nPerFig))
    % summary on efficiencies
    ax = subplot(nPerFig,nCols,1 + mod(j-1,nPerFig)*nCols ); cla
    
    title_text = sprintf('TotalTime = %g\n',listTotalLength{i});
    currentEffs = listEff{i};
    
    for iC = 1:numel(listC_names)
        title_text = sprintf('%seff_{%s} = %g',...
            title_text, listC_names{iC},currentEffs{iC});
        if mod(iC,2)
            title_text = sprintf('%s\n',title_text);
        else
            title_text = sprintf('%s       ',title_text);
        end
    end
    text(-0.5,0.5,title_text)
    set(ax,'visible','off');
    
    % design: trial type
    subplot(nPerFig,nCols,2 + mod(j-1,nPerFig)*nCols)
    cla
    imagesc(listIsTone1kHz{i}')
    colormap('gray')
    
    % design: ISI
    subplot(nPerFig,nCols,3 + mod(j-1,nPerFig)*nCols)
    cla
    plot(listDurationAftershock{i})
    
    subplot(nPerFig,nCols,4 + mod(j-1,nPerFig)*nCols)
    cla
    C = corr(listKWX{i});
    imagesc(abs(C), [0 1]);
%     colormap gray
    colorbar
    xticks(1:6)
    xticklabels(colnames)
    xtickangle(45)

    
end
% tilefigs([], 10)