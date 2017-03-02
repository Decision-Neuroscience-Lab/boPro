function [data] = TIRE
%% Initialisation
% Clear workspace
clear all
close all
clc

% Request ID (as string)
disp('Hello, you are about to start the TIRE task.')
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
datafilename = sprintf('%.0f_%s_TIRE.mat', id, datestr(now,'yyyymmddHHMMSS'));

% Create new data file
data = {};
data.id = id;
data.time = datestr(now,'yyyymmddHHMMSS');

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
[params] = TIRE_config(window, width, height);

%% Task instructions
drawbackground(window, width, height);
DrawFormattedText(window, 'Different volumes of juice will be delivered to you.\n\nPlease indicate how pleasant each volume is by selecting a number on the line, where ''1'' indicates ''not at all pleasant'' and ''9'' indicates ''completely pleasant''.\n\nUse the arrow buttons to move the cursor and the down arrow to select a number.\n\nPress any button to continue.', 'center', 'center',  [0 0 0], 70, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2);

%% Start task

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

%% Save data
data.trialLog = trialLog;
data.params = params;
oldcd = cd;
cd(params.dataDir);
save(datafilename, 'data');
cd(oldcd);

clear trialLog

%% End experiment
drawText(window,'Thank you! This component is complete.\n\nPlease see the experimenter.');

% Close PTB
ClosePTB;

return