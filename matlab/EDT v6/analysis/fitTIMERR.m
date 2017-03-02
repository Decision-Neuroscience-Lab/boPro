function [minPar, fval, exitflag] = fitTIMERR(ssA, ssD, llA, llD, empChoice, iti, model)

minFun = @(par) findTIME(par, ssA, ssD, llA, llD, empChoice, iti, model);
initial_values = [10,1];
lowerBounds = [1, 0];
upperBounds = [Inf, Inf];
options = optimset('display','iter','algorithm','interior-point');
[minPar, fval, exitflag, ~] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[],options);

    function [logLikelihood] = findTIME(par, ssA, ssD, llA, llD, empChoice, iti, model)  
        
        R = []; % Initialise reward timeseries
        likelihood = zeros(size(stimuli,1),1);
        
        for t = 1:size(stimuli,1)
            
            % Get stimuli for each trial
            amounts = [ssA(t,1),llA(t,1), 0];
            delays = [ssD(t,1),llD(t,1), llD(t,1)];
            
            if t == 1
                vSS(t,1) = ssA(t,1) / ssD(t,1); % Calculate simple ratios as we don't have history yet
                vLL(t,1) = llA(t,1) / llD(t,1);
                
                % Calculate probability using softmax
                probLL(t,1) = exp(vLL(t,1) / par(2)) ./ (exp( vLL(t,1) / par(2) ) + exp(vSS(t,1) / par(2)));
                
                switch empChoice(t,1)
                    case 1
                        likelihood(t,1) = 1 - probLL(t,1);
                    case 2
                        likelihood(t,1) = probLL(t,1);
                    case 3
                        likelihood(t,1) = 0.5;
                end
                
                % Append rewards into time series (unit of 1 second)
                R = cat(1, R, zeros(choiceTime+delays(empChoice(t,1)),1));
                % R = cat(1, R, repmat(amounts(empChoice(t,1)) / drinkTime, drinkTime, 1));
                R = cat(1, R, amounts(empChoice(t,1))); % Reward delivered in single time point
                
                % Update memory
                A(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                T(t,1) = delays(empChoice(t,1)) + iti;
                
            else
                
                TIME = round(par(1));
                if size(R,1) > TIME % If reward history isn't smaller than TIME
                    aEst = sum(R(end-TIME:end)) / size(R(end-TIME:end),1);
                else % If reward history is smaller than TIME, just go to start
                    aEst = sum(R(1:end)) / size(R(1:end),1);
                end
                
                switch model
                    case 'simple'
                        vSS(t,1) = (ssA(t,1) + sum(A)) / (ssD(t,1) + sum(T));
                        vLL(t,1) = (llA(t,1) + sum(A)) / (llD(t,1) + sum(T));
                    case 'timerr'
                        sv = @(r,t,TIME,aEst) (r - (aEst * t)) / 1 + (t/TIME); % Subjective value function
                        % Calculate values using TIMERR
                        vSS(t,1) = sv(ssA(t,1), ssD(t,1), TIME, aEst);
                        vLL(t,1) = sv(llA(t,1), llD(t,1), TIME, aEst);
                    case 'ert'
                        vSS(t,1) = ssA(t,1) / ssD(t,1);
                        vLL(t,1) = llA(t,1) / llD(t,1);
                    case 'ofs'
                        v0 = mean(A) / mean(T);
                        vSS(t,1) = (ssA(t,1) / (ssD(t,1) + drinkTime + choiceTime)) - (v0*ssD(t,1));
                        vLL(t,1) = (llA(t,1) / (llD(t,1) + drinkTime + choiceTime)) - (v0*llD(t,1));
                end
                
                % Calculate probability using softmax
                probLL(t,1) = exp(vLL(t,1) / par(2)) ./ (exp( vLL(t,1) / par(2) ) + exp(vSS(t,1) / par(2)));
                
                switch empChoice(t,1)
                    case 1
                        likelihood(t,1) = 1 - probLL(t,1);
                    case 2
                        likelihood(t,1) = probLL(t,1);
                    case 3
                        likelihood(t,1) = 0.5;
                end
                
                % Append rewards into time series (unit of 1 second)
                R = cat(1, R, zeros(choiceTime+delays(empChoice(t,1)),1));
                % R = cat(1, R, repmat(amounts(empChoice(t,1)) / drinkTime, drinkTime, 1));
                R = cat(1, R, amounts(empChoice(t,1))); % Reward delivered in single time point
                
                    % Update memory
                A(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                T(t,1) = delays(empChoice(t,1)) + iti;
            end
            
        end
        
        logLikelihood = -sum(log(likelihood));
        [ssA ssD llA llD vSS vLL probLL empChoice likelihood]
    end
end
