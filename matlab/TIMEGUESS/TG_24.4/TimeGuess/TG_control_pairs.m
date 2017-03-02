function [TG] = TG_control_pairs
% Control script

%% Clear workspace
clear all
close all
clc

%% Check for Java
PsychJavaTrouble;

%% Set rand seed
% rng('shuffle');

%% Load paramaters
[key, params] = TG_config;

%% Try for PTB
try
    
    %% Request ID (as string)
    disp('Hey!')
    id = [];
    while isempty(id)
        id = input('Enter participant ID: ');
    end
    subject = num2str(id);
    cond = 'pairs';
    
    %% Log ID and time
    datafilename = [subject '_' cond '_' datestr(now,'yyyymmddHHMMSS') '.mat'];
    
    %% Set up data structures
    TG{params.blocks} = [];
    
    %% Set up screen
    myScreen = max(Screen('Screens'));
    Screen('Preference', 'SkipSyncTests', 0);
    [window, winRect] = Screen(myScreen,'OpenWindow');
    [width, height] = RectSize(winRect);
    HideCursor;
    ListenChar(2);
    
    %% Call tasks
    
    % Time guess task
    for block = 1:params.blocks;
                 
                params.presentation_list = generate_presentation_list(params.pair(block,:), params.numrepeats);
                params.practice_presentation_list = generate_presentation_list(params.pair(block,:), params.practice_repeats);
                
                % Get ready
                get_ready(window, width, height);
                % Time guess practice
                TG_practice(window, width, height, key, params);
                % Get ready
                get_ready(window, width, height);
                
                % Randomise presentation
                params.presentation_list = shuffleDim(params.presentation_list, 2);
                % Run task
                [TGDATA] = TG_task_mag(window, width, height, key, params)
                TG{block} = TGDATA;
       
        save(datafilename,'TG');
        take_break(window, width, height); % Take break
        
    end % Block loop
    
    
    %% End experiment
    thank_you(window, width, height);
    
    %% Close PTB
    ClosePTB;
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
end % PTB try catch

%% Save data
% cd('C:\Users\bowenf\Documents\MATLAB\TimeGuess');
save(datafilename,'TG');

end
