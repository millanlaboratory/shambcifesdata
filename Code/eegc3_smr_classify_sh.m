% - Initially written by Michele
% - Then modified by Simis who casted the Perdikisian spells in this file
% - Then corrected and integrated in eegemg by Michele
% - Finally approved by Chuck Norris
function [support, nfeature, afeature, rfeature] = eegc3_smr_classify_sh(analysis, buffer, ...
	support, shprobs)

nfeature = [];
afeature = [];
rfeature = [];
fs = analysis.settings.eeg.fs;

if(ndf_isfull(buffer))
    if(nargout == 4)
        [support.cprobs, nfeature, afeature, rfeature] = ...
			eegc3_smr_bci(analysis, buffer);
	elseif(nargout == 3)
        [support.cprobs, nfeature, afeature] = ...
			eegc3_smr_bci(analysis, buffer);
    else
        [support.cprobs, nfeature] = ...
			eegc3_smr_bci(analysis, buffer);
    end
    
    % Replace real probabilities with fake ones
    support.cprobs = shprobs;

    if(support.rejection > 0)
        if(max(support.cprobs) < support.rejection)
            support.cprobs = support.nprobs;
        end
    end
    
    if(support.integration > 0)
        support.nprobs = ...
            eegc3_expsmooth(support.nprobs, support.cprobs, ...
            support.integration);
    else
        support.postprobs = support.probs;
    end
end