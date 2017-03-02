function TG_practice(window, width, height, ~, params)
%% Try
try
    
    % Setup screen
    ifi = Screen('GetFlipInterval', window);
    HideCursor;
    ListenChar(2);
    WaitSecs(0.05);
    
    % Set font
    oldFont = Screen('TextFont', window, 'Courier New');
    oldColor = Screen('TextColor', window, [100 100 100]);
    
    % Setup sounds
    cf = 2000;
    sf = 22050;
    d = 0.05;
    n = sf * d;
    s = (1:n)/sf;
    s = sin(2*pi*cf*s);
    
    practice_presentation_list = params.practice_presentation_list;
    
    %% Trial loop
    
    for t = 1:size(practice_presentation_list, 2)
        
        %% Presentation
        
        interval = practice_presentation_list(1,t); % Choose practice interval
        
        % Present anchor
        if interval == 1
            anchor_disp = sprintf('This will be exactly %.0f second', interval);
        else
            anchor_disp = sprintf('This will be exactly %.0f seconds', interval);
        end
        
        drawbackground(window, width, height);
        DrawFormattedText(window, anchor_disp, 'center', 'center',  [255 255 255], 35, 0, 0, 2);
        anchor_onset = Screen(window, 'Flip'); % Screen flip
        
        % Build presentation stimulus
        drawbackground(window, width, height);
        drawfixation(window, width, height);
        presentation_onset = Screen(window, 'Flip',  anchor_onset + floor(params.anchortime/ifi) * ifi); % Screen flip
        
        
        %% Response
        
        % Choice
        if interval == 1
            feed_disp = sprintf('That was %.0f second\nPress any button for next interval', interval);
        else
            feed_disp = sprintf('That was %.0f seconds\nPress any button for next interval', interval);
        end
        
        drawbackground(window, width, height);
        DrawFormattedText(window, feed_disp, 'center', 'center',  [255 255 255], 70, 0, 0, 2);
        fix2_onset = Screen(window, 'Flip', presentation_onset + floor(interval/ifi) * ifi); % Screen flip
        
        % Wait until all keys are released
        while KbCheck
        end
        
        % Set up the timer
        pressed = 0;
        button_down = [];
        
        % Check for response
        while pressed == 0
            
            [ keyIsDown, secs, keyCode, deltaSecs ] = KbCheck;
            
            if keyIsDown && isempty(button_down)
                button_down = GetSecs;
                %  sound(s,sf);
                pressed = 1;
                break;
            end
        end
        
    end % Trial loop
    
     Screen('TextFont', window, oldFont);
     Screen('TextColor', window, oldColor);
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
end % Try
end