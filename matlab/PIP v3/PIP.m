function [data] = PIP
%% Initialisation

% Request ID (as string)
disp('Hello, you are running the PIP.')
id = [];
while isempty(id)
    id = input('Enter participant ID: ');
end

% Query session
disp('Would you like to start at the beginning (1) or reload old data (2)?')
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
        params.colours = {[0 60 100], [0 113.985 188.955], [0 153 255], [160 210 255]};
    case 0 % If even participant, increased reward is represented by decreased saturation
        params.colours = {[160 210 255], [0 153 255], [0 113.985 188.955], [0 60 100]};
end

% Create new data file
data = {};
data.id = id;
data.session = session;
data.time = datestr(now,'yyyymmddHHMMSS');
data.startThirst = [];
data.rewardPractice = [];
data.firstPractice = [];
data.trialLog = [];
data.endThirst = [];
data.secondPractice = [];

if session == 1 % If we are running the task for the first time
    
    % Generate stimuli
    [params] = generateStimuli(params);
    
    % Run the reward association practice
    [data.rewardPractice] = reward_practice(params);
    
    % Run the first baseline task
    params.practiceStim = params.practiceStim1;
    [data.firstPractice] = PIP_practice(params);
        
    % Run a first thirst rating
    [~,data.startThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
    
    % Run the main task
    [data.trialLog] = PIP_task(params,[]); % The second argument here is the trialLog structure, which can be blank as it is new
    
    % Run a final thirst rating
    [~,data.endThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
    
    % Run the final baseline task
    params.practiceStim = params.practiceStim2;
    [data.secondPractice] = PIP_practice(params);
    
else % If there was a problem and we had to restart, load previous session and start where we left off
    
    cd(params.dataDir);
    name = sprintf('%.0f_1_*', id);
    loadname = dir(name);
    try
    load(loadname.name,'data');
    catch
        ClosePTB; % Close PTB
        disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
        disp('No existing file for this id!');
        disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
        return;
    end
    
    % Recover parameters from old data
    params = data.params;
    params.pump = pump; % As we've removed the pump object from the previous file, we must restore it
    
    % Change starting point to where we left off
    lastTrial = size(data.trialLog,2);
    params.startTrial = lastTrial;
    
    % Run the main task
    [data.trialLog] = PIP_task(params,data.trialLog); % We need to provide the old trialLog structure
       
    % Run a final thirst rating
    [~,data.endThirst,~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
    
    % Run the final baseline task
    params.practiceStim = params.practiceStim2;
    [data.secondPractice] = PIP_practice(params);
    
end

%% Save data
params.pump = []; % Clear pump object
data.params = params;
oldcd = cd;
cd(params.dataDir);
save(datafilename, 'data');
cd(oldcd);

%% End experiment
drawText(params.window,'Thank you! The experiment is complete.\n\nIf you need to see the experimenter for any reason, please see them now.\n\nOtherwise, press any key to start filling in the surveys.');

if params.testing ~= 1
    % Close pump
    fclose(pump);
    delete(pump);
end

% Close PTB
ClosePTB;

% Launch Qualtrics
url = sprintf('https://fbeunimelb.asia.qualtrics.com/SE/?SID=SV_5jaVzm23pvSIJUh&ParticipantID=%.0f',id); % Append ID to URL (if ID is empty for whatever reason, survey will prompt for ID entry)
web(url,'-browser')
return