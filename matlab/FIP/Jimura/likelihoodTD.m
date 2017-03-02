function [logLikelihood] = likelihoodTD(par, ssA, ssD, llA, llD, empChoice, model)

switch model
    case 'hyperbolic'
        sv = @(A,D,par) A / (1 + (par(2)*D)); % Value function (including generative k)
    case 'exponential'
        sv = @(A,D,par) A * exp((-par(2)*D)); % Value function (including generative k)
end

likelihood = zeros(size(empChoice,1),1);

for t = 1:size(empChoice,1)
    
    % Calculate values
    vSS = sv(ssA(t,1),ssD(t,1),par);
    vLL = sv(llA(t,1),llD(t,1),par);
    
    % Calculate probability using softmax
    probLL = exp(vLL ./ par(1)) ./ (exp(vLL ./ par(1)) + exp(vSS ./ par(1)));
    
    % Calculate likelihood
    switch empChoice(t,1)
        case 1
            likelihood(t,1) = 1 - probLL;
        case 2
            likelihood(t,1) = probLL;
        case 3
            likelihood(t,1) = 0.5;
    end
    
    logLikelihood = -sum(log(likelihood));
    
end
end