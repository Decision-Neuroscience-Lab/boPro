function [number] = draw_magnitude_stimulus(window, width, height, params, t, dots)

%% Choose magnitude
switch params.presentation_list(2,t);
    case 1
        if rand<0.5
            magnitude = 1;
        else
            magnitude = 2;
        end
    case 2
        if rand<0.5
            magnitude = 3;
        else
            magnitude = 4;
        end
end

%% Draw numbers

if dots == 0
    
    % Set font
    oldFont = Screen('TextFont', window, 'Helvetica');
    oldSize = Screen('TextSize', window, 42);
    
    % Draw stimulus
    switch magnitude
        case 1
            stimulus_disp = sprintf('%.0f', 1);
        case 2
            stimulus_disp = sprintf('%.0f', 2);
        case 3
            stimulus_disp = sprintf('%.0f', 8);
        case 4
            stimulus_disp = sprintf('%.0f', 9);
    end
    
    drawbackground(window, width, height);
    DrawFormattedText(window, stimulus_disp, 'center', 'center',  [255 255 255], 35, 0, 0, 2);
    
    % Reset font
    Screen('TextFont', window, oldFont);
    Screen('TextSize', window, oldSize);
    
    number = magnitude; % Write to data
end

%% Draw dots

if dots == 1
    
    switch magnitude
        case 1
            Screen('FillArc', window, [255 255 255], [width/2-10, height/2-10, width/2+10, height/2+10], 0, 360);
        case 2
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2-10, width/2-20, height/2+10], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2-10, width/2+40, height/2+10], 0, 360);
        case 3
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2-10, width/2-20, height/2+10], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2-10, width/2+40, height/2+10], 0, 360);
            
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2+20, width/2-20, height/2+40], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2+20, width/2+40, height/2+40], 0, 360);
            
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2-40, width/2-20, height/2-20], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2-40, width/2+40, height/2-20], 0, 360);
        case 4
            Screen('FillArc', window, [255 255 255], [width/2-10, height/2-10, width/2+10, height/2+10], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2-10, width/2-20, height/2+10], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2-10, width/2+40, height/2+10], 0, 360);
            
            Screen('FillArc', window, [255 255 255], [width/2-10, height/2+20, width/2+10, height/2+40], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2+20, width/2-20, height/2+40], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2+20, width/2+40, height/2+40], 0, 360);
            
            Screen('FillArc', window, [255 255 255], [width/2-10, height/2-40, width/2+10, height/2-20], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2-40, height/2-40, width/2-20, height/2-20], 0, 360);
            Screen('FillArc', window, [255 255 255], [width/2+20, height/2-40, width/2+40, height/2-20], 0, 360);
    end
    
    number = magnitude; % Write to data
end

%% Draw circles

if dots == 2
    
    switch magnitude
        case 1
            Screen('DrawArc', window, [255 255 255], [width/2-10, height/2-10, width/2+10, height/2+10], 0, 360);
        case 2
            Screen('DrawArc', window, [255 255 255], [width/2-20, height/2-20, width/2+20, height/2+20], 0, 360);
        case 3
            Screen('DrawArc', window, [255 255 255], [width/2-100, height/2-100, width/2+100, height/2+100], 0, 360);
        case 4
            Screen('DrawArc', window, [255 255 255], [width/2-120, height/2-120, width/2+120, height/2+120], 0, 360);
    end
    
    number = magnitude; % Write to data
end

%% Draw lines

if dots == 3
    
    switch magnitude
        case 1
            Screen('DrawLine', window, [0 0 0], width/2-10, height/2, width/2+10, height/2, 4);
        case 2
            Screen('DrawLine', window, [0 0 0], width/2-20, height/2, width/2+20, height/2, 4);
        case 3
            Screen('DrawLine', window, [0 0 0], width/2-180, height/2, width/2+180, height/2, 4);
        case 4
            Screen('DrawLine', window, [0 0 0], width/2-200, height/2, width/2+200, height/2, 4);
    end
    
    number = magnitude; % Write to data
end
