addpath(genpath('~/dev/cnbi-smrtrain/'));
lap = load('laplacian16.mat');
lap = lap.lap;

Path = '~/data/Sinergia';

SavePath = '~/dev/shamBCIFESData/';

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


for subject = 1:length(SubDir)
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
    classifierFiles = dir([Path '/' Sub '/*.mat']);
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
            if(strcmp(sessionInfos{end}, 'flex'))
                if(floor(classifierIndex(1) / 2 + 1) < length(classifiersFlex))
                    currentClassifier = classifiersFlex{floor(classifierIndex(1) / 2 + 1)};
                else
                    currentClassifier = classifiersFlex{end};
                end
                classifierIndex(1) = classifierIndex(1) + 1;
            else
                if(floor(classifierIndex(2) / 2 + 1) < length(classifiersExt))
                    currentClassifier = classifiersExt{floor(classifierIndex(2) / 2 + 1)};
                else
                    currentClassifier = classifiersExt{end};
                end
                classifierIndex(2) = classifierIndex(2) + 1;
            end
            % Load log file
            files = dir([Path '/' Sub '/' SesName '/*.gdf']);
            run=0;
            for fileIndex = 1:length(files)

                GDFName = files(fileIndex).name;
                GDFPath = [Path '/' Sub '/' SesName '/' GDFName];
                MATPath = [Path '/' Sub '/' currentClassifier];

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

                    [rAcc, rTrAcc, probdata, rLabels] = analyzeOnlineStroke(GDFPath, MATPath, lap);
                else
                    load([SavePath Sub '/' GDFName(1:end-4) '.mat']); 
                end

                if(~isnan(rAcc))
                    % Save playback probability file
                    if(~exist([SavePath '/' Sub],'dir'))
                        % Create subject's playback folder
                        mkdir(SavePath,Sub);
                    end
                    if( (length(probdata)>15) && (rAcc >=40))
                        run = run+1;
                        Acc{onses}(run) = rAcc;
                        TrAcc{onses}(run) = rTrAcc;
                        labels{onses}{run} = rLabels;
                        disp(['Subject: ' Sub ' , Session: ' num2str(onses) ' , Run: ' num2str(run) ' , Acc: ' num2str(round(Acc{onses}(run)))...
                            ' , Trial Acc: ' num2str(round(TrAcc{onses}(run)))]);

                        save([SavePath Sub '/' GDFName(1:end-4) '.mat'],'probdata','rAcc','rTrAcc', 'rLabels');
                    else
                        save([SavePath 'Rej/' GDFName(1:end-4) '.mat'],'probdata','rAcc','rTrAcc', 'rLabels');
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