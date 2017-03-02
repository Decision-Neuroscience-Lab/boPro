function [gT] = valuePolicy(params,t,rStar,T,distribution)
% Generates an action based on expected reward and delay: either abort or wait

%% Estimate subjective value
pt = probReward(params,t,distribution);
pT = probReward(params,T,distribution);
p = (pT - pt) ./ (1 - pt);
aT = params.largeReward * p;
    
    probSamples = pt + (pT-pt).*rand(1,params.numTauEstimations); % Sample from the cumulative probability function between t and T
            if strcmp(distribution,'uniform');
                    expectedTime = mean(gpinv(probSamples,params.k,params.sigma,params.theta)); % Pass through inverse cumulative function and take average
         elseif strcmp(distribution,'pareto');
                 expectedTime = mean(gpinv(probSamples,params.k,params.sigma,params.theta)); % Pass through inverse cumulative function and take average
            end

bT = p*(expectedTime - t) + (1 - p)*(T - t);
gT = aT - (rStar * bT);



%% Temporal uncertainty
% CV = 0.16;
% random('Normal','mu',t,'sigma',t*CV);

%% Choose action stochastically
% sMax = @(v0,v1) exp(v1 .* params.beta) ./ (exp(v1 .* params.beta) + exp(v0 .* params.beta)); % Softmax function (inverse temperature)
% prob = sMax(0.1,Gt);
% 
% if rand < prob
%     action = 0;
% else
%     action = 1;
% end

%% Cumulative probability function
    function p = probReward(params,t,distribution)
        if strcmp(distribution,'uniform');
            % Check cumulative probability of reward at time t
            if t <= params.a
                p = 0;
            elseif params.a < t && t < params.b
                p = (t-params.a)/(params.b - params.a);
            elseif t >= params.b
                p = 1;
            end
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