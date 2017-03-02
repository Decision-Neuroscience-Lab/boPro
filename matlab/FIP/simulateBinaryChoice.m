function [data] = simulateBinaryChoice
%% Set params
amounts = [2.9,4];
delays = [2,4];
ITI = 4;
beta = 5;% For softmax
numTrials = 100;
effectSize = [0, 0.8];

Sm = @(v0,v1) exp(v1 .* beta) ./ (exp(v1 .* beta) + exp(v0 .* beta)); % Softmax function

%% Generate data
data = nan(numTrials,10);
     R = nan(numTrials,1); % Initialise reward memory
     D = nan(numTrials,1); % Initialise delay memory
        
        for t = 1:numTrials
            
            % Get stimuli for each trial
           ssA = amounts(1);
           ssD = delays(1);
           llA = amounts(2);
           llD = delays(2);
            
            if t == 1
                
                % Choice rule
                vSS = ssA / ssD; % Calculate simple ratios as we don't have history yet
                vLL = llA / llD;
                
                % Calculate probability using softmax
                probLL = Sm(vSS,vLL);
 
                % Choose
                if probLL > 0.5
                    choice = 2;
                else
                    choice = 1;
                end
 
                % Update memory
                R(t) = amounts(choice);
                D(t) = delays(choice);
                omega(t) = ITI - effectSize(R(t)==amounts);
                
            else % Include ITI estimate
                
                % Choice rule
                vSS = ssA / (ssD + omega(t-1));
                vLL = llA / (llD + omega(t-1));
                
                % Calculate probability using softmax
                probLL = Sm(vSS,vLL);
 
                % Choose
                if probLL > 0.5
                    choice = 2;
                else
                    choice = 1;
                end
 
                % Update memory
                R(t) = amounts(choice);
                D(t) = delays(choice);
                omega(t) = ITI - effectSize(R(t)==amounts);
                
            end
            data(t,:) = [t, ssA, ssD, llA, llD, omega(t), vSS, vLL, probLL, choice];
        end
end