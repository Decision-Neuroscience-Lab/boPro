function [trialLog] = QT_task_autoWin(params)
try
    % Preallocate data structure
    trialLog = table;
    
    % Start block timer
    exit = 0;
    t = 0;
    totalReward = 0;
    blockStartTime = GetSecs;
    while GetSecs <= blockStartTime + params.blockTime
        
        % Start trial timer
        t = t + 1; % Trial counter
        trialStartTime = GetSecs;
        % Either sample sequentially from quartiles of distribution or
        % sample normally
        if params.quartileSampling == 1 && strcmp(params.d.DistributionName,'Generalized Pareto')
            switch params.qtList(t)
                case 1
                    delay = random(truncate(params.d,0,icdf(params.d,0.25)));
                case 2
                    delay = random(truncate(params.d,icdf(params.d,0.25),icdf(params.d,0.5)));
                case 3
                    delay = random(truncate(params.d,icdf(params.d,0.5),icdf(params.d,0.75)));
                case 4
                    delay = random(truncate(params.d,icdf(params.d,0.75),icdf(params.d,1)));
            end
        else
            delay = random(params.d); % Choose a random reward delay from distribution
        end
        rt = NaN;
        reward = params.smallReward;
        censor = 0;
        while GetSecs < (trialStartTime + params.upperlimit) && GetSecs <= blockStartTime + params.blockTime
            % Present stimuli and check for responses
            drawQuitStim(params, totalReward, GetSecs - blockStartTime, 0, 0);
            Screen('Flip', params.window);
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            % If key is pressed
            if keyIsDown && isnan(rt)
                % If force exit
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break; % Break out of trial
                end
                % If participant quits trial
                rt = GetSecs - trialStartTime; % Record time
                % Maintain stimuli through first half of ITI
                while GetSecs < trialStartTime + rt + (params.iti/2) && GetSecs <= blockStartTime + params.blockTime
                    drawQuitStim(params, totalReward, GetSecs - blockStartTime, 0, 1);
                    Screen('Flip', params.window);
                end
                break; % Break out of trial 
            end
            
            % If delay is reached (reward delivered before response)
            if GetSecs >= (trialStartTime + delay)
                reward = params.largeReward; % Record reward amount (default is small)
                % Maintain stimuli through first half of ITI
                while GetSecs < trialStartTime + delay + (params.iti/2) && GetSecs <= blockStartTime + params.blockTime
                    drawQuitStim(params, totalReward, GetSecs - blockStartTime, 1, 0);
                    Screen('Flip', params.window);
                end
                break; % Break out of trial
            end
        end
        
        % Record data
        totalReward = totalReward + reward;
        if isnan(rt) % If participant didn't make a response, add censor variable
            censor = 1;
        end
        trialLog(t,:) = {t, cellstr(params.d.DistributionName), delay, rt, logical(censor), reward, totalReward};
        
        % Maintain total and time through second half of ITI
        itiStart = GetSecs;
        while GetSecs < itiStart + (params.iti/2) && GetSecs <= blockStartTime + params.blockTime
            Screen(params.window, 'FillRect', [128 128 128]);
            % Display total reward
            total = sprintf('($%.2f total)', totalReward);
            DrawFormattedText(params.window, total, 'center', params.height.*(3/4), [0 0 0], 40, 0, 0, 2);
            % Display total time
            Screen('FrameRect', params.window, [0 0 0],...
                [params.width.*(1/5), params.height.*(4/5), params.width.*(4/5), params.height.*(4/5) + 40], 3);
            Screen('FillRect', params.window, params.cPrime,...
                [params.width.*(1/5) + 3, params.height.*(4/5) + 3,...
                (params.width.*(1/5) + 3) + (((params.width.*(4/5)...
                - params.width.*(1/5)) - (2*3)) .* ((GetSecs - blockStartTime)./params.blockTime)),... % Fraction of remaining time
                params.height.*(4/5) + 40 - 3]);
            Screen('Flip', params.window);
        end
        
        if exit == 1 % If we 'escaped' earlier
            break; % Break out of block
        end
        
    end % Block timer
catch
    % If program crashes re-engage mouse and keyboard, close screen, show
    % error message and save data as 'recoveredData'
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
    data.trialLog = trialLog;
    data.params = params;
    oldcd = cd(params.dataDir);
    save('recoveredData', 'data');
    cd(oldcd);
end % Try
return