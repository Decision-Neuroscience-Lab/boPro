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
    drawText(window, 'In this experiment there are three different colours that represent three different rewards and one colour that represents no reward.\n\nEach colour will be shown to you. Press any button to see the reward associated with that colour.\n\n[Press any button to start]');
    % Volume delivery
    for v = 1:4
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen('FillArc',window, params.colours{v},[(width/2)-30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
        DrawFormattedText(window, '[Press a button to see the reward]', 'center', (height/2)+50,  [0 0 0], 35, 0, 0, 2);
        Screen(window, 'Flip');
        KbWait([], 2);
        if params.A(v) == 0;
            text = sprintf('You got no reward...');
        else
            text = sprintf('You got %.0f cents!', params.A(v));
        end
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        drawRewardText(window, text);
        
        WaitSecs(params.drinktime);
    end
    
    % Instructions
    drawText(window, 'Now you will be shown these rewards without the colours being shown.\n\nPlease try to identify which the correct colour of the reward by pressing the left, down or right arrows.\n\n[Press any button to start]');
    
    %% Trial loop
    exit = 0;
    practiceStim = shuffleDim(repmat(params.A,1,2),2);
    correct = zeros(1,numel(practiceStim));
    for t = 1:numel(practiceStim)
        
        %% Capture response
        
        % Draw choices
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        text = sprintf('Which colour is %.0f cents?\n[Use the the left and right arrows to select a colour, and the down arrow to make a selection]', practiceStim(t));
        DrawFormattedText(window, text, 'center', (height/2)-250,  [0 0 0], 100, 0, 0, 2);
        arcPos = {[(width/2)-255, (height/2)-30, (width/2)-195, (height/2)+30], [(width/2)-105, (height/2)-30, (width/2)-45, (height/2)+30], [(width/2)+45, (height/2)-30, (width/2)+105, (height/2)+30], [(width/2)+195, (height/2)-30, (width/2)+255, (height/2)+30]}; % Define arc positions
        arcPosBig = {[(width/2)-265, (height/2)-40, (width/2)-185, (height/2)+40], [(width/2)-115, (height/2)-40, (width/2)-35, (height/2)+40], [(width/2)+35, (height/2)-40, (width/2)+115, (height/2)+40], [(width/2)+185, (height/2)-40, (width/2)+265, (height/2)+40]}; % Define arc positions for larger arcs
        Screen('FillArc',window, params.colours{1},arcPos{1}, 0, 360);
        Screen('FillArc',window, params.colours{2},arcPos{2}, 0, 360);
        Screen('FillArc',window, params.colours{3},arcPos{3}, 0, 360);
        Screen('FillArc',window, params.colours{4},arcPos{4}, 0, 360);
        Screen(window, 'Flip');
        
        % Check for response
        button_down = [];
        pos = 2;
        while true
            % Wait until all keys are released
            KbWait([], 2);
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
                DrawFormattedText(window, text, 'center', (height/2)-250,  [0 0 0], 100, 0, 0, 2);
                Screen('FillArc',window, params.colours{1},arcPos{1}, 0, 360);
                Screen('FillArc',window, params.colours{2},arcPos{2}, 0, 360);
                Screen('FillArc',window, params.colours{3},arcPos{3}, 0, 360);
                Screen('FillArc',window, params.colours{4},arcPos{4}, 0, 360);
                
                switch response
                    case 0
                        continue;
                    case 1
                        if pos > 1
                            pos = pos - 1;
                        else
                            pos = 1;
                        end
                        Screen('FillArc',window, params.colours{pos},arcPosBig{pos}, 0, 360);
                    case 2
                        Screen('FillArc',window, [216.75 82.875 24.99],arcPosBig{pos}, 0, 360);
                        choice = pos;
                        Screen('Flip', window);
                        break; % Break out of response window
                    case 3
                        if pos < 4
                            pos = pos + 1;
                        else
                            pos = 4;
                        end
                        Screen('FillArc',window, params.colours{pos},arcPosBig{pos}, 0, 360);
                end
                Screen('Flip', window);
            end
        end
        
        if params.A(choice) == practiceStim(t)
            correct(t) = 1;
        end
        
        if exit == 1
            break;
        end
        WaitSecs(0.5);
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        Screen(window, 'Flip');
        WaitSecs(0.5);
    end % Trial loop
    
    numCorrect = sum(correct);
    text = sprintf('You got %.0f out of %.0f correct.\n\n[Press any key to finish]', numCorrect, numel(practiceStim));
    drawText(window, text);
    
catch ERROR
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    rethrow(ERROR)
end % Try
return