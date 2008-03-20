function D = spm_eeg_artefact(S)
% simple artefact detection
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Stefan Kiebel, Rik Henson & James Kilner
% $Id: spm_eeg_artefact.m 1236 2008-03-20 18:15:33Z stefan $


[Finter,Fgraph,CmdLine] = spm('FnUIsetup', 'EEG artefact setup',0);

try
    D = S.D;
catch
    D = spm_select(1, '.*\.mat$', 'Select EEG mat file');
end

P = spm_str_manip(D, 'H');

try
    D = spm_eeg_load(D);
catch
    error(sprintf('Trouble reading file %s', D));
end

try
    artefact.External_list = S.artefact.External_list;
catch
    artefact.External_list = spm_input('Read own artefact list?','+1','yes|no',[1 0]);
end

MustDoWork = 1; % flag to indicate whether user already specified full artefact list

if artefact.External_list
    try
        artefact.out_list = S.artefact.out_list;
    catch
        artefact.out_list = ...
            spm_input('List artefactual trials (0 for none)', '+1', 'w', '', inf);
    end
    
    if artefact.out_list == 0
        artefact.out_list = [];
    end
    
    try
        artefact.in_list = S.artefact.in_list;
    catch
        artefact.in_list = ...
            spm_input('List clean trials (0 for none)', '+1', 'w', '', inf);
    end
    
    if artefact.in_list == 0
        artefact.in_list = [];
    end
    
    if any([artefact.out_list; artefact.in_list] < 1 | [artefact.out_list; artefact.in_list] > D.ntrials)
        error('Trial numbers cannot be smaller than 1 or greater than %d.', D.ntrials);
    end
    
    % check the lists
    tmp = intersect(artefact.out_list, artefact.in_list);
    if ~isempty(tmp)
        error('These trials were listed as both artefactual and clean: %s', mat2str(tmp));
    end
    
    % Check whether user has specified all trials
    Iuser = [artefact.out_list; artefact.in_list];
    if length(Iuser) == D.ntrials
        MustDoWork = 0;
    end
end

try
    artefact.Weighted = S.artefact.weighted;
catch
    artefact.Weighted = spm_input('robust average?','+1','yes|no',[1 0]);
end

if artefact.Weighted == 1
    try 
        artefact.Weightingfunction = S.artefact.weightingfunction;
    catch
        artefact.Weightingfunction = spm_input('Offset weighting function by', '+1', 'r', '3', 1);
    end
        try 
        artefact.Smoothing = S.artefact.smoothing;
    catch
        artefact.Smoothing = spm_input('FWHM for residual smoothing (ms)', '+1', 'r', '20', 1);
    end
    artefact.Smoothing=round(artefact.Smoothing/1000*D.fsample);
end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup', 'EEG artefact setup',0);

if MustDoWork
    try
        artefact.Check_Threshold = S.artefact.Check_Threshold;
    catch
        artefact.Check_Threshold = spm_input('Threshold channels?','+1','yes|no',[1 0]);
    end
    
    if artefact.Check_Threshold
        try
            artefact.threshold = S.artefact.threshold;
            if length(artefact.threshold) == 1
                artefact.threshold = artefact.threshold * ones(1, D.nchannels);
            end
        catch
            str = 'threshold[s]';
            Ypos = -1;
            
            while 1
                if Ypos == -1
                    [artefact.threshold, Ypos] = spm_input(str, '+1', 'r', [], [1 Inf]);
                else
                    artefact.threshold = spm_input(str, Ypos, 'r', [], [1 Inf]);
                end
                if length(artefact.threshold) == 1
                    artefact.threshold = artefact.threshold * ones(1, D.nchannels);
                end
                
                if length(artefact.threshold) == D.nchannels, break, end
                str = sprintf('enter a scalar or [%d] vector', D.nchannels);
            end
        end
    else
        artefact.threshold = kron(ones(1, D.nchannels), Inf);
    end
    
end % MustDoWork

spm('Pointer', 'Watch'); drawnow

% matrix used for detecting bad channels
Mbad = zeros(D.nchannels, D.ntrials);
% flag channels that were already marked as bad
Mbad(D.badchannels, :) = 1;

