function [trialLog] = PIP_practice(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    % Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Preallocate data structure
    trialLog.D = NaN;
    trialLog.bisectRt = NaN;
    trialLog.rawbisect = NaN;
    trialLog.bisect = NaN;
    trialLog = repmat(trialLog,1,numel(params.practiceStim));
    
    % Instructions
    drawText(window, params.baselineInstructions);
    
    %% Trial loop
    exit = 0;
    for t = 1:numel(params.practiceStim)
        
        trialLog(t).D = params.practiceStim(t);
        
        % Present interval
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', trialLog(t).D);
        DrawFormattedText(window, delay_text, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        onset = Screen('Flip', window);
        
        % Build delay stimulus
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen('DrawLine', window, [0 0 0], width/2, height/2-(height/90), width/2, height/2+(height/90), 2.5); % Draw fixation cross
        Screen('DrawLine', window, [0 0 0], width/2-(height/90), height/2, width/2+(height/90), height/2, 2.5);
        delay_onset = Screen(window, 'Flip', onset + params.choicetime);
        
        % Trigger PIP delay start
        switch params.stimuli(t,2)
            case params.D(1)
                trigger = 20;
            case params.D(2)
                trigger = 21;
            case params.D(3)
                trigger = 22;
            case params.D(4)
                trigger = 23;
        end
        sendTrigger(params,trigger);
        
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
                sendTrigger(params,24); % Response trigger
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
    %     ShowCursor;
    %     ListenChar(1);
    %     Screen('CloseAll');
    
    % Save data
    data.trialLog = trialLog;
    data.params = params;
    oldcd = cd(params.dataDir);
    save('recoveredData', 'data');
    cd(oldcd);
    
    psychrethrow(psychlasterror)
    
end % Try
return