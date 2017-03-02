function [simData, score, varargout] = checkOptimality(iti, session, model, varargin)

id = [];

if ~isempty(varargin) % If based on data
    id = varargin{1};
    oldcd = cd('/Users/Bowen/Documents/MATLAB/EDT v6/data');
    name = sprintf('%.0f_%.0f_*', id, session); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);
    stimuli = cat(2,[data.trialLog.A]', [data.trialLog.fA]', [data.trialLog.D]', [data.trialLog.fD]');
    empChoice = [data.trialLog.choice]';
else % If simulated
    %% Generate stimuli (amounts chosen using factors)
    fD = 2;
    fA = 3;
    D = [6, 8, 10];
    stimuli = []; % Create empty list in correct format
    factors = linspace(0.05,1,9)'; % Create range of modifiers to adjust amounts
    factors = repmat(factors,3,1); % Repeat to fit
    sequence = deBruijn(numel(D), 3); % Create de Bruijn Sequence
    delays = D(sequence)'; % Create delay stimuli
    delays = repmat(delays,3,1); % Repeat to fit
    for d = 1:numel(D)
        [x,~,~] = shuffleDim(factors,1); % Shuffle factors each time
        x = x.*fD;
        i = delays == D(d);
        stimuli(i,2) = x;
    end
    stimuli(:,3) = delays;
    stimuli(:,1) = fA;
    stimuli(:,4) = fD;
end

