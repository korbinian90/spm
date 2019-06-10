function [Y,I,FS] = spm_voice_get_next(wfile)
% Evaluates the likelihood of the next word in a file or object
% FORMAT [Y,I,FS] = spm_voice_get_next(wfile)
%
% wfile  - .wav file, audiorecorder object or (double) time series
%
% Y      - timeseries
% I      - Index prior to spectral peak
% FS     - sampling frequency
%
% This routine finds the index 500 ms before the next spectral peak in a
% file, timeseries (Y) or audio object. It filters  successive (one second)
% epochs with a Gaussian kernel of width VOX.C to identify peaks greater
% than VOX.U. if no such peak exists it advances for 500 ms (at most four
% times)
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_voice_get_next.m 7601 2019-06-03 09:41:06Z karl $

%% get peak identification parameters from VOX
%==========================================================================

% get source (recorder) and FS
%--------------------------------------------------------------------------
[FS,read] = spm_voice_FS(wfile);

% defaults
%--------------------------------------------------------------------------
global VOX
try, VOX.C;  catch, VOX.C  = 1/16;  end              % smoothing for peaks
try, VOX.U;  catch, VOX.U  = 1/256; end              % threshold for peaks
try, VOX.IT; catch, VOX.IT = 1;     end              % current index

% ensure 2 second of data has been accumulated
%--------------------------------------------------------------------------
if isa(wfile,'audiorecorder')
    IS = get(wfile,'TotalSamples');
    if ~IS
        stop(VOX.audio);
        record(VOX.audio,8);
        pause(2);
    else
        dt = (IS - VOX.IT)/FS;
        pause(2 - dt);
    end
end


%% find next peak
%==========================================================================

% find next word (waiting for a couple of seconds if necessary)
%--------------------------------------------------------------------------
for i = 1:4
    
    % find next spectral peak (I)
    %----------------------------------------------------------------------
    Y = read(wfile);
    n = numel(Y);
    j = fix((0:FS) + VOX.IT);
    G = spm_voice_check(Y(j(j < n)),FS,VOX.C);
    I = find((diff(G(1:end - 1)) > 0) & (diff(G(2:end)) < 0));
    I = I(G(I) > VOX.U);
    
    % advance pointer if silence
    %----------------------------------------------------------------------
    if isempty(I)
        
        % advance pointer 500 ms
        %------------------------------------------------------------------
        VOX.IT = VOX.IT + FS/2;
        
        % ensure 2 second of data has been accumulated
        %------------------------------------------------------------------
        if isa(wfile,'audiorecorder')
            dt = (get(wfile,'TotalSamples') - VOX.IT)/FS;
            pause(2 - dt);
        end
        
    else
        
        % move pointer to 500ms before peak
        %------------------------------------------------------------------
        I  = VOX.IT + I(1) - FS/2;
        
        % ensure 2 second of data has been accumulated
        %------------------------------------------------------------------
        if isa(wfile,'audiorecorder')
            dt = (get(wfile,'TotalSamples') - I)/FS;
            pause(2 - dt);
        end
        
        break
    end
end

% break if EOF
%--------------------------------------------------------------------------
if isempty(I), Y  = []; return, end
