function [expectedReturn, expectedCost, rT] = waitPolicy(params,t,distribution)
% Finds expected return, cost and reward rate for waitPolicy(t)

%% Estimate mean reward delivery time
if strcmp(distribution,'uniform');
    % Estimate mean reward delivery time
    tau = t./2; % For uniform distribution of delays, this is t/2.
elseif strcmp(distribution,'pareto');
    % Estimate mean reward delivery time by taking random samples from the pdf between [0 t]
    pd = makedist('Generalized Pareto','k',params.k,'sigma',params.sigma,'theta',params.theta);
    pd = truncate(pd,0,t);
    estTau = random(pd,[1,params.numTauEstimations]);
    tau = mean(estTau);
end

%% Calculate expected return, cost and reward rate
p = probReward(params,t,distribution);
expectedReturn = (params.largeReward*p) + (params.smallReward*(1 - p));
expectedCost = tau*p + t*(1-p) + params.ITI;
rT = expectedReturn ./ expectedCost;

%% Cumulative probability function
    function p = probReward(params,t,distribution)
        if strcmp(distribution,'uniform');
            % Check cumulative probability of reward at time t
            p = unifcdf(t,params.a,params.b);
        elseif strcmp(distribution,'pareto');
            % Check cumulative probability of reward at time t
            if t <= params.upperlimit
                p = gpcdf(t,params.k,params.sigma,params.theta) ./...
                    gpcdf(params.upperlimit,params.k,params.sigma,params.theta);
            elseif t > params.upperlimit
                p = 1;
            end           
        end
    end
end