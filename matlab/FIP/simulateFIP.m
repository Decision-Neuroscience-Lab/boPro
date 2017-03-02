function [data] = simulateFIP(model)
%% Set params
R = [0, 2.3];
D = [10];
ITI = 4;
beta = 5;% For softmax
numTrials = 100;
alpha = 1; % Scaling factor for time perception effect
effectSize = [0, 0.1];

Sm = @(v0,v1) exp(v1 ./ beta) ./ (exp(v1 ./ beta) + exp(v0 ./ beta)); % Softmax function

%% Setup trial list
r = nan(numTrials,1);
d = nan(numTrials,1);
trialLog = {};
for t = 1:numTrials
    trialLog{t,1} = [0,0];
    trialLog{t,2} = [R(randi(numel(R))),D(randi(numel(D)))];
end
%% Generate data
data = [];
window = 1;
for t = 1:numTrials
    
    if t <= window % Choose ratio as we have no history
        
        v1 = trialLog{t,1}(1) ./ trialLog{t,1}(2);
        v0 = 0;
        
    else
        sv = @(r,d,rBar) (r + sum(rBar{t-window:t-1}(1))) ./ (d + sum(rBar{t-window:t-1}(2)) + sum(rBar{t-window:t-1}(3)));
        % Calculate values using TIMERR
        v1 = sv(trialLog{t,2}(1), trialLog{t,2}(2), rBar);
        v0 = sv(trialLog{t,1}(1), trialLog{t,1}(2), rBar);
    end
    
    % Calculate probability using softmax
    prob = Sm(v0,v1);
    if v1 > v0
        choice = 2;
    else
        choice = 1;
    end
    
    rBar{t} = [trialLog{t,choice}(1), trialLog{t,choice}(2), ITI - effectSize(R == trialLog{t,choice}(1))];
    data = cat(1,data,[trialLog{t,1}(1),trialLog{t,1}(2),v1,v0,prob,choice]);
    
end

