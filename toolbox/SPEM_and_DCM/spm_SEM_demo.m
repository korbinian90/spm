% DCM for SPEM: Demo routine for meta-Bayesian inference
%--------------------------------------------------------------------------
 
% load and create data structure
%==========================================================================
clear
load DATA
 

% data structure
%--------------------------------------------------------------------------
xY.Y{1} = allsubj.SS.one;        % eye position    (condition 1)       
xY.Y{2} = allsubj.SN.one;        % eye position    (condition 2)  
xY.C{1} = allsubj.SS.target;     % target position (condition 1)
xY.C{2} = allsubj.SS.target;     % target position (condition 2)

% data structure
%--------------------------------------------------------------------------
xY.Y{3} = allsubj.FS.one;        % eye position    (condition 3)       
xY.Y{4} = allsubj.FN.one;        % eye position    (condition 4)  
xY.C{3} = allsubj.FS.target;     % target position (condition 3)
xY.C{4} = allsubj.FS.target;     % target position (condition 4)
 
xY.DT   = 0.1;                   % time bin (ms)
xY.occ  = @(x) x > 0 | x < -0.8; % occluder function of normalised x
 
% decimate and normalise
%--------------------------------------------------------------------------
DCM.xY  = spm_dcm_spem_data(xY);
 
 
% condition specific effects (in the form of a design matrix)
%==========================================================================
DCM.xU  = [-1  1 -1  1;          % smooth vs noisy condotions
           -1 -1  1  1];         % slow vs. fast stimulus speed
       
                                 % = 2 effects x 4 conditions
 
 
% model specification - in terms of priors
%==========================================================================
 
% Parameters (expectations of parameters and precisions)
%--------------------------------------------------------------------------
P.k = sparse(1,6);               % parameters of motion
P.h = sparse(1,3);               % parameters of precision
P.u = sparse(1,2);               % parameters of priors
 
% condition specific effects
%--------------------------------------------------------------------------
nu  = size(DCM.xU,1);            % number of (2) experimental effects
B   = cell(1,nu);
for i = 1:nu
    B{i} = P;
end
 
% Prior expectations and covariances
%--------------------------------------------------------------------------
pE.A   = P;
pE.B   = B;
DCM.pE = pE;
DCM.pC = pE;
 
% specify free parameters using (non-zero) variance
%--------------------------------------------------------------------------
v        = 1/2;
DCM.pC.A = spm_unvec(spm_vec(P) + v,P);

% allow precisions to change
%--------------------------------------------------------------------------
DCM.pC.B{1}.k(1:6) = v;
DCM.pC.B{1}.h(1:3) = v;
DCM.pC.B{1}.u(1:2) = v;

DCM.pC.B{2}.k(1:6) = v;
DCM.pC.B{2}.h(1:3) = v;
DCM.pC.B{2}.u(1:2) = v;



 
% prior predictions
%==========================================================================
spm_figure('GetWin','DEM');
M.ns    = length(DCM.xY.y{1});
M.C     = DCM.xY.u{1};
M.occ   = DCM.xY.occ;
 
% intial states
%--------------------------------------------------------------------------
M.x     = DCM.xY.x(1);
 
% generate prior predictions
%--------------------------------------------------------------------------
[Y DEM] = spm_SEM_gen(P,M);
DCM.Y   = {Y};
DCM.DEM = {DEM};
 
spm_DEM_qU(DEM.qU,DEM.pU)
 
% plot responses and prior predictions
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 1');
spm_dcm_spem_results(DCM);

% return
 
% invert and optimise (reduce) DCM
%==========================================================================
DCM = spm_dcm_spem(DCM);
DCM = spm_dcm_post_hoc(DCM);

% graphics
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 2');
spm_dcm_spem_results(DCM);



% Foucus on precion and Bayesian Model Comparison
%==========================================================================

% graphics
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 3');

subplot(2,2,1)
spm_plot_ci(DCM.Ep.B{1},DCM.Vp.B{1})
xlabel('Parameter')
ylabel('Mean and 90% CI')
title('Effect of target noise','FontSize',16)
spm_axis square
 
subplot(2,2,3)
spm_plot_ci(DCM.Ep.B{2},DCM.Vp.B{2})
xlabel('Parameter')
ylabel('Mean and 90% CI')
title('Effect of target speed','FontSize',16)
spm_axis square

subplot(2,2,2)
bar([DCM.Pp.B{1}.h; DCM.Pp.B{2}.h])
xlabel('Effects on precision')
ylabel('Model posterior')
title('Model comparison','FontSize',16)
spm_axis square
legend({'sensory','motion','prior'})
set(gca,'XLim',[1/2 5/2],'YLim',[0 1.2],'XTicklabel',{'noise','speed'})





