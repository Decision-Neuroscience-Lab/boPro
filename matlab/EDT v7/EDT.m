function [data] = EDT
%% Initialisation
% Clear workspace
clear all
close all
clc

% Check and clear Java
% PsychJavaTrouble;

% Set random seed
% rng('shuffle');

% Request ID (as string)
disp('Hello, you are running the EDT.')
id = [];
while isempty(id)
    id = input('Enter participant ID: ');
end

% Query session
disp('Is this the bisection practice (1) or the EDT (2)?')
session = [];
while isempty(session)
    session = input('Enter session number: ');
end

datafilename = sprintf('%.0f_%.0f_%s_EDT.mat', id, session, datestr(now,'yyyymmddHHMMSS'));

% Setup pump
delete(instrfindall); % Make sure pump is not connected already
pump = pumpSetup;

% Set up screen
myScreen = max(Screen('Screens'));
Screen('Preference', 'SkipSyncTests', 0);
[window, winRect] = Screen(myScreen,'OpenWindow');
[width, height] = RectSize(winRect);
HideCursor;
ListenChar(2);

% Set font
Screen('TextFont', window, 'Helvetica');
Screen('TextSize', window, 30);

% Load parameters
[params] = EDT_config(window, width, height);
params.session = session;
params.pump = pump;

% Create new data file
data = {};
data.id = id;
data.session = session;
data.time = datestr(now,'yyyymmddHHMMSS');
data.startThirst = [];
data.endThirst = [];

%% Thirst rating scale
[~,data.startThirst,~] = sliderResponse(window,width,height,1:10,0,'Firstly, on a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]');

switch session
    case 1
        [params] = generateStimuli(params);
        [trialLog] = bisection(params);
    case 2
        [params] = generateStimuli(params);
        params.stimuli = shuffleDim(params.stimuli,1); % Shuffle stimuli
        [trialLog] = task(params);        
end

%% Thirst rating
[~,data.endThirst,~] = sliderResponse(window,width,height,1:10,0,'Finally, on a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]');

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

if session ~= 2
    % Close pump
    fclose(pump);
    delete(pump);
end

% Close PTB
ClosePTB;

if session == 3
    % Qualtrics
    url = 'https://fbeunimelb.asia.qualtrics.com/SE/?SID=SV_bHfIOCrNnFTJRtP';
    web(url,'-browser')
end 
return