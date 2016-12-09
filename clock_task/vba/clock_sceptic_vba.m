function [posterior,out] = clock_sceptic_vba(id,model,n_basis, multinomial,multisession,fixed_params_across_runs,fit_propspread,n_steps,u_aversion,data_str, saveresults, graphics,results_dir)

%% fits SCEPTIC model to Clock Task subject data using VBA toolbox
% example call:
% [posterior,out]=clock_sceptic_vba(10638,'modelname',nbasis,multinomial,multisession,fixed_params_across_runs,fit_propsrpead)
% id:           5-digit subject id in Michael Hallquist's BPD study
% only works with 'fixed' (fixed learning rate SCEPTIC) so far
% n_basis:      8 works well, 4 also OK
% multinomial:  if 1 fits p_chosen from the softmax; continuous RT (multinomial=0) works less well
% multisession: treats runs/conditions as separate, helps fit (do not allow X0 to vary though)
% fixed_params_across_runs -- self-explanatory
% fit_propspread -- makes temporal generalization within the eligibility trace a free parameter
% n_steps:      number of time bins
% u_aversion:   allow for uncertainty (ambiguity) aversion for UV_sum
%%
close all

%% uncertainty aversion for UV_sum
if nargin < 7, fit_propspread = 0; end
if nargin < 9, u_aversion = 0; end
if nargin < 10, data_str=0; end
if nargin < 11, saveresults = 1; end
if nargin < 12, graphics = 0; end
if nargin < 13, results_dir = pwd; end

global rew_rng_state no_gamma
rew_rng_seed = 99;

if ~graphics
    options.DisplayWin = 0;
    options.GnFigs = 0;
end
%% set up dim defaults
n_theta = 1;
n_phi = 1;

%% no choice autocorrelation by default
% options.inG.autocorrelation = 'none';
<<<<<<< Updated upstream
options.inG.autocorrelation = 'none'; %% implements AR(1) choice autocorrelation with exponential temporal generalization
options.inF.entropy = 1; %If we want to track entropy per trial
track_entropy=options.inF.entropy;
options.inF.H_threshold = 0.01;

%If we want to use the elig update variant in choice rule
options.inF.total_pe=0;

%If we want to track delta for regressors
options.inF.track_pe = 1;

% options.inG.autocorrelation = 'softmax_multitrial'; % implements choice autocorrelation as in Schoenberg et al. 2007 without temporal generalization
=======
% options.inG.autocorrelation = 'exponential'; %% implements AR(1) choice autocorrelation with exponential temporal
% generalization
options.inG.autocorrelation = 'softmax_multitrial'; % implements choice autocorrelation as in Schoenberg et al. 2007 without temporal generalization
>>>>>>> Stashed changes
% options.inG.autocorrelation = 'softmax_multitrial_smooth'; %% implements choice autocorrelation as in Schoenberg et al. 2007 with temporal generalization controlled by an additional temporal smoothing parameter iota
options.inF.autocorrelation = options.inG.autocorrelation;

%% fit as multiple runs
% multisession = 1;
% fix parameters across runs
% fixed_params_across_runs = 1;

