function [minPar, fval, exitflag] = fitRR(delay, reward, rt)

minFun = @(par) likelihood(par, delay, reward, rt);
initial_values = [1 1]; % Temperature for softmax and omega from value function
lowerBounds = [0 0];
upperBounds = [Inf Inf];
options = optimset('display','iter','algorithm','interior-point');
[minPar, fval, exitflag, ~] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[],options);

    function [logLikelihood] = likelihood(par, delay, reward, rt)
        %% Possible choice algorithms
        % Alternate between wait and quit, quitting at previous wait, or a mean over last n trials
        % Quit based on threshold calculated from reward rate over last n trials
        % Fit reward rate decay parameter (n trials or t time window)
        % Information bonus for waiting (initial exploratory phase)?
        
        sd = @(RR) 1./RR; % Wait tolerance function
        
        likelihood = zeros(size(rt,1),1);
        
        for t = 1:size(rt,1)
            
            % Calculate values
            pW = sd(ssA(t,1),ssD(t,1),par);
            pQ = sd(llA(t,1),llD(t,1),par);
            
            % Calculate probability using softmax
            prob = exp(pQ ./ par(1)) ./ (exp(pQ ./ par(1)) + exp(pW ./ par(1)));
            
            % Calculate likelihood
            switch empChoice(t,1)
                case 1
                    likelihood(t,1) = 1 - prob;
                case 2
                    likelihood(t,1) = prob;
                case 3
                    likelihood(t,1) = 0.5;
            end
            
            logLikelihood = -sum(log(likelihood));
            
        end
    end
end
