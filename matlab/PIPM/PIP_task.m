function [trialLog] = PIP_task(params, trialLog)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    % Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    if isempty(trialLog)
        % Preallocate data structure
        trialLog.A = NaN;
        trialLog.D = NaN;
        trialLog.bisectRt = NaN;
        trialLog.rawbisect = NaN;
        trialLog.bisect = NaN;
        trialLog.totalvolume = NaN;
        trialLog = repmat(trialLog,1,params.numTrials);
    end
    
    % Instructions
    drawText(window, 'In the next task you will be presented with a colour that represents a reward amount and the time it will take to win that reward (e.g. "4 seconds").\n\nPress the down arrow when you think half the interval (e.g. 2 seconds) has elapsed, before you win the reward. In other words, try to divide the interval in half.\n\n[Press any button to start]');
    
    %% Trial loop
    exit = 0;
    for t = params.startTrial:params.numTrials
        
        % Break at n trials
        if mod(t,20) == 0;
            text = 'Take a break.\nPress any button to proceed.';
            drawText(window,text);
        end
        
        trialLog(t).A = params.stimuli(t,1);
        trialLog(t).D = params.stimuli(t,2);
        
        % Present interval
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', trialLog(t).D);
        reward_colour = params.colours{(params.A == trialLog(t).A)};
        DrawFormattedText(window, delay_text, 'center',(height/2)+50,  [0 0 0], 35, 0, 0, 2);
        Screen('FillArc',window, reward_colour,[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
        onset = Screen('Flip', window);
        
        % Build delay stimulus
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen('DrawLine', window, [0 0 0], width/2, height/2-(height/90), width/2, height/2+(height/90), 2.5); % Draw fixation cross
        Screen('DrawLine', window, [0 0 0], width/2-(height/90), height/2, width/2+(height/90), height/2, 2.5);
        delay_onset = Screen(window, 'Flip', onset + params.choicetime);
        
        %% Capture response
        
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while GetSecs < (delay_onset + (trialLog(t).D)) % Response window
            [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break;
                end
                button_down = GetSecs;
                Screen('DrawLine', window, [216.75 82.875 24.99], width/2, height/2-(height/90), width/2, height/2+(height/90), 2.5); % Draw fixation cross
                Screen('DrawLine', window, [216.75 82.875 24.99], width/2-(height/90), height/2, width/2+(height/90), height/2, 2.5);
                Screen('Flip', window);
                break; % Break out of response window
            end
        end
        
        % Record data
        if ~isempty(button_down)
            trialLog(t).bisectRt = button_down - delay_onset;
            trialLog(t).rawbisect = trialLog(t).bisectRt - (trialLog(t).D / 2);
            trialLog(t).bisect = trialLog(t).bisectRt/(trialLog(t).D);
        end
        
        while GetSecs < (delay_onset + (trialLog(t).D))
        end
        
        %% Reward delivery
        
            % Total reward count
        if isempty(params.totalvolume)
            if t == 1
                trialLog(t).totalvolume = trialLog(t).A;
            else
                trialLog(t).totalvolume = trialLog(t-1).totalvolume + trialLog(t).A;
            end
        else
            trialLog(t).totalvolume = params.totalvolume + trialLog(t).A;
            params.totalvolume = [];
        end
        
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        % Warn if missed
        if isnan(trialLog(t).bisectRt)
            DrawFormattedText(window, 'Please try to divide the delay in half!', 'center', (height/2) - 100,  [0 0 0], 40, 0, 0, 2);
        end
        % Draw reward
        if trialLog(t).A == 0;
            text = 'You got no reward...';
        else
            text = sprintf('You got %.0f cents!', trialLog(t).A);
        end
        Screen('TextSize', window, 35);
        DrawFormattedText(window, text, 'center', 'center',  [0 0 0], 90, 0, 0, 2);
        Screen('TextSize', window, 30);

        % Draw total
        total = sprintf('($%.2f total)',trialLog(t).totalvolume./100);
        DrawFormattedText(window, total,'center', (height/2)+30,[0 0 0], 40, 0, 0, 2);
        
        Screen(window, 'Flip');
        WaitSecs(params.drinktime);
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen(window, 'Flip');
        
        if exit == 1
            break;
        end
        
        WaitSecs(params.iti);
    end % Trial loop
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
    % Save data
    data.trialLog = trialLog;
    data.params = params;
    oldcd = cd(params.dataDir);
    save('recoveredData', 'data');
    cd(oldcd);
    
end % Try
return