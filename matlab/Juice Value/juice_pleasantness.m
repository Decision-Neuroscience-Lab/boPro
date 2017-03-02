function [data] = juice_pleasantness
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
choiceTime = 0; % Response window in seconds
scaleSize = 1:9; % Size of response scale
refills = 1; % This just sets the number of refills so we can keep track of syringe changes
testing = 0; % If testing is on, amounts will be displayed on screen instead of the syringe pump working
juice_exit = 0; % Catch variable for exiting the task
thirstScaleSize = 1:10;

%% Start task
startTime = GetSecs;

%% Thirst rating scale
[~,data.startThirst,~] = sliderResponse(window,width,height,thirstScaleSize,0,'Firstly, on a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?');

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
    
    %% Get response
    trialLog(t).choiceOnset = GetSecs - startTime;
    [trialLog(t).rt,trialLog(t).value,juice_exit] = sliderResponse(window,width,height,scaleSize,choiceTime,'How pleasant was that volume?');
  
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

%% Thirst rating
[~,data.endThirst,~] = sliderResponse(window,width,height,1:10,0,'Finally, on a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?');

%% Save data
data.trialLog = trialLog;
oldcd = cd;
cd(juiceValueLoc);
save(datafilename, 'data');
cd(oldcd);

clear trialLog

%% End experiment
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