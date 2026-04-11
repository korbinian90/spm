function vdm_pha = spm_est_vdm_from_phase(vol1, vol1_mean, vol1_pha, total_readout_time, TE, PE_dir, outdir)

%==========================================================================
% Estimate Voxel Displacement Map (VDM) from phase images using ROMEO phase
% unwrapping tool.
% FORMAT:
% vdm_pha = spm_est_vdm_from_phase(vol1, vol1_mean, vol1_pha,
%                                         total_readout_time, TE, PE_dir, outdir)
%
% Input:
%   vol1                - cell array of file names of magnitude images with
%                         the same PE direction as the fMRI data to be corrected
%   vol1_mean          - file name of mean magnitude image with the same PE
%                         direction as the fMRI data to be corrected
%   vol1_pha           - cell array of file names of phase images with the
%                         same PE direction as the fMRI data to be corrected
%   total_readout_time - total readout time in seconds
%   TE                 - echo time in seconds
%   PE_dir             - phase-encoding direction (+1 or -1)
%   outdir             - output directory for temporary files
%
% Output:
%   vdm_pha            - Voxel Displacement Map (in mm) estimated from phase
%                         images
%
% Barbara Dymerska
% Copyright (C) 2025 Department of Imaging Neuroscience, UCL
%==========================================================================

if numel(vol1(:,1))~=numel(vol1_pha(:,1))
    error('You need the same nr of same PE direction phase volumes as magnitude volumes')
end

Nii_mag = zeros([size(nifti(vol1(1,:)).dat(:,:,:)) numel(vol1(:,1))]) ;
Nii_pha = zeros(size(Nii_mag)) ;

for f = 1:numel(vol1(:,1))
    Nii_mag_1vol = nifti(vol1(f,:)).dat(:,:,:);
    Nii_pha_1vol = nifti(vol1_pha(f,:)).dat(:,:,:);

    Nii_mag(:,:,:,f)= Nii_mag_1vol;
    Nii_pha(:,:,:,f)= Nii_pha_1vol;
end


% calling ROMEO phase unwrapping via MATFrost
%--------------------------------------------------------------------------
jl = spm_julia('server');
if ndims(Nii_pha) == 4 %#ok<ISMAT>
    pha_unwr = jl.SPMSpatial.romeo_unwrap_4d(single(Nii_pha), single(Nii_mag));
else
    pha_unwr = jl.SPMSpatial.romeo_unwrap_3d(single(Nii_pha), single(Nii_mag));
end
pha_unwr = mean(pha_unwr,4) ;

vdm_pha = pha_unwr*total_readout_time/(2*pi*TE)*PE_dir ;

[~, mask] = spm_mask_from_segments(vol1_mean);

% fast VDM smoothing and extrapolation
vdm_pha = spm_smooth_extrap(vdm_pha, mask) ;


end