function D = spm_eeg_prep(S)
% Prepare converted M/EEG data for further analysis
% FORMAT D = spm_eeg_prep(S)
% S                 - configuration structure (optional)
% (optional) fields of S:
%   S.D             - MEEG object or filename of M/EEG mat-file
%   S.task          - action string. One of 'settype', 'defaulttype',
%                     'loadtemplate','setcoor2d', 'project3d', 'loadeegsens', 
%                     'defaulteegsens', 'sens2chan', 'headshape', 'coregister'.
%   S.updatehistory - update history information [default: true]
%   S.save          - save MEEG object [default: false]
%
% D                 - MEEG object
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_eeg_prep.m 2970 2009-03-26 19:19:07Z vladimir $

if ~nargin
    spm_eeg_prep_ui;
    return;
end

D = spm_eeg_load(S.D);

switch lower(S.task)
    
    %----------------------------------------------------------------------
    case 'settype'
    %----------------------------------------------------------------------
        D = chantype(D, S.ind, S.type);
        
    %----------------------------------------------------------------------
    case 'defaulttype'
    %----------------------------------------------------------------------
        if isfield(S, 'ind')
            ind = S.ind;
        else
            ind = 1:D.nchannels;
        end

        dictionary = {
            'eog',           'EOG';
            'eeg',           'EEG';
            'ecg',           'ECG';
            'lfp',           'LFP';
            'emg',           'EMG';
            'meg',           'MEG';
            'ref',           'REF';
            'megmag',        'MEGMAG';
            'megplanar',     'MEGPLANAR';
            'meggrad',       'MEGGRAD';
            'refmag',        'REFMAG';
            'refgrad',       'REFGRAD'
            };

        D = chantype(D, ind, 'Other');

        type = fileio_chantype(D.chanlabels);
                
        spmtype = repmat({'Other'}, 1, numel(type));
        
        [sel1, sel2] = spm_match_str(type, dictionary(:, 1));

        spmtype(sel1) = dictionary(sel2, 2);
                
        % If there is useful information in the original types it
        % overwrites the default assignment
        if isfield(D, 'origchantypes') 
            [sel1, sel2] = spm_match_str(chanlabels(D, ind), D.origchantypes.label);            
            
            type = D.origchantypes.type(sel2);
            
            [sel1, sel2] = spm_match_str(type, dictionary(:, 1));
            
            spmtype(sel1) = dictionary(sel2, 2);
        end        

        D = chantype(D, ind, spmtype);
        
    %----------------------------------------------------------------------
    case {'loadtemplate', 'setcoor2d', 'project3d'}
    %----------------------------------------------------------------------
        switch lower(S.task)
            case 'loadtemplate'
                template    = load(S.P); % must contain Cpos, Cnames
                xy          = template.Cpos;
                label       = template.Cnames;
            case 'setcoor2d'
                xy          = S.xy;
                label       = S.label;
            case 'project3d'
                [xy, label] = spm_eeg_project3D(D.sensors(S.modality), S.modality);
        end

        [sel1, sel2] = spm_match_str(lower(D.chanlabels), lower(label));

        if ~isempty(sel1)

            megind = strmatch('MEG', chantype(D), 'exact');
            eegind = strmatch('EEG', chantype(D), 'exact');

            if ~isempty(intersect(megind, sel1)) && ~isempty(setdiff(megind, sel1))
                error('2D locations not found for all MEG channels');
            end

            if ~isempty(intersect(eegind, sel1)) && ~isempty(setdiff(eegind, sel1))
                warning(['2D locations not found for all EEG channels, changing type of channels', ...
                    num2str(setdiff(eegind, sel1)) ' to ''Other''']);

                D = chantype(D, setdiff(eegind, sel1), 'Other');
            end

            if any(any(coor2D(D, sel1) - xy(:, sel2)))
                D = coor2D(D, sel1, num2cell(xy(:, sel2)));
            end
        end
        
    %----------------------------------------------------------------------
    case 'loadeegsens'
    %----------------------------------------------------------------------
        switch S.source
            case 'mat'
                senspos = load(S.sensfile);
                name    = fieldnames(senspos);
                senspos = getfield(senspos,name{1});

                label = chanlabels(D, sort(strmatch('EEG', D.chantype, 'exact')));

                if size(senspos, 1) ~= length(label)
                    error('To read sensor positions without labels the numbers of sensors and EEG channels should match.');
                end

                elec = [];
                elec.pnt = senspos;
                elec.label = label;
                
                headshape = load(S.headshapefile);
                name    = fieldnames(headshape);
                headshape = getfield(headshape,name{1});
                
                shape = [];

                fidnum = 0;
                while ~all(isspace(S.fidlabel))
                    fidnum = fidnum+1;
                    [shape.fid.label{fidnum} S.fidlabel] = strtok(S.fidlabel);
                end

                if (fidnum < 3)  || (size(headshape, 1) < fidnum)
                    error('At least 3 labeled fiducials are necessary');
                end

                shape.fid.pnt = headshape(1:fidnum, :);

                if size(headshape, 1) > fidnum
                    shape.pnt = headshape((fidnum+1):end, :);
                else
                    shape.pnt = [];
                end
            case 'locfile'
                label = chanlabels(D, sort(strmatch('EEG', D.chantype, 'exact')));

                elec = fileio_read_sens(S.sensfile);

                % This handles FIL Polhemus case and other possible cases
                % when no proper labels are available.
                if isempty(intersect(label, elec.label))
                    ind = str2num(strvcat(elec.label));
                    if length(ind) == length(label)
                        elec.label = label(ind);
                    else
                        error('To read sensor positions without labels the numbers of sensors and EEG channels should match.');
                    end
                end
                
                shape = fileio_read_headshape(S.sensfile);

                % In case electrode file is used for fiducials, the
                % electrodes can be used as headshape
                if ~isfield(shape, 'pnt') || isempty(shape.pnt) && ...
                        size(shape.fid.pnt, 1) > 3
                    shape.pnt = shape.fid.pnt;
                end

        end

        elec = forwinv_convert_units(elec, 'mm');
        shape= forwinv_convert_units(shape, 'mm');

        if isequal(D.modality(1, 0), 'Multimodal')
            if ~isempty(D.fiducials) && isfield(S, 'regfid') && ~isempty(S.regfid)
                M1 = coreg(D.fiducials, shape, S.regfid);
                elec = forwinv_transform_sens(M1, elec);
            else
                error(['MEG fiducials matched to EEG fiducials are required '...
                    'to add EEG sensors to a multimodal dataset.']);
            end
        else
            D = fiducials(D, shape);
        end

        D = sensors(D, 'EEG', elec);

    %----------------------------------------------------------------------
    case 'defaulteegsens'
    %----------------------------------------------------------------------

        template_sfp = dir(fullfile(spm('dir'), 'EEGtemplates', '*.sfp'));
        template_sfp = {template_sfp.name};

        ind = strmatch([forwinv_senstype(D.chanlabels(D.meegchannels('EEG'))) '.sfp'], template_sfp, 'exact');

        if ~isempty(ind)
            elec = fileio_read_sens(fullfile(spm('dir'), 'EEGtemplates', template_sfp{ind}));

            [sel1, sel2] = spm_match_str(lower(D.chanlabels), lower(elec.label));

            sens = elec;
            sens.pnt = sens.pnt(sel2, :);
            % This takes care of possible case mismatch
            sens.label = D.chanlabels(sel1);

            D = sensors(D, 'EEG', sens);

            % Assumes that the first 3 points in standard location files
            % are the 3 fiducials (nas, lpa, rpa)
            fid = [];
            fid.pnt = elec.pnt;
            fid.fid.pnt = elec.pnt(1:3, :);
            fid.fid.label = elec.label(1:3);

            [xy, label] = spm_eeg_project3D(D.sensors('EEG'), 'EEG');

            [sel1, sel2] = spm_match_str(lower(D.chanlabels), lower(label));

            if ~isempty(sel1)

                eegind = strmatch('EEG', chantype(D), 'exact');

                if ~isempty(intersect(eegind, sel1)) && ~isempty(setdiff(eegind, sel1))
                    warning(['2D locations not found for all EEG channels, changing type of channels ', ...
                        num2str(setdiff(eegind(:)', sel1(:)')) ' to ''Other''']);

                    D = chantype(D, setdiff(eegind, sel1), 'Other');
                end

                if any(any(coor2D(D, sel1) - xy(:, sel2)))
                    D = coor2D(D, sel1, num2cell(xy(:, sel2)));
                end
            end

            if ~isempty(D.fiducials) && isfield(S, 'regfid') && ~isempty(S.regfid)
                M1 = coreg(D.fiducials, fid, S.regfid);
                D = sensors(D, 'EEG', forwinv_transform_sens(M1, D.sensors('EEG')));
            else
                D = fiducials(D, fid);
            end

        end

    %----------------------------------------------------------------------
    case 'sens2chan'
    %----------------------------------------------------------------------
        montage = S.montage;

        eeglabel = D.chanlabels(strmatch('EEG',D.chantype));
        meglabel = D.chanlabels(strmatch('MEG',D.chantype));

        if ~isempty(intersect(eeglabel, montage.labelnew))
            sens = sensors(D, 'EEG');
            if isempty(sens)
                error('The montage cannod be applied - no EEG sensors specified');
            end
            sens = forwinv_apply_montage(sens, montage, 'keepunused', 'no');
            D = sensors(D, 'EEG', sens);
        elseif ~isempty(intersect(meglabel, montage.labelnew))
            sens = sensors(D, 'MEG');
            if isempty(sens)
                error('The montage cannod be applied - no MEG sensors specified');
            end
            sens = forwinv_apply_montage(sens, montage, 'keepunused', 'no');
            D = sensors(D, 'MEG', sens);
        else
            error('The montage cannot be applied to the sensors');
        end

    %----------------------------------------------------------------------
    case 'headshape'
    %----------------------------------------------------------------------
        switch S.source
            case 'mat'
                headshape = load(S.headshapefile);
                name    = fieldnames(headshape);
                headshape = getfield(headshape,name{1});

                shape = [];

                fidnum = 0;
                while ~all(isspace(S.fidlabel))
                    fidnum = fidnum+1;
                    [shape.fid.label{fidnum} S.fidlabel] = strtok(S.fidlabel);
                end

                if (fidnum < 3)  || (size(headshape, 1) < fidnum)
                    error('At least 3 labeled fiducials are necessary');
                end

                shape.fid.pnt = headshape(1:fidnum, :);

                if size(headshape, 1) > fidnum
                    shape.pnt = headshape((fidnum+1):end, :);
                else
                    shape.pnt = [];
                end
            otherwise
                shape = fileio_read_headshape(S.headshapefile);

                % In case electrode file is used for fiducials, the
                % electrodes can be used as headshape
                if ~isfield(shape, 'pnt') || isempty(shape.pnt) && ...
                        size(shape.fid.pnt, 1) > 3
                    shape.pnt = shape.fid.pnt;
                end
        end

        shape = forwinv_convert_units(shape, 'mm');

        fid = D.fiducials;

        if ~isempty(fid) && isfield(S, 'regfid') && ~isempty(S.regfid)
            M1 = coreg(fid, shape, S.regfid);
            shape = forwinv_transform_headshape(M1, shape);
        end
        
        D = fiducials(D, shape);
    %----------------------------------------------------------------------
    case 'coregister'
    %----------------------------------------------------------------------
        [ok, D] = check(D, 'sensfid');

        if ~ok
            error('Coregistration cannot be performed due to missing data');
        end

        try
            val = D.val;
            Msize = D.inv{val}.mesh.Msize;
        catch
            val = 1;
            Msize = 1;
        end
        
        D = spm_eeg_inv_mesh_ui(D, val, 1, Msize);
        D = spm_eeg_inv_datareg_ui(D, val);

        if isequal(D.modality(1, 0), 'EEG')
            D = sensors(D, 'EEG', D.inv{1}.datareg.sensors);
            D = fiducials(D, D.inv{1}.datareg.fid_eeg);
        end

    %----------------------------------------------------------------------
    otherwise
    %----------------------------------------------------------------------
        fprintf('Unknown task ''%s'' to perform: Nothing done.\n',S.task);
end

% When prep is called from other functions with history, history should be
% disabled
if ~isfield(S, 'updatehistory') || S.updatehistory
    Stemp = S;
    Stemp.D = fullfile(D.path,D.fname);
    Stemp.save = 1;
    D = D.history('spm_eeg_prep', Stemp);
end

if isfield(S, 'save') && S.save
    save(D);
end


%==========================================================================
% function coreg
%==========================================================================
function M1 = coreg(fid, shape, regfid)
[junk, sel1] = spm_match_str(regfid(:, 1), fid.fid.label);
[junk, sel2] = spm_match_str(regfid(:, 2), shape.fid.label);

S = [];
S.targetfid = fid;
S.targetfid.fid.pnt = S.targetfid.fid.pnt(sel1, :);

S.sourcefid = shape;
S.sourcefid.fid.pnt = S.sourcefid.fid.pnt(sel2, :);
S.sourcefid.fid.label = S.sourcefid.fid.label(sel2);

S.targetfid.fid.label = S.sourcefid.fid.label;

S.template = 1;
S.useheadshape = 0;

M1 = spm_eeg_inv_datareg(S);
