function [minPar, fval, exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, model)
% Fits simple foraging models to the data. Returns minPar(1), which is the
% temperature of the softmax function.

minFun = @(par) likelihood(par, ssA, ssD, llA, llD, empChoice, iti, model);
initial_values = rand(1);
lowerBounds = [1]; % Fix temperature to 1 for simple choice probability normalisation
upperBounds = [1];
options = optimset('display','iter','algorithm','interior-point');
[minPar, fval, exitflag, ~] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[],options);

    function [logLikelihood] = likelihood(par, ssA, ssD, llA, llD, empChoice, iti, model)
        
        switch model % Choose model
            case 'ert'
                sv = @(A,D,R,T) A / D;
            case 'opportunityCost'
                sv = @(A,D,R,T) (A / D) - ((mean(R) / mean(T))*D);
            case 'simpleTimerr'
                sv = @(A,D,R,T) (A + sum(R)) / (D + sum(T));
            case 'random'
                sv = @(A,D,R,T) rand(1,1);
        end
        
        likelihood = zeros(size(empChoice,1),1);
        
        for t = 1:size(empChoice,1)
            
            amounts = [ssA(t,1),llA(t,1), 0];
            delays = [ssD(t,1),llD(t,1), llD(t,1)];
            
            if t == 1
                
                vSS(t,1) = ssA(t,1) / ssD(t,1); % Calculate simple ratios as we don't have history yet
                vLL(t,1) = llA(t,1) / llD(t,1);
                
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
                
                % Update memory
                R(t,1) = amounts(empChoice(t,1));
                T(t,1) = delays(empChoice(t,1)) + iti;
                
            else
                
                vSS(t,1) = sv(ssA(t,1),ssD(t,1),R,T);
                vLL(t,1) = sv(llA(t,1),llD(t,1),R,T);
                
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
                
                % Update memory
                R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                T(t,1) = delays(empChoice(t,1)) + iti;
                
            end
            
            logLikelihood = -sum(log(likelihood));
            
        end
    end
end
