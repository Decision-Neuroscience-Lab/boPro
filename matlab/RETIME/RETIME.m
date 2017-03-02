function [data] = RETIME
%% Initialisation

% Request ID (as string)
disp('Hello, you are about to start the RETIME task.')
id = [];
while isempty(id)
    id = input('Enter participant ID: ');
end

% Query session
disp('Which session is this?')
session = [];
while isempty(session)
    session = input('Enter session number: ');
end

% Setup data file
datafilename = sprintf('%.0f_%.0f_%s_RETIME.mat', id, session, datestr(now,'yyyymmddHHMMSS'));

% Load parameters
[params] = RETIME_config;

% Create new data file
data = {};
data.id = id;
data.time = datestr(now,'yyyymmddHHMMSS');
data.trialLog = [];

%% Task instructions
Screen(params.window, 'FillRect', [128 128 128]); % Draw background
DrawFormattedText(params.window, 'Foo.', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
Screen(params.window, 'Flip');
KbWait([], 2);

% Create trialLog data
trialLog(1:params.numTrials).swapBet = -1;
trialLog(1:params.numTrials).bet = -1;
trialLog(1:params.numTrials).betRT = -1;
trialLog(1:params.numTrials).standardFirst = -1;
trialLog(1:params.numTrials).standard = -1;
trialLog(1:params.numTrials).sample = -1;
trialLog(1:params.numTrials).choice = -1;
trialLog(1:params.numTrials).choiceRT = -1;

%% Start task
exit = 0;
for t = 1:params.numTrials % Trial loop
    %% Gamble
    % Present bet
    Screen(window, 'FillRect', [128 128 128]); % Draw background
    trialLog(t).swapBet = round(rand);
    switch trialLog(t).swapBet
        case 0
            Screen('FillArc',params.window, params.colours{1},[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
            Screen('FillArc',params.window, params.colours{2},[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
        case 1
            Screen('FillArc',params.window, params.colours{2},[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
            Screen('FillArc',params.window, params.colours{1},[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
    end
    betOnset = Screen(params.window, 'Flip');
    
    % Capture bet
    while KbCheck % Wait until all keys are released
    end
    % Check for response
    button_down = [];
    while GetSecs < betOnset + params.betTime
        [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
        if keyIsDown && isempty(button_down)
            trialLog(t).betRT = GetSecs - betOnset;
            if keyCode(params.escapekey) == 1
                exit = 1;
                break;
            elseif keyCode(params.leftkey) == 1
                trialLog(t).bet = 1;
                Screen('FillArc',params.window, params.colours{3},[(width/2)-210, (height/2)-30, (width/2)-150, (height/2)+30], 0, 360);
            elseif keyCode(params.rightkey) == 1
                trialLog(t).bet = 2;
                Screen('FillArc',params.window, params.colours{3},[(width/2)+150, (height/2)-30, (width/2)+210, (height/2)+30], 0, 360);
            end
            Screen('Flip', params.window);
            break; % Break out of response window
        end
    end
    
    % WaitSecs(params.postBetTime);
    WaitSecs((betOnset + params.betTime) - GetSecs); % Constant response window
    
    %% Bisection
    trialLog(t).standard = params.stimuli(t,1);
    trialLog(t).sample = params.stimuli(t,2);
    trialLog(t).standardFirst = params.stimuli(t,3);
    
    % Present first interval
    Screen(window, 'FillRect', [128 128 128]); % Draw background
    Screen('FillArc',params.window, params.colours{4},[(width/2)+30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
    firstIntOnset = Screen('Flip', params.window);
    
    % Present second interval
    Screen(params.window, 'FillRect', [128 128 128]); % Draw background
    Screen('FillArc',params.window, params.colours{4},[(width/2)+30, (height/2)-30, (width/2)+30, (height/2)+30], 0, 360);
    secondIntOnset = Screen('Flip', params.window, firstIntOnset + params.stimuli(t,1));
    
    % Present choice
    Screen(window, 'FillRect', [128 128 128]); % Draw background
    DrawFormattedText(params.window, 'Couldn''t tell', params.x0 - 30, 'center',  [0 0 0], 35, 0, 0, 2);
    DrawFormattedText(params.window, 'First', params.width*(1/3), 'center',  [0 0 0], 35, 0, 0, 2);
    DrawFormattedText(params.window, 'Second', params.width*(2/3), 'center',  [0 0 0], 35, 0, 0, 2);
    choiceOnset = Screen('Flip', params.window, secondIntOnset + params.stimuli(t,2));
    
    % Capture choice
    while KbCheck % Wait until all keys are released
    end
    % Check for response
    button_down = [];
    while GetSecs < choiceOnset + params.choiceTime
        [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
        if keyIsDown && isempty(button_down)
            trialLog(t).choiceRT = GetSecs - choiceOnset;
            if keyCode(params.escapekey) == 1
                exit = 1;
                break;
            elseif keyCode(params.leftkey) == 1
                trialLog(t).choice = 1;
                DrawFormattedText(params.window, 'First', params.width*(1/3), 'center',  params.colours{3}, 35, 0, 0, 2);
            elseif keyCode(params.rightkey) == 1
                trialLog(t).choice = 2;
                DrawFormattedText(params.window, 'Second', params.width*(2/3), 'center',  params.colours{3}, 35, 0, 0, 2);
            elseif keyCode(params.downkey) == 1
                trialLog(t).choice = 3;
                DrawFormattedText(params.window, 'Couldn''t tell', 'center', 'center',  params.colours{3}, 35, 0, 0, 2);
            end
            Screen('Flip', params.window);
            break; % Break out of response window
        end
    end
    
    % WaitSecs(params.postChoiceTime);
    WaitSecs((choiceOnset + params.choiceTime) - GetSecs); % Constant response window
   
end % Trial loop

%% Save data
data.trialLog = trialLog;
data.params = params;
oldcd = cd;
cd(params.dataDir);
save(datafilename, 'data');
cd(oldcd);

%% End experiment
Screen(params.window, 'FillRect', [128 128 128]); % Draw background
DrawFormattedText(params.window, 'Thank you! This component is complete.\n\nPlease see the experimenter.', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2);

% Close PTB
ShowCursor;
ListenChar(1);
Screen('CloseAll');

return