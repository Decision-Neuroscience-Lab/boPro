function [trialLog] = PIP_task(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    % Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Instructions
    drawText(window, 'In the next task you will be presented with a colour that represents a reward amount and the time to the delivery of the reward (e.g. "4 seconds").\n\nPress the down arrow when you think half the interval (e.g. 2 seconds) has elapsed, before the juice is delivered. In other words, try to divide the interval in half.\n\n[Press any button to start]');
    
    %% Trial loop
    exit = 0;
    refills = 1;
    for t = 1:params.numTrials
        
        % Break every 20 trials
        if mod(t,15) == 0;
            drawText(window,'Take a break.\nPress any button to proceed.');
        end
        
        trialLog(t).A = params.stimuli(t,1);
        trialLog(t).D = params.stimuli(t,2);
        trialLog(t).bisect = -1;
        
        % Present interval
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', trialLog(t).D);
        reward_colour = params.colours{(params.A == trialLog(t).A)};
        DrawFormattedText(window, delay_text, 'center',(height/2)+50,  [0 0 0], 35, 0, 0, 2);
        Screen('FillArc',window, reward_colour,[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
        onset = Screen('Flip', window);
        
        % Build delay stimulus
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        %         oldSize = Screen('TextSize', window, 40);
        %         DrawFormattedText(window, '...', 'center', 'center',  [0 113.985 188.955], 70, 0, 0, 2);
        %         Screen('TextSize', window, oldSize);
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
                %                 oldSize = Screen('TextSize', window, 40);
                %                 DrawFormattedText(window, '...', 'center', 'center',  [216.75 82.875 24.99], 70, 0, 0, 2);
                %                 Screen('TextSize', window, oldSize);
                Screen('DrawLine', window, [216.75 82.875 24.99], width/2, height/2-(height/90), width/2, height/2+(height/90), 2.5); % Draw fixation cross
                Screen('DrawLine', window, [216.75 82.875 24.99], width/2-(height/90), height/2, width/2+(height/90), height/2, 2.5);
                Screen('Flip', window);
                break; % Break out of response window
            end
        end
        
        % Record data
        if ~isempty(button_down)
            trialLog(t).bisectRt = button_down - delay_onset;
        end
        
        while GetSecs < (delay_onset + (trialLog(t).D))
        end
        
        %% Reward delivery
        if params.testing == 1
            text = sprintf('%05.3f', trialLog(t).A);
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            if trialLog(t).bisectRt == -1
                DrawFormattedText(window, 'Please try to divide the delay in half!', 'center', (height/2) - 100,  [0 0 0], 40, 0, 0, 2);
            end
            DrawFormattedText(window, text, 'center', 'center',  [20 240 20], 35, 0, 0, 2);
            Screen(window, 'Flip');
        else
            pumpInf(params.pump, trialLog(t).A);
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            if trialLog(t).bisectRt == -1
                DrawFormattedText(window, 'Please try to divide the delay in half!', 'center', (height/2) - 100,  [0 0 0], 40, 0, 0, 2);
            end
            DrawFormattedText(window, 'Juice is dispensing...', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        end
        
        % Total juice count
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
        
        WaitSecs(params.drinktime);
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen(window, 'Flip');
        
        %% Check to see if pump is empty
        if trialLog(t).totalvolume > refills * 250 && ~params.testing
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Syringes are almost out of juice.\nPlease see the experimenter so they can be refilled.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
            
            % Backup data in case of quit
            oldcd = cd;
            cd(params.dataDir);
            data.trialLog = trialLog;
            data.params = params;
            save('recoveredData', 'data');
            cd(oldcd);
            
            KbWait([], 2)
            
            % Prompt refill and trigger pump withdrawal
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Ready to fill? Press down arrow to refill via withdrawal (remember to press a button to stop). Press escape once finished.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
            
            response = [];
            while isempty(response)
                [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
                if keyIsDown && isempty(button_down)
                    if keyCode(params.escapekey) == 1
                        exit = 1;
                        break;
                    elseif keyCode(params.downkey) == 1
                        pumpRefill(params.pump);
                    end
                end
            end
            
            refills = refills + 1;
        end
        
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