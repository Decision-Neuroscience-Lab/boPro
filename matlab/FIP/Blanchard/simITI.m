function [data] = simITI(par,amounts,delays,numTrials)
% Generate binary choices from task parameters and Blanchard's choice model
beta = par(1);
omega = par(2);

sMax = @(v0,v1) exp(v1 ./ beta) ./ (exp(v1 ./ beta) + exp(v0 ./ beta)); % Softmax function
sv = @(A,D) A / (D + omega); % Value function (including generative omega)

choice = nan(numTrials,1);
data = nan(numTrials,1);

% Generate data
for t = 1:numTrials
    % Calculate values
    vSS = sv(amounts(t,1),delays(t,1));
    vLL = sv(amounts(t,2),delays(t,2));
    
    prob = sMax(vSS,vLL);
    
    % Choose
    if rand < prob
        choice(t) = 2;
    else
        choice(t) = 1;
    end
    
    data(t,1:5) = [amounts(t,1),delays(t,1),amounts(t,2),delays(t,2),choice(t)];
end
end