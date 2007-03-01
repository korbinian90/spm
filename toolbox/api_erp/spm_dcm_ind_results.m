function [DCM] = spm_dcm_ind_results(DCM,Action)
% Results for induced Dynamic Causal Modeling (DCM)
% FORMAT spm_dcm_ind_results(DCM,Action);
% Action:
% 'Hz modes'
% 'Time-Hz'
% 'Coupling (A)'
% 'Coupling (B)'
% 'Input (C)'
% 'Input'
% 'Dipoles'
%                
%___________________________________________________________________________
%
% DCM is a causal modelling procedure for dynamical systems in which
% causality is inherent in the differential equations that specify the model.
% The basic idea is to treat the system of interest, in this case the brain,
% as an input-state-output system.  By perturbing the system with known
% inputs, measured responses are used to estimate various parameters that
% govern the evolution of brain states.  Although there are no restrictions
% on the parameterisation of the model, a bilinear approximation affords a
% simple re-parameterisation in terms of effective connectivity.  This
% effective connectivity can be latent or intrinsic or, through bilinear
% terms, model input-dependent changes in effective connectivity.  Parameter
% estimation proceeds using fairly standard approaches to system
% identification that rest upon Bayesian inference.
% 
%__________________________________________________________________________
% %W% Karl Friston %E


% get figure handle
%--------------------------------------------------------------------------
Fgraph = spm_figure('GetWin','Graphics');
figure(Fgraph)
clf

xY     = DCM.xY;
nt     = size(xY.xf,1);          % Nr of trials
nf     = size(xY.xf,2);          % Nr of frequnecy modes
nc     = size(xY.xf{1},2);       % Nr channels
ns     = size(xY.xf{1},1);       % Nr channels
nu     = size(DCM.B,2);          % Nr inputs
nm     = size(DCM.H{1},2);       % Nr time-frequency modes
nr     = size(DCM.K{1},2);       % Nr of sources
pst    = xY.Time;                % peri-stmulus time
Hz     = xY.Hz;                  % frequencies


% switch
%--------------------------------------------------------------------------
switch(lower(Action))
    
case{lower('Hz modes')}
    
    % spm_dcm_erp_results(DCM,'modes - channel space');
    %----------------------------------------------------------------------
    co = {'b', 'r', 'g', 'm', 'y', 'k'};
    lo = {'-', '--'};
    
    for i = 1:nm
        subplot(ceil(nm/2),2,i), hold on
        str   = {};
        for j = 1:nt
            plot(pst,DCM.H{j}(:,i), lo{1},...
                'Color', co{j},...
                'LineWidth',2);
            str{end + 1} = sprintf('trial %i (predicted)',j);
            plot(pst,DCM.H{j}(:,i) + DCM.R{j}(:,i), lo{2},...
                'Color',co{j});
            str{end + 1} = sprintf('trial %i (observed)',j);
                        set(gca, 'XLim', [pst(1) pst(end)]);

        end
        hold off
        title(sprintf('source-frequnecy mode %i',i))
        grid on
        axis square
        try
            axis(A);
        catch
            A = axis;
        end
    end
    xlabel('time (ms)')
    legend(str)

    
case{lower('Time-Hz')}
    
    % reconstitute time-frequency and get principle model over channels
    %----------------------------------------------------------------------
    nk    = length(Hz);
    for i = 1:nt
        for j = 1:nr
            TF{i,j} = sparse(ns,nk);
            RF{i,j} = sparse(ns,nk);
        end
    end
    for i = 1:nt
        for j = 1:nr
            for k = 1:nf
                TF{i,j} = TF{i,j} + DCM.Hc{i,k}(:,j)*xY.U(:,k)';
                RF{i,j} = RF{i,j} + DCM.Rc{i,k}(:,j)*xY.U(:,k)';
            end
        end
    end

      
    % loop over trials, sources (predicted and observed)
    %----------------------------------------------------------------------
    for i = 1:nt
        for j = 1:nr
            subplot(nt*2,nr,(i - 1)*nr + j)
            imagesc(Hz,pst,TF{i,j} + RF{i,j})
            xlabel('frequency')
            ylabel('pst (ms)')
            title({sprintf('trial %i: source %i ',i,j);
                  'observed'})

            subplot(nt*2,nr,(i - 1)*nr + nr + j)
            imagesc(Hz,pst,TF{i,j})
            xlabel('channel')
            ylabel('pst (ms)')
            title({sprintf('trial %i: source %i ',i,j);
                  'predicted'})
        end
    end

    
