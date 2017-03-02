function [trialLog] = QT_task(params)
try
    % Preallocate data structure
    trialLog = table;
    
    %% Start block timer
    exit = 0;
    t = 0;
    totalReward = 0;
    blockStartTime = GetSecs;
    
    while KbCheck % Make sure there isn't a first instant response
    end
    while GetSecs <= blockStartTime + params.blockTime
        %% Reset trial variables
        t = t + 1; % Trial counter
        rt = NaN;
        censor = 0;
        matured = 0;
        reward = params.smallReward;
        % Choose delay, either by sampling sequentially from quartiles of distribution or
        % sampling normally
        if params.quartileSampling == 1
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
        trialStartTime = GetSecs;
        %% Start trial loop
        while GetSecs <= blockStartTime + params.blockTime
            
            if GetSecs >= (trialStartTime + delay) % If delay is reached (reward delivered before response)
                matured = 1;
                reward = params.largeReward; % Record reward amount (default is small)
                censor = 1;
                
                % Trigger QT matured
                io32(params.ioObj,params.address,31);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
                
            end
            
            drawQuitStim(params, totalReward, GetSecs - blockStartTime, matured, 0);
            Screen('Flip', params.window);
            % Check for response
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if keyIsDown && isnan(rt) % Key press
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break; % Break out of trial
                end
                rt = GetSecs - trialStartTime; % Record time
                
                % Trigger QT response
                io32(params.ioObj,params.address,32);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
                
                % Maintain stimuli through first half of ITI
                while GetSecs < trialStartTime + rt + (params.iti/2) && GetSecs <= blockStartTime + params.blockTime
                    drawQuitStim(params, totalReward, GetSecs - blockStartTime, matured, 1);
                    Screen('Flip', params.window);
                end
                break; % Break out of trial
            end
        end
        
        % Record data
        totalReward = totalReward + reward;
        trialLog(t,:) = {t, delay, rt, logical(censor), reward, totalReward, (GetSecs - blockStartTime)};
        
        % Maintain total and time through second half of ITI
        itiStart = GetSecs;
        while GetSecs < itiStart + (params.iti/2) && GetSecs <= blockStartTime + params.blockTime
            Screen(params.window, 'FillRect', [128 128 128]);
            % Display total reward
            total = sprintf('($%.2f total)', totalReward);
            DrawFormattedText(params.window, total, 'center', params.height.*(6/8), [0 0 0], 40, 0, 0, 2);
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
    
    data.trialLog = trialLog;
    data.params = params;
    oldcd = cd(params.dataDir);
    save('recoveredData', 'data');
    cd(oldcd);
    
    psychrethrow(psychlasterror)
end % Try
return