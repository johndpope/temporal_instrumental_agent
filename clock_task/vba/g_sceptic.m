function  [ gx ] = g_sceptic(x_t,phi,u,inG)
% INPUT
% - x : Q-values (2x1)
% - beta : temperature (1x1)
% - OR K: mean response tendency
% - inG : multinomial
% OUTPUT
% - gx : p(chosen|x_t) or RT


beta = exp(phi(1));


gaussmat=inG.gaussmat;
ntimesteps = inG.ntimesteps;
nbasis = inG.nbasis;


v=x_t(1:nbasis)*ones(1,ntimesteps) .* gaussmat; %use vector outer product to replicate weight vector


v_func = sum(v); %subjective value by timestep as a sum of all basis functions

p_choice = (exp((v_func-max(v_func))/beta)) / (sum(exp((v_func-max(v_func))/beta))); %Divide by temperature

rt_prev = u(1); %% retrieve previous RT

if strcmp(inG.autocorrelation,'exponential') || strcmp(inG.autocorrelation,'softmax_multitrial')
    pi =  1./(1+exp(-phi(2))); %% introduce a choice autocorrelation parameter lambda
    %     chi =  1./(1+exp(-phi(3))); %% control the extent of choice autocorrelation
    %% try a Gaussian chi to enable it to go negative (choice anticorrelation as in Lau & Glimcher 2005 at t-1)
    chi =  phi(3)./100;
end

if strcmp(inG.autocorrelation,'exponential')
    p_choice = p_choice + chi.*(pi.^(abs((1:ntimesteps) - rt_prev)));  %% incorporate an exponential choice autocorrelation function
    
    
    
    %     rt_prev = 25;
    %     lambdas = 0:.1:1;
    %     for lambda = lambdas
    %         lambda_val=lambda.^(abs((1:ntimesteps) - rt_prev));
    %         plot(lambda_val)
    %         hold on
    %     end
    
    p_choice = p_choice./(sum(p_choice));  %% re-normalize choice probability so that it adds up to 1
elseif strcmp(inG.autocorrelation,'softmax_multitrial') || strcmp(inG.autocorrelation,'softmax_multitrial_smooth')
    %% build a matrix of past rts
    if  u(3)>0
        lambda = pi; %When writing the equations we decided lambda is fine for schonberg but we should change it for AR1 so we did...to pi.
        trial = u(3);
        choice_history = inG.rts(1:trial);
        discounted_choice_history = zeros(size(1:ntimesteps));
        
        for bin = 1:ntimesteps
            if sum(choice_history(1:trial-1)==bin)>0
                when_occurred = find(choice_history(1:trial-1)==bin);
                last_occurred = when_occurred(end);
                trials_ago = trial - last_occurred;
                discounted_choice_history(bin) = lambda^trials_ago; %% it goes to 41 instead of 40  WHY?
            else
                discounted_choice_history(bin) = 0;
            end
        end
        if strcmp(inG.autocorrelation,'softmax_multitrial_smooth')
            iota =  1./(1+exp(-phi(4))); %% control the extent of choice autocorrelation
            discounted_choice_history = smooth(discounted_choice_history,(10*ntimesteps*iota))';
        end
        p_choice = (exp((v_func-max(v_func)+chi.*max(v_func).*discounted_choice_history)/beta)) / (sum(exp((v_func-max(v_func)+chi.*max(v_func).*discounted_choice_history)/beta))); %Divide by temperature
    end
    
elseif strcmp(inG.autocorrelation,'choice_tbf')
    choice = x_t(length(x_t)-nbasis+1:end)*ones(1,ntimesteps) .* gaussmat; %use vector outer product to replicate weight vector
    choice_func = sum(choice); %subjective value of choice by timestep as a sum of all basis functions
    chi =  phi(2)./100;
    p_choice = (exp((v_func-max(v_func)+chi.*max(v_func).*choice_func)/beta)) / (sum(exp((v_func-max(v_func)+chi.*max(v_func).*choice_func)/beta))); %Divide by temperature
end
% figure(777);clf;
% plot(log(x_t(1:24))); hold on;
% plot(log(x_t(25:48))); hold on;
% plot(log(x_t(49:end))); hold off;
gx = p_choice';
end



