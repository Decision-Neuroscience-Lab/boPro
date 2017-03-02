function practice(params)
try
    
    % Setup screen
    window = params.window;
    params.ifi = Screen('GetFlipInterval', window);
    Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Instructions
    Screen(window, 'FillRect', [128 128 128]);
    DrawFormattedText(window, 'An important aspect of this experiment is that the units of juice you will recieve are ''made up'' and do not match the volume perfectly (2 drops is not half the volume of 4 drops).\n\nTo give you an idea of what drops are like, here are a few practice amounts.\n\nPay attention as you will need to remember these amounts for the rest of the experiment.\n\n[Press any button to continue]', 'center', 'center',  [0 0 0], 100, 0, 0, 2);
    Screen(window, 'Flip');
    KbWait([], 2);
    
    %% Trial loop
    for t = 1:length(params.practice)
        
        % Ready signal
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        plsnt = params.ml2plsnt(params.powerA,params.powerB,params.practice(t))*10;
        if round(plsnt) == 1
            text = sprintf('This is %0.1f drop.\n\n[Press any button for delivery!]', plsnt);
        else
            text = sprintf('This is %0.1f drops.\n\n[Press any button for delivery!]', plsnt);     
        end
        drawText(window,text);
        
        % First squirt
        if params.testing == 1
            first = sprintf('%0.2f', params.practice(t));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, first, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        else
            pumpInf(params.pump, params.practice(t));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Juice dispensing...', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        end
        WaitSecs(params.drinktime);
        
    end % Trial loop
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
    
end % Try
return