%% Run through stimuli using different models
for t = 1:size(stimuli,1)
    ssA(t,1) = stimuli(t,2);
    ssD(t,1) = stimuli(t,4);
    llA(t,1) = stimuli(t,1);
    llD(t,1) = stimuli(t,3);
    amounts = [ssA(t,1),llA(t,1), 0];
    delays = [ssD(t,1),llD(t,1), llD(t,1)];
    
    if t == 1 % If first trial, go with simple
        vSS(t,1) = ssA(t,1) / ssD(t,1); % Calculate ratios
        vLL(t,1) = llA(t,1) / llD(t,1);
        
        if vSS(t,1) > vLL(t,1) % Choose higher value
            choice(t,1) = 1;
        else
            choice(t,1) = 2;
        end
        % Update memory
        if ~isempty(varargin)
            R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
            T(t,1) = delays(empChoice(t,1)) + iti;
            simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for simRewardDensity
            simT(t,1) = delays(choice(t,1)) + iti;
        else
            R(t,1) = amounts(choice(t,1));
            T(t,1) = delays(choice(t,1)) + iti;
        end
    else % For all other trials
        switch model
            
            case 'ert' % Ecological rationality theory: maximises local reward
                % Calculate values
                vSS(t,1) = ssA(t,1) / ssD(t,1);
                vLL(t,1) = llA(t,1) / llD(t,1);
                % Choose higher value
                if vSS(t,1) > vLL(t,1)
                    choice(t,1) = 1;
                else
                    choice(t,1) = 2;
                end
                
            case 'ofs' % Optimal foraging strategy: maximises reward rate over an effective trial
                % Calculate values including iti
                vSS(t,1) = ssA(t,1) / ssD(t,1);
                vLL(t,1) = llA(t,1) / llD(t,1);
                v0 = mean(R) / (mean(T));
                % Choose higher value if larger than v0 - miss otherwise
                if vSS(t,1) >= v0 || vLL(t,1) >= v0
                    if vSS(t,1) > vLL(t,1)
                        choice(t,1) = 1;
                    else
                        choice(t,1) = 2;
                    end
                else
                    choice(t,1) = 3;
                end
                % Update memory
                if ~isempty(varargin)
                    R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                    T(t,1) = delays(empChoice(t,1)) + iti;
                    simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for score
                    simT(t,1) = delays(choice(t,1)) + iti;
                else
                    R(t,1) = amounts(choice(t,1));
                    T(t,1) = delays(choice(t,1)) + iti;
                end
                
            case 'timerr'
                timerr = @(R,T,Ri,Ti) (R+Ri)/(T+Ti); % TIMERR algorithm
                % Calculate values using TIMERR
                vSS(t,1) = timerr(sum(R),sum(T),ssA(t,1),ssD(t,1) + iti);
                vLL(t,1) = timerr(sum(R),sum(T),llA(t,1),llD(t,1) + iti);
                % Choose higher value
                if vSS(t,1) > vLL(t,1)
                    choice(t,1) = 1;
                else
                    choice(t,1) = 2;
                end
                % Update memory
                if ~isempty(varargin)
                    R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                    T(t,1) = delays(empChoice(t,1)) + iti;
                    simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for score
                    simT(t,1) = delays(choice(t,1)) + iti;
                else
                    R(t,1) = amounts(choice(t,1));
                    T(t,1) = delays(choice(t,1)) + iti;
                end
                
            case 'opportunityCost'
                rBar(t,1) = mean(R) / mean(T); % Average reward rate up to current trial
                % Calculate values minus opportunity cost
                vSS(t,1) = (ssA(t,1) / (ssD(t,1) + iti)) - (ssD(t,1) * rBar(t,1));
                vLL(t,1) = (llA(t,1) / (llD(t,1) + iti)) - (llD(t,1) * rBar(t,1));
                % Choose highest value
                if vSS(t,1) > vLL(t,1)
                    choice(t,1) = 1;
                else
                    choice(t,1) = 2;
                end
                % Update memory
                if ~isempty(varargin)
                    R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                    T(t,1) = delays(empChoice(t,1)) + iti;
                    simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for score
                    simT(t,1) = delays(choice(t,1)) + iti;
                else
                    R(t,1) = amounts(choice(t,1));
                    T(t,1) = delays(choice(t,1)) + iti;
                end
                
            case 'opportunityBonus'
                rBar(t,1) = mean(R) / mean(T); % Average reward rate up to current trial
                % Calculate values (SS + opportunity bonus)
                vSS(t,1) = ((ssA(t,1) / (ssD(t,1)) + iti)) + ((llD(t,1) - ssD(t,1)) * rBar(t,1));
                vLL(t,1) = (llA(t,1) / (llD(t,1) + iti));
                % Choose highest value
                if vSS(t,1) > vLL(t,1)
                    choice(t,1) = 1;
                else
                    choice(t,1) = 2;
                end
                % Update memory
                if ~isempty(varargin)
                    R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                    T(t,1) = delays(empChoice(t,1)) + iti;
                    simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for score
                    simT(t,1) = delays(choice(t,1)) + iti;
                else
                    R(t,1) = amounts(choice(t,1));
                    T(t,1) = delays(choice(t,1)) + iti;
                end
                
            case 'takeLargest'
                
                rBar(t,1) = (ssA(t,1) + llA(t,1)) / 2; % Calculate local mean reward
                vLL(t,1) = llA(t,1) - rBar(t,1);
                vSS(t,1) = ssA(t,1) - rBar(t,1);
                
                % Choose highest value
                if vSS(t,1) > vLL(t,1)
                    choice(t,1) = 1;
                else
                    choice(t,1) = 2;
                end
                % Update memory
                if ~isempty(varargin)
                    R(t,1) = amounts(empChoice(t,1)); % Use real choices for memory
                    T(t,1) = delays(empChoice(t,1)) + iti;
                    simR(t,1) = amounts(choice(t,1)); % Use algorithm choices for score
                    simT(t,1) = delays(choice(t,1)) + iti;
                else
                    R(t,1) = amounts(choice(t,1));
                    T(t,1) = delays(choice(t,1)) + iti;
                end
        end
    end
end

simData = [ssA,ssD,llA,llD,vSS,vLL,choice];

%%
if ~isempty(varargin) % If based on real data, add empirical choice and evaluate model
    simData = cat(2,simData,[data.trialLog.choice]');
    score = sum(R) / sum(T);
    varargout{1} = mean(simData(:,7) == [data.trialLog.choice]');
    varargout{2} = sum(simR) / sum(simT);
else
    score = [];
    varargout{1} = [];
    varargout{2} = sum(R) / sum(T);
end

return
