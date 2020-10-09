ExpandPath();

n = length(listEff);

for  i=1:n
   figure(i)
   clf
   ax = subplot(221);
   title_text = '';
   currentEffs = listEff{i};
   for iC = 1:numel(listC_names)
       title_text = sprintf('%seff_{%s} = %g\n',...
           title_text, listC_names{iC},currentEffs{iC});
   end
   text(0.5,0.5,title_text)
   set(ax,'visible','off');
   
   
   subplot(223)
   imagesc(listIsTone1kHz{i}')
   colormap('gray')

   subplot(224)
   plot(listDurationAftershock{i})
   
end
tilefigs([], 10)