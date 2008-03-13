function [y] = spm_gen_erp(P,M,U)
% Generates a prediction of trial-specific source activity
% FORMAT [y] = spm_gen_erp(P,M,U)
%
% P - parameters
% M - neural-mass model structure
% U - trial-specific effects
%
% y - {[ns,nc],...} - predictions for nc channels {trials}
%                   - for ns samples (time bins)
%
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_gen_erp.m 1208 2008-03-13 20:59:12Z karl $


% within-trial inputs
%==========================================================================

% check input u = f(t,P,M)
%--------------------------------------------------------------------------
try
    fu  = M.fu;
catch
    fu  = 'spm_erp_u';
end

% peri-stimulus time inputs
%--------------------------------------------------------------------------
t   = [1:M.ns]*U.dt;
U.u = feval(fu,t,P,M);


% between-trial inputs
%==========================================================================
try, X = U.X; catch, X = sparse(1,0); end


% cycle over trials
%--------------------------------------------------------------------------
for  c = 1:size(X,1)
    
    % baseline parameters
    %----------------------------------------------------------------------
    Q  = P;

    % trial-specific inputs
    %----------------------------------------------------------------------
    for i = 1:size(X,2)
        
        Q.A{1}  = Q.A{1} + X(c,i)*P.B{i};         % forward   connections
        Q.A{2}  = Q.A{2} + X(c,i)*P.B{i};         % backward  connections
        Q.A{3}  = Q.A{3} + X(c,i)*P.B{i};         % lateral   connections
        
        try
            Q.H = Q.H + X(c,i)*diag(P.B{i});      % intrinsic connections
        catch
            Q.G = Q.G + X(c,i)*diag(P.B{i});
        end
    end

    % integrate DCM for this trial
    %----------------------------------------------------------------------
    y{c,1}     = spm_int_L(Q,M,U);

end