%% u is 2 x ntrials where first row is rt and second row is reward
% If we can't find the path have the user select it.
%Have the data file be an input now since we will be working with multiple
%clock data
if data_str==0
    os = computer;
    if strcmp(os(1:end-2),'PCWIN')
        data = readtable(sprintf('c:/kod/temporal_instrumental_agent/clock_task/subjects/fMRIEmoClock_%d_tc_tcExport.csv', id),'Delimiter',',','ReadVariableNames',true);
        %vbadir = 'c:/kod/temporal_instrumental_agent/clock_task/vba';
        %results_dir = 'E:/data/sceptic/vba_out/new_lambda_results/';
    else
        [~, me] = system('whoami');
        me = strtrim(me);
        if strcmp(me,'Alex')==1
            data = readtable(sprintf('/Users/localadmin/code/clock_smoothoperator/clock_task/subjects/fMRIEmoClock_%d_tc_tcExport.csv', id),'Delimiter',',','ReadVariableNames',true);
            %vbadir = '/Users/localadmin/code/clock_smoothoperator/clock_task/vba';
            %results_dir = '/Users/localadmin/Google Drive/skinner/SCEPTIC/subject_fitting/vba_results';
            
        elseif strcmp(me(1:6),'dombax')==1
            data = readtable(sprintf('/Users/dombax/temporal_instrumental_agent/clock_task/subjects/fMRIEmoClock_%d_tc_tcExport.csv', id),'Delimiter',',','ReadVariableNames',true);
            %vbadir = '/Volumes/bek/vba_results/uv_sum';
            %results_dir = '/Volumes/bek/vba_results/';
            
        elseif strcmpi(me(1:(min(length(me), 14))),'alexdombrovski')
            data = readtable(sprintf('/Users/alexdombrovski/code/temporal_instrumental_agent/clock_task/subjects/fMRIEmoClock_%d_tc_tcExport.csv', id),'Delimiter',',','ReadVariableNames',true);
            %vbadir = '/Users/alexdombrovski/code/temporal_instrumental_agent/clock_task/vba';
            %results_dir = '/Users/alexdombrovski/Google Drive/skinner/SCEPTIC/subject_fitting/vba_results';
            
        else
            data = readtable(sprintf('subjects/fMRIEmoClock_%d_tc_tcExport.csv', id),'Delimiter',',','ReadVariableNames',true);
            %results_dir = '/Volumes/bek/vba_results/';
        end
    end
else
    data = readtable(data_str,'Delimiter',',','ReadVariableNames',true);
end
options.inF.fit_nbasis = 0;
range_RT = 400;
% n_steps = 4000;
n_t = size(data,1);
n_runs = n_t/50;
trialsToFit = 1:n_t;
% fit_propspread = 1;
options.inF.fit_propspread = fit_propspread;


%% set up models within evolution/observation Fx
%Note: we might need to add option.inF.model to make the kalman models
%easier to deal with...
options.inF.nbasis = n_basis;
options.inF.ntimesteps = n_steps;
options.inG.ntimesteps = n_steps;
options.inG.multinomial = multinomial;
options.inG.nbasis = n_basis;
options.inG.maxRT = range_RT;
%%
options.TolFun = 1e-6;
options.GnTolFun = 1e-6;
options.verbose=1;
% options.DisplayWin=1;

%% set up kalman defaults
options.inF.kalman.kalmna_processnoise = 0;
options.inF.kalman.kalman_sigmavolatility  = 0;
options.inF.kalman.kalman_softmax = 0;
options.inF.kalman.kalman_logistic = 0;
options.inF.kalman.kalman_uv_logistic = 0;
options.inF.kalman.kalman_uv_sum = 0;
options.inF.kalman.kalman_uv_sum_sig_vol = 0;
options.inF.kalman.fixed_uv = 0;
options.inF.kalman.kalman_sigmavolatility_local =0;
options.inF.kalman.kalman_sigmavolatility_precision=0;


%% set up basis
fixed_prop_spread = .0125;

[~, ~, options.inF.tvec, options.inF.sig_spread, options.inG.gaussmat, options.inF.gaussmat_trunc, options.inF.refspread] = setup_rbf(options.inF.ntimesteps, options.inF.nbasis, fixed_prop_spread);

options.inG.sig_spread = options.inF.sig_spread;

%Set up sigma noise for every point in u or hidden state?
rng(rew_rng_seed); %inside trial loop, use random number generator to draw probabilistic outcomes using RewFunction
rew_rng_state=rng;
[~,idx] = unique(data.run);
conditions=data.rewFunc(idx);
sigma_noise = [];
run_length = n_t/n_runs;
for i = 1:length(conditions)
    sigma_noise = [sigma_noise repmat(std(arrayfun(@(x) RewFunction(x*100, conditions(i), 0), options.inF.tvec))^2, 1, run_length)];
end
sigma_noise = mean(sigma_noise);
options.inF.sigma_noise = sigma_noise;
options.inF.gaussmat = options.inG.gaussmat;

%% split into conditions/runs
if multisession %improves fits moderately
    options.multisession.split = repmat(n_t/n_runs,1,n_runs); % two sessions of 120 datapoints each
    %% fix parameters
    if fixed_params_across_runs
        options.multisession.fixed.theta = 'all';
        options.multisession.fixed.phi = 'all';
        %
        % allow unique initial values for each run?x
        options.multisession.fixed.X0 = 'all';
    end
    
