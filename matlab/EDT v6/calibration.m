function [trialLog] = calibration(params)
try
    
    % Setup screen
    window = params.window;
    width = params.width;
    height = params.height;
    params.ifi = Screen('GetFlipInterval', window);
    Screen('TextFont', window, 'Helvetica');
    Screen('TextSize', window, 30);
    
    % Instructions
    drawText(window, 'In each trial you will be given a choice between 2 options, each with an amount of juice and a delay. Choose the option that you prefer by pressing the left or right arrow.\n\nYou will have to wait for the appropriate amount of time before the juice is delivered.\n\n[Press any button to continue]');
    drawText(window, 'Because the task duration is fixed, the delay associated with each choice can be viewed as a cost - each choice you make will be trading off time for juice.\n\n[Press any button to start]');
    
    % Setup QUEST and Psi
    if params.adaptiveSC
        % QUEST
        threshold = 85;
        estimate = 0.8; % Estimated discriminability at thresholds
        
        sd_guess = 1.5; % Standard deviation of the threshold guess given by estimated_threshold
        beta = 3.5; % The steepness of the implicit psychometric function - 3.5 is the default
        delta = .01; % Proportion of 'random responses' - default is .01 (1%) but I think this might be a little low for the present task
        gamma = 0; % Gamma is the proportion of responses that will be correct when the difference is zero, i.e. the chance-rate
        range = 10; % Important to restrict range!
        grain = 0.1; % Step size
        
        % Psi parameters (are default if not specified)
        stimRange = [0.1:0.1:5];
        
        % Create structure for each delay in both QUEST and Psi
        for d = 1:length(params.D)
            q(d) = QuestCreate(estimate, sd_guess, threshold/100, beta, delta, gamma, grain, range);
            PM(d) = PAL_AMPM_setupPM('stimRange', stimRange);
        end
    end
    
    %% Trial loop
    refills = 1;
    exit = 0;
    for t = 1:params.numTrials
        
        % Break every 20 trials
        if mod(t,20) == 0;
            drawText(window,'Take a break.\nPress any button to proceed.');
        end
        
        % Setup data
        trialLog(t).A = params.stimuli(t,1);
        trialLog(t).fA = params.stimuli(t,2);
        trialLog(t).D = params.stimuli(t,3);
        trialLog(t).fD = params.stimuli(t,4);
        trialLog(t).delay = [trialLog(t).fD, trialLog(t).D, trialLog(t).fD];
        trialLog(t).amount = [trialLog(t).fA, trialLog(t).A, 0];
        trialLog(t).choice = 3; % 3 if missed
        trialLog(t).rt = -1; % -1 if missed
        
        if params.adaptiveSC
            % Get reccomendation and modify
            for d = 1:length(params.D)
                if trialLog(t).D == params.D(d)
                    trialLog(t).fA = PM(d).xCurrent;
                    trialLog(t).amount = [trialLog(t).fA, trialLog(t).A, 0];
                end
            end
        end
        
        % Randomise presentation side
        if rand < 0.5
            trialLog(t).swapped = 0;
        else
            trialLog(t).swapped = 1;
        end
        
        % Present options
        drawOptions(params,trialLog);
        onset = Screen(window, 'Flip');
        
        %% Capture response
        
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while GetSecs < (onset + params.choicetime)
            [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                button_down = GetSecs;
                trialLog(t).rt = button_down - onset;
                if keyCode(params.escapekey) == 1
                    exit = 1;
                    break;
                end
                switch trialLog(t).swapped
                    case 0
                        if keyCode(params.leftkey) == 1 % In case SS
                            trialLog(t).choice = 1;
                            position = 1;
                        elseif keyCode(params.rightkey) == 1 % In case LL
                            trialLog(t).choice = 2;
                            position = 2;
                        end
                    case 1
                        if keyCode(params.rightkey) == 1 % In case SS
                            trialLog(t).choice = 1;
                            position = 2;
                        elseif keyCode(params.leftkey) == 1 % In case LL
                            trialLog(t).choice = 2;
                            position = 1;
                        end
                end % Swapped switch
                if trialLog(t).choice ~= 3
                    drawOptions(params,trialLog);
                    Screen(window,'Flip');
                end
                break;
            end
        end
        
        % Make sure response window is consistent
        %         while GetSecs < (onset + params.choicetime);
        %         end
        WaitSecs(0.5);
        
        % Record remaining response window time to add to post-reward
        % buffer
        extraTime = 0;
        if trialLog(t).choice ~= 3
            extraTime = params.choicetime - trialLog(t).rt;
        end
        
        %% Delay
        
        % Build delay stimulus
        Screen(window, 'FillRect', [128 128 128]); % Draw background
        oldSize = Screen('TextSize', window, 40);
        DrawFormattedText(window, '...', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
        Screen('TextSize', window, oldSize);
        delay_onset = Screen(window, 'Flip');
        
        % Time delay
        while GetSecs < (delay_onset + trialLog(t).delay(trialLog(t).choice));
        end
        
        %% Reward delivery
        if params.testing == 1
            text = sprintf('%05.3f', trialLog(t).amount(trialLog(t).choice));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, text, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        elseif trialLog(t).choice == 3
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'You missed the choice! Please try and respond next time.', 'center', 'center',  [0 255 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        else
            pumpInf(params.pump, trialLog(t).amount(trialLog(t).choice));
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Juice dispensing...', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
        end
        
        % Total juice count
        if t == 1
            trialLog(t).totalvolume = trialLog(t).amount(trialLog(t).choice);
        else
            trialLog(t).totalvolume = trialLog(t-1).totalvolume + trialLog(t).amount(trialLog(t).choice);
        end
        
        if params.adaptiveSC
            if trialLog(t).choice == 1 % Change choice to 'correct' for SC
                correct = 1;
            else
                correct = 0;
            end
            for d = 1:length(params.D)
                if trialLog(t).D == params.D(d)
                    if t > 9
                        q(d) = QuestUpdate(q(d), trialLog(t).fA, correct); % Update Quest
                    end
                    PM(d) = PAL_AMPM_updatePM(PM(d), correct); % Update Psi
                end
            end
        end
        %% Check to see if pump is empty
        if trialLog(t).totalvolume > refills * 260 && ~params.testing
            pumpWit(params.pump, 8);
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Syringes are out of juice.\nPlease see the experimenter so they can be refilled.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
            
            % Backup data in case of quit
            oldcd = cd;
            cd(params.dataDir);
            data.trialLog = trialLog;
            data.params = params;
            save('recoveredData', 'data');
            cd(oldcd);
            
            KbWait([], 2)
            
            % Prompt refill and trigger pump withdrawal
            Screen(window, 'FillRect', [128 128 128]); % Draw background
            DrawFormattedText(window, 'Ready to fill? Press down arrow to refill via withdrawal (remember to press a button to stop). Press escape once finished.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
            Screen(window, 'Flip');
            
            response = [];
            while isempty(response)
                [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
                if keyIsDown && isempty(button_down)
                    if keyCode(params.escapekey) == 1
                        exit = 1;
                        break;
                    elseif keyCode(params.downkey) == 1
                        pumpRefill(params.pump);
                    end
                end
            end
            
            refills = refills + 1;
        end
        
        if exit == 1
            break;
        end
        
        WaitSecs(params.drinktime + extraTime); % Modified ITI (extra response window time)
    end % Trial loop
    
    if params.adaptiveSC
        trialLog(end).PM = PM;
        trialLog(end).q = q;
    end
    
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
    save('recoveredData', 'data');
    cd(oldcd);
    
end % Try
return