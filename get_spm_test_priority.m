function spm_standalone_test_priority = get_spm_test_priority()
% GET_SPM_TEST_PRIORITY Return prioritized list of SPM tests for conversion
%
% Returns a structure with test files prioritized by importance for
% standalone validation.

spm_standalone_test_priority = struct();

% Phase 1: Critical Core (CONVERTED)
spm_standalone_test_priority.phase1_critical = {
    'tests/test_spm.m'          % Core SPM functions
    'tests/test_spm_basic.m'    % Basic functionality
};

% Phase 2: Mathematical Core
spm_standalone_test_priority.phase2_math = {
    'tests/test_spm_dctmtx.m'         % DCT matrices (signal processing)
    'tests/test_spm_Tcdf.m'           % T-distribution
    'tests/test_spm_Ncdf.m'           % Normal distribution  
    'tests/test_spm_Gcdf.m'           % Gamma distribution
    'tests/test_spm_invTcdf.m'        % Inverse T-distribution
    'tests/test_spm_invNcdf.m'        % Inverse normal
};

% Phase 3: File I/O and Data Handling  
spm_standalone_test_priority.phase3_io = {
    'tests/test_gifti.m'              % GIfTI format support
    'tests/test_spm_file.m'           % File utilities
    'tests/test_spm_jsonread.m'       % JSON handling
    'tests/test_spm_vol.m'            % Volume handling
};

% Phase 4: Statistical Analysis
spm_standalone_test_priority.phase4_stats = {
    'tests/test_spm_BMS_gibbs.m'      % Bayesian model selection
    'tests/test_spm_reml.m'           % REML estimation
    'tests/test_spm_DEM.m'            % Dynamic expectation maximization
};

% Phase 5: Domain-Specific (Lower Priority)
spm_standalone_test_priority.phase5_fmri = {
    'tests/test_regress_fmri_glm_dcm.m'
    'tests/test_regress_fmri_group.m'
};

spm_standalone_test_priority.phase5_eeg = {
    'tests/test_spm_eeg_load.m'
    'tests/test_spm_eeg_bc.m'
    'tests/test_spm_eeg_average.m'
    'tests/test_spm_eeg_crop.m'
    'tests/test_spm_eeg_filter.m'
};

spm_standalone_test_priority.phase5_dcm = {
    'tests/test_spm_dcm_specify.m'
    'tests/test_spm_dcm_simulate.m' 
    'tests/test_spm_dcm_post_hoc.m'
    'tests/test_spm_dcm_peb_to_gcm.m'
};

% Phase 6: Code Quality (Optional)
spm_standalone_test_priority.phase6_quality = {
    'tests/test_checkcode.m'          % Code style checking
};

end
