function out = spm_label(cfg)

if nargin==0
    % Select images to label
    P        = spm_select(Inf,'nifti','Select scans to label');
else
    if isa(cfg,'char')
        P = cfg;
    else
        P = strvcat(cfg.images);
    end
end

% Needs some files uploaded from:
% https://figshare.com/projects/Factorisation-based_Image_Labelling/128189

datadir = fullfile(spm('dir'),'toolbox','mb','data'); % Suggested location for data files
if ~exist(datadir,'dir')
    try
        fprintf('Attempting to make %s directory.\n', datadir);
        mkdir(datadir);
    catch
        fprintf('Failed to make directory %s\n', datadir);
        datadir = spm_select(1,'dir','Select directory for labelling data');
        %error(['Failed to make a directory for the template and labelling files (' datadir ').']);
    end
end

%datadir  = '.'; % Edit to indicate location of various files
mufname  = 'mu_X.nii';
filfname = 'fil30-nuNaN-v1-d4-K24-r2-sd1.5.mat';
%filfname = 'fil15-nuNaN-v1-d4-K24-r3-sd2.mat';
mufile   = fullfile(datadir,mufname);  % Head Tissue Template
filfile  = fullfile(datadir,filfname); % Trained FIL Model (15 training + 15 test subjects)
if ~exist(mufile,'file') || ~exist(filfile,'file')
    try
        fprintf('Attempting to download %s and %s files.\n', mufile, filfile);
        websave(mufile, 'https://figshare.com/ndownloader/files/31699187');
        websave(filfile,'https://figshare.com/ndownloader/files/31784579');
    catch
        error('Failed to download the template and labelling data.');
    end
end
% Could use Normal-Wishart priors for intensities. The following might help for
% labelling T1w scans.
%   nw_priors = fullfile(datadir,'prior_X_2.mat'); % MRI Intensity Priors for T1w
%   if ~exist(nw_priors,file),  error('Can''t find the Normal-Wishart priors.'); end

nw_priors = ''; % Any data

% Settings for MB alignment and tissue classification
clear chan
chan.inu.inu_reg = 10000;               % Intensity non-uniformity (INU) regularisation
chan.inu.inu_co  = 40;                  % Cut-off for INU
chan.modality    = 1;                   % Indicates MRI

clear gmm
gmm.chan           = chan;              % Attach
gmm.labels.false   = [];                % Not informed by labels
gmm.pr.file        = {nw_priors};       % Uses intensity priors
gmm.pr.hyperpriors = [];                % Do not update priors
gmm.tol_gmm        = 0.0005;            % When to stop clustering (GMM)
gmm.nit_gmm_miss   = 32;                % Maximum iterations for missing data
gmm.nit_gmm        = 8;                 % Maximum clustering (GMM) iterations
gmm.nit_appear     = 4;                 % Number of times to iterate the GMM and INU

clear cfg
cfg.mu.exist   = {mufile};              % Tissue priors
cfg.aff        = 'SE(3)';               % Include rigid alignment
cfg.v_settings = [0.0001 0.5 0.5 0 1];  % Registration regularisation
cfg.del_settings = Inf;                 % No variability of tissue prior rescaling
cfg.onam       = '';                    % No names for the outputs
cfg.odir       = {''};                  % No output directory
cfg.cat        = {{}};                  % Not working with pre-segmented images
cfg.gmm        = gmm;                   % Attach
cfg.accel      = 0.8;                   % 0 is slow and stable. 1 is fast and unstable
cfg.min_dim    = 8;                     % Minimum image size for multi-scale fitting
cfg.tol        = 0.001;                 % When to stop
cfg.sampdens   = 2;                     % Speed accuracy tradeoff
cfg.save       = false;                 % Don't save to disk
cfg.nworker    = 0;                     % No parallelisation

% Set search path to find additional functions
addpath(fullfile(spm('dir'),'toolbox','Shoot'));
addpath(fullfile(spm('dir'),'toolbox','Longitudinal'));
fil = load(filfile);

out.labels = cell(size(P,1),1);
for n=1:size(P,1)
    cfg.gmm.chan.images = {deblank(P(n,:))};
    [odir,onam,ext] = fileparts(cfg.gmm.chan.images{1}); % Output directory and filename
    [dat,sett]  = spm_mb_init(cfg);                  % Set up data structure
    dat(1).v    = zeros([dat(1).dm 3],'single');     % Modify structure to work in memory
    dat(1).psi  = zeros([dat(1).dm 3],'single');     % Modify structure to work in memory
    dat(1).onam = onam;
    [dat,sett]  = spm_mb_fit(dat,sett);              % Run Multi-Brain fitting
    Plab        = fil_label(fil,sett,dat,[6 10 10],0.25,odir); % Label the image
    out.labels{n} = Plab;
end

