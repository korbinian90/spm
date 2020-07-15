function [DCM] = DEM_COVID_UTLA
% FORMAT [DCM] = DEM_COVID_UTLA
%
% Demonstration of COVID-19 modelling with stratified populations
%__________________________________________________________________________
%
% This demonstration routine fixed multiple regional death by date and new
% cases data and compiles estimates of latent states for local
% authorities served by an NHS trust provider.
%
% Technical details about the dynamic causal model used here can be found
% at https://www.fil.ion.ucl.ac.uk/spm/covid-19/.
%
% The (annotated) open source code creating these graphics is
% DEM_COVID_DASH.m
%__________________________________________________________________________
% Copyright (C) 2020 Wellcome Centre for Human Neuroimaging

% Karl Friston
% $Id: DEM_COVID_UTLA.m 7895 2020-07-14 08:55:30Z karl $


% NHS postcode data
%==========================================================================
% http://geoportal.statistics.gov.uk/datasets/75edec484c5d49bcadd4893c0ebca0ff_0
% xy   = readmatrix('NHS_Postcode.csv','range',[2 1  2643867 2]);
% pc   = readmatrix('NHS_Postcode.csv','range',[2 5  2643867 5], 'OutputType','char');
% cc   = readmatrix('NHS_Postcode.csv','range',[2 12 2643867 12],'OutputType','char');
% G.X  = xy(:,1);
% G.Y  = xy(:,2);
% G.PC = pc;
% G.LT = cc;

LTLA   = readmatrix('Population_LTLACD.xlsx','range',[6 1  35097 1], 'OutputType','char');
Pop    = readmatrix('Population_LTLACD.xlsx','range',[6 4  35097 4], 'OutputType','char');

% NHS provider code to post code
%--------------------------------------------------------------------------
% E    = importdata('etr.xlsx');
% E    = E.textdata(:,[1,10]);

% save('COVID_CODES','G','E')
% load codes
%--------------------------------------------------------------------------
load COVID_CODES

% retrieve recent data from https://coronavirus.data.gov.uk
%--------------------------------------------------------------------------
url  = 'https://c19downloads.azureedge.net/downloads/csv/';
websave('coronavirus-cases_latest.csv',[url,'coronavirus-cases_latest.csv']);

% retrieve recent data from https://www.england.nhs.uk
%--------------------------------------------------------------------------
URL  = 'https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/07/';
for i = 0:4
    try
        dstr = datestr(datenum(date) - i,'dd-mmm-yyyy');
        if strcmp(dstr(1),'0'),dstr = dstr(2:end); end
        url  = [URL 'COVID-19-total-announced-deaths-' dstr '-1.xlsx'];
        websave('COVID-19-total-announced-deaths.xlsx',url);
        break
    end
end

% load (ONS Pillar 1) testing and (PHE) death-by-date data
%--------------------------------------------------------------------------
C    = importdata('coronavirus-cases_latest.csv');
D    = importdata('COVID-19-total-announced-deaths.xlsx');
P    = importdata('Populations.xlsx');


% get death by date from each NHS trust
%--------------------------------------------------------------------------
DN   = datenum(D.textdata.Tab4DeathsByTrust(15,6:end - 4),'dd-mmm-yy');
NHS  = D.textdata.Tab4DeathsByTrust(18:end,3);
DA   = D.data.Tab4DeathsByTrust(3:end,2:end - 4);

% get population by lower tier local authority
%--------------------------------------------------------------------------
PN   = P.data;
PCD  = P.textdata(2:end,1);

% get new cases by (lower tier) local authority
%--------------------------------------------------------------------------
AreaCode = C.textdata(2:end,2);
AreaType = C.textdata(2:end,3);
AreaDate = C.textdata(2:end,4);
AreaName = C.textdata(2:end,1);

j        = find(ismember(AreaType,'Lower tier local authority'));
AreaCode = AreaCode(j);
AreaDate = AreaDate(j);
AreaName = AreaName(j);
AreaCase = C.data(j,4);

