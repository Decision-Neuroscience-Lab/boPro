function [numCorrect] = reward_practice(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    % Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    %% Sample volumes
    drawText(window, 'In this experiment there are three different colours that represent three different volumes.\n\nEach colour will be shown to you. Press any button to dispense the volume of juice associated with that colour.\n\n[Press any button to start]');
    % Volume delivery
    for v = 1:3
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen('FillArc',window, params.colours{v},[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
        DrawFormattedText(window, '[Press a button to dispense]', 'center', (height/2)+50,  [0 0 0], 35, 0, 0, 2);
        Screen(window, 'Flip');
        KbWait([], 2);
        if params.testing == 1
            text = sprintf('%05.3f', params.A(v));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, text, 'center', 'center',  [20 240 20], 35, 0, 0, 2);
            Screen(window, 'Flip');
        else
            pumpInf(params.pump, params.A(v));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Juice is dispensing...', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        end
        WaitSecs(params.drinktime);
    end
    
    % Instructions
    drawText(window, 'Now you will be given these volumes without the colours being shown.\n\nPlease try to identify which volume you have been given by pressing the left, down or right arrows.\n\n[Press any button to start]');
    
    %% Trial loop
    exit = 0;
    practiceStim = shuffleDim(repmat(params.A,1,3),2);
    correct = zeros(1,numel(practiceStim));
    for t = 1:numel(practiceStim)
        
        % Volume delivery
        drawText(window, '[Press any button to dispense juice]');
        if params.testing == 1
            text = sprintf('%05.3f', practiceStim(t));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, text, 'center', 'center',  [20 240 20], 35, 0, 0, 2);
            Screen(window, 'Flip');
        else
            pumpInf(params.pump, practiceStim(t));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Juice is dispensing...', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        end
        WaitSecs(params.drinktime);
        
        %% Capture response
        
        % Draw choices
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        DrawFormattedText(window, 'Which volume was that?\n[Press the left, down or right arrows]', 'center', (height/2)-250,  [0 0 0], 100, 0, 0, 2);
        Screen('FillArc',window, params.colours{1},[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
        Screen('FillArc',window, params.colours{2},[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
        Screen('FillArc',window, params.colours{3},[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
        Screen(window, 'Flip');
        
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while true
            [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break;
                elseif keyCode(params.leftkey) == 1
                    response = 1;
                elseif keyCode(params.downkey) == 1
                    response = 2;
                elseif keyCode(params.rightkey) == 1
                    response = 3;
                else
                    response = 0;
                end
                % Redraw choices and change selected arc to orange
                Screen(window, 'FillRect', [128 128 128]); % Draw background
                DrawFormattedText(window, 'Which volume was that?\n[Press the left, down or right arrows]', 'center', (height/2)-250,  [0 0 0], 100, 0, 0, 2);
                Screen('FillArc',window, params.colours{1},[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
                Screen('FillArc',window, params.colours{2},[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
                Screen('FillArc',window, params.colours{3},[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
                switch response
                    case 0
                        continue;
                    case 1
                        Screen('FillArc',window, [216.75 82.875 24.99],[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
                    case 2
                        Screen('FillArc',window, [216.75 82.875 24.99],[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
                    case 3
                        Screen('FillArc',window, [216.75 82.875 24.99],[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
                end
                Screen('Flip', window);
                break; % Break out of response window
            end
        end
        
        if params.A(response) == practiceStim(t)
            correct(t) = 1;
        end
        
        if exit == 1
            break;
        end
        
        WaitSecs(0.5);
    end % Trial loop
    
    numCorrect = sum(correct);
    text = sprintf('You got %.0f out of %.0f correct.\n\n[Press any key to finish]', numCorrect, numel(practiceStim));
    drawText(window, text);
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
end % Try
return