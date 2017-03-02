function [expectedReturn, expectedCost, rT] = waitPolicy(params,t,distribution)
% Finds expected return, cost and reward rate for waitPolicy(t)

%% Estimate mean reward delivery time

% Estimate mean reward delivery time by taking random samples from the pdf between [0 t]
pd = truncate(distribution,0,t);
%estTau = random(pd,[1,params.numTauEstimations]); 
%tau = mean(estTau);
tau = mean(pd); % Why take samples when there's a function?

%% Calculate expected return, cost and reward rate
p = cdf(distribution,t);
expectedReturn = (params.largeReward*p) + (params.smallReward*(1 - p));
expectedCost = (tau*p + t*(1-p) + params.iti);
rT = expectedReturn ./ expectedCost;
end