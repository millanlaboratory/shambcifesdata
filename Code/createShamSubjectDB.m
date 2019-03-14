addpath(genpath('~/dev/cnbi-smrtrain/'));
lap = load('laplacian16.mat');
lap = lap.lap;
subjectsToAnalyze = load('/tmp/sinergia/finishedEntries.mat');
subjectsToAnalyze = convertCharsToStrings(subjectsToAnalyze.finished_entries')
if(isempty(subjectsToAnalyze))
    disp('Could not find finished subject list');
    exit();
end
Path = '~/data/';

SavePath = '~/dev/shambcifesdata/Data/';

if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end
if ~exist([SavePath 'Rej/'], 'dir')
    mkdir([SavePath 'Rej/'])
end

SubDir = dir(Path);
SubDir = SubDir(3:end);
isd = [SubDir(:).isdir];
SubDir = SubDir(isd);
disp('Generating playback files')

for subject = 1:length(SubDir)
    if ~contains(subjectsToAnalyze, SubDir(subject).name)
        break;
    end
    disp(['Doing analysis for subject ' SubDir(subject).name])
    Acc= {};
    TrAcc = {};
    labels = {};
    Sub = SubDir(subject).name;
    SubSes = dir([Path '/' Sub]);
    SubSes = SubSes(3:end);
    isd = [SubSes(:).isdir];
    SubSes = SubSes(isd);

    onses = 0;
    countSessions = struct('flex', {}, 'ext', {});
    classifierFiles = dir([Path Sub '/*.mat']);
    classifiersFlex = {};
    classifiersExt = {};
    classifierCounter = zeros(2,1);
    for i = 1:length(classifierFiles)
        if isempty(strfind(classifierFiles(i).name, 'smr.mat'))
            if strfind(classifierFiles(i).name, 'flrst')
                classifierCounter(1) = classifierCounter(1) + 1;
                classifiersFlex{classifierCounter(1)} = classifierFiles(i).name;
            elseif strfind(classifierFiles(i).name, 'extrst')
                classifierCounter(2) = classifierCounter(2) + 1;
                classifiersExt{classifierCounter(2)} = classifierFiles(i).name;
            end
        end
    end
    classifierIndex = ones(2,1);
    for ses=1:length(SubSes)
        % Check if it is an online session
        SesName = SubSes(ses).name;

        if ~isempty(strfind(SesName, 'training'))
            onses = onses + 1;
            sessionInfos = strsplit(SesName, '_');
            currentClassifier = '';
            if(contains(SesName, 'flex'))
                classifiers = classifiersFlex;
            elseif(contains(SesName, 'ext'))
                classifiers = classifiersExt;
            else
                disp(['Session type not identified' sessionInfos{end}])
            end
            % Load log file
            files = dir([Path '/' Sub '/' SesName '/*.gdf']);
            run=0;
            for fileIndex = 1:length(files)

                GDFName = files(fileIndex).name;
                GDFPath = [Path '/' Sub '/' SesName '/' GDFName];
                MATPath = [Path '/' Sub '/' currentClassifier];
                gdfDate = strsplit(GDFName(1:end-4), '.');
                gdfDate = str2num(gdfDate{2});

                if(exist(GDFPath,'file')>0)
                    if( ( files(fileIndex).bytes/(1024^2)) < 1.0 ) % Get rid of too small GDFs, probably failed attempts to start the loop or interrupted runs
                        continue;
                    end
                else
                    continue;
                end

                if(exist([SavePath Sub '/' GDFName(1:end-4) '.mat'],'file') == 0)
                    if(exist([SavePath 'Rej/' GDFName(1:end-4) '.mat'],'file') > 0) % Maybe it is on the rejected runs, do not recompute it
                        continue;
                    end
                    bestThresholdSTD = 1;
                    bestThresholdMedian = 0;
                    currentValues.rAcc = [];
                    currentValues.rTrAcc = [];
                    currentValues.probdata = [];
                    currentValues.rLabels = [];
                    currentValues.success = [];
                    bestValues = [];
                    for index = 1:length(classifiers)
                        classifierDate = strsplit(classifiers{index}(1:end-4), '_');
                        classifierDate = str2num(classifierDate{3});
                        if classifierDate <= gdfDate
                            MATPath = [Path '/' Sub '/' classifiers{index}];
                            [currentValues.rAcc, currentValues.rTrAcc, currentValues.probdata, ...
                                currentValues.rLabels, currentValues.success] = ...
                                analyzeOnlineStroke(GDFPath, MATPath, lap);
                            if(isnan(currentValues.rAcc))
                                break;
                            end
                            [threhsoldMean, threhsoldSTD] = findThreshold(currentValues.probdata, currentValues.rLabels, currentValues.success);
                            if(threhsoldSTD < bestThresholdSTD)
                                bestValues = currentValues;
                                bestThresholdSTD = threhsoldSTD;
                                bestThresholdMedian = threhsoldMean;
                            end
                        end
                    end
                    if(isnan(currentValues.rAcc))
                        break;
                    end
                    probdata = bestValues.probdata;
                    rAcc = bestValues.rAcc;
                    rTrAcc = bestValues.rTrAcc;
                    rLabels = bestValues.rLabels;
                else
                    load([SavePath Sub '/' GDFName(1:end-4) '.mat']);
                end

                if(~isnan(rAcc))
                    % Save playback probability file
                    if(~exist([SavePath '/' Sub],'dir'))
                        % Create subject's playback folder
                        mkdir(SavePath,Sub);
                    end
                    if( (length(probdata)>15) && (rAcc >=40) && sum(sum(isnan(probdata{1,1}))) == 0)
                        run = run+1;
                        Acc{onses}(run) = rAcc;
                        TrAcc{onses}(run) = rTrAcc;
                        labels{onses}{run} = rLabels;
                        
                        disp(['Subject: ' Sub ' , Session: ' num2str(onses) ' , Run: ' num2str(run) ' , Acc: ' num2str(round(Acc{onses}(run)))...
                            ' , Trial Acc: ' num2str(round(TrAcc{onses}(run))) ' Threshold STD ' num2str(bestThresholdSTD)]);
                        if (~exist([SavePath Sub '/' GDFName(1:end-4) '.mat'], 'file'))
                            save([SavePath Sub '/' GDFName(1:end-4) '.mat'],'probdata','rAcc','rTrAcc', 'rLabels', 'bestThresholdMedian', 'bestThresholdSTD');
                        end
                    else
                        if (~exist([SavePath Sub '/' GDFName(1:end-4) '.mat'], 'file'))
                            save([SavePath 'Rej/' GDFName(1:end-4) '.mat'],'probdata','rAcc','rTrAcc', 'rLabels', 'bestThresholdMedian', 'bestThresholdSTD');
                        end
                    end
                end
            end
        end
    end
    Sum.Acc = Acc;
    Sum.TrAcc = TrAcc;
    Sum.labels = labels;
    if(~exist([SavePath '/' Sub],'dir'))
        % Create subject's playback folder
        mkdir(SavePath,Sub);
    end
    save([SavePath Sub '/' Sub '_Acc.mat'],'Sum');
end
