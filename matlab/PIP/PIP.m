function [data] = PIP
%% Initialisation

% Request ID (as string)
disp('Hello, you are running the PIP.')
id = [];
while isempty(id)
    id = input('Enter participant ID: ');
end

% Query session
disp('Would you like to start at the reward practice (1), the PIP practice (2), the PIP (3), or the final PIP practice (4)?')
session = [];
while isempty(session)
    session = input('Enter session number: ');
end

datafilename = sprintf('%.0f_%.0f_%s_PIP.mat', id, session, datestr(now,'yyyymmddHHMMSS'));

% Load task parameters
[params] = PIP_config;

if params.testing ~= 1
    % Setup pump
    delete(instrfindall); % Make sure pump is not connected already
    pump = pumpSetup;
    params.pump = pump;
end

switch mod(id,2)
    case 1 % If odd participant, increased reward is represented by increased saturation
        params.colours = {[0 60 100], [0 113.985 188.955], [0 153 255]};
    case 0 % If even participant, increased reward is represented by decreased saturation
        params.colours = {[0 153 255], [0 113.985 188.955], [0 60 100]};
end

% Create new data file
data = {};
data.id = id;
data.session = session;
data.time = datestr(now,'yyyymmddHHMMSS');
data.startThirst = [];
data.rewardPractice = [];
data.firstPractice = [];
data.midThirst = [];
data.trialLog = [];
data.endThirst = [];
data.secondPractice = [];

% Reward practice
if session == 1 
% First thirst rating
[~,data.startThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,'On a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]');
[params] = generateStimuli(params);
[data.rewardPractice] = reward_practice(params);
session = 2;
end
% PIP practice
if session == 2
[params] = generateStimuli(params);
[data.firstPractice] = PIP_practice(params);
session = 3;
end
% PIP task
if session == 3;
% Second thirst rating
[~,data.midThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,'On a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]');
[params] = generateStimuli(params);
[data.trialLog] = PIP_task(params);
% Final thirst rating
[~,data.endThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,'On a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]');
session = 4;
end
% Final PIP practice
if session == 4
[params] = generateStimuli(params);
[data.secondPractice] = PIP_practice(params);
end

%% Save data
data.params = params;
oldcd = cd;
cd(params.dataDir);
save(datafilename, 'data');
cd(oldcd);

%% End experiment
drawText(params.window,'Thank you! The experiment is complete.\n\nPlease see the experimenter.');

if params.testing ~= 1
    % Close pump
    fclose(pump);
    delete(pump);
end


% Close PTB
ClosePTB;

if session == 4
    % Qualtrics
    url = 'https://fbeunimelb.asia.qualtrics.com/SE/?SID=SV_7R7BvZE5bDwjkO1';
    web(url,'-browser')
end
return