case{lower('Coupling (A)')}
    
        
    % images
    %----------------------------------------------------------------------
    subplot(3,2,1)
    imagesc(DCM.Ep.A)
    title('Coupling','FontSize',10)
    set(gca,'YTick',[1:nr],'YTickLabel',DCM.Sname,'FontSize',8)
    set(gca,'XTick',[])
    xlabel('from','FontSize',10)
    ylabel('to','FontSize',10)
    axis square

    % table
    %----------------------------------------------------------------------
    subplot(3,2,2)
    text(-1/8,1/2,num2str(DCM.Ep.A,' %-8.2f'),'FontSize',8)
    axis off,axis square


    % PPM
    %----------------------------------------------------------------------
    subplot(3,2,3)
    image(64*DCM.Pp.A)
    set(gca,'YTick',[1:nr],'YTickLabel',DCM.Sname,'FontSize',8)
    set(gca,'XTick',[])
    title('Conditonal probabilities')
    axis square

    % table
    %----------------------------------------------------------------------
    subplot(3,2,4)
    text(-1/8,1/2,num2str(DCM.Pp.A,' %-8.2f'),'FontSize',8)
    axis off, axis square
    
    
    % Guide
    %----------------------------------------------------------------------
    subplot(3,2,5)
    image(48*(kron(eye(nf,nf),ones(nr,nr)) - speye(nr*nf,nr*nf)))
    title('Within frequency (linear)')
    axis square
    
    subplot(3,2,6)
    image(48*(kron(1 - eye(nf,nf),ones(nr,nr))))
    title('Between frequency (non-linear)')
    axis square


case{lower('Coupling (B)')}
    
    % spm_dcm_erp_results(DCM,'coupling (B)');
    %--------------------------------------------------------------------
    for i = 1:nu
        
        % images
        %-----------------------------------------------------------
        subplot(4,nu,i)
        imagesc(DCM.Ep.B{i})
        title(DCM.xU.name{i},'FontSize',10)
        set(gca,'YTick',[1:ns],'YTickLabel',DCM.Sname,'FontSize',8)
        set(gca,'XTick',[])
        xlabel('from','FontSize',8)
        ylabel('to','FontSize',8)
        axis square

        % tables
        %--------------------------------------------------------------------
        subplot(4,nu,i + nu)
        text(-1/8,1/2,num2str(full(DCM.Ep.B{i}),' %-8.2f'),'FontSize',8)
        axis off
        axis square
        
        % PPM
        %-----------------------------------------------------------
        subplot(4,nu,i + 2*nu)
        image(64*DCM.Pp.B{i})
        set(gca,'YTick',[1:ns],'YTickLabel',DCM.Sname,'FontSize',8)
        set(gca,'XTick',[])
        title('PPM')
        axis square

        % tables
        %--------------------------------------------------------------------
        subplot(4,nu,i + 3*nu)
        text(-1/8,1/2,num2str(DCM.Pp.B{i},' %-8.2f'),'FontSize',8)
        axis off
        axis square
        
    end
    

case{lower('Input (C)')}
    
    % reconstitute time-frequency and get principle model over channels
    %----------------------------------------------------------------------
    for i = 1:nr
        j = [1:nf]*nr - nr + i;
        UF(:,i) = DCM.Eg.L(i)*xY.U*DCM.Ep.C(j);
    end
    plot(Hz,UF)
    xlabel('Frequency (Hz)')
    title('frequency response to input')
    axis square, grid on
    legend(DCM.Sname)
    
    
case{lower('Input')}
    
    % get input
    % --------------------------------------------------------------------
    [U N] = spm_ind_u((pst - pst(1))/1000,DCM.Ep,DCM.M);
    
    subplot(2,1,1)
    plot(pst,U,pst,N,':')
    xlabel('time (ms)')
    title('input')
    axis square, grid on
    legend({'input','nonspecific'})
    
    
case{lower('Dipoles')}
    
        sdip.n_seeds = 1;
        sdip.n_dip  = nr;
        sdip.Mtb    = 1;
        sdip.j{1}   = zeros(3*nr, 1);
        sdip.loc{1} = full(DCM.M.dipfit.L.pos);
        spm_eeg_inv_ecd_DrawDip('Init', sdip)

end
