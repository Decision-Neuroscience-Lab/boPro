function drawOptions(params, trialLog)

if trialLog(end).choice == 1
    leftColour = [20 240 20];
    rightColour = [0 0 0];
elseif trialLog(end).choice == 2
    leftColour = [0 0 0];
    rightColour = [20 240 20];
else
    leftColour = [0 0 0];
    rightColour = [0 0 0];
end

window = params.window;
width = params.width;
height = params.height;
t = length(trialLog);

Screen('TextFont', window, 'Helvetica');
Screen('TextSize', window, 30);

Screen(window, 'FillRect', [128 128 128]); % Draw background
Screen('DrawLine', window, [0 0 0], width/2, height/2-(height/80), width/2, height/2+(height/80), 3); % Draw fixation cross
Screen('DrawLine', window, [0 0 0], width/2-(height/90), height/2, width/2+(height/80), height/2, 3);

switch params.text
    case 0 % If symbols
        SS = Screen('MakeTexture', window, params.ssTextures{params.presentation_list(t,1)});
        LL = Screen('MakeTexture', window, params.llTextures{params.presentation_list(t,2)});
        
        if trialLog(t).swapped == 0
            Screen('DrawTexture', window, SS, [], [params.leftup, params.leftdown]);
            Screen('DrawTexture', window, LL, [], [params.rightup, params.rightdown]);
            switch trialLog(end).choice
                case 1
                    Screen('FrameRect', window, [0 255 0], [params.leftup, params.leftdown], 5);
                case 2
                    Screen('FrameRect', window, [0 255 0], [params.rightup, params.rightdown], 5);
            end
        else
            Screen('DrawTexture', window, SS, [], [params.rightup, params.rightdown]);
            Screen('DrawTexture', window, LL, [], [params.leftup, params.leftdown]);
            switch trialLog(end).choice
                case 1
                    Screen('FrameRect', window, [0 255 0], [params.rightup, params.rightdown], 5);
                case 2
                    Screen('FrameRect', window, [0 255 0], [params.leftup, params.leftdown], 5);
            end
        end
    case 1 % If text
        % Transform volume to arbitrary units
        plsntfA = params.ml2plsnt(params.powerA,params.powerB,trialLog(t).fA)*10;
        plsntA = params.ml2plsnt(params.powerA,params.powerB,trialLog(t).A)*10;
        
        if params.transform == 1
            if round(plsntfA) == 100 % Fix plurality (disabled, set to 1 to enable)
                ss_option = sprintf('  %.1f drop\n\n%.0f seconds', plsntfA, trialLog(t).fD);
            else
                ss_option = sprintf(' %.1f drops\n\n%.0f seconds', plsntfA, trialLog(t).fD);
            end
            if round(plsntA) > 9 % Fix length of top line if reward is two digits
                ll_option = sprintf('%.1f drops\n\n%.0f seconds', plsntA, trialLog(t).D);
            elseif trialLog(t).D > 9 % Fix length of top line if delay is two digits
                ll_option = sprintf('  %.1f drops\n\n%.0f seconds', plsntA, trialLog(t).D);
            else
                ll_option = sprintf(' %.1f drops\n\n%.0f seconds', plsntA, trialLog(t).D);
            end
        else
            if round(trialLog(t).fA) == 100 % Fix plurality (disabled, set to 1 to enable)
                ss_option = sprintf('  %.1f drop\n\n%.0f seconds', trialLog(t).fA, trialLog(t).fD);
            else
                ss_option = sprintf(' %.1f drops\n\n%.0f seconds', trialLog(t).fA, trialLog(t).fD);
            end
            ll_option = sprintf(' %.1f drops\n\n%.0f seconds', trialLog(t).A, trialLog(t).D);
        end
        
        if trialLog(t).swapped == 0
            DrawFormattedText(window, ll_option, width*(2/3)-70, 'center',  rightColour, 35, 0, 0, 2);
            DrawFormattedText(window, ss_option, width*(1/3)-70, 'center',  leftColour, 35, 0, 0, 2);
        else
            DrawFormattedText(window, ll_option, width*(1/3)-70, 'center',  rightColour, 35, 0, 0, 2);
            DrawFormattedText(window, ss_option, width*(2/3)-70, 'center',  leftColour, 35, 0, 0, 2);
        end
end

return