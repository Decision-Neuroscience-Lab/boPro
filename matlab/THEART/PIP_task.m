function [trialLog] = PIP_task(params)
try
    
    % Setup screen
    params.ifi = Screen('GetFlipInterval', params.window);
    % Screen('TextFont', params.window, 'Helvetica');
    Screen('TextSize', params.window, 30);
    
    trialLog = table;
    
    % Instructions
    drawText(params.window, ['In the next task you will be presented with an interval (e.g. "4 seconds").'...
        '\n\nPress the down arrow when you think the interval has elapsed.\n\n\n[Press any button to start]']);
    
    %% Trial loop
    exit = 0;
    for t = 1:numel(params.pipTrials)
        
        % Present interval
        Screen(params.window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', params.pipStimuli(t)./2);
        DrawFormattedText(params.window, delay_text, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        onset = Screen('Flip', params.window);
        
        % Build delay stimulus
        Screen(params.window, 'FillRect', [128 128 128]); % Draw background
        Screen('DrawLine', params.window, [0 0 0],...
            params.width/2, params.height/2-(params.height/90),...
            params.width/2, params.height/2+(params.height/90), 2.5); % Draw fixation cross
        Screen('DrawLine', params.window, [0 0 0],...
            params.width/2-(params.height/90), params.height/2,...
            params.width/2+(params.height/90), params.height/2, 2.5);
        delay_onset = Screen(params.window, 'Flip', onset + params.pipDisplay);
        
        % Trigger PIP delay start
        switch params.pipStimuli(t)
            case params.pipDelays(1)
                trigger = 20;
            case params.pipDelays(2)
                trigger = 21;
            case params.pipDelays(3)
                trigger = 22;
            case params.pipDelays(4)
                trigger = 23;
        end
        io32(params.ioObj,params.address,trigger);
        WaitSecs(0.01);
        io32(params.ioObj,params.address,0);
        
        %% Capture response
        
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while GetSecs < (delay_onset + params.pipStimuli(t)) % Response window
            [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break;
                end
                button_down = GetSecs;
                Screen('DrawLine', params.window, [216.75 82.875 24.99], params.width/2, params.height/2-(params.height/90), params.width/2, params.height/2+(params.height/90), 2.5); % Draw fixation cross
                Screen('DrawLine', params.window, [216.75 82.875 24.99], params.width/2-(params.height/90), params.height/2, params.width/2+(params.height/90), params.height/2, 2.5);
                Screen('Flip', params.window);
                
                % Trigger PIP response
                io32(params.ioObj,params.address,24);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
                
                break; % Break out of response window
            end
        end
        
        % Record data
        if ~isempty(button_down)
            rt = button_down - delay_onset;
        else
            rt = NaN;
        end
        
        while GetSecs < (delay_onset + (params.pipStimuli(t)))
        end
        
        if isnan(rt)
            Screen(params.window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(params.window, 'Too late! Please try and respond at the correct time!', 'center','center',  [0 0 0], 40, 0, 0, 2);
        else
            Screen(params.window, 'FillRect', [128 128 128]); % Draw background
        end
        Screen(params.window, 'Flip');
        
        WaitSecs(params.pipITI);
        
        trialLog(t,:) = {t, params.pipStimuli(t), rt};
        
        if exit == 1 % If we 'escaped' earlier
            break; % Break out of task
        end
    end % Trial loop
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    
    % Save data
    data.trialLog = trialLog;
    data.params = params;
    oldcd = cd(params.dataDir);
    save('recoveredData', 'data');
    cd(oldcd);
    
    psychrethrow(psychlasterror)
end % Try
return