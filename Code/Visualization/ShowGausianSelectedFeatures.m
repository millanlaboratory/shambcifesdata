% displaying the selected frequencies and channels for the gaussian classifier
ListOfEEGChannels={'Fz','FC3','FC1','FCz','FC2','FC4','C3','C1','Cz','C2','C4','CP3','CP1','CPz','CP2','CP4'};
s_cnt = 0;
for s_k = 1 : length(analysis.tools.features.channels)
    s_Ch = analysis.tools.features.channels(s_k);
    s_f = analysis.tools.features.bands{s_Ch};
    for s_fk = 1 : length(s_f)        
        %analysis.settings.features.psd.freqs(
        s_cnt = s_cnt+1;
        disp([num2str(s_cnt,'%02d') ':  ch ' num2str(s_Ch,'%02d') ' - ' num2str(s_f(s_fk)) ' Hz'])
%        disp([num2str(s_cnt,'%02d') ':   ' ListOfEEGChannels{s_Ch} ' - ' num2str(s_f(s_fk)) ' Hz'])
    end
end
clear s_k s_Ch s_f s_fk s_cnt