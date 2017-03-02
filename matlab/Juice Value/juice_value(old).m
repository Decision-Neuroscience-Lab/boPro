function [data] = juice_value(old)
%% Initialisation
% Clear workspace
clear all
close all
clc

% Check and clear Java
PsychJavaTrouble;
% jheapcl;

% Set random seed
% rng('shuffle');

% Request ID (as string)
disp('Hello, you are about to explore juice value.')
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
juiceValueLoc = 'Q:\CODE\PROJECTS\TIMEJUICE\Juice Value\data';
datafilename = sprintf('%.0f_%.0f_%s_juicevalue.mat', id, session, datestr(now,'yyyymmddHHMMSS'));
% Create new data file
data = {};
data.id = id;
data.session = session;
data.time = datestr(now,'yyyymmddHHMMSS');
data.startThirst = [];
data.endThirst = [];

% Setup pump
delete(instrfindall); % Make sure pump is not connected already
pump = squirtSetup;

% Set up screen
myScreen = max(Screen('Screens'));
Screen('Preference', 'SkipSyncTests', 0);
[window, winRect] = Screen(myScreen,'OpenWindow');
[width, height] = RectSize(winRect);
HideCursor;
ListenChar(2);

% Set font
Screen('TextFont', window, 'Helvetica');
Screen('TextSize', window, 25);

% Set keyboard
KbName('UnifyKeyNames');
leftkey = KbName('LeftArrow');
rightkey = KbName('RightArrow');
downkey = KbName('DownArrow');
escapekey = KbName('ESCAPE');

%% Setup parameters
% Other parameters
WF = 0.5; % Weber Fraction - this dictates the differences (based on discriminiability) between each volume, 0.5 is conservative to allow slightly more discriminability
numVolumes = 4; % Number of volumes we want to test
minVolume = 0.5; % The smallest volume (starting point)
sequence = debruijn_generator(numVolumes, 3); % Create de Bruijn counterbalance sequence
volumes = zeros(1, numVolumes);
volumes(1) = minVolume;
for x = 2:numVolumes
    volumes(x) = volumes(x-1) + (volumes(x-1)*(WF*2)); % This adds 2*JND amounts to each volume to determine the next
end
stimuli = volumes(sequence); % Build stimuli based on dB sequence
stimuli = cat(2,stimuli,stimuli); % We only have half the total volume - double it
numTrials = length(stimuli); % Number of total trials for this session
% juiceTime = 3; % Countdown to juice delivery
drinkTime = 6 ; % Consumption window
choiceTime = 7; % Response window in seconds
scaleSize = 9; % Size of response scale
refills = 1; % This just sets the number of refills so we can keep track of syringe changes
testing = 1; % If testing is on, amounts will be displayed on screen instead of the syringe pump working
juice_exit = 0; % Catch variable for exiting the task
thirstScaleSize = 11;

%% Start task

startTime = GetSecs;

%% Thirst rating scale

thirst = (thirstScaleSize + 1)/2;
y = (width/2);

while isempty(data.startThirst)
    
    right_down = 0;
    left_down = 0;
    
    % Draw text
    drawbackground(window, width, height);
    Screen('TextSize',window, 25);
    DrawFormattedText(window, 'Firstly, on a scale of ''0'' to ''10'', where ''0'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?', 'center', height/4,  [0 0 0], 70, 0, 0, 2);
    % Draw slider
    bar_width = 0.7 * width;
    Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
    % Draw markers
    markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), thirstScaleSize);
    markers_top = (height/2) - 10;
    markers_bottom = (height/2) + 10;
    for l = 1:length(markers_x)
        Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
    end
    % Draw numbers
    num = 0;
    for n = 1:length(markers_x)
        number = sprintf('%0.f', num);
        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
        num = num + 1;
        clear number
    end
    % Draw line
    line_x = y;
    line_top = (height/2) + 15;
    line_bottom = (height/2) - 15;
    Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
    Screen(window, 'Flip');
    
    % Wait for input
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
        % Draw text
        drawbackground(window, width, height);
        Screen('TextSize',window, 25);
        DrawFormattedText(window, 'Firstly, on a scale of ''0'' to ''10'', where ''0'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?', 'center', height/4,  [0 0 0], 70, 0, 0, 2);
        % Draw slider
        bar_width = 0.7 * width;
        Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
        % Draw markers
        markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), thirstScaleSize);
        markers_top = (height/2) - 10;
        markers_bottom = (height/2) + 10;
        for l = 1:length(markers_x)
            Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
        end
        % Draw numbers
        num = 0;
        for n = 1:length(markers_x)
            number = sprintf('%0.f', num);
            if thirst == n
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 255, 0]);
            else
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
            end
            num = num + 1;
            clear number
        end
        % Draw line
        line_x = y;
        line_top = (height/2) + 15;
        line_bottom = (height/2) - 15;
        Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
        Screen(window, 'Flip');
        WaitSecs(0.5);
        
        data.startThirst = thirst; % Record answer
        break;
    end
    
    if keyIsDown && keyCode(escapekey) == 1
        juice_exit = 1;
        break;
    end
    
    % Adjust cursor position
    if left_down && thirst ~= 1
        thirst = thirst - 1;
        y = markers_x(thirst);
    elseif right_down && thirst ~= max(thirstScaleSize)
        thirst = thirst + 1;
        y = markers_x(thirst);
    end
    WaitSecs(0.005);
    
end % Response window

%% Task instructions
drawbackground(window, width, height);
DrawFormattedText(window, 'Different volumes of juice will be delivered to you.\n\nPlease indicate how pleasant each volume is by selecting a number on the line, where ''1'' indicates ''not at all pleasant'' and ''9'' indicates ''completely pleasant''.\n\nUse the arrow buttons to move the cursor and the down arrow to select a number.\n\nPress any button to continue.', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2);

drawbackground(window, width, height);
DrawFormattedText(window, 'If the juice becomes completely unpleasant, press the escape key to exit when the slider appears.\n\nPress any button to continue.', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2);

for t = 1:numTrials % Trial loop
    
    trialLog(t).volume = stimuli(t); % Record anchor volume
    
    %% Present juice
    
    % Total juice count
    if t == 1
        trialLog(t).totalvolume = trialLog(t).volume;
    else
        trialLog(t).totalvolume = trialLog(t-1).totalvolume + trialLog(t).volume;
    end
    
    % Ready signal
    drawbackground(window, width, height);
    DrawFormattedText(window, 'Press a button for juice!', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
    Screen(window, 'Flip');
    KbWait([], 2);
    
    %WaitSecs(juiceTime);
    
    % First squirt
    if testing == 1
        first = sprintf('%05.3f', trialLog(t).volume);
        drawbackground(window, width, height);
        DrawFormattedText(window, first, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
        Screen(window, 'Flip');
    else
        squirtMaker(pump, trialLog(t).volume);
    end
    
    WaitSecs(drinkTime);
    clear first
    
    %% Get response
    
    value = (scaleSize + 1)/2;
    y = (width/2);
    onset = GetSecs; % Record onset time
    trialLog(t).choiceOnset = onset - startTime;
    trialLog(t).rt = -1;
    
    while GetSecs < (onset + choiceTime) % Response window
        right_down = 0;
        left_down = 0;
        
        % Draw text
        drawbackground(window, width, height);
        Screen('TextSize',window, 25);
        DrawFormattedText(window, 'How pleasant was that volume?', 'center', height/3,  [0 0 0], 35);
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
        for n = 1:length(markers_x)
            number = sprintf('%0.f', n);
            Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
            clear number
        end
        % Draw line
        line_x = y;
        line_top = (height/2) + 15;
        line_bottom = (height/2) - 15;
        Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
        Screen(window, 'Flip');
        
        % Wait for input
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
            trialLog(t).rt = GetSecs - onset;
            % Draw text
            drawbackground(window, width, height);
            Screen('TextSize',window, 25);
            DrawFormattedText(window, 'How pleasant was that volume?', 'center', height/3,  [0 0 0], 35);
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
            for n = 1:length(markers_x)
                number = sprintf('%0.f', n);
                if value == n
                    Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 255, 0]);
                else
                    Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
                end
                clear number
            end
            % Draw line
            line_x = y;
            line_top = (height/2) + 15;
            line_bottom = (height/2) - 15;
            Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
            Screen(window, 'Flip');
            WaitSecs(0.5);
            break;
        end
        
        if keyIsDown && keyCode(escapekey) == 1
            juice_exit = 1;
            break;
        end
        
        % Adjust cursor position
        if left_down && value ~= 1
            value = value - 1;
            y = markers_x(value);
        elseif right_down && value ~= max(scaleSize)
            value = value + 1;
            y = markers_x(value);
        end
        WaitSecs(0.005);
        
    end % Response window
    trialLog(t).slider = y - 960;
    trialLog(t).value = value;
    
    %% Keypad
    
    %         % Wait until all keys are released
    %         while KbCheck
    %         end
    %         % Check for response
    %         button_down = [];
    %         while GetSecs < (onset + choiceTime)
    %             [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
    %             if keyIsDown && isempty(button_down)
    %                 button_down = GetSecs;
    %                 trialLog(t).rt = button_down - onset;
    %                 trialLog(t).value = KbName(keyCode);
    %                 value = trialLog(t).value;
    %                 drawbackground(window, width, height);
    %                 DrawFormattedText(window, value, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
    %                 Screen(window, 'Flip');
    %                 break;
    %             end
    %         end
    %
    %     % Make sure response window is consistent
    %     while GetSecs < (onset + choiceTime);
    %     end
    
    %% Check to see if pump is empty
    if trialLog(t).totalvolume > refills * 260 && ~testing
        squirtRetreat(pump, 8);
        drawbackground(window, width, height);
        DrawFormattedText(window, 'Syringes are out of juice.\nPlease see the experimenter so they can be refilled.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        Screen(window, 'Flip');
        
        % Backup data in case of quit
        data.trialLog = trialLog;
        oldcd = cd;
        cd(juiceValueLoc);
        save(datafilename, 'data');
        cd(oldcd);
        
        KbWait([], 2)
        refills = refills + 1;
    end
    
    if juice_exit == 1
        break;
    end
    
end % Trial loop

%% Thirst rating scale

thirst = (thirstScaleSize + 1)/2;
y = (width/2);

while isempty(data.endThirst)
    
    right_down = 0;
    left_down = 0;
    
    % Draw text
    drawbackground(window, width, height);
    Screen('TextSize',window, 25);
    DrawFormattedText(window, 'Finally, on a scale of ''0'' to ''10'', where ''0'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?', 'center', height/4,  [0 0 0], 70, 0, 0, 2);
    % Draw slider
    bar_width = 0.7 * width;
    Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
    % Draw markers
    markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), thirstScaleSize);
    markers_top = (height/2) - 10;
    markers_bottom = (height/2) + 10;
    for l = 1:length(markers_x)
        Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
    end
    % Draw numbers
    num = 0;
    for n = 1:length(markers_x)
        number = sprintf('%0.f', num);
        Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
        num = num + 1;
        clear number
    end
    % Draw line
    line_x = y;
    line_top = (height/2) + 15;
    line_bottom = (height/2) - 15;
    Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
    Screen(window, 'Flip');
    
    % Wait for input
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
        % Draw text
        drawbackground(window, width, height);
        Screen('TextSize',window, 25);
        DrawFormattedText(window, 'Finally, on a scale of ''0'' to ''10'', where ''0'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?', 'center', height/4,  [0 0 0], 70, 0, 0, 2);
        % Draw slider
        bar_width = 0.7 * width;
        Screen('DrawLine', window, [0, 0, 0], (width/2) - (bar_width/2), (height/2), (width/2) + (bar_width/2), (height/2) );
        % Draw markers
        markers_x = linspace((width/2) - (bar_width/2), (width/2) + (bar_width/2), thirstScaleSize);
        markers_top = (height/2) - 10;
        markers_bottom = (height/2) + 10;
        for l = 1:length(markers_x)
            Screen('DrawLine', window, [0, 0, 0], markers_x(l), markers_top, markers_x(l), markers_bottom, 1);
        end
        % Draw numbers
        num = 0;
        for n = 1:length(markers_x)
            number = sprintf('%0.f', num);
            if thirst == n
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 255, 0]);
            else
                Screen('DrawText', window, number, markers_x(n) - 10, (height/2) + 60, [0, 0, 0]);
            end
            num = num + 1;
            clear number
        end
        % Draw line
        line_x = y;
        line_top = (height/2) + 15;
        line_bottom = (height/2) - 15;
        Screen('DrawLine', window, [20, 20, 200], line_x, line_top, line_x, line_bottom, 3 );
        Screen(window, 'Flip');
        WaitSecs(0.5);
        
        data.endThirst = thirst; % Record answer
        break;
    end
    
    % Adjust cursor position
    if left_down && thirst ~= 1
        thirst = thirst - 1;
        y = markers_x(thirst);
    elseif right_down && thirst ~= max(thirstScaleSize)
        thirst = thirst + 1;
        y = markers_x(thirst);
    end
    WaitSecs(0.005);
    
end % Response window

%% Save data
data.trialLog = trialLog;
oldcd = cd;
cd(juiceValueLoc);
save(datafilename, 'data');
cd(oldcd);

clear trialLog

% End experiment
thank_you(window, width, height);

% Withdraw pump
if ~testing
    squirtRetreat(pump, 8);
end

% Close PTB
ClosePTB;

% Close pump
fclose(pump);
delete(pump);

return