addpath(genpath('~/dev/cnbi-smrtrain/'));
close all;
playbackFolder = '/home/cnbi/dev/shamBCIFESData/Data/';
files = dir([playbackFolder 's07']);
for fileIndex = 3:length(files)
    if contains(files(fileIndex).name, "flexion")
        disp(files(fileIndex).name);
        load([files(fileIndex).folder '/' files(fileIndex).name])
        probdata(~success | rLabels == 783) = [];
        rLabels(~success | rLabels == 783) = [];
        maxProbas = zeros(length(probdata),3);
        endProbas = zeros(length(probdata),3);

        for k = 1:18
            for trial = 1:length(probdata)
                currentColumn = (rLabels(trial) == 783) + 1;
                currentsProbas = probdata{1,trial};
                currentsProbas = currentsProbas(k:end,:);
                cumulativeSum = zeros(length(currentsProbas)+1,1);
                cumulativeSum(1) = 0.5;
                for i = 2:length(currentsProbas)+1
                    if abs(currentsProbas(i-1, currentColumn) - 0.5) < 0.1
                        currentsProbas(i-1, currentColumn) = cumulativeSum(i-1);
                    end
                    cumulativeSum(i) = eegc3_expsmooth(cumulativeSum(i-1), currentsProbas(i-1, currentColumn), 0.96);

                end
                maxProbas(trial,:) = [max(cumulativeSum) length(currentsProbas) < 177 rLabels(trial)];
                endProbas(trial,:) = [cumulativeSum(end) length(currentsProbas) < 177 rLabels(trial)];
            end

            endProbasMovement = endProbas(endProbas(:,3) ~= 783,1);
            endProbMean(k) = median(endProbasMovement);
            endProbSTD(k) = std(endProbasMovement);
        end

        if(min(endProbSTD) > 0.03)
           disp(['wtf?? std = ' num2str(min(endProbSTD))]) 
%                figure()
%                hist(endProbasMovement);
        else

        end
        figure(1);
        hold on;
        errorbar(1:length(endProbMean), endProbMean,  endProbSTD);
    end
end