end



%Determine which evolution funciton to use
options.inF.kalman.(model)=1; %Declare which model to use if kalman

switch model
    %fixed learning rate (alpha) for PE+ and PE-; softmax choice rule
    case 'fixed'
        h_name = @h_sceptic_fixed;
        hidden_variables = 1; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        %         priors.SigmaX0 = 10*ones(hidden_variables*n_basis);

    case 'fixed_lambda'
        h_name = @h_sceptic_fixed;
        hidden_variables = 1; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        %n_phi = 2;  %% add an observation parameter for choice autocorrelation lambda
        
    case 'fixed_decay'
        h_name = @h_sceptic_fixed_decay;
        hidden_variables = 1; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        n_theta = 2; %learning rate and decay outside of the eligibility trace
        
    case 'fixed_decay_lambda'
        h_name = @h_sceptic_fixed_decay;
        hidden_variables = 1; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        n_theta = 2; %learning rate and decay outside of the eligibility trace
        %n_phi = 2;  %% add an observation parameter for choice autocorrelation lambda
        options.inG.lambda = 1;
        
        %kalman learning rule (no free parameter); softmax choice over value curve
    case 'kalman_softmax'
        %Prop_spread is the only variable in this model
        if fit_propspread
            n_theta = 0;
        end
        hidden_variables = 2; %tracks value and uncertainty
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1)];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman;
        
        %kalman learning rule (no free parameter); PEs enhance gain through process noise Q according to parameter omega
    case 'kalman_processnoise'
        hidden_variables = 2; %tracks value and uncertainty
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1)];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman;
        
        %old kalman with explore/exploit hardmax selection according to logistic function
    case 'kalman_logistic'
        %Prop_spread is the only variable currently in this model
        if fit_propspread
            n_theta = 0;
        end
        n_phi  = 2;  %Beta and discrim
        %Different observation function than other kalman models
        %         g_name = @g_sceptic_logistic;
        hidden_variables = 2; %tracks value and uncertainty
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1)];
        priors.SigmaX0 = zeros(hidden_variables*n_basis); %This is Discrim not Beta for this model
        h_name = @h_sceptic_kalman;
        %Define indifference point between explore and exploit (p = 0.5) as proportion reduction in variance from initial value
        tradeoff = 0.1209529; %From what was the optimized overall
        options.inG.u_threshold = (1 - tradeoff * sigma_noise);
        %Predetermined random trials
        %options.inG.choice_rand=rand(n_steps,1);
        
        %kalman learning rule (no free parameter); PEs inflate posterior variance (sigma) according to phi and gamma
    case 'kalman_sigmavolatility'
        n_theta = 2;
        hidden_variables = 3; %tracks value and uncertainty and volatility
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1); zeros(n_basis,1);];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        options.inF.no_gamma = 0; %If 1 gamma will be 1-phi
        h_name = @h_sceptic_kalman;
        
        %kalman learning rule and uncertainty update; V and U are mixed by tau; softmax choice over U+V
    case 'kalman_uv_sum'
        hidden_variables = 2; %tracks value and uncertainty
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1)];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman;
        options.inF.u_aversion = u_aversion;
        options.inG.u_aversion = u_aversion;
        
    case 'kalman_uv_sum_sig_vol'
        %n_phi  = 2;  %Beta and Tau
        n_theta = 3; %sigma gamma tau
        hidden_variables = 3; %tracks value and uncertainty and volatility
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1); zeros(n_basis,1);];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman;
        options.inF.u_aversion = u_aversion;
        options.inG.u_aversion = u_aversion;
        
    case 'fixed_uv'
        n_theta = 2; %tau alpha
        hidden_variables = 2; %tracks value and uncertainty
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1)];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman;
        options.inF.u_aversion = u_aversion;
        options.inG.u_aversion = u_aversion;
        
    case 'kalman_sigmavolatility_local'
        %n_theta = 2;
        hidden_variables = 3; %tracks value and uncertainty and volatility
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1); zeros(n_basis,1);];
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        options.inF.no_gamma = no_gamma; %If 1 gamma will be 1-phi
        if options.inF.no_gamma
            n_theta = 1;
        else
            n_theta = 2;
        end
        h_name = @h_sceptic_kalman;
        
    case 'kalman_sigmavolatility_precision'
        %n_theta = 2;
        hidden_variables = 3; %tracks value and uncertainty and volatility
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1); zeros(n_basis,1);];
        options.inF.priors = priors;
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        options.inF.no_gamma = no_gamma; %If 1 gamma will be 1-phi
        if options.inF.no_gamma
            n_theta = 1;
        else
            n_theta = 2;
        end
        h_name = @h_sceptic_kalman;
    case 'win_stay_lose_switch'
        n_phi  = 2;  %Beta and precision
        n_theta = 0;
        h_name = @h_dummy;
        hidden_variables = 0; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        options.inG.stay = 0;
    case 'stay'
        n_phi  = 2;  %Beta and precision
        n_theta = 0;
        h_name = @h_dummy;
        hidden_variables = 0; %tracks only value
        priors.muX0 = zeros(hidden_variables*n_basis,1);
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        options.inG.stay = 1;
    case 'kalman_monster'
        hidden_variables = 3; %value, uncertainty, and local volatility
        n_phi = 2; %beta and tau
        n_theta = 4; %gamma, phi, alpha, kappa
        priors.muX0 = [zeros(n_basis,1); sigma_noise*ones(n_basis,1); zeros(n_basis,1);];
        options.inF.priors = priors;
        priors.SigmaX0 = zeros(hidden_variables*n_basis);
        h_name = @h_sceptic_kalman_monster;
    otherwise
        disp('The model you have entered does not match any of the default names, check spelling!');
        return
        
