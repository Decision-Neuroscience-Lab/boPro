function [minPar, fval, exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, model)
% Fits temporal discounting models (hyperbolic or exponential) to the data.
% Returns minPar(1), which is the temperature parameter of the softmax
% function, and minPar(2), which is the discount rate (k). For the quasi-hyperbolic model, will return
% minPar(2), which is beta coefficient, and minPar(3), which is the delta coefficient.

minFun = @(par) likelihood(par, ssA, ssD, llA, llD, empChoice, model);
if strcmp(model,'qh')
    initial_values = rand(1,3);
else
    initial_values = rand(1,2);
end
lowerBounds = [0 0];
upperBounds = [Inf 1];
options = optimset('display','off','algorithm','interior-point');
[minPar, fval, exitflag, ~] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[],options);

    function [logLikelihood] = likelihood(par, ssA, ssD, llA, llD, empChoice, model)
        
        switch model % Choose model
            case 'hyperbolic'
                sv = @(A,D,par) A .* 1 ./ ( 1 + par(2) .* D );
            case 'exponential'
                sv = @(A,D,par) A .* exp( - par(2) .* D );
            case 'qh'
                sv = @(A,D,par) A .* par(2) .* par(3) .^ D;
            case 'random'
                sv = @(A,D,par) rand(1,1);
        end
        
        likelihood = zeros(size(empChoice,1),1);
        
        for t = 1:size(empChoice,1)
            
            vSS(t,1) = sv(ssA(t,1),ssD(t,1),par);
            vLL(t,1) = sv(llA(t,1),llD(t,1),par);
            
            % Calculate probability using softmax
            probLL(t,1) = exp(vLL(t,1) / par(1)) ./ (exp( vLL(t,1) / par(1) ) + exp(vSS(t,1) / par(1)));
            
            switch empChoice(t,1)
                case 1
                    likelihood(t,1) = 1 - probLL(t,1);
                case 2
                    likelihood(t,1) = probLL(t,1);
                case 3
                    likelihood(t,1) = 0.5;
            end
            
        end
        
        logLikelihood = -sum(log(likelihood));
        
    end
end
