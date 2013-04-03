function dcm_group = spm_cfg_eeg_dcm_group
% Invert multiple DCMs specified in GUI.
%__________________________________________________________________________
% Copyright (C) 2013 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_cfg_eeg_dcm_group.m 5383 2013-04-03 16:22:30Z vladimir $

%--------------------------------------------------------------------------
% D
%--------------------------------------------------------------------------
D = cfg_files;
D.tag = 'D';
D.name = 'M/EEG datasets';
D.filter = 'mat';
D.num = [1 Inf];
D.help = {'Select the M/EEG mat files.'};

%--------------------------------------------------------------------------
% DCM
%--------------------------------------------------------------------------
DCM = cfg_files;
DCM.tag = 'DCMs';
DCM.name = 'DCM files';
DCM.filter = 'mat';
DCM.num = [1 Inf];
DCM.help = {'Select pre-specified DCM files.'};

%--------------------------------------------------------------------------
% Prior DCM
%--------------------------------------------------------------------------
pE = cfg_files;
pE.tag = 'pE';
pE.name = 'Priors';
pE.filter = 'mat';
pE.num = [0 1];
pE.val = {''};
pE.help = {'Select a DCM file where priors will be taken from (DCM.M.pE, DCM.M.pC)'};

%--------------------------------------------------------------------------
% Initialisation DCM
%--------------------------------------------------------------------------
P = cfg_files;
P.tag = 'P';
P.name = 'Initialisation';
P.filter = 'mat';
P.num = [0 1];
P.val = {''};
P.help = {'Select a DCM file for initialising the inversion (at DCM.Ep)'};

%--------------------------------------------------------------------------
% Feedback
%--------------------------------------------------------------------------
feedback = cfg_menu;
feedback.tag = 'feedback';
feedback.name = 'Graphical feedback';
feedback.help = {'Plot intermediate results during inversions'};
feedback.labels = {'Yes', 'No'};
feedback.values = {1, 0};
feedback.val = {1};

%--------------------------------------------------------------------------
% DCM_group
%--------------------------------------------------------------------------
dcm_group          = cfg_exbranch;
dcm_group.tag      = 'dcm_group';
dcm_group.name     = 'Invert multiple DCMs';
dcm_group.val      = {D, DCM, pE, P, feedback};
dcm_group.help     = {'Run multiple DCMs on multiple subjects'}';
dcm_group.prog     = @eeg_dcm;
dcm_group.modality = {'EEG'};

%==========================================================================
function eeg_dcm(job)

if ~isempty(char(job.pE))
    pE = load(char(job.pE));
    pC = pE.DCM.M.pC;
    pE = pE.DCM.M.pE;    
else
    pE = [];
    pC = [];
end

if ~isempty(char(job.P))
    P  = load(char(job.P));
    P  = P.DCM.Ep;   
else
    P  = [];
end
    
spm_dcm_estimate_group(char(job.DCMs),  char(job.D), P, pE, pC, job.feedback)
