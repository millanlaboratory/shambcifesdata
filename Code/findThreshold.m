function [medianThreshold, stdThreshold] = findThreshold(probdata,rLabels, success)
%FINDTHRESHOLD Summary of this function goes here
%   Detailed explanation goes here
    probdata(~success | rLabels == 783) = [];
    rLabels(~success | rLabels == 783) = [];
    maxProbas = zeros(length(probdata),3);
    endProbas = zeros(length(probdata),3);
    for trial = 1:length(probdata)
        currentColumn = (rLabels(trial) == 783) + 1;
        currentsProbas = probdata{1,trial};
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
    medianThreshold = nanmedian(endProbasMovement);
    stdThreshold = nanstd(endProbasMovement);
end

