function [DATA] = TG_task(window, width, height, key, params)
% For each block returns: 
%DATA(t,1) = Interval 
%DATA(t,2) = Response time 
%DATA(t,3) = Choice (1 = 'much shorter', 2 = 'shorter', 3 = 'same', 4 = 'longer', 5 = 'much longer')
%DATA(t,4) = Magnitude (small = 1 or 2, large = 8 or 9)
% This version displays a fixation cross as a stimulus (Magnitude is
% recorded as '0')
%% Try
try
    
    % Setup screen
    ifi = Screen('GetFlipInterval', window);
    HideCursor;
    ListenChar(2);
    WaitSecs(0.05);
    
    % Set font
    Screen('TextFont', window, 'Helvetica');
    
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
        anchor_disp = sprintf('About %.0f seconds', interval);
        drawbackground(window, width, height);
        DrawFormattedText(window, anchor_disp, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        anchor_onset = Screen(window, 'Flip'); % Screen flip
        
        % Build presentation stimulus
        drawbackground(window, width, height);
        drawfixation(window, width, height);
        if t == params.oddball
            Screen('FillRect', window, [200 200 200], [width/2-30, height/2-30, width/2+30, height/2+30]);
        end
        presentation_onset = Screen(window, 'Flip',  anchor_onset + floor(params.anchortime/ifi) * ifi); % Screen flip
       
        
        %% Response
        
        % Choice
        feed_disp = sprintf('%.0f seconds\n\n-3    -2    -1    0    1    2    3', interval);
        drawbackground(window, width, height);
        Screen('TextStyle', window, 1);
        DrawFormattedText(window, feed_disp, 'center', 'center',  [0 0 0], 70, 0, 0, 2);
        fix2_onset = Screen(window, 'Flip', presentation_onset + floor(interval/ifi) * ifi); % Screen flip
        Screen('TextStyle', window, 0);
        
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
            DATA(t,3) = 2;
        elseif keyCode(key(2)) == 1 % In case 'shorter'
            DATA(t,3) = 3;
        elseif keyCode(key(3)) == 1 % In case 'the same'
            DATA(t,3) = 4;
        elseif keyCode(key(4)) == 1 % In case 'longer'
            DATA(t,3) = 5;
        elseif keyCode(key(5)) == 1 % In case 'much longer'
            DATA(t,3) = 6;
        elseif keyCode(key(6)) == 1 % In case 'extra short'
            DATA(t,3) = 1;
        elseif keyCode(key(7)) == 1 % In case 'extra long'
            DATA(t,3) = 7;
        end
        
    end % Trial loop
    
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
end % Try
end