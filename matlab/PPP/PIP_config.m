function [params] = PIP_config
%% Global parameters
params.dataDir = 'C:\Users\DLAB\Documents\MATLAB\PPP\data';
params.testing = 0;
params.startTrial = 1;
params.choicetime = 3;
params.drinktime = 4;
params.iti = 2;
params.totalvolume = [];

KbName('UnifyKeyNames');
params.leftkey = KbName('LeftArrow');
params.rightkey = KbName('RightArrow');
params.downkey = KbName('DownArrow');
params.escapekey = KbName('ESCAPE');

%% Variable parameters
params.A = [0.05 0.7 1.4 2.8];%[0.05 0.5 1.2 2.3];
params.D = [4 6 8 10];
params.colours = {[0 60 100], [0 113.985 188.955], [0 153 255], [160 210 255]};
params.numRepeats = 8;

params.thirstText = ['This question is about THIRST.\n\nOn a scale of ''1'' to ''10'', '...
    'where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', '...
    'how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]'];

params.pleasantnessText = ['This question is about PLEASANTNESS.\n\nOn a scale of ''1'' to ''10'', '...
    'where ''1'' indicates ''very unpleasant'', and ''10'' indicates ''very pleasant'', '...
    'how pleasant are you finding the liquid?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]'];

params.mainInstructions = ['In the next task you will be presented with a colour that represents a reward amount '...
    'and the time to the delivery of the reward (e.g. "4 seconds").'...
    '\n\nPress the down arrow when you think half the interval (e.g. 2 seconds) has elapsed, before the liquid is delivered. '...
    'In other words, try to divide the interval in half.\n\n[Press any button to start]'];

params.practiceInstructions = ['In this next section there are four different colours '...
    'that represent different rewards sizes.'...
    '\n\nEach colour will be shown to you. Press any button to dispense the liquid associated with that colour.'...
    '\n\n[Press any button to start]'];
    
params.baselineInstructions = ['The next task is a short test without liquid (you can put the mouthpeice down).'...
'\n\nYou will be presented with an interval (e.g. "4 seconds") which starts immediately when the cross appears.'...
'\n\nPlease press the down arrow when you think half the interval (e.g. 2 seconds) has elapsed. '...
'In other words, try to divide the interval in half.\n\n[Press any button to start]'];
%% Setup pump and parallel port
if params.testing ~= 1
    % Setup pump
    delete(instrfindall); % Make sure pump is not connected already
    pump = pumpSetup;
    params.pump = pump;
    
    % Open parallel port and test
    params.ioObj = io32;
    status = io32(params.ioObj);
    if status
        error('Cannot initialise io32.\n');
    end
    params.address = hex2dec('e010'); % Standard LPT1 output port address (0x378)
    io32(params.ioObj,params.address,0); % Send a 0 to reset
else
    params.address = -1;
end

%% Initialise PTB and Screen parameters
AssertOpenGL; % Check graphics library is compatible with this version of Psychtoolbox
params.PTB.myScreen = max(Screen('Screens')); % Get max screen number (if there is an external monitor, use that)
Screen('Preference', 'SkipSyncTests', 0); % Set test preferences (0 is normal, 1 is short, 2 is skip completely)
[params.window,params.PTB.dimensions] = Screen(params.PTB.myScreen,'OpenWindow',[],[],[],[],[],8); % Open a new screen and set multisampling to 8 for anti-aliasing
[params.width, params.height] = RectSize(params.PTB.dimensions); % Get screen dimensions
params.x0 = params.width/2;
params.y0 = params.height/2;
params.PTB.FlipInterval = Screen('GetFlipInterval',params.window); % Get Flip Interval
params.PTB.slack = params.PTB.FlipInterval/2;
params.PTB.MonitorFrequency = round(1/params.PTB.FlipInterval);
if params.PTB.myScreen < 1 % Hide mouse and turn off keyboard if there is no external monitor
HideCursor;
ListenChar(2);
end
Screen(params.window,'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Set the blend function
Screen('TextFont', params.window, 'Helvetica'); % Set font
Screen('TextSize', params.window, 30);

%% Positions

rect = 190;
params.leftup = [params.width*(1/3) params.y0-(rect/2)-20];
params.leftdown = [params.width*(1/3)+rect params.y0+(rect/2)];
params.leftpos = [params.leftup, params.leftdown];
params.rightup = [params.width*(2/3)-rect params.y0-(rect/2)-20];
params.rightdown = [params.width*(2/3), params.y0+(rect/2)];
params.rightpos = [params.rightup, params.rightdown];
params.pos = {params.leftpos, params.rightpos};

return