end

%Adjust initial arrays is tracking pe
if options.inF.track_pe == 1
    track_pe = 1;
    hidden_variables = hidden_variables + 1;
    priors.muX0 = [priors.muX0; zeros(n_basis,1)];
    priors.SigmaX0 = zeros(hidden_variables*n_basis);
else
    track_pe = 0;
end


%Add in the lambda parameter
if strcmp(options.inG.autocorrelation,'exponential') || strcmp(options.inG.autocorrelation,'softmax_multitrial')
    n_phi = n_phi + 2;
elseif strcmp(options.inG.autocorrelation,'softmax_multitrial_smooth')
    n_phi = n_phi + 3;
elseif strcmp(options.inG.autocorrelation,'choice_tbf') %Modifiy the models if we want to add the choice basis autocorrelation
    n_phi = n_phi + 1;
    n_theta = n_theta+1; %Add choice decay parameter
    hidden_variables = hidden_variables + 1; %Add in choice basis
    priors.muX0 = [priors.muX0; zeros(n_basis,1)];
    priors.SigmaX0 = zeros(hidden_variables*n_basis);
elseif options.inF.entropy == 1
    track_entropy=2; %Add 2 hidden states to track entropy and max value pre-update
    priors.muX0 = [priors.muX0; zeros(track_entropy,1)];
    priors.SigmaX0 = zeros(hidden_variables*n_basis+track_entropy);
end

options.inF.hidden_state = hidden_variables;

%Map the necessary options from F to G
options.inG.hidden_state = options.inF.hidden_state;
options.inG.kalman = options.inF.kalman;



    


if multinomial
    rtrnd = round(data{trialsToFit,'rt'}*0.1*n_steps/range_RT)';
    rtrnd(rtrnd==0)=1;
    dim = struct('n',hidden_variables*n_basis+track_entropy,'n_theta',n_theta+fit_propspread,'n_phi',n_phi,'p',n_steps);
    options.sources(1) = struct('out',1:n_steps,'type',2);
    
    %% compute multinomial response -- renamed 'y' here instead of 'rtbin'
    y = zeros(n_steps, length(trialsToFit));
    for i = 1:length(trialsToFit)
        y(rtrnd(i), i) = 1;
    end
    priors.a_alpha = Inf;   % infinite precision prior
    priors.b_alpha = 0;
    priors.a_sigma = 1;     % Jeffrey's prior
    priors.b_sigma = 1;     % Jeffrey's prior
    options.binomial = 1;
    priors.muPhi = zeros(dim.n_phi,1); % exp tranform
    priors.SigmaPhi = 1e1*eye(dim.n_phi);
    % Inputs
    u = [(data{trialsToFit, 'rt'}*0.1*n_steps/range_RT)'; data{trialsToFit, 'score'}'; trialsToFit];
    u = [zeros(size(u,1),1) u(:,1:end-1)];
    options.inG.rts = round(data{trialsToFit, 'rt'}*0.1*n_steps/range_RT)';
    % Observation function
    switch model
        case 'kalman_logistic'
            g_name = @g_sceptic_logistic;
        case 'win_stay_lose_switch'
            g_name = @g_WSLS;
        case 'stay'
            g_name = @g_WSLS;
        case 'kalman_monster'
            g_name = @g_sceptic_monster;
        otherwise
            g_name = @g_sceptic;
    end