% organise via NHS trust
%--------------------------------------------------------------------------
clear D C P
k     = 1;
for i = 1:numel(NHS)
    
    % get NHS Trust code
    %----------------------------------------------------------------------
    j = find(ismember(E(:,1),NHS(i)));
    if numel(j)
        
        % get postcode of NHS trust
        %------------------------------------------------------------------
        PC = E(j,2);
        
        % get local authority code of postcode
        %------------------------------------------------------------------
        g  = find(ismember(G.PC,PC));
        LA = G.LT(g);
        
        % get local authority code of NHS trust
        %------------------------------------------------------------------
        j  = find(ismember(AreaCode,LA));
        l  = find(ismember(G.LT,LA));
        
        % get local authority population
        %------------------------------------------------------------------
        N  = PN(find(ismember(PCD,LA)));
        
        
        if numel(j)
            
            % get deaths
            %--------------------------------------------------------------
            D(k).deaths = DA(i,:);
            D(k).date   = DN;
            D(k).name   = AreaName(j(1));
            D(k).NHS    = NHS(i);
            D(k).code   = LA;
            D(k).N      = N;
            D(k).PC     = PC(1);
            D(k).X      = G.X(l);
            D(k).Y      = G.Y(l);
            
            % get cumulative cases
            %--------------------------------------------------------------
            CN    = datenum(AreaDate(j),'yyyy-mm-dd');
            for n = 1:numel(DN)
                [d,m]         = min(abs(CN - DN(n)));
                D(k).cases(n) = AreaCase(j(m));
            end
            
            % next region
            %--------------------------------------------------------------
            k = k + 1
        end
    end
end

% find unique local authorities served by each NHS provider code
%--------------------------------------------------------------------------
Area  = unique([D.code]);
k     = 1;
for i = 1:numel(Area)
    
    % accumulate deaths within each local authority
    %----------------------------------------------------------------------
    j     = find(ismember([D.code],Area(i)));
    DD(k) = D(j(1));
    for n = 2:numel(j)
        DD(k).deaths = DD(k).deaths + D(j(n)).deaths;
    end
    k     = k + 1;
end
D    = DD;

% find local authorities not accounted for
%--------------------------------------------------------------------------
[UniqueArea,j] = unique(AreaCode);
UniqueName = AreaName(j);
j          = unique(find(~ismember(UniqueArea,Area)));
UniqueArea = UniqueArea(j);
UniqueName = UniqueName(j);

% get centroids of local authorities with NHS trusts
%--------------------------------------------------------------------------
for i = 1:numel(D)
    X(i) = mean(D(i).X);
    Y(i) = mean(D(i).Y);
end

% assign local authorities to local authorities with NHS trusts
%--------------------------------------------------------------------------
for i = 1:numel(UniqueArea)
    
    % find closest area in D
    %----------------------------------------------------------------------
    j     = find(ismember(G.LT,UniqueArea(i)));
    x     = mean(G.X(j));
    y     = mean(G.Y(j));
    [d,k] = min((X - x).^2 + (Y - y).^2);
    
    % get local authority code of NHS trust
    %----------------------------------------------------------------------
    j     = find(ismember(AreaCode,UniqueArea(i)));
    l     = find(ismember(G.LT,UniqueArea(i)));
    
    % get local authority population
    %------------------------------------------------------------------
    N     = PN(find(ismember(PCD,UniqueArea(i))));
    
    % supplement area
    %----------------------------------------------------------------------
    D(k).code(end + 1) = UniqueArea(i);
    D(k).name(end + 1) = UniqueName(i);
    D(k).X             = [D(k).X; G.X(l)];
    D(k).Y             = [D(k).Y; G.Y(l)];
    D(k).N             = D(k).N + N;
    
    % add cumulative cases
    %----------------------------------------------------------------------
    CN    = datenum(AreaDate(j),'yyyy-mm-dd');
    for n = 1:numel(DN)
        [d,m]         = min(abs(CN - DN(n)));
        D(k).cases(n) = D(k).cases(n) + AreaCase(j(m));
    end
end


% regional images
%--------------------------------------------------------------------------
n    = 512;
i    = ceil(n*G.X/7e5);
j    = ceil(n*G.Y/7e5);
i    = i(isfinite(j));
j    = j(isfinite(j));
UK   = sparse(i,j,1,n,2*n);

