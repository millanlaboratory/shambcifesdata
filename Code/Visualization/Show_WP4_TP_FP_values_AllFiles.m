% R.Leeb, CNBI, dec-2011
files=dir('*online.wp4.mi*.gdf');
clear s h
sum_acc =[]; sum_N=[]; sum_TP=[]; 
for kk=1:length(files)
   disp(' ')
   disp(files(kk).name)
   [s,h]=sload(files(kk).name);    
   Show_WP4_TP_FP_values
   sum_acc(kk)=sum(TP(idx)) / (sum(TP(idx)) + sum(FP(idx))) * 100;
   sum_N(kk) = length(idx_cue);
   sum_TP(kk) = sum(TP);
end
disp(' ')
disp(['average acc= ' num2str(mean(sum_acc),'%.2f') ' %'])
str='';
for k=1:length(sum_TP)
   str = [str num2str(sum_TP(k)) '/' num2str(sum_N(k)) '' '  ']; 
end
disp(' ')
disp(['TP(N):  ' str])


%disp('L R F rest')
