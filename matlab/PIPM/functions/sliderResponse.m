function [rt, value, exit] = sliderResponse(window,width,height,scale,choiceTime,text,varargin)
% This function draws a bar as a scale, with instructional text. choiceTime
% is the response window in seconds, and if set to 0 will wait indefinitely
% until a response is made. The scale argument are the markers for
% response, i.e. Likert scale. The values of scale must be positive. The
% optional argument takes two values ([label1 and label2]) which replace
% the numbers on the scale. If the scale is then set to be large, this
% essentially transforms this Likert scale into a VAS. If the escape key is
% pressed, this will exit the repsonse window (a non reponse is recorded
% via rt = -1, but the value will still be recorded). It returns a value
% (along the provided scale) and a response time.

if ~isempty(varargin)
    [label1, label2] = varargin{1};
end

% Set keyboard
KbName('UnifyKeyNames');
leftkey = KbName('LeftArrow');
rightkey = KbName('RightArrow');
downkey = KbName('DownArrow');
escapekey = KbName('ESCAPE');

% Set returned variables
exit = 0;
rt = -1;
value = [];

scaleSize = numel(scale);

if mod(scaleSize,2) == 0
    pos = scaleSize / 2;
else
    pos = (scaleSize + 1) / 2;
end

y = (width/2);
onset = GetSecs;

Screen('TextSize',window, 30);