else
    n_phi = 2; % [autocorrelation lambda and response bias/meanRT K] instead of temperature
    dim = struct('n',hidden_variables*n_basis,'n_theta',n_theta+fit_propspread,'n_phi',n_phi, 'n_t', n_t);
    y = (data{trialsToFit,'rt'}*0.1*n_steps/range_RT)';
    priors.a_alpha = Inf;
    priors.b_alpha = 0;
    priors.a_sigma = 1;     % Jeffrey's prior
    priors.b_sigma = 1;     % Jeffrey's prior
    priors.muPhi = [0, 0];  % K, lambda
    %     priors.SigmaPhi = diag([0,1]); % get rid of the K
    priors.SigmaPhi = diag([1,1]);
    options.binomial = 0;
    options.sources(1) = struct('out',1,'type',0);
    prev_rt = [0 y(1:end-1)];
    % Inputs
    u = [(data{trialsToFit, 'rt'}*0.1*n_steps/range_RT)'; data{trialsToFit, 'score'}'; prev_rt];
    u = [zeros(size(u,1),1) u(:,1:end-1)];
    
    % Observation function
    g_name = @g_sceptic_continuous;
    
end
%
% if options.inF.fit_nbasis
%     dim = struct('n',n_basis,'n_theta',2,'n_phi',1,'p',n_steps);
% priors.muTheta = [0 8];
% priors.muPhi = zeros(dim.n_phi,1); % exp tranform
% priors.muX0 = zeros(dim.n,1);
% priors.SigmaPhi = 1e1*eye(dim.n_phi);
% priors.SigmaTheta = 1e1*eye(dim.n_theta);
% options.inF.priordist_theta2 = makedist('Normal',priors.muTheta(2), unique(max(priors.SigmaTheta)));
% options.inF.maxbasis = 24;
% options.inF.muTheta2 = priors.muTheta(2);
% options.inF.SigmaTheta2 = unique(max(priors.SigmaTheta));
% else
% priors.muTheta = zeros(dim.n_theta,1);
% priors.muPhi = zeros(dim.n_phi,1); % exp tranform
% priors.muX0 = zeros(dim.n,1);
% priors.SigmaPhi = 1e1*eye(dim.n_phi);
% priors.SigmaTheta = 1e1*eye(dim.n_theta);

% end
%% skip first trial
options.skipf = zeros(1,n_t);
options.skipf(1) = 1;

%% priors
priors.muTheta = zeros(dim.n_theta,1);
priors.SigmaTheta = 1e1*eye(dim.n_theta); % lower the learning rate variance -- it tends to be low in the posterior
options.priors = priors;
options.inG.priors = priors; %copy priors into inG for parameter transformation (e.g., Gaussian -> uniform)

onsets=NaN(1,size(y,2));
for mm=1:size(y,2)
    pos = find(y(:,mm)==1);
    if isempty(pos), pos=NaN; end
    onsets(mm) = pos;
end


[posterior,out] = VBA_NLStateSpaceModel(y,u,h_name,g_name,dim,options);

if saveresults
    %% save output figure
    % h = figure(1);
    % savefig(h,sprintf('results/%d_%s_multinomial%d_multisession%d_fixedParams%d',id,model,multinomial,multisession,fixed_params_across_runs))
    save([results_dir sprintf('/SHIFTED_U_CORRECT%d_%s_multinomial%d_multisession%d_fixedParams%d_uaversion%d_sceptic_vba_fit_fixed_prop_spread_%s_autocorreltaion_total_pe_variant', id, model, multinomial,multisession,fixed_params_across_runs, u_aversion,options.inG.autocorrelation)], 'posterior', 'out');
end
