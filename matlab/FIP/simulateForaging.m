function [data] = simulateForaging(ITI,amounts,delays,effectSize)
% Build in softmax, re-represent ITI in choice


%amounts = [0,4];
%delays = [0,4];
%ITI = 4;
beta = 5;% For softmax
numTrials = 500;
%effectSize = [0, 0.1];
%effectSize = [0,0,0,0];
alpha = 0.8; % Discount rate of weighted average of RR (similar to tIME)

Sm = @(v0,v1) exp(v1 .* beta) ./ (exp(v1 .* beta) + exp(v0 .* beta)); % Softmax function

% Build stimuli
data = nan(numTrials,10);
for t = 1:numTrials
    % Get stimuli for each trial
    ssA(t) = amounts(1);
    ssD(t) = delays(1);
    pair = randi([2,numel(amounts)]);
    llA(t) = amounts(pair);
    llD(t) = delays(pair);
end

%% Generate data
for t = 1:numTrials
    if t == 1
        
        % Choice rule
        vLL = llA(t);
        opCost = 0;
        
        prob = 0.5;
        
        % Choose
        if vLL > opCost
            choice = 2;
            omega(t) = ITI - effectSize(llA(t)==amounts);
        else
            choice = 1;
            omega(t) = ITI - effectSize(ssA(t)==amounts);
        end
        
        % Update memory
        R(t) = amounts(choice);
        D(t) = delays(choice);
        % Reward rate
        RR(t) = R(t) ./ (D(t) + omega(t));
        wRR(t) = RR(t);
        
    else % Include ITI estimate
        
        % Degrade reward rate memory
        wRR(t) = (alpha * RR(t-1)) + (1-alpha) * wRR(t-1);
        
        % Choice rule
        vLL = llA(t);
        %opCost = (RR(t-1)*(llD+ITI));
        opCost = wRR(t) * (llD(t) + ITI); % omega instead of ITI?
        
        prob = Sm(opCost,vLL);
        
        % Choose
        if rand < prob
            choice = 2;
            omega(t) = ITI - effectSize(llA(t)==amounts);
        else
            choice = 1;
            omega(t) = ITI - effectSize(ssA(t)==amounts);
            
        end
        
        % Update memory
        R(t) = amounts(choice);
        D(t) = delays(choice);
        RR(t) = R(t) ./ (D(t) + omega(t));
        
    end
    data(t,:) = [t, llA(t), llD(t), wRR(t), opCost, vLL, prob, choice, omega(t), RR(t)];
end
end