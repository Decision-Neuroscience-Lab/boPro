function [data] = QT
%% Initialisation

% Request ID (as string)
disp('Hello, you are running the QT juice task.')
id = [];
while isempty(id)
    id = input('Enter participant ID: ');
end

% Query session
disp('Would you like to start from the beginning (1) or reload old data (2)?')
reload = [];
while isempty(reload)
    reload = input('Enter session number: ');
end

datafilename = sprintf('%.0f_%.0f_%s_QT.mat', id, reload, datestr(now,'yyyymmddHHMMSS'));

% Load task parameters
[params] = QT_config;

if params.testing ~= 1
    % Setup pump
    delete(instrfindall); % Make sure pump is not connected already
    pump = pumpSetup;
    params.pump = pump;
end

% Open parallel port and test
if params.testing ~= 1
    params.ioObj = io32;
    status = io32(ioObj);
    if status
        error('Cannot initialise io32.\n');
    end
    params.address = hex2dec('d010'); % Standard LPT1 output port address (0x378)
    io32(params.ioObj,params.address,0); % Send a 0 to reset
end

% Trigger Experiment on
io32(params.ioObj,params.address,10);
WaitSecs(0.01);
io32(params.ioObj,params.address,0);

% Create new data file
data = struct;
data.id = id;
data.session = reload;
data.time = datestr(now,'yyyymmddHHMMSS');
data.blockThirst = [];
data.trialLog = [];

if reload == 1 % If we are running the task for the first time
    
    % Run first PIP task
    
    % Trigger PIP on
    io32(params.ioObj,params.address,11);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    pipTrials = PIP_task(params);
    pipTrials.block = repmat(1,[height(pipTrials),1]);
    
    % Trigger PIP off
    io32(params.ioObj,params.address,12);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    for b = 1:params.numBlocks
        % Set colours
        params.c = params.colours{1};
        params.cPrime = params.colours{2};
        
        [~,data.blockThirst(b),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
        
        % Trigger QT on
        io32(params.ioObj,params.address,13);
        WaitSecs(0.01);
        io32(params.ioObj,params.address,0);
        
        
        switch b
            case 1
                % Practice instructions
                text = sprintf(['Your task is to try and harvest as much money '...
                    'as possible within each %.0f minute block '...
                    '(elapsed time will be shown at the bottom of the screen).\n\n'...
                    'A coloured token will be displayed in the middle of the screen. '...
                    'Initially, it will be valued at %.0f cents, but this will increase to %.0f cents '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'This first block will just be a practice - you won''t win any of the money that you earn.\n\n'...
                    'Use any strategy you want - but remember that you only have a limited time...\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward*100,params.largeReward*100);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                % Baseline instructions
                text = ['Now money harvested in the task will be added to your winnings!\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
            case {2,3,8,9}
                [trialLog] = QT_task(params);
                
            case {4,5,6,7}
                % Main task instructions
                text = sprintf(['This is a "drinking" block. The task is identical, '...
                    'but you will receive a juice reward after each button press.\n\n\n'...
                    '[Press any button to continue]']);
                drawText(params.window, text);
                
                % Trigger Juice on
                io32(params.ioObj,params.address,15);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
                
                [trialLog] = QT_juice(params);
                
                % Trigger Juice off
                io32(params.ioObj,params.address,16);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
        end
        
        trialLog.Properties.VariableNames = {'trial','delay','rt','censor','reward','totalReward','blockTime'};
        block(1:size(trialLog,1),1) = b; % Add block to data
        trialLog = cat(2,array2table(block,'VariableNames',{'block'}),trialLog);
        data.trialLog = cat(1,data.trialLog,trialLog); % Add to full trial table
        clearvars block trialLog
        
        % Trigger QT off
        io32(params.ioObj,params.address,14);
        WaitSecs(0.01);
        io32(params.ioObj,params.address,0);
        
    end
    
    % Run second PIP task
    % Trigger PIP on
    io32(params.ioObj,params.address,11);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    pipTrials2 = PIP_task(params);
    pipTrials2.block = repmat(2,[height(pipTrials2),1]);
    
    % Trigger PIP off
    io32(params.ioObj,params.address,12);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    data.pip = cat(1,pipTrials,pipTrials2);
    
    ID(1:size(data.trialLog,1),1) = id; % Add id to data
    data.trialLog = cat(2,array2table(ID,'VariableNames',{'id'}),data.trialLog);
    
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
    
    % Change starting point to where we left off
    lastBlock = data.trialLog.block(end);
    
    for b = 1:params.numBlocks
        % Set colours
        params.c = params.colours{1};
        params.cPrime = params.colours{2};
        
        [~,data.blockThirst(b),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
        
        % Trigger QT on
        io32(params.ioObj,params.address,13);
        WaitSecs(0.01);
        io32(params.ioObj,params.address,0);
        
        
        switch b
            case 1
                % Practice instructions
                text = sprintf(['Your task is to try and harvest as much money '...
                    'as possible within each %.0f minute block '...
                    '(elapsed time will be shown at the bottom of the screen).\n\n'...
                    'A coloured token will be displayed in the middle of the screen. '...
                    'Initially, it will be valued at %.0f cents, but this will increase to %.0f cents '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'This first block will just be a practice - you won''t win any of the money that you earn.\n\n'...
                    'Use any strategy you want - but remember that you only have a limited time...\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward*100,params.largeReward*100);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                % Baseline instructions
                text = ['Now money harvested in the task will be added to your winnings!\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
            case {2,3,8,9}
                [trialLog] = QT_task(params);
                
            case {4,5,6,7}
                % Main task instructions
                text = sprintf(['This is a "drinking" block. The task is identical, '...
                    'but you will receive a juice reward after each button press.\n\n\n'...
                    '[Press any button to continue]']);
                drawText(params.window, text);
                
                % Trigger Juice on
                io32(params.ioObj,params.address,15);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
                
                [trialLog] = QT_juice(params);
                
                % Trigger Juice off
                io32(params.ioObj,params.address,16);
                WaitSecs(0.01);
                io32(params.ioObj,params.address,0);
        end
        
        trialLog.Properties.VariableNames = {'trial','delay','rt','censor','reward','totalReward','blockTime'};
        block(1:size(trialLog,1),1) = b; % Add block to data
        trialLog = cat(2,array2table(block,'VariableNames',{'block'}),trialLog);
        data.trialLog = cat(1,data.trialLog,trialLog); % Add to full trial table
        clearvars block trialLog
        
        % Trigger QT off
        io32(params.ioObj,params.address,14);
        WaitSecs(0.01);
        io32(params.ioObj,params.address,0);
        
    end
    
    % Run second PIP task
    % Trigger PIP on
    io32(params.ioObj,params.address,11);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    pipTrials2 = PIP_task(params);
    pipTrials2.block = repmat(2,[height(pipTrials2),1]);
    
    % Trigger PIP off
    io32(params.ioObj,params.address,12);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
    
    data.pip = cat(1,pipTrials,pipTrials2);
    
    ID(1:size(data.trialLog,1),1) = id; % Add id to data
    data.trialLog = cat(2,array2table(ID,'VariableNames',{'id'}),data.trialLog);
    
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
% url = sprintf('https://fbeunimelb.asia.qualtrics.com/SE/?SID=SV_0upF5APHQFGGm5n&ParticipantID=%.0f',id); % Append ID to URL (if ID is empty for whatever reason, survey will prompt for ID entry)
% web(url,'-browser')
return