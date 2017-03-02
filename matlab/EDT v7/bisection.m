function [trialLog] = bisection(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Instructions
    drawText(window, 'In this component, you will be presented with an interval (e.g. 4 seconds). When the cross appears, the interval has started. Please try to press a button when you think half the interval (e.g. 2 seconds) has elapsed, to divide the interval in half.\n\n[Press any button to start]');
    
    %% Trial loop
    
    for t = 1:params.numTrials
        
        trialLog(t).delay = params.stimuli(t);
        trialLog(t).rt = -1;
        trialLog(t).rawbisect = [];
        trialLog(t).bisect = [];
        
        % Present interval
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        delay_text = sprintf('%.0f seconds', trialLog(t).delay);
        DrawFormattedText(window, delay_text, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        onset = Screen('Flip', window);
        
        % Build delay stimulus
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen('DrawLine', window, [255 255 255], width/2, height/2-(height/90), width/2, height/2+(height/90), 2); % Draw fixation cross
        Screen('DrawLine', window, [255 255 255], width/2-(height/90), height/2, width/2+(height/90), height/2, 2);
        delay_onset = Screen(window, 'Flip', onset + 1);
        
        %% Capture response
        
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while GetSecs < (delay_onset + (trial(t).delay)) % Response window
            [ keyIsDown, ~, ~, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                button_down = GetSecs;
                Screen('DrawLine', window, [20 240 20], width/2, height/2-(height/90), width/2, height/2+(height/90), 2); % Draw fixation cross
                Screen('DrawLine', window, [20 240 20], width/2-(height/90), height/2, width/2+(height/90), height/2, 2);
                Screen('Flip', window);
                break; % Break out of response window
            end
        end
        
        % Record data
        if ~isempty(button_down)
            trialLog(t).rt = button_down - delay_onset;
            trialLog(t).rawbisect = trialLog(t).rt - (trial(t).delay / 2);
            trialLog(t).bisect = trialLog(t).rt/(trial(t).delay);
        end
        
        while GetSecs < (delay_onset + (trial(t).delay))
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
    oldcd = cd;
    cd(params.dataDir);
    save(datafilename, 'data');
    cd(oldcd);
    
end % Try
return