function [params] = generateStimuli(params, id)
% Generates stimuli for all components of the EDT. For calibration it
% generates a MOCS type scheme. For bisection, it generates a repeated,
% randomised list of delays. For the final task, it generates choice
% options from the calibrated indifferences points, in such a way that
% there are the values for each LL option are stable, by changing the value
% of the SS amount for each opttion.

switch params.session
    case 1
        %% Generate stimuli via deBruijn sequence (for delay) - CURRENTLY SET FOR ADAPTIVE STAIRCASE ONLY
        % Set fixed delay (SS) and fixed amount (LL)
        fD = 2;
        fA = 3;
        stimuli = []; % Create empty list in correct format
        
%         factors = linspace(1/5,3/2,9)'; % Create range of modifiers to adjust amounts
%         factors = repmat(factors,3,1); % Repeat to fit
        
        sequence = deBruijn(numel(params.D), 3); % Create de Bruijn Sequence
        delays = params.D(sequence)'; % Create delay stimuli
        delays = repmat(delays,3,1); % Repeat to fit
%         
%         for d = 1:numel(params.D)
%             [x,~,~] = shuffleDim(factors,1); % Shuffle factors each time
%             x = x.*(fA/params.D(d))*fA;
%             i = delays == params.D(d);
%             stimuli(i,2) = x;
%         end
        stimuli(:,3) = delays;
        stimuli(:,1) = fA;
        stimuli(:,4) = fD;
        stimuli(:,2) = 0.3; % Set at min for practice

        % Generate practice stimuli (to familiarise to amounts)
        params.practice = shuffleDim(linspace(min(stimuli(:,2)),max(stimuli(:,1)),5));
        
    case 2
        %% Generate stimuli for bisection
        sequence = deBruijn(numel(params.D),3); % Create deBruijn counterbalance sequence
        stimuli = params.D(sequence)';
        
    case 3
        %% Generate stimuli for main EDT task
        
        % Load calibration file for participant
        oldcd = cd(params.dataDir);
        name = sprintf('%.0f_1_*', id); % 1 is session number for calibration
        try
            loadname = dir(name);
        catch
            disp(name)
            disp('No such file.')
        end
        load(loadname.name);
        
        cd(oldcd);
        
        % Put variables in matrix
        X = [data.trialLog.A; data.trialLog.fA; data.trialLog.D; data.trialLog.fD]';
        Y = [data.trialLog.choice]';
        % Locate and remove missing responses
        i = Y == 3;
        Y(i) = [];
        X(i,:) = [];
        
        switch params.adaptiveSC
            case 0
                [acc, ip, modelParams] = modelEDT(X(:,3),X(:,2),Y,0,0); % Get indifference points, to plot, set last argument to 1
            case 1
                for d = 1:numel(params.D)
                    ip(d) =  mean(data.trialLog(end).PM(d).threshold(end-9:end)) % If using Psi, take the average threshold of the last third of trials
                    % ip(d) = QuestMean(data.trialLog(end).q(d)); % If using QUEST
                end
        end
        
        df = ip ./ unique(X(:,1)); % Calculate discount factors
        
                % Generate presentation list
                list = []; % Output of list is: (:,1) = SS amount, (:,2) = LL amount, (:,3) = SS delay, (:,4) = LL delay
                probList = []; % Alternative list using logit probabilities instead of simple discount factors
                for a = 1:numel(params.A)
                    fA = params.A(a); % LL amount
                    ssD = 2; % SS delay
                    for lld = 1:numel(params.D)
                        LLx = params.D(lld); % LL delay
                        for ratio = params.ratio % Ratio of SS:LL biased options
                            % IP method (multiply fixed reward with modified discount factor)
                            if ratio > 1
                                ssA = (df(lld)-(df(lld)*(4/5))) * fA;
                                bias = 2;
                            else
                                ssA = (df(lld)+(df(lld)*(4/5))) * fA;
                                bias = 1;
                            end
                            list = cat(1, list, [ssA fA ssD LLx bias]); % Add to list
                            
                            % Probability method
%                             highProb = ((-log((1-0.85)./0.85)) ./ modelParams{lld}(1)) + modelParams{lld}(2); % Find amounts with inverted logistic function
%                             lowProb = ((-log((1-0.15)./0.15)) ./ modelParams{lld}(1)) + modelParams{lld}(2); % Find amounts with inverted logistic function
%                             if ratio > 1
%                                 sA = (highProb / unique(X(:,1))) *fA;
%                                 bias = 2;
%                             else
%                                 sA = (lowProb / unique(X(:,1))) *fA;
%                                 bias = 1;
%                             end
%                             probList = cat(1, probList, [sA fA ssD LLx bias]); % Add to list
                        end
                    end
                end
                
%                 % Locate and adjust negative volumes
%                 i = probList < 0;
%                 probList(i) = 0;
%                 
%                 % Intermingle the two types of list and add identifier
%                 probList(:,6) = 1;
%                 list(:,6) = 0;
%                 stimuli = cat(1,probList, list);
                
                stimuli = repmat(list, params.numrepeats, 1);
                
                % Load totalvolume from previous file
                params.totalvolume = data.trialLog(end).totalvolume;
                
        end % End session switch
        
        params.stimuli = stimuli;
        params.numTrials = size(stimuli,1);
        
        return
        
