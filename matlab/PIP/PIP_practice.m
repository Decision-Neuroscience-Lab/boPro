function [trialLog] = PIP_practice(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    % Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Instructions
    drawText(window, 'The next task is a short test without juice.\n\nYou will be presented with an interval (e.g. "4 seconds") which starts immediately when the cross appears.\n\nPlease press the down arrow when you think half the interval (e.g. 2 seconds) has elapsed. In other words, try to divide the interval in half.\n\n[Press any button to start]');
    
    %% Trial loop
    exit = 0;
    for t = 1:numel(params.practiceStim)
        
        trialLog(t).D = params.practiceStim(t);
        trialLog(t).bisectRt = -1;
        trialLog(t).rawbisect = [];
        trialLog(t).bisect = [];
        
        % Present interval
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', trialLog(t).D);
        DrawFormattedText(window, delay_text, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
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
            trialLog(t).rawbisect = trialLog(t).bisectRt - (trialLog(t).D / 2);
            trialLog(t).bisect = trialLog(t).bisectRt/(trialLog(t).D);
        end
        
        while GetSecs < (delay_onset + (trialLog(t).D))
        end
        
        if exit == 1
            break;
        end
        
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