function [minPar, fval, exitflag] = fitITI(ssA, ssD, llA, llD, empChoice)

minFun = @(par) likelihood(par, ssA, ssD, llA, llD, empChoice);
initial_values = [1 1]; % Temperature for softmax and omega from value function
lowerBounds = [0 0];
upperBounds = [Inf Inf];
options = optimset('display','iter','algorithm','interior-point');
[minPar, fval, exitflag, ~] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[],options);

    function [logLikelihood] = likelihood(par, ssA, ssD, llA, llD, empChoice)
        
        sv = @(A,D,par) A / (D + par(2)); % Value function
        
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
end
