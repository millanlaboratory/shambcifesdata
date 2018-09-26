clear;close all;clc;
%Path = '/home/scratch/sperdikis/Git/cnbi-stroke-protocol/extra/fesprotocolextra/scripts/matlab/playback/';
Path = '/home/sperdikis/Git/cnbi-stroke-protocol/extra/fesprotocolextra/scripts/matlab/playback/';

% Find mat files with performances
SubMat = dir([Path '*.mat']);

for i=1:length(SubMat)
    US = strfind(SubMat(i).name,'_');
    SubID{i} = SubMat(i).name(1:US-1);
    
    % Load mat file
    Sum = load([Path SubMat(i).name]);
    Acc = Sum.Sum.Acc;
    TrAcc = Sum.Sum.TrAcc;
    
    % Plot average per session
    for ses=1:length(Acc)
        AvgAcc(ses) = nanmean(Acc{ses});
        StdAcc(ses) = nanstd(Acc{ses});
        AvgTrAcc(ses) = nanmean(TrAcc{ses});
        StdTrAcc(ses) = nanstd(TrAcc{ses});        
    end
    
    figure('units','normalized','outerposition',[0 0 1 1])  
    bar(AvgAcc)
    hold on;
    errorbar(1:length(AvgAcc),AvgAcc,StdAcc,'.k','LineWidth',5);
    set(gca,'XTick',[1:length(AvgAcc)]);
    set(gca,'XTickLabel',[1:length(AvgAcc)]);
    xlabel(['Sessions ' SubID{i}],'FontSize',30,'Fontweight','bold');
    ylabel('Average single-sample accuracy','FontSize',30,'Fontweight','bold');
    set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 30 20])
    print('-dpng','-zbuffer','-r300',[Path 'SesAcc' SubID{i}]);
    
    figure('units','normalized','outerposition',[0 0 1 1])  
    bar(AvgTrAcc)
    hold on;
    errorbar(1:length(AvgTrAcc),AvgTrAcc,StdTrAcc,'.k','LineWidth',5);
    set(gca,'XTick',[1:length(AvgTrAcc)]);
    set(gca,'XTickLabel',[1:length(AvgTrAcc)]);
    xlabel(['Sessions ' SubID{i}],'FontSize',30,'Fontweight','bold');
    ylabel('Average trial accuracy','FontSize',30,'Fontweight','bold');
    set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 30 20])
    print('-dpng','-zbuffer','-r300',[Path 'SesTrAcc' SubID{i}]);

    AllMAcc(i) = mean(cell2mat(Acc));
    AllStdAcc(i) = std2(cell2mat(Acc));
    AllTrMAcc(i) = mean(cell2mat(TrAcc));
    AllTrStdAcc(i) = std2(cell2mat(TrAcc));    
end


figure('units','normalized','outerposition',[0 0 1 1])  
bar(AllMAcc)
hold on;
errorbar(1:length(AllMAcc),AllMAcc,AllStdAcc,'.k','LineWidth',5);
set(gca,'XTick',[1:length(SubID)]);
set(gca,'XTickLabel',SubID,'FontSize',20,'Fontweight','bold');
xlabel('Subject','FontSize',20,'Fontweight','bold');
ylabel('Single-sample accuracy','FontSize',20,'Fontweight','bold');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 30 20])
print('-dpng','-zbuffer','-r300',[Path 'Acc']);



figure('units','normalized','outerposition',[0 0 1 1])  
bar(AllTrMAcc)
hold on;
errorbar(1:length(SubID),AllTrMAcc,AllTrStdAcc,'.k','LineWidth',5);
set(gca,'XTick',[1:length(SubID)]);
set(gca,'XTickLabel',SubID,'FontSize',20,'Fontweight','bold');
xlabel('Subject','FontSize',20,'Fontweight','bold');
ylabel('Trial accuracy','FontSize',20,'Fontweight','bold');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 30 20])
print('-dpng','-zbuffer','-r300',[Path 'TrAcc']);
c4science · Help