% plot map
%--------------------------------------------------------------------------
GRAPHICS = 1;
if GRAPHICS
    spm_figure('GetWin','UK - regional data'); clf;
    subplot(2,1,1), hold on
    imagesc(1 - log(UK + 1)'), axis xy image off
end

for k = 1:numel(D)
    
    % prepend 16 days to timeseries
    %----------------------------------------------------------------------
    D(k).cases  = [zeros(1,16), D(k).cases];
    D(k).deaths = [zeros(1,16), D(k).deaths];
    D(k).date   = [(DN(1) - flip(1:16)) DN'];
    
    % assemble and smooth data matrix
    %----------------------------------------------------------------------
    s        = 7;                        % seven day average
    Y        = [spm_conv(D(k).deaths',s,0), gradient(spm_conv(D(k).cases,s))'];
    Y(Y < 0) = 0;
    D(k).YY  = Y;
    
    if GRAPHICS
        
        % show data
        %------------------------------------------------------------------
        subplot(2,1,1), hold on
        plot(D(k).X,D(k).Y,'.')
        axis image, axis off, box off
        title([D(k).name,D(k).PC])
        
        subplot(2,2,3), hold on
        plot(D(k).date,D(k).YY(:,1))
        datetick, axis square, title('Deaths')
        
        subplot(2,2,4), hold on
        plot(D(k).date,D(k).YY(:,2))
        datetick, axis square, title('New cases')
        drawnow
    end
    
end

% create image array
%--------------------------------------------------------------------------
clear G DD
for k = 1:numel(D)
    i        = ceil(n*D(k).X/7e5);
    j        = ceil(n*D(k).Y/7e5);
    i        = i(isfinite(j));
    j        = j(isfinite(j));
    D(k).X   = mean(i);
    D(k).Y   = mean(j);
    LA       = spm_conv(double(logical(sparse(i,j,1,n,n))),1,1);
    ENG(:,k) = spm_vec(LA);
end
ENG = bsxfun(@rdivide,ENG,sum(ENG,2) + eps);

% dates
%--------------------------------------------------------------------------
t     = D(1).date;
T     = [t ((1:64) + t(end))];

% fit each regional dataset
%==========================================================================
for r = 1:numel(D)
    
    % get (Gaussian) priors over model parameters
    %----------------------------------------------------------------------
    [pE,pC] = spm_COVID_priors;
    
    % priors for this analysis
    %----------------------------------------------------------------------
    pE.N   = log(D(r).N/1e6);             % population of local authority
    pC.N   = 0;
    pE.n   = 0;                           % initial number of cases (n)
    
    % variational Laplace (estimating log evidence (F) and posteriors)
    %======================================================================
    Y      = D(r).YY;
    
    % complete model specification
    %----------------------------------------------------------------------
    M.date = datestr(DN(1),'dd-mm-yyyy'); % date of first time point
    M.G    = @spm_COVID_gen;              % generative function
    M.FS   = @(Y)sqrt(Y);                 % feature selection  (link function)
    M.pE   = pE;                          % prior expectations (parameters)
    M.pC   = pC;                          % prior covariances  (parameters)
    M.hE   = [4 2];                       % prior expectation  (log-precision)
    M.hC   = 1/512;                       % prior covariances  (log-precision)
    M.T    = size(Y,1);                   % number of samples
    U      = [1 2];                       % outputs to model
    
    % model inversion with Variational Laplace (Gauss Newton)
    %----------------------------------------------------------------------
    [Ep,Cp,Eh,F] = spm_nlsi_GN(M,U,Y);
    
    % save prior and posterior estimates (and log evidence)
    %----------------------------------------------------------------------
    DCM(r).M  = M;
    DCM(r).Ep = Ep;
    DCM(r).Cp = Cp;
    DCM(r).Y  = Y;
    DCM(r).F  = F;
    
    % now-casting for this region and date
    %======================================================================
    spm_figure('GetWin',D(r).name{1}); clf;
    %----------------------------------------------------------------------
    M.T   = numel(T);
    [Y,X] = spm_COVID_gen(DCM(r).Ep,M,[1 2]);
    spm_COVID_plot(Y,X,DCM(r).Y);
    
    
    %----------------------------------------------------------------------
    % Y(:,1)  - number of new deaths
    % Y(:,2)  - number of new cases
    % Y(:,3)  - CCU bed occupancy
    % Y(:,4)  - effective reproduction rate (R)
    % Y(:,5)  - population immunity (%)
    % Y(:,6)  - total number of tests
    % Y(:,7)  - contagion risk (%)
    % Y(:,8)  - prevalence of infection (%)
    % Y(:,9)  - number of infected at home, untested and asymptomatic
    % Y(:,10) - new cases per day
    %----------------------------------------------------------------------
    Y       = spm_COVID_gen(DCM(r).Ep,DCM(r).M,[4 5 8 9 10]);
    
    DR(:,r) = Y(:,1);                           % Reproduction ratio
    DI(:,r) = Y(:,2);                           % Prevalence of immunity
    DP(:,r) = Y(:,3);                           % Prevalence of infection
    DC(:,r) = Y(:,4);                           % Infected, asymptomatic people
    DT(:,r) = Y(:,5);                           % New daily cases
    
    
    % supplement with table of posterior expectations
    %----------------------------------------------------------------------
    subplot(3,2,2), cla reset, axis([0 1 0 1])
    title(D(r).name,'Fontsize',16)
    
    str      = sprintf('Population %.2f million',exp(Ep.N));
    text(0,0.9,str,'FontSize',10,'FontWeight','bold','Color','k')
    
    str      = sprintf('Reproduction ratio %.2f',DR(end,r));
    text(0,0.8,str,'FontSize',10,'FontWeight','bold','Color','k')
    
    str      = sprintf('Infected, asymptomatic people %.0f',DC(end,r));
    text(0,0.7,str,'FontSize',10,'FontWeight','bold','Color','k')
    
    str      = sprintf('Daily new cases: %.0f per 100,000',DT(end,r)/exp(Ep.N)/10);
    text(0,0.6,str,'FontSize',10,'FontWeight','bold','Color','r')
    
    str      = sprintf('Prevalence of infection: %.2f%s',DP(end,r),'%');
    text(0,0.5,str,'FontSize',10,'FontWeight','bold','Color','r')
    
    str = sprintf('Prevalence of immunity %.1f%s',DI(end,r),'%');
    text(0,0.4,str,'FontSize',10,'FontWeight','bold','Color','k')
    
    str = {'The prevalences refer to the effective population' ...
        'as estimated from the new cases and deaths (shown as' ...
        'dots on the upper left panel)'};
    text(0,0.0,str,'FontSize',8,'Color','k')
    
    spm_axis tight, axis off
    
end

% save and reload
%----------------------------------------------------------------------
try, clear ans, end
save COVID_LA

load COVID_LA

str = {'Reproduction ratio',...
       'Prevalence of infection (%)'...
       'New infections per day'};
DD    = {DR,DP,DT};
for j = 1:numel(DD)
    
    % save
    %----------------------------------------------------------------------
    spm_figure('GetWin',str{j}); clf; colormap('pink')
    subplot(2,1,1)
    
    Y     = DD{j}';
    m     = max(Y(:));
    Y     = 64*Y/m;
    for i = 1:size(Y,2)
        
        % image
        %------------------------------------------------------------------
        E   = reshape(ENG*Y(:,i),n,n);
        image(64 - 2*E'), axis xy image off, drawnow
        dat = datestr(D(1).date(i),'dd-mmm-yy');
        text(128,256,{str{j},dat},...
            'HorizontalAlignment','Center',...
            'FontWeight','bold','FontSize',12);
        
        % save
        %------------------------------------------------------------------
        MOV(i) = getframe(gca);
    end
    
    % ButtonDownFcn
    %----------------------------------------------------------------------
    h = findobj(gca,'type','image');
    set(h(1),'Userdata',{MOV,16})
    set(h(1),'ButtonDownFcn','spm_DEM_ButtonDownFcn')
    
    subplot(2,1,2)
    imagesc(64 - E'), axis xy image off, drawnow
    dat = datestr(D(1).date(i),'dd-mmm-yy');
    title({str{j},dat},'FontSize',12)
    
    
    % List four most affected authorities
    %----------------------------------------------------------------------
    [y,k] = sort(DD{j}(end,:),'descend');
    for i = 1:4
        if y(i) > 32
            Atsr = sprintf('%s (%.0f)',D(k(i)).name{1},y(i));
        else
            Atsr = sprintf('%s (%.2f)',D(k(i)).name{1},y(i));
        end
        text(8 + D(k(i)).X,D(k(i)).Y,Atsr,...
            'HorizontalAlignment','Left',...
            'FontWeight','bold','FontSize',10);
    end
    
end


% fit average over regions
%==========================================================================
clear M
Y     = 0;
for r = 1:numel(D)
    Y       = Y + D(r).YY;
    EP(:,r) = spm_vec(DCM(r).Ep);
end

% priors for this analysis
%--------------------------------------------------------------------------
[pE,pC] = spm_COVID_priors;
pE.N    = log(56);                    % population of local authority
pC.N    = 0;
pE.n    = 4;                          % initial number of cases (n)
% pE.Tim = log(64)

% complete model specification
%--------------------------------------------------------------------------
M.date = datestr(DN(1),'dd-mm-yyyy'); % date of first time point
M.G    = @spm_COVID_gen;              % generative function
M.FS   = @(Y)sqrt(Y);                 % feature selection  (link function)
M.pE   = pE;                          % prior expectations (parameters)
M.pC   = pC;                          % prior covariances  (parameters)
M.hE   = [2 0];                       % prior expectation  (log-precision)
M.hC   = 1/512;                       % prior covariances  (log-precision)
M.T    = size(Y,1);                   % number of samples
U      = [1 2];                       % outputs to model

% model inversion with Variational Laplace (Gauss Newton)
%--------------------------------------------------------------------------
[Ep,Cp] = spm_nlsi_GN(M,U,Y);

% forecast
%--------------------------------------------------------------------------
spm_figure('GetWin','England'); clf;
%--------------------------------------------------------------------------
t       = D(1).date;
T       = [t ((1:64) + t(end))];
M.T     = numel(T);
[P,X]   = spm_COVID_gen(Ep,M,[1 2]);
spm_COVID_plot(P,X,Y);

% prevalence in terms of new cases per week and day
%--------------------------------------------------------------------------
spm_figure('GetWin','Supression'); clf;
%--------------------------------------------------------------------------
[S,CS,P,C] = spm_COVID_ci(Ep,Cp,[],[8 10],M);
k          = 7;
Eq         = P(:,2)*k;
Cq         = C{2}*(k^2);
Sq         = sqrt(diag(Cq))*1.69;

subplot(2,1,1), hold off
spm_plot_ci(Eq',Cq,T), hold on
title('New cases per week','Fontsize',16)
datetick('x','mmm-dd')
xlabel('date'),ylabel('new cases'), box off

d      = datenum(date);
j      = find(ismember(T,d));
plot([d,d],[0 1e6],'b')
txt{1} = sprintf('Cases/week : %.0f (%0.0f - %.0f)',Eq(j),Eq(j) - Sq(j),Eq(j) + Sq(j));
Eq     = Eq/7; Sq = Sq/7;
txt{2} = sprintf('Cases/day  : %.0f (%0.0f - %.0f)',Eq(j),Eq(j) - Sq(j),Eq(j) + Sq(j));
Eq     = Eq/exp(Ep.N); Sq = Sq/exp(Ep.N);
txt{3} = sprintf('Cases/day/M: %.0f (%0.0f - %.0f)',Eq(j),Eq(j) - Sq(j),Eq(j) + Sq(j));
qE     = P(:,1); qS = sqrt(diag(C{1}))*1.69;
txt{4} = sprintf('Prevalence of infection (%s): %.3f (%.3f - %.3f)','%',qE(j),qE(j) - qS(j),qE(j) + qS(j));

text(d,1e6,txt,'FontSize',10,'Fontweight','bold')

% plot in terms of cases per hundred thousand
%--------------------------------------------------------------------------
subplot(2,1,2), hold off
Eq     = Eq/10;
semilogy(T,Eq,'LineWidth',2), hold on

plot(T,ones(size(T))*1,'-r'),  text(T(8),1,'Suppression (1 per 100,000)','FontSize',10,'Fontweight','bold')
plot(T,ones(size(T))*10,'-r'), text(T(8),10,'Special measures (10 per 100,000)','FontSize',10,'Fontweight','bold')
plot(T,ones(size(T))*100,'-r'),text(T(8),100,'Lockdown (100 per 100,000)','FontSize',10,'Fontweight','bold')
title('New daily cases per 100,000','Fontsize',16)
datetick('x','mmm-dd')
xlabel('date'), ylabel('new cases')

% projections and an enhanced FTTIS protocol
%--------------------------------------------------------------------------
Ep.ttt = log(1/4);
M.TTT  = j;
P      = spm_COVID_gen(Ep,M,10);
Eq     = P/exp(Ep.N)/10;
semilogy(T,Eq,'-.','LineWidth',1)

text(T(end),Eq(end),'with 25% FTTIS','FontSize',10)
plot([d,d],[1 50],'b')
box off

return



% 'Cornwall.Isles of Scilly','E41000052',D(37) 'Cornwall and Isles of Scilly'
%
% 'City of London and Westminster' 'E07000324' D(149) 'Westminster'
%
% 'St Edmundsbury',  'E07000204'  D(99)  'West Suffolk'
% 'Forest Heath',    'E07000201'  D(99)
%
% 'Suffolk coastal', 'E07000205'  D(98)  'East Suffolk'
% 'Waveney',         'E07000 206' D(98)
%
% 'West Somerset',   'E07000191'  D(100) 'Somerset West and Taunton'
% 'Taunton Deane',   'E07000190'  D(100)
%
% 'West Dorset',  'E07000052'     D(41)  'Dorset'
% 'North Dorset', 'E07000050'     D(41)
% 'East Dorset',  'E07000049'     D(41)
%
% 'Christchurch', 'E07000048'     D(40)  'Bournemouth, Christchurch and Poole'
% 'Bournemouth',  'E07000028'     D(40)
% 'Purbeck',      'E07000051'     D(40)
% 'Poole',        'E07000029'     D(40)
%
%
% 'East Herts',      'E07000097'  D(97)  'Stevenage'
% 'Welwyn Hatfield', 'E07000104'  D(96)  'Welwyn Hatfield'
% 'St Albans',       'E07000100'  D(95)  'St Albans'



