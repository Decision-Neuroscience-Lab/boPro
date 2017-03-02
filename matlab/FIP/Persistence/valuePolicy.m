function [action, gT] = valuePolicy(params,t,rStar,T,distribution,beta)
% Generates an action based on expected reward and delay: either abort or wait

%% Estimate subjective value
pt = probReward(params,t,distribution);
pT = probReward(params,T,distribution);
p = (pT - pt) ./ (1 - pt);
aT = params.largeReward * p;

probSamples = pt + ((pT-pt).*rand(1,params.numTauEstimations)); % Sample from the cumulative probability function between t and T
expectedTime = mean(icdf(distribution,probSamples)); % Pass through inverse cumulative function and take average


bT = p*(expectedTime - t) + (1 - p)*(T - t);
gT = aT - (rStar * bT);

%% Temporal uncertainty
% CV = 0.16;
% random('Normal','mu',t,'sigma',t*CV);

%% Choose action stochastically
    sMax = @(v0,v1) exp(v1 ./ beta) ./ (exp(v1 ./ beta) + exp(v0 ./ beta)); % Softmax function (normal temperature)
    prob = sMax(0,gT*5); % NEED TO MAKE NOT STOPPING DEFAULT - REASONABLE SBJ VALUE RESULTS IN
% CHANCE (multiply by 5?)
    
    if rand < prob
        action = 0;
    else
        action = 1;
    end

%% Cumulative probability function
    function p = probReward(params,t,distribution)
        % Check cumulative probability of reward at time t
        if t <= params.upperlimit
            p = cdf(distribution,t) ./ cdf(distribution,params.upperlimit);
        elseif t > params.upperlimit
            p = 1;
        end   
    end
end