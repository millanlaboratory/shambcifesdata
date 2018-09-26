function [SAccA, TrAccA, probdata, labels] = analyzeOnlineStroke(FilePath, MATpath, lap)

    try
    
        [data, header] = sload(FilePath);

    catch e
        disp(['Problem loading file, skipping: ' FilePath]);
        SAccA = NaN;
        TrAccA = NaN;
        probdata = NaN;
        labels = NaN;
        return
    end

    try
        analysis = load(MATpath);
        analysis = analysis.analysis;
        if sum(analysis.settings.task.classes_old == 781) > 0
           disp('Duplicated '); 
        end
        a = find(header.EVENT.TYP == analysis.settings.task.classes_old(1) | ...
            header.EVENT.TYP == analysis.settings.task.classes_old(2));
        
        a(header.EVENT.TYP(a-1) == analysis.settings.task.classes_old(1)) = [];
        a(header.EVENT.TYP(a-1) == analysis.settings.task.classes_old(2)) = [];
        labels = header.EVENT.TYP(a);
        if(~isempty(strfind(MATpath,'rhrst')))
            Class = 1;
        else
            Class = 2;
        end

    catch
        disp(['Problem loading classifier mat file: ' MATpath ', skipping: ' FilePath]);
        SAccA = NaN;
        TrAccA = NaN;    
        probdata = NaN;
        labels = NaN;
        return
    end

    % Remove overall DC
    data = data-repmat(mean(data),size(data,1),1);

    % Laplacian spatial filtering
    data = data(:,1:16);
    data = laplacianSP(data,lap);

    % Trial extraction
    pos = header.EVENT.POS;
    dur = header.EVENT.DUR;
    cf = find(header.EVENT.TYP==781);
    cf(header.EVENT.TYP(cf-1) == 781) = [];
    cue = cf-1;

    if (length(cf) < 15)
        % Too few trials
        SAccA = NaN;
        TrAccA = NaN;
        probdata = NaN;
        disp('Too few trials, skipping...');
        return;
    end

    trials = [pos(cue) pos(cf)+dur(cf)];

    % Useful params for PSD extraction with the fast algorithm
    psdshift = 512*0.5*0.5;
    winshift = 512*0.0625;

    if((mod(psdshift,winshift) ~=0) && (mod(winshift,psdshift) ~=0))
        disp(['[eegc3_smr_simloop_fast] The fast PSD method cannot be applied with the current settings!']);
        disp(['[eegc3_smr_simloop_fast] The internal welch window shift must be a multiple of the overall feature window shift (or vice versa)!']);
        return;
    end

    % Create arguments for spectrogram
    spec_win = 512*0.5;
    % Careful here: The overlapping depends on whether the winshift or the
    % psdshift is smaller. Some calculated internal windows will be redundant,
    % but the speed is much faster anyway

    if(psdshift <= winshift)
        spec_ovl = spec_win - psdshift;
    else
        spec_ovl = spec_win - winshift;
    end

    % Calculate all the internal PSD windows
    for ch=1:16
        %disp(['[eegc3_smr_simloop_fast] Internal PSDs on electrode ' num2str(ch)]);
        [~,f,t,p(:,:,ch)] = spectrogram(data(:,ch), spec_win, spec_ovl, [], 512);
    end

    % Keep only desired frequencies
    freqs = [4:2:48];
    p = p(find(ismember(f,freqs)),:,:);

    % Setup moving average filter parameters
    FiltA = 1;
    if(winshift >= psdshift)
        % Case where internal windows are shifted according to psdshift
        MAsize = (512*1.00)/psdshift - 1;   
        FiltB = (1/MAsize)*ones(1,MAsize);
        MAstep = winshift/psdshift;
    else
        % Case where internal windows are shifted according to winshift
        FiltStep = psdshift/winshift;
        MAsize = (512*1.00)/winshift - FiltStep;   
        FiltB = zeros(1,MAsize);
        FiltB(1:FiltStep:end-1) = 1;
        FiltB = FiltB/sum(FiltB);
        MAstep = 1;
    end

    StartInd = find(FiltB~=0);
    StartInd = StartInd(end);

    afeats = filter(FiltB,FiltA,p,[],2);
    afeats = permute(afeats, [2 1 3]);

    % Get rid of initial filter byproducts
    afeats = afeats(StartInd:end,:,:);

    % In case of psdshift, there will be redundant windows. Remove them
    if(MAstep > 1)
       afeats = afeats(1:MAstep:end,:,:);
    end

    % Take the log as final feature values
    afeats = log(afeats);

    % Remap trials to PSD space
    ftrials(:,1) = floor(trials(:,1)/32)+1;
    ftrials(:,2) = floor(trials(:,2)/32)-15;

    % Find features used
    UsedFeat = [];
    fInd = 0;

    for ch=1:length(analysis.tools.features.channels)
        for fr=1:length(analysis.tools.features.bands{analysis.tools.features.channels(ch)})
            fInd = fInd + 1;

            UsedFeat = [UsedFeat ; analysis.tools.features.channels(ch) ...
                analysis.tools.features.bands{analysis.tools.features.channels(ch)}(fr)];

        end
    end

    % Crop all data to selected features
    sfeats = zeros(size(afeats,1),size(UsedFeat,1));
    for s=1:size(afeats,1)
        for f=1:size(UsedFeat,1)
            sfeats(s,f) = afeats(s,(UsedFeat(f,2)-4)/2+1,UsedFeat(f,1));
        end
    end

    % Crop to trials
    fdata = [];
    ftrlbl = [];
    for i=1:size(ftrials,1)
        fdata = [fdata; sfeats(ftrials(i,1):ftrials(i,2),:)];
        ftrlbl = [ftrlbl; i*ones(ftrials(i,2)-ftrials(i,1)+1,1)];
    end

    % Single-sample accuracies
    prob = [];
    for i=1:size(fdata,1)
        [usl prob(i,:)] = gauClassifier(analysis.tools.net.gau.M, analysis.tools.net.gau.C,...
            fdata(i,:));
    end
    [maxV maxI] = max(prob');
    SAccA = 100*sum(maxI==Class)/size(fdata,1);

    probdata = [];
    for i=1:max(unique(ftrlbl))
        probdata{i} = prob(ftrlbl==i,:);
    end

    TrAccA = 100*length(find(header.EVENT.TYP==897))/length(find(header.EVENT.TYP==781));
end