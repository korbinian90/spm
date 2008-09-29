function spm_eeg_convertmat2nifti(S)
% Convert epoched EEG/ERP data from SPM- to analyze format by projecting
% onto the scalp surface
% FORMAT spm_eeg_convertmat2nifti(S)
%
% S         - optional input struct
% (optional) fields of S:
% Fname     - matrix of EEG mat-files
% n         - size of quadratic output image (size: n x n x 1)
%_______________________________________________________________________
%
% spm_eeg_convertmat2ana converts EEG/MEG data from the SPM M/EEG format to
% nifti format. The channel data are interpolated to voxel-space using a
% trilinear interpolation. The electrodes' locations are specified by the
% channel template file. Each channel's data will be found in an individual
% voxel given that n is big enough. The data is written to 4-dim nifti
% images.
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Stefan Kiebel
% $Id: spm_eeg_convertmat2nifti.m 2215 2008-09-29 09:43:35Z stefan $

% [Finter, Fgraph, CmdLine] = spm('FnUIsetup', 'EEG conversion setup',0);

try
    Fname = S.Fname;
catch
    Fname = spm_select(inf, '\.mat$', 'Select EEG mat file');
end

Nsub = size(Fname, 1);

try
    n = S.n;
catch
    n = spm_input('Output image dimension', '+1', 'n', '32', 1);
end

if length(n) > 1
    error('n must be a scalar.');
end

try
    interpolate_bad = S.interpolate_bad;
catch
    interpolate_bad = spm_input('Interpolate bad channels or mask out?',...
        '+1', 'b', 'Interpolate|Mask out', [1,0]);
end

spm('Pointer', 'Watch'); drawnow

% Load data set into structures
clear D
for i = 1:Nsub
    D{i} = spm_eeg_load(deblank(Fname(i,:)));
end

for k = 1:Nsub

    [Cel, Cind, x, y] = spm_eeg_locate_channels(D{k}, n, interpolate_bad);

    % nr of channels
    Nel = length(Cel);
    
    % generate data directory into which converted data goes
    [P, F] = fileparts(spm_str_manip(Fname(k, :), 'r'));
    [m, sta] = mkdir(P, spm_str_manip(Fname(k, :), 'tr'));
    if m ~= 1
        error(sta);
        return
    end
    
    cd(fullfile(P, spm_str_manip(Fname(k, :), 'tr')));
    
    d = (D{k}(Cind, :,:));
    cl = D{k}.condlist;
    
    for i = 1 : D{k}.nconditions
        
        Itrials = intersect(pickconditions(D{k}, cl(i)), find(~D{k}.reject))';
        
        dname = sprintf('type_%s', cl{i});
        [m, sta] = mkdir(dname);
        cd(dname);
        
        for l = Itrials
            % single trial data
            if l < 10
                tmp = '000';
            elseif l <100
                tmp = '00';
            elseif l < 1000
                tmp = '0';
            else
                tmp = [];
            end

            fname = sprintf('trial%s%d.img', tmp, l);
            
            dat = file_array(fname,[n n 1 D{k}.nsamples],'FLOAT32-LE');
            N = nifti;
            N.dat = dat;
            N.mat = eye(4);
            N.mat_intent = 'Aligned';
            create(N);
                        
            for j = 1 : D{k}.nsamples % time bins
                di = ones(n, n)*NaN;                
                di(sub2ind([n n], x, y)) = griddata(Cel(:,1), Cel(:,2), d(:, j, l), x, y, 'linear');
                % griddata returns NaN for voxels outside convex hull (this can
                % happen due to bad electrodes at borders of setup.)
                % Replace these by nearest neighbour interpoltation.
                tmp = find(isnan(di(sub2ind([n n], x, y))));
                di(sub2ind([n n], x(tmp), y(tmp))) =...
                    griddata(Cel(:,1), Cel(:,2), d(:, j, l), x(tmp), y(tmp), 'nearest');
                
                N.dat(:,:,1,j) = di;
            end        
            
                disp(sprintf('File %d, type %d, trial %d', k, i, l))
            
        end
        cd ..
    end
    cd ..
end

spm('Pointer', 'Arrow');