% cell vectors of channel-wise indices for thresholded events
thresholded = cell(1, D.nchannels);
index = [];
if MustDoWork
    
    Tchannel = artefact.threshold;
    
    spm_progress_bar('Init', D.ntrials, '1st pass - Events thresholded'); drawnow;
    if D.ntrials > 100, Ibar = floor(linspace(1, D.ntrials, 100));
    else Ibar = [1:D.ntrials]; end
    
    % first flag bad channels based on thresholding
    for i = 1:D.ntrials
        
        d = squeeze(D(:, :, i));
        
        % indices of channels that are above threshold and not marked as
        % bad
        Id = find(max(abs(d')) > Tchannel & ~Mbad(:, i)');
        Mbad(intersect(Id, D.meegchannels), i) = 1;
        
        if ismember(i, Ibar)
            spm_progress_bar('Set', i);
            drawnow;
        end
        
    end
    
    spm_progress_bar('Clear');
    
    % flag channels as bad if 20% of events above threshold
    s = sum(Mbad, 2)/D.ntrials;
    ind = find(s > 0.2);

    Mbad = zeros(D.nchannels, D.ntrials);
    Mbad(ind, :) = 1;
    
    % report on command line
    if isempty(ind)
        disp(sprintf('There isn''t a bad channel.'));
        D = putbadchannel(D, [1:D.meegchannels], zeros(length(D.meegchannels), 1));
    else
        disp(['Bad channels: ', sprintf('%s ', D.chanlabels(ind)')])    
        D = putbadchannel(D, ind, ones(length(ind), 1));
    end
    
    cl = conditionlabels(D);
    
    if artefact.Weighted == 1
        % weighted averaging by J Kilner

        allWf = zeros(D.nchannels, D.ntrials * D.nsamples);
        tloops = 1:D.nchannels;
        tloops(ind) = [];
        
        for i = 1:D.nconditions
            nbars = D.nconditions * length(tloops);
            spm_progress_bar('Init', nbars, '2nd pass - robust averaging'); drawnow;
            if nbars > 100, Ibar = floor(linspace(1, nbars,100));
            else Ibar = [1:nbars]; end
            
            trials = pickconditions(D, deblank(cl(i,:)));
            
            for j = tloops %loop across electrodes      
                if ismember((i-1)*length(tloops)+j, Ibar)
                    spm_progress_bar('Set', (i-1)*length(tloops)+j);
                    drawnow;
                end
                tempdata=max(abs(squeeze(D(j, :, trials))));
                itrials=trials;
               
                itrials(find(tempdata>Tchannel(j))) = '';
                tdata = squeeze(D(j, :, itrials));
                [B, bc] = spm_eeg_robust_averaget(tdata, artefact.Weightingfunction, artefact.Smoothing);
                bc = bc(:);
                ins = 0;
                
                for n = itrials
                    ins = ins+1;
                    allWf(j, (n-1)*D.nsamples+1 : n*D.nsamples) = bc((ins-1)*D.nsamples+1:ins*D.nsamples)';
                end
            end
            
            
        end
        
        spm_progress_bar('Clear');
        
        artefact.weights = allWf;
        D = putother(D, artefact);
        
    else
        
        % 2nd round of thresholding, but excluding bad channels
        index = [];
        
        spm_progress_bar('Init', D.ntrials, '2nd pass - Events thresholded'); drawnow;
        if D.ntrials > 100, Ibar = floor(linspace(1, D.ntrials,100));
        else Ibar = [1:D.ntrials]; end
        
        for i = 1:D.ntrials
            
            d = squeeze(D(:, :, i));
            
            % indices of channels that are above threshold
            Id = find(max(abs(d')) > Tchannel & ~Mbad(:, i)');
            Mbad(Id, i) = 1;
            
            if any(Id)
                % reject
                index = [index i];
            end
            
            % stow away event indices for which good channels were
            % above threshold
            for j = Id
                thresholded{j} = [thresholded{j} i];
            end

            if ismember(i, Ibar)
                spm_progress_bar('Set', i);
                drawnow;
            end
            
        end
        
        D = putother(D, thresholded);

        spm_progress_bar('Clear');
        disp(sprintf('%d rejected trials: %s', length(index), mat2str(index)))
        
        D = putreject(D, index, 1);
    end
    
end % MustDoWork

% User-specified lists override any artefact classification
if artefact.External_list
    D = putreject(D, artefact.out_list, 1);
    D = putreject(D, artefact.in_list, 0);
end

% Save the data
copyfile(fullfile(D.path, D.fnamedat), fullfile(D.path, ['a' D.fnamedat]));
putfnamedat(D, ['a' D.fnamedat]);

spm_progress_bar('Clear');

D = putfname(D, ['a' D.fname]);

save(D);

spm('Pointer', 'Arrow');
