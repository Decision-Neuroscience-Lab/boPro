function [simData, IP] = simulateTD(model)

% Choose ITI
iti = 0;

%% Generate stimuli
% Set fixed delay (SS) and fixed amount (LL)
D = [6 8 10];
fD = 2;
fA = 3;
stimuli = []; % Create empty list in correct format

sequence = deBruijn(numel(D), 3); % Create de Bruijn Sequence
delays = D(sequence)'; % Create delay stimuli
delays = repmat(delays,3,1); % Repeat to fit

stimuli(:,3) = delays;
stimuli(:,1) = fA;
stimuli(:,4) = fD;
stimuli(:,2) = 0.3; % Set at min for practice

%% Setup Psi
stimRange = [0.1:0.1:5];

% Create structure for each delay in both QUEST and Psi
for d = 1:length(D)
    PM(d) = PAL_AMPM_setupPM('stimRange', stimRange);
end

% Setup memory
R = [];
T = [];

%% Run through stimuli using different models
for t = 1:size(stimuli,1)
    ssA(t,1) = stimuli(t,2);
    ssD(t,1) = stimuli(t,4);
    llA(t,1) = stimuli(t,1);
    llD(t,1) = stimuli(t,3);
    amounts = [ssA(t,1),llA(t,1), 0];
    delays = [ssD(t,1),llD(t,1), llD(t,1)];
    
    % Get reccomendation and modify
    for d = 1:length(D)
        if llD(t,1) == D(d)
            ssA(t,1) = PM(d).xCurrent;
            amounts = [ssA(t,1), llA(t,1), 0];
        end
    end
    
    % Use choice algorithm to set value
    switch model
        case 'takeLargest'
            
            rBar(t,1) = (ssA(t,1) + llA(t,1)) / 2; % Calculate local mean reward
            vLL(t,1) = llA(t,1) - rBar(t,1);
            vSS(t,1) = ssA(t,1) - rBar(t,1);
            
        case 'timerr'
            
            timerr = @(R,T,Ri,Ti) (R+Ri)/(T+Ti); % TIMERR algorithm
            
            vSS(t,1) = timerr(sum(R),sum(T),ssA(t,1),ssD(t,1));
            vLL(t,1) = timerr(sum(R),sum(T),llA(t,1),llD(t,1));
            
        case 'ert'
            
            vSS(t,1) = ssA(t,1) / ssD(t,1);
            vLL(t,1) = llA(t,1) / llD(t,1);
            
        case 'ofs'
            
            v0(t,1) = mean(R) / mean(T);
            vSS(t,1) = (ssA(t,1) / ssD(t,1)) - v0(t,1);
            vLL(t,1) = (llA(t,1) / llD(t,1)) - v0(t,1);
            
    end
    
    % Choice
    if vSS(t,1) > vLL(t,1) % Choose higher value
        choice(t,1) = 1;
    else
        choice(t,1) = 2;
    end
    
    % Update memory and Psi
    R(t,1) = amounts(choice(t,1));
    T(t,1) = delays(choice(t,1)) + iti;
    
    if choice(t,1) == 1 % Change choice to 'correct'
        correct = 1;
    else
        correct = 0;
    end
    for d = 1:length(D)
        if llD(t,1) == D(d)
            PM(d) = PAL_AMPM_updatePM(PM(d), correct); % Update Psi
        end
    end
    
end

simData = [ssA,ssD,llA,llD,vSS,vLL,choice];
for d = 1:numel(D)
    IP(d) = PM(d).threshold(end);
end


return
