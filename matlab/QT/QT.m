function [data] = QT
%% Initialisation

% Request ID (as string)
disp('Hello, you are running the QT.')
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

% Create new data file
data = struct;
data.id = id;
data.session = reload;
data.time = datestr(now,'yyyymmddHHMMSS');
data.blockThirst = [];
data.trialLog = [];

if reload == 1 % If we are running the task for the first time
    
    for b = 1:params.numBlocks
        % Distribution switch
        switch mod(b,2)
            case 1
                params.d = params.D{1};
                params.c = params.colours{1};
                params.cPrime = params.colours{2};
            case 0
                params.d = params.D{2};
                params.c = params.colours{2};
                params.cPrime = params.colours{1};
        end
        
        switch b
            case 1
                % Practice instructions
                text = sprintf(['Your task is to try and harvest as much money '...
                    'as possible within each %.0f minute block '...
                    '(elapsed time will be shown at the bottom of the screen).\n\n'...
                    'In these first two practice blocks, a coloured token will be displayed in the middle of the screen. '...
                    'Initially, it will be valued at %.0f point, but this will increase to %.0f points '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'The timing of when the money increases can change in each block (indicated by the different coloured tokens). '...
                    'Use any strategy you want - but remember that you only have a limited time...\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward*100,params.largeReward*100);
                drawText(params.window, text);
                
                [trialLog] = QT_practice(params);
            case 2
                % Break
                text = ['Take a break!\n\nThe next practice block will start once you''re ready...\n'...
                    '\n(remember that the timing can change)\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_practice(params);
                
            case 3
                % Baseline instructions
                text = sprintf(['Now money harvested in the task will be added to your winnings! '...
                    'Initially, the token will be valued at %.2f cents, but this will increase to %.2f cents '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'The timing of when the money increases can change in each block (it''s the same as in the practice).\n\n\n'...
                    '[Press any button to start]'],params.smallReward,params.largeReward);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
            case 4
                % Break
                text = ['Take a break!\n\nThe next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                % Main task instructions
                text = sprintf(['This is now the drinking phase of the task. The task is identical, but in between each block, '...
                    'you will consume a small amount of soft drink. Firstly, please tell us how thirsty you are.\n\n\n'...
                    '[Press any button to continue]']);
                drawText(params.window, text);
                
                % Run a first thirst rating
                [~,data.blockThirst(1),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
                
            case {5, 6, 7, 8}
                % Drink
                text = 'Please call the experimenter into the booth!';
                drawText(params.window, text);
                WaitSecs(10);
                
                text = ['The next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                % Run a thirst rating for each block
                [~,data.blockThirst(b - 3),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
                
            case 9
                % Second baseline
                text = sprintf(['There are two more blocks left. You won''t have to drink in these blocks.\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward,params.largeReward);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
            case 10
                % Break
                text = ['Take a break!\n\nThe next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
        end
        
        trialLog.Properties.VariableNames = {'trial','distribution','delay','rt','censor','reward','totalReward','blockTime'};
        block(1:size(trialLog,1),1) = b; % Add block to data
        trialLog = cat(2,array2table(block,'VariableNames',{'block'}),trialLog);
        data.trialLog = cat(1,data.trialLog,trialLog); % Add to full trial table
        clearvars block trialLog
        
    end
    
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
    
    for b = lastBlock:numBlocks
            % Distribution switch
        switch mod(b,2)
            case 1
                params.d = params.D{1};
                params.c = params.colours{1};
                params.cPrime = params.colours{2};
            case 0
                params.d = params.D{2};
                params.c = params.colours{2};
                params.cPrime = params.colours{1};
        end
        
        switch b
            case 1
                % Practice instructions
                text = sprintf(['Your task is to try and harvest as much money '...
                    'as possible within each %.0f minute block '...
                    '(elapsed time will be shown at the bottom of the screen).\n\n'...
                    'In these first two practice blocks, a coloured token will be displayed in the middle of the screen. '...
                    'Initially, it will be valued at %.0f point, but this will increase to %.0f points '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'The timing of when the money increases can change in each block (indicated by the different coloured tokens). '...
                    'Use any strategy you want - but remember that you only have a limited time...\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward,params.largeReward);
                drawText(params.window, text);
                
                [trialLog] = QT_practice(params);
            case 2
                % Break
                text = ['Take a break!\n\nThe next practice block will start once you''re ready...\n'...
                    '\n(remember that the timing can change)\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_practice(params);
                
            case 3
                % Baseline instructions
                text = sprintf(['Now money harvested in the task will be added to your winnings!'...
                    'Initially, the token will be valued at %.2f cents, but this will increase to %.2f cents '...
                    'after a random delay.\n\n'...
                    'You can press a button at any time to take the token.\n\n'...
                    'The timing of when the money increases can change in each block (it''s the same as in the practice).\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward,params.largeReward);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
            case 4
                % Break
                text = ['Take a break!\n\nThe next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                % Main task instructions
                text = sprintf(['This is now the drinking phase of the task. The task is identical, but in between each block, '...
                    'you will consume a small amount of soft drink. Firstly, please tell us how thirsty you are.\n\n\n'...
                    '[Press any button to continue]']);
                drawText(params.window, text);
                
                 % Run a first thirst rating
                [~,data.blockThirst(1),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);
                
            case {5, 6, 7, 8}
                % Drink
                text = 'Please call the experimenter into the booth!';
                drawText(params.window, text);
                WaitSecs(10);
                
                text = ['The next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);
                
                 % Run a thirst rating for each block
                [~,data.blockThirst(b - 4),~] = sliderResponse(params.window,params.width,params.height,1:10,0,params.thirstText);  
                
            case 9
                % Second baseline
                 text = sprintf(['There are two more blocks left. You won''t have to drink in these blocks.\n\n\n'...
                    '[Press any button to start]'],params.blockTime./60,params.smallReward,params.largeReward);
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);     
                
            case 10
                % Break
                  text = ['Take a break!\n\nThe next block will start once you''re ready...\n\n\n'...
                    '[Press any button to start]'];
                drawText(params.window, text);
                
                [trialLog] = QT_task(params);        
        end
        
        trialLog.Properties.VariableNames = {'trial','distribution','delay','rt','censor','reward','totalReward','blockTime'};
        block(1:size(trialLog,1),1) = b; % Add block to data
        trialLog = cat(2,array2table(block,'VariableNames',{'block'}),trialLog);
        data.trialLog = cat(1,data.trialLog,trialLog); % Add to full trial table
        clearvars block trialLog
        
    end
    
    ID(size(data.trialLog,1),1) = id; % Add id to data
    data.trialLog = cat(2,array2table(ID,'VariableNames',{'id'}),data.trialLog);
    
end

%% Save data
data.params = params;
oldcd = cd;
cd(params.dataDir);
save(datafilename, 'data');
cd(oldcd);

%% End experiment
drawText(params.window,'Thank you! The experiment is complete.\n\nIf you need to see the experimenter for any reason, please see them now.\n\nOtherwise, press any key to start filling in the surveys.');

% Close PTB
ClosePTB;

% Launch Qualtrics
url = sprintf('https://fbeunimelb.asia.qualtrics.com/SE/?SID=SV_0upF5APHQFGGm5n&ParticipantID=%.0f',id); % Append ID to URL (if ID is empty for whatever reason, survey will prompt for ID entry)
web(url,'-browser')
return