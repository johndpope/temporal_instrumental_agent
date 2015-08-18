%script to load in subjects' data and fit using the logistic operator
%behavfiles = dir( fullfile('/Users/michael/Data_Analysis/clock_analysis/fmri/behavior_files', '*.csv'));
%curpath = fileparts(mfilename('fullpath'));

%behavfiles = glob('/Users/michael/Data_Analysis/clock_analysis/fmri/behavior_files/*.csv');
%%
[~, me] = system('whoami');
me = strtrim(me);
if strcmp(me,'Alex')==1
  behavfiles = glob('/Users/localadmin/clock_smoothoperator/clock_task/subjects/*.csv');
else    
  behavfiles = glob('/Users/michael/Data_Analysis/clock_analysis/fmri/behavior_files/*.csv');
end
%%
%read header
% fid = fopen(behavfiles(1).name, 'r');
% head = textscan(fid, '%s', 1);
% fclose(fid);
% m = csvread(behavfiles(1).name, 1, 0);

%wow, matlab has a useful function for mixed data types!!
%% write struct array of behavioral data with ids
for sub = 1:length(behavfiles)
    % write data
behav{sub}.data = readtable(behavfiles{sub},'Delimiter',',','ReadVariableNames',true);
    % write id
fname = behavfiles{sub};
idchars = regexp(fname,'\d');
behav{sub}.id = fname(idchars);
end


%just example first run, single subject
sub = 7;
rts_obs = behav{sub}.data.rt(1:50);
rew_obs = behav{sub}.data.score(1:50);
cond = behav{sub}.data.rewFunc(sub);


%%
params = [5 .05 1 .2]; %epsilon, prop_spread
%clock_logistic_fitsubject(params, rts_obs', rew_obs');
[cost, ret, mov] = skeptic_fitsubject(params, rts_obs', rew_obs', [10 9 15 50], 24, 400, 1, cond, 25);

%%
%function [cost,mov,ret] = skeptic_fitsubject(params, rt_obs, rew_obs, rngseeds, nbasis, ntimesteps, trial_plots, cond, minrt)

fmincon_options = optimoptions(@fmincon, 'UseParallel',false, 'Algorithm', 'active-set');%, 'DiffMinChange', 0.001);

init_params_1 = [.02 .9877 -.06];
lower_bounds = [0.001 0.9 -1];
upper_bounds = [0.2 .999 0];

[fittedparameters_fmincon, cost_fmincon, exitflag_fmincon] = fmincon(@(params) clock_logistic_fitsubject(params, rts_obs', rew_obs'), init_params_1, [], [], [], [], lower_bounds, upper_bounds, [], fmincon_options);

[~, fitted_object] = clock_logistic_fitsubject(-.09, rts_obs', rew_obs');
fitted_object.cost_total
[~, fitted_object] = clock_logistic_fitsubject(-.06, rts_obs', rew_obs');
fitted_object.cost_total

plot(1:50, fitted_object.rts_obs)
hold on;
plot(1:50, fitted_object.rts_pred, 'b')