if choiceTime == 0 % If indefinite response time
    
    while isempty(value)
        
        right_down = 0;
        left_down = 0;
        
        % Draw text
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        DrawFormattedText(window, text, 'center', height/6,  [0 0 0], 70, 0, 0, 2);
        
        % Draw slider
        bar_width = 0.7 * width;
        Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
        
        % Draw markers
        markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), scaleSize);
        markers_top = (height/2) - 10;
        markers_bottom = (height/2) + 10;
        for l = 1:length(markers_x)
            Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
        end
        
        % Draw numbers
        if isempty(varargin)
            for n = 1:length(markers_x)
                number = sprintf('%0.f', n);
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
                clear number
            end
        else % Only draw labels at the ends
            textbox = Screen('TextBounds', window, label1);
            Screen('DrawText', window, label1, (width/2) - bar_width/2 - textbox(3) - 10, height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
            Screen('DrawText', window, label2, (width/2) + bar_width/2 + 10,  height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
        end
        
        % Draw line
        line_x = y;
        line_top = (height/2) + 15;
        line_bottom = (height/2) - 15;
        Screen('DrawLine', window, [0 113.985 188.955], line_x, line_top, line_x, line_bottom, 3 );
        Screen(window, 'Flip');
        
        %% Wait for input
        KbWait([], 2);
        [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
        % Capture left and right response
        if keyIsDown
            if keyCode(leftkey) == 1
                left_down = 1;
            elseif keyCode(rightkey) == 1
                right_down = 1;
            else
                right_down = 0;
                left_down = 0;
            end
        end
        
        % Capture choice response, frame choice and exit response window
        if keyIsDown == 1 && keyCode(downkey) == 1
            rt = GetSecs - onset;
            % Draw text
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, text, 'center',  height/6,  [0 0 0], 70, 0, 0, 2);
            
            % Draw slider
            bar_width = 0.7 * width;
            Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
            
            % Draw markers
            markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), scaleSize);
            markers_top = (height/2) - 10;
            markers_bottom = (height/2) + 10;
            for l = 1:length(markers_x)
                Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
            end
            
            % Draw numbers
            if isempty(varargin)
                for n = 1:length(markers_x)
                    number = sprintf('%0.f', n);
                    if pos == n
                        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [216.75 82.875 24.99]);
                    else
                        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
                    end
                    clear number
                end
            else % Only draw labels at the ends
                textbox = Screen('TextBounds', window, label1);
                Screen('DrawText', window, label1, (width/2) - bar_width/2 - textbox(3) - 10, height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
                Screen('DrawText', window, label2, (width/2) + bar_width/2 + 10,  height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
            end
            
            % Draw line
            line_x = y;
            line_top = (height/2) + 15;
            line_bottom = (height/2) - 15;
            Screen('DrawLine', window, [216.75 82.875 24.99], line_x, line_top, line_x, line_bottom, 3 );
            Screen(window, 'Flip');
            
            WaitSecs(0.5);
            
            value = pos; % Record answer
            break;
        end
        
        if keyIsDown && keyCode(escapekey) == 1
            exit = 1;
            value = pos;
            break;
        end
        
        % Adjust cursor position
        if left_down && pos ~= 1
            pos = pos - 1;
            y = markers_x(pos);
        elseif right_down && pos ~= scaleSize
            pos = pos + 1;
            y = markers_x(pos);
        end
        WaitSecs(0.005);
        
    end % Response window
    
else % If there is a limited response window
    
    while GetSecs < (onset + choiceTime)
        
        right_down = 0;
        left_down = 0;
        
        % Draw text
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        DrawFormattedText(window, text, 'center',  height/6,  [0 0 0], 70, 0, 0, 2);
        
        % Draw slider
        bar_width = 0.7 * width;
        Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
        
        % Draw markers
        markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), scaleSize);
        markers_top = (height/2) - 10;
        markers_bottom = (height/2) + 10;
        for l = 1:length(markers_x)
            Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
        end
        
        % Draw numbers
        if isempty(varargin)
            for n = 1:length(markers_x)
                number = sprintf('%0.f', n);
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
                clear number
            end
        else % Only draw labels at the ends
            textbox = Screen('TextBounds', window, label1);
            Screen('DrawText', window, label1, (width/2) - bar_width/2 - textbox(3) - 10, height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
            Screen('DrawText', window, label2, (width/2) + bar_width/2 + 10,  height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
        end
        
        % Draw line
        line_x = y;
        line_top = (height/2) + 15;
        line_bottom = (height/2) - 15;
        Screen('DrawLine', window, [0 113.985 188.955], line_x, line_top, line_x, line_bottom, 3 );
        Screen(window, 'Flip');
        
        %% Wait for input
        KbWait([], 2);
        [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
        % Capture left and right response
        if keyIsDown
            if keyCode(leftkey) == 1
                left_down = 1;
            elseif keyCode(rightkey) == 1
                right_down = 1;
            else
                right_down = 0;
                left_down = 0;
            end
        end
        
        % Capture choice response, frame choice and exit response window
        if keyIsDown && keyCode(downkey) == 1
            rt = GetSecs - onset;
            % Draw text
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, text, 'center',  height/6,  [0 0 0], 70, 0, 0, 2);
            
            % Draw slider
            bar_width = 0.7 * width;
            Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
            
            % Draw markers
            markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), scaleSize);
            markers_top = (height/2) - 10;
            markers_bottom = (height/2) + 10;
            for l = 1:length(markers_x)
                Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
            end
            
            % Draw numbers
            if isempty(varargin)
                for n = 1:length(markers_x)
                    number = sprintf('%0.f', n);
                    if pos == n
                        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [216.75 82.875 24.99]);
                    else
                        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
                    end
                    clear number
                end
            else % Only draw labels at the ends
                textbox = Screen('TextBounds', window, label1);
                Screen('DrawText', window, label1, (width/2) - bar_width/2 - textbox(3) - 10, height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
                Screen('DrawText', window, label2, (width/2) + bar_width/2 + 10,  height - 0.45 * height + bar_height/2 - fontSize/2, [0, 0, 0]);
            end
            
            % Draw line
            line_x = y;
            line_top = (height/2) + 15;
            line_bottom = (height/2) - 15;
            Screen('DrawLine', window, [216.75 82.875 24.99], line_x, line_top, line_x, line_bottom, 3 );
            Screen(window, 'Flip');
            
            WaitSecs(0.5);
            
            value = pos; % Record answer
            break;
        end
        
        if keyIsDown && keyCode(escapekey) == 1
            exit = 1;
            value = pos;
            break;
        end
        
        % Adjust cursor position
        if left_down && pos ~= 1
            pos = pos - 1;
            y = markers_x(pos);
        elseif right_down && pos ~= scaleSize
            pos = pos + 1;
            y = markers_x(pos);
        end
        WaitSecs(0.005);
        
    end % Response window
end
