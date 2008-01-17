function [inverse] = spm_eeg_inv_custom_ui(D)
% GUI for parameters of inversion of forward model for EEG-EMG
% FORMAT [inverse] = spm_eeg_inv_custom_ui
% FORMAT [inverse] = spm_eeg_inv_custom_ui(D)
%
% D  - M/EEG data structure
%
% gets:
%
%     inverse.type   - 'GS' Greedy search on MSPs
%                      'ARD' ARD search on MSPs
%                      'MSP' GS and ARD multiple sparse priors
%                      'LOR' LORETA-like model
%                      'IID' LORETA and minimum norm
%     inverse.woi    - time window of interest ([start stop] in ms)
%     inverse.lpf    - band-pass filter - low frequency cut-off (Hz)
%     inverse.hpf    - band-pass filter - high frequency cut-off (Hz)
%     inverse.Han    - switch for Hanning window
%     inverse.xyz    - (n x 3) locations of spherical VOIs
%     inverse.rad    - radius (mm) of VOIs
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_eeg_inv_custom_ui.m 1104 2008-01-17 16:26:33Z karl $
 
% defaults from D is specified
%==========================================================================
try
    woi = fix([-D.events.start D.events.stop]*1000/D.Radc);
    if (woi(end) - woi(1)) > 128
        q = 1;
    else
        q = 3;
    end
catch
    woi = [-100 200];
    q   = 1;
end
 
% get inversion parameters
%==========================================================================
inverse.type = 'GS';
if spm_input('Model','+1','b',{'Standard|Custom'},[0 1],1)
    
    % Search strategy
    %--------------------------------------------------------------------------
    type         = spm_input('Model inversion','+1','GS|ARD|COH|IID',{'GS','ARD','LOR','IID'},1);
    inverse.type = type{1};
    
    % Time window of interest
    %----------------------------------------------------------------------
    woi          = spm_input('Time-window (ms)','+1','r',woi);
    inverse.woi  = fix([min(woi) max(woi)]);
    
    % Hanning
    %----------------------------------------------------------------------
    inverse.Han  = spm_input('PST Hanning','+1','yes|no',[1 0],1);
 
    % High-pass filter
    %----------------------------------------------------------------------
    inverse.lpf  = spm_input('High-pass (Hz)','+1','1|8|16',[1 8 16],q);
    
    % Low-pass filter
    %----------------------------------------------------------------------
    inverse.hpf  = spm_input('Low-pass (Hz)','+1','48|128|256',[48 128 256],q);
        
    % Source space restictions
    %----------------------------------------------------------------------
    if spm_input('Restrict solutions','+1','no|yes',[0 1],1);
 
        [f,p]       = uigetfile('*.mat','source (n x 3) location file');
        xyz         = load(fullfile(p,f));
        name        = fieldnames(xyz);
        xyz         = getfield(xyz, name{1});
        inverse.xyz = xyz;
        inverse.rad = spm_input('radius of VOI (mm)','+1','r',32);
        
    end
end
 
return
%==========================================================================
% other GUI options
 
    % Hanning
    %----------------------------------------------------------------------
    inverse.Han = spm_input('PST Hanning','+1','yes|no',[1 0],1);
 
    % Channel modes
    %----------------------------------------------------------------------
    inverse.Nm  = spm_input('Channel modes (max)','+1','32|64|128',[32 64 128],2);
    
    % Temporal modes
    %----------------------------------------------------------------------
    inverse.Nr  = spm_input('Temporal modes (max)','+1','4|8|16',[4 8 16],2);
    
    % D.inverse.sdv    - smoothness of source priors (ms)
    %----------------------------------------------------------------------
    inverse.sdv      = spm_input('Temporal smoothness (ms)','+1','1|4|16',[1 4 16],2);
 
    % Number of sparse priors
    %----------------------------------------------------------------------
    switch inverse.type, case{'MSP','GS','ARD'}
        inverse.Np   = spm_input('MSPs per hemisphere','+1','64|128|256|512',[64 128 256 512],3);
    end
    
    % D.inverse.smooth - smoothness of source priors (mm)
    %----------------------------------------------------------------------
    switch inverse.type, case{'GS','MSP','ARD''LOR'}
        inverse.smooth = spm_input('Spatial smoothness (0-1)','+1','0.2|0.4|0.6',[0.2 0.4 0.6],3);
    end
