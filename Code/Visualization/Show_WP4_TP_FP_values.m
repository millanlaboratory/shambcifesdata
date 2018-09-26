% R.Leeb, CNP, feb-2015
%idx_cue = sort([find(h.EVENT.TYP==769) find(h.EVENT.TYP==770)]);
idx_cue = find(h.EVENT.TYP==769);
cl=1;
if isempty(idx_cue)
    idx_cue =  find(h.EVENT.TYP==770); 
    cl=2;
end
idx_fes = find(h.EVENT.TYP==14); % fes 14 / hit 897
if isempty(idx_fes)
    idx_fes = find(h.EVENT.TYP==897); % fes 14 / hit 897
end

TP = zeros(size(idx_cue));
FP = TP;
Dur = TP;
for k=1:length(idx_cue)
    if k < length(idx_cue)
        pos = find((idx_fes>idx_cue(k)) & (idx_fes<idx_cue(k+1)));
        if pos > 0
            TP(k) = 1;
            Dur(k) = h.EVENT.POS(idx_fes(pos)) - h.EVENT.POS(idx_cue(k));
        else
            FP(k)=1;
        end
    else 
        pos = find(idx_fes>idx_cue(k));
        if pos > 0
            TP(k) = 1;
            Dur(k) = h.EVENT.POS(idx_fes(pos)) - h.EVENT.POS(idx_cue(k));
        else
            FP(k)=1;
        end
    end
end

idx=find(TP==1);
str_time = ['     [' num2str(mean(Dur(idx))/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur(idx))/h.SampleRate,'%.2f'), 's (' num2str(min(Dur(idx))/h.SampleRate,'%.2f') '-' num2str(max(Dur(idx))/h.SampleRate,'%.2f') 's/' num2str(median(Dur(idx))/h.SampleRate,'%.2f') 's)'];
disp([' cl ' num2str(cl) ' (' num2str(length(idx_cue)) ') :  ' num2str(length(idx)) '  '  str_time])
idx=[1:length(idx_cue)];
return


%%
disp(['Conf matrix']);
cl=1;
str_time = ['     [' num2str(mean(Dur{idx(cl)})/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur{idx(cl)})/h.SampleRate,'%.2f'), 's (' num2str(min(Dur{idx(cl)})/h.SampleRate,'%.2f') '-' num2str(max(Dur{idx(cl)})/h.SampleRate,'%.2f') 's/' num2str(median(Dur{idx(cl)})/h.SampleRate,'%.2f') 's)'];
disp([' cl ' num2str(idx(cl)) ' (' num2str(N(idx(cl))) ') :  ' num2str(TP(idx(cl))) '  ' num2str(FP(idx(cl))) str_time])

    
return
%---
% R.Leeb, CNBI, dec-2011
clear N TP FP Dur
for cl = 1 : 3
    idx = find(h.EVENT.TYP==(768+cl));
    idx(find((idx+2)>length(h.EVENT.TYP)))=[];
    N(cl) = length(idx);
    TP(cl) = length(find(h.EVENT.TYP(idx+2)==897));
    FP(cl) = length(find(h.EVENT.TYP(idx+2)==898));   
    Dur{cl} = h.EVENT.POS(idx+2)-h.EVENT.POS(idx);
end

% Confusion matrix
str_time=[];
idx = find(N>0);
if length(idx)==1
    disp(['Conf matrix']);
    cl=1;
    str_time = ['     [' num2str(mean(Dur{idx(cl)})/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur{idx(cl)})/h.SampleRate,'%.2f'), 's (' num2str(min(Dur{idx(cl)})/h.SampleRate,'%.2f') '-' num2str(max(Dur{idx(cl)})/h.SampleRate,'%.2f') 's/' num2str(median(Dur{idx(cl)})/h.SampleRate,'%.2f') 's)'];
    disp([' cl ' num2str(idx(cl)) ' (' num2str(N(idx(cl))) ') :  ' num2str(TP(idx(cl))) '  ' num2str(FP(idx(cl))) str_time])
elseif length(idx)==2
    disp(['Conf matrix']);
    cl=1;
    str_time = ['     [' num2str(mean(Dur{idx(cl)})/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur{idx(cl)})/h.SampleRate,'%.2f'), 's (' num2str(min(Dur{idx(cl)})/h.SampleRate,'%.2f') '-' num2str(max(Dur{idx(cl)})/h.SampleRate,'%.2f') 's/' num2str(median(Dur{idx(cl)})/h.SampleRate,'%.2f') 's)'];
    disp([' cl ' num2str(idx(cl)) ' (' num2str(N(idx(cl))) ') :  ' num2str(TP(idx(cl))) '  ' num2str(FP(idx(cl))) str_time])
    cl=2;
    str_time = ['     [' num2str(mean(Dur{idx(cl)})/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur{idx(cl)})/h.SampleRate,'%.2f'), 's (' num2str(min(Dur{idx(cl)})/h.SampleRate,'%.2f') '-' num2str(max(Dur{idx(cl)})/h.SampleRate,'%.2f') 's/' num2str(median(Dur{idx(cl)})/h.SampleRate,'%.2f') 's)'];
    disp([' cl ' num2str(idx(cl)) ' (' num2str(N(idx(cl))) ') :  ' num2str(FP(idx(cl))) '  ' num2str(TP(idx(cl))) str_time])
else
    for cl = 1 : 3
        str_time = ['     [' num2str(mean(Dur{cl})/h.SampleRate,'%.2f') ' +/- ' num2str(std(Dur{cl})/h.SampleRate,'%.2f'), 's (' num2str(min(Dur{cl})/h.SampleRate,'%.2f') '-' num2str(max(Dur{cl})/h.SampleRate,'%.2f') 's/' num2str(median(Dur{cl})/h.SampleRate,'%.2f') 's)'];
        disp([' cl ' num2str(cl) ' :  TP = ' num2str(TP(cl)) ' /  FP = ' num2str(FP(cl)) ' /  N = ' num2str(N(cl)) str_time])
    end
end