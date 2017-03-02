function [DATA] = TG_task_mag(window, width, height, key, params)
% For each block returns:
%DATA(t,1) = Interval
%DATA(t,2) = Response time
%DATA(t,3) = Choice (1 = 'shorter', 2 = 'short', 3 = 'long', 4 = 'longer')
%DATA(t,4) = Magnitude (small = 1 or 2, large = 8 or 9)
% This version displays stimuli of varying magnitudes and has forced
% response valence.
%% Try
try
    
    % Setup screen
    ifi = Screen('GetFlipInterval', window);
    HideCursor;
    ListenChar(2);
    WaitSecs(0.05);
    
    % Set font
    oldFont = Screen('TextFont', window, 'Helvetica');
    oldSize = Screen('TextSize', window, 30);
    
    % Setup sounds
    cf = 2000;
    sf = 22050;
    d = 0.05;
    n = sf * d;
    s = (1:n)/sf;
    s = sin(2*pi*cf*s);
    
    % Setup data file
    num_trials = size(params.presentation_list, 2);
    DATA = zeros(num_trials, 4);
    
    %% Trial loop
    
    for t = 1:num_trials
        
        %% Presentation
        
        interval = params.presentation_list(1,t); % Choose and write presented interval
        DATA(t,1) = interval;
        
        % Present anchor
        if interval == 1
            anchor_disp = sprintf('About %.0f second', interval);
        else
            anchor_disp = sprintf('About %.0f seconds', interval);
        end
        drawbackground(window, width, height);
        DrawFormattedText(window, anchor_disp, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        anchor_onset = Screen(window, 'Flip'); % Screen flip
        
        % Build presentation stimulus
        drawbackground(window, width, height);
        dots = params.dots;
        number = draw_magnitude_stimulus(window, width, height, params, t, dots);
        DATA(t,4) = number;
        presentation_onset = Screen(window, 'Flip',  anchor_onset + floor(params.anchortime/ifi) * ifi); % Screen flip
        
        %% Response
        
        % Choice
        feed_disp = sprintf('%.0f seconds\n\nvery short      shorter      longer      very long', interval);
        drawbackground(window, width, height);
        DrawFormattedText(window, feed_disp, 'center', 'center',  [0 0 0], 70, 0, 0, 2);
        if ismember(t, params.oddball)
            fix2_onset = Screen(window, 'Flip', presentation_onset + floor(interval*2/ifi) * ifi); % Screen flip
        else
            fix2_onset = Screen(window, 'Flip', presentation_onset + floor(interval/ifi) * ifi); % Screen flip
        end
        
        
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
                % sound(s,sf);
                pressed = 1;
                break;
            end
        end
        
        DATA(t,2) = button_down - fix2_onset; % Record RT
        
        if keyCode(key(1)) == 1 % In case 'much shorter'
            DATA(t,3) = 1;
        elseif keyCode(key(2)) == 1 % In case 'shorter'
            DATA(t,3) = 2;
        elseif keyCode(key(3)) == 1 % In case 'longer'
            DATA(t,3) = 3;
        elseif keyCode(key(4)) == 1 % In case 'much longer'
            DATA(t,3) = 4;
        end
        
    end % Trial loop
    
    Screen('TextFont', window, oldFont);
    Screen('TextSize', window, oldSize);
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
end % Try
end