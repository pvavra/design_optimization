ExpandPath();

n = length(listEff);

nPerFig = 5;

nCols = 3;
for  i=1:n
    fprintf('ceil: %g, mod: %g\n',ceil(i/nPerFig), mod(i-1,nPerFig))
   figure(ceil(i/nPerFig))
   % summary on efficiencies
   ax = subplot(nPerFig,3,1 + mod(i-1,nPerFig)*nCols ); cla
   
   title_text = '';
   currentEffs = listEff{i};
   for iC = 1:numel(listC_names)
       title_text = sprintf('%seff_{%s} = %g\n',...
           title_text, listC_names{iC},currentEffs{iC});
   end
   text(0.5,0.5,title_text)
   set(ax,'visible','off');
   
   % design: trial type
   subplot(nPerFig,3,2 + mod(i-1,nPerFig)*nCols)
   cla
   imagesc(listIsTone1kHz{i}')
   colormap('gray')

   % design: ISI 
   subplot(nPerFig,3,3 + mod(i-1,nPerFig)*nCols)
   cla
   plot(listDurationAftershock{i})
   
end
% tilefigs([], 10)