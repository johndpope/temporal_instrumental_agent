function [aic_stat, aic_stat_trialwise]=compute_aic(model, condition, all, rev)
%This script is to calculate the iac statistic for the clock models (kalman, TD, frank)
%model is a string ex: 'kalmanUV'
%n is the number of trials
%k is the number of params

load('s.mat');
load('perfect_cost.mat');
n=200; %number of trials
runs = 100;
aic_stat_trialwise = zeros(1,runs);

if (all) val = 'mean_costEV'; else val = 'mean_cost'; end


switch condition
    case 'IEV'
        idx = 1;
    case 'DEV'
        idx = 2;
    otherwise
        idx = 3;
end

trial_idx = idx;



if rev==1
    val = 'mean_costIevtoDev_EV';
    idx = 1;
    trial_idx = 4;
elseif rev==2
    val = 'mean_costDevtoIev_EV';
    idx = 1;
    trial_idx = 5;
end
    





if strfind(model, 'kalman') %will have to update once Frank is introduced
    k=2;
else
    k=4;
end


model_cost = s.(model).(val)(idx);

 
%The equation
aic_stat = log(((perfect_cost.(condition) - model_cost).^2)/n)+2*k;

for i = 1:runs %num of runs
    model_cost_trialwise = s.(model).eV(trial_idx,i).ev_i;
    diff = model_cost_trialwise-perfect_cost.([condition '_pertrial']);
    aic_stat_trialwise(1,i) = log(sum((diff.^2))/n) + 2*k;
end

aic_stat_trialwise = mean(aic_stat_trialwise);