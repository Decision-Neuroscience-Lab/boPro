function [data] = juice_space

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
disp('Hello, you are about to explore juice space.')
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
juiceSpaceLoc = 'Q:\CODE\PROJECTS\TIMEJUICE\Juice Space\sessions';
datafilename = sprintf('%.0f_%.0f_%s_juicespace.mat', id, session, datestr(now,'yyyymmddHHMMSS'));
if session == 1 % Create new data file if first session
    data = {};
    data.id = id;
    data.time = datestr(now,'yyyymmddHHMMSS');
else % Load previous data file
    prev = session - 1;
    filename = sprintf('%s\\%.0f_%.0f*.mat', juiceSpaceLoc, id, prev);
    loadname = dir(filename);
    oldcd = cd(juiceSpaceLoc);
    load(loadname.name);
    cd(oldcd);
    % Check for correct file
    disp(loadname.name);
    disp('If this is correct press any key to continue.');
    KbWait([], 2);
end

% Choose cedrus / keyboard
cedrus = [];
while isempty(cedrus)
    cedrus = input('Are you using the Cedrus button box? ');
end
if cedrus
    [~, ~, h] = cedrus_setup;
end

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

%% Setup QUEST, Psi and other parameters
% Other parameters
anchors = [0.5, 3]; % Juice anchor volumes (discrimination thresholds may be non-linear)
sequence = debruijn_generator(length(anchors), 5); % Create de Bruijn counterbalance sequence
sequence = anchors(sequence);
numTrials = length(sequence); % Number of total trials for this session, note that the first 3 trials are PRACTICE TRIALS
practiceDelta = [2, 1];
% juiceTime = 3; % Countdown to juice delivery
drinkTime = 6 ; % Consumption window
choiceTime = 3; % Response window in seconds
refills = 1; % This just sets the number of refills so we can keep track of syringe changes
testing = 0; % If testing is on, amounts will be displayed on screen instead of the syringe pump working
numPractice = numel(practiceDelta); % Number of practice trials (will not update Quest)

% QUEST
threshold = 75;
estimate = 1.5; % Estimated discriminability at thresholds

sd_guess = 0.5; % Standard deviation of the threshold guess given by estimated_threshold
beta = 3.5; % The steepness of the implicit psychometric function - 3.5 is the default
delta = .01; % Proportion of 'random responses' - default is .01 (1%) but I think this might be a little low for the present task
gamma = .5; % Gamma is the proportion of responses that will be correct when the difference is zero, i.e. the chance-rate
range = 5; % Important to restrict range!
grain = 1; % Step size

% Psi parameters (are default if not specified)
stimRange = [0.05:0.05:4];

%% Start task
% Create structure for each anchor in both QUEST and Psi
if session == 1 % Create new structures if first session
    for a = 1:length(anchors)
        q(a) = QuestCreate(estimate, sd_guess, threshold/100, beta, delta, gamma, grain, range);
        PM(a) = PAL_AMPM_setupPM('stimRange', stimRange);
    end
else % Load previous structures
    for a = 1:length(anchors)
        q(a) = data.trialLog(end).q(a);
        PM(a) = data.trialLog(end).PM(a);
    end
end

% Ready signal
drawbackground(window, width, height);
DrawFormattedText(window, 'Are you ready?\nPress any button to start.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2);

for t = 1:numTrials % Trial loop
    
    trialLog(t).anchor = sequence(t); % Record anchor volume
    
    %% Present juice
    % Randomise presentation order
    trialLog(t).anchorFirst = round(rand(1));
    
    % Get reccomendation and modify
    if t <= numPractice
        juiceDelta = practiceDelta(t);
    else
        for a = 1:length(anchors)
            if trialLog(t).anchor == anchors(a)
                juiceDelta = PM(a).xCurrent;
            end
        end
    end
    trialLog(t).sample = trialLog(t).anchor + juiceDelta;
    
    % Make sure sample is within bounds
    if trialLog(t).sample < trialLog(t).anchor
        trialLog(t).sample = trialLog(t).anchor;
    end
    if trialLog(t).sample > 7
        trialLog(t).sample = 7;
    end
    
    % Total juice count
    if t == 1
        trialLog(t).totalvolume = trialLog(t).anchor + trialLog(t).sample;
    else
        trialLog(t).totalvolume = trialLog(t-1).totalvolume + trialLog(t).anchor + trialLog(t).sample;
    end
    
    % Ready signal
    drawbackground(window, width, height);
    DrawFormattedText(window, 'Press a button for juice!', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
    Screen(window, 'Flip');
    KbWait([], 2);
    
    %WaitSecs(juiceTime);
    
    % First squirt
    drawbackground(window, width, height);
    DrawFormattedText(window, 'First squirt!', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
    Screen(window, 'Flip');
    switch trialLog(t).anchorFirst
        case 0
            if testing == 1
                first = sprintf('%05.3f', trialLog(t).sample);
                drawbackground(window, width, height);
                DrawFormattedText(window, first, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
                Screen(window, 'Flip');
            else
                squirtMaker(pump, trialLog(t).sample);
            end
        case 1
            if testing == 1
                first = sprintf('%05.3f', trialLog(t).anchor);
                drawbackground(window, width, height);
                DrawFormattedText(window, first, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
                Screen(window, 'Flip');
            else
                squirtMaker(pump, trialLog(t).anchor);
            end
    end
    WaitSecs(drinkTime);
    clear first
    
    % Second squirt
    drawbackground(window, width, height);
    DrawFormattedText(window, 'Second squirt!', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
    Screen(window, 'Flip');
    switch trialLog(t).anchorFirst
        case 0
            if testing == 1
                second = sprintf('%05.3f', trialLog(t).anchor);
                drawbackground(window, width, height);
                DrawFormattedText(window, second, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
                Screen(window, 'Flip');
            else
                squirtMaker(pump, trialLog(t).anchor);
            end
        case 1
            if testing == 1
                second = sprintf('%05.3f', trialLog(t).sample);
                drawbackground(window, width, height);
                DrawFormattedText(window, second, 'center', 'center',  [0 255 0], 35, 0, 0, 2);
                Screen(window, 'Flip');
            else
                squirtMaker(pump, trialLog(t).sample);
            end
    end
    WaitSecs(drinkTime);
    clear second
    
    %% Get response
    
    trialLog(t).choice = -1;
    
    drawbackground(window, width, height);
    drawFixationColour(window,width, height, [0 0 255]);
    DrawFormattedText(window, 'Which squirt was larger?', 'center', height/3,  [0 0 0], 35, 0, 0, 2);
    
    % Randomise presentation side and draw options
    trialLog(t).swapped = round(rand(1));
    
    switch trialLog(t).swapped == 1
        case 0
            DrawFormattedText(window, 'First', width*(1/3)-30, 'center',  [0 0 0], 35, 0, 0, 2);
            DrawFormattedText(window, 'Second', width*(2/3)-30, 'center',  [0 0 0], 35, 0, 0, 2);
        case 1
            DrawFormattedText(window, 'Second', width*(1/3)-30, 'center',  [0 0 0], 35, 0, 0, 2);
            DrawFormattedText(window, 'First', width*(2/3)-30, 'center',  [0 0 0], 35, 0, 0, 2);
    end
    
    onset = Screen(window, 'Flip'); % Record onset time
    trialLog(t).choiceOnset = onset;
    trialLog(t).rt = -1;
    
    if ~cedrus  % If using keyboard
        % Wait until all keys are released
        while KbCheck
        end
        % Check for response
        button_down = [];
        while GetSecs < (onset + choiceTime)
            [ keyIsDown, ~, keyCode, ~ ] = KbCheck;
            if keyIsDown && isempty(button_down)
                button_down = GetSecs;
                trialLog(t).rt = button_down - onset;
                drawFixationColour(window, width, height, [0 0 200]);
                Screen(window,'Flip');
                switch trialLog(t).swapped
                    case 0
                        if keyCode(leftkey) == 1 % In case first
                            trialLog(t).choice = 1;
                        elseif keyCode(rightkey) == 1 % In case second
                            trialLog(t).choice = 2;
                        end
                    case 1
                        if keyCode(rightkey) == 1 % In case first
                            trialLog(t).choice = 1;
                        elseif keyCode(leftkey) == 1 % In case second
                            trialLog(t).choice = 2;
                        end
                end % Swapped switch
                break;
            end
        end
        
    else % If using Cedrus
        % Wait for buttons to be released
        buttons = 1;
        while any(buttons(1,:))
            buttons = CedrusResponseBox('FlushEvents', h);
        end
        
        % Check for response
        button_down = [];
        while GetSecs < (onset + choiceTime)
            responseContainer = CedrusResponseBox('GetButtons', h);
            if ~isempty(responseContainer) && isempty(button_down)
                button_down = GetSecs;
                trialLog(t).rt = button_down - onset;
                drawFixationColour(window, width, height, [0 0 200]);
                Screen(window,'Flip');
                switch trialLog(t).swapped
                    case 0
                        switch responseContainer.buttonID
                            case 'left' % In case first
                                trialLog(t).choice = 1;
                            case 'right' % In case second
                                trialLog(t).choice = 2;
                        end
                    case 1
                        switch responseContainer.buttonID
                            case 'right' % In case first
                                trialLog(t).choice = 1;
                            case 'left' % In case second
                                trialLog(t).choice = 2;
                        end
                end % Swapped switch
                break;
            end
        end
        
    end
    % Make sure response window is consistent
    while GetSecs < (onset + choiceTime);
    end
    
    %% Record data
    % Check response and update Quest and Psi
    correct = 0;
    trialLog(t).correct = 0;
    if trialLog(t).choice ~= -1 % If not missed
        switch trialLog(t).anchorFirst
            case 0 % If sample was first
                if trialLog(t).choice == 1 % Correct if first
                    correct = 1;
                    trialLog(t).correct = 1;
                end
            case 1 % If sample was second
                if trialLog(t).choice == 2 % Correct if second
                    correct = 1;
                    trialLog(t).correct = 1;
                end
        end
        if t > numPractice % Don't update for practice trials
            for a = 1:length(anchors)
                if trialLog(t).anchor == anchors(a)
                    q(a) = QuestUpdate(q(a), juiceDelta, correct); % Update Quest
                    PM(a) = PAL_AMPM_updatePM(PM(a), correct); % Update Psi
                end
            end
        end
    end
    trialLog(t).q = q;
    trialLog(t).PM = PM;
    
    %% Check to see if pump is empty
    if trialLog(t).totalvolume > refills * 260
        drawbackground(window, width, height);
        DrawFormattedText(window, 'Syringes are out of juice.\nPlease see the experimenter so they can be refilled.', 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        Screen(window, 'Flip');
        
        % Backup data in case of quit
        data.trialLog = trialLog;
        oldcd = cd;
        cd(juiceSpaceLoc);
        save(datafilename, 'data');
        cd(oldcd);
        
        KbWait([], 2)
        refills = refills + 1;
    end
    
end % Trial loop

% Save data
data.trialLog = trialLog;
oldcd = cd;
cd(juiceSpaceLoc);
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