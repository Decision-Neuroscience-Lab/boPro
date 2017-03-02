%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script controls the tasks in a TIMEDEC session
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TD = td_control_0()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear workpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check whether Java is in path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PsychJavaTrouble;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up button box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%TRIGGER SETUP
%%% open parallel port (ioport)
fprintf('Opening parallel port...\n')
% create an instance of the io32 object
ioObj = io32;
% initialize the hwinterface.sys kernel-level I/O driver
status = io32(ioObj);
if status
    error('Perceptual_Calibration_fMRI: Cannot initialise io32.\n');
end
%if status = 0, you are now ready to write and read to a hardware port
% set parallel port address (should be d010 on LPT3)
address = hex2dec('d010');          %standard LPT1 output port address (0x378)
% write value 0 to part to reset
data_out=0;                                 %sample data value
io32(ioObj,address,data_out);   %output command

fprintf('Done.\n')

if IsOSX
    devs = dir('/dev/cu.usbserial*');
elseif IsWin
    % Ok, no way of really enumerating what's there, so we simply predifne
    % the first 7 hard-coded port names:
    devs = {'COM0', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7'};
else
    error('Cannot find port to which button box is connected.\n');
end

% Let user choose if there are multiple potential candidates:
if length(devs) > 1
    fprintf('Following devices are potentially Cedrus RB devices: Choose one.\n\n');
    for i=1:length(devs)
        fprintf('%i: %s\n', i, char(devs(i)));
    end
    fprintf('\n');
    
    while 1
        devidxs = input('Type the number + ENTER of your response pad device: ', 's');
        devid = str2double(devidxs);
        
        if isempty(devid)
            fprintf('Type the number please, not something else!\n');
        end
        
        if ~isnumeric(devid)
            fprintf('Type the number please, not something else!\n');
        end
        
        if devid < 1 || devid > length(devs) || ~isfinite(devid)
            fprintf('Type one of the listed numbers please!\n');
        else
            break;
        end
    end
    
    if ~IsWin
        port = ['/dev/' char(devs(devid))];
    else
        port = char(devs(devid));
    end
else
    % Only one candidate: Choose it.
    if ~IsWin
        port = ['/dev/' char(devs(1).name)];
    else
        port = char(devs(1));
    end
end
h = CedrusResponseBox('Open', port, 0, 1);

%Get roundtriptime
       roundtrip = CedrusResponseBox('RoundTripTest', h);

%First, send a 0:
io32(ioObj,address,0);   %reset TTL to 0
WaitSecs(0.01);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up global data structures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% global TD
TD = struct();
TD.id = []; % subject ID
TD.time = []; % timestamp
TD.version = '0';
TD.delay1 = [];
TD.time1 = [];
TD.condition = [];
% TD.runs = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Switch on tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RUN_PRAC = 1;
RUN_TD1 = 1;
RUN_DR = 1;
RUN_TD2 = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TD Task
DELAYS = [1 2 4 6 9 12];
THRESHOLDS = [0.25 0.5 0.5 0.75];
%DR Task
INTERVALS = exp(.7+.4.*[0 1 2 3 4 5]);
NUM_REPEATS = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try-catch for PTB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Request subject ID
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Hey!')
    reply = [];
    while isempty(reply)
        reply = input('Enter participant ID: ');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load condition randomisation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load('ALL_ORDER_CONTROL.mat');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Log input
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TD(1).id = reply;
    TD(1).time = now;
    TD(1).condition = participants_cond(reply,2);
    idname = num2str(reply);
    logfilename = ['data/' idname '_' datestr(now,'yyyymmddHHMMSS') '.mat'];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set seed of RNG
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    stream0 = RandStream('mt19937ar','Seed',sum(double(reply)));
    RandStream.setDefaultStream(stream0);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Set up Screen
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    myScreen = max(Screen('Screens'));
    Screen('Preference', 'SkipSyncTests', 0);
    [window, winRect] = Screen(myScreen,'OpenWindow');
    [width, height] = RectSize(winRect);
    HideCursor;
    ListenChar(2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % call tasks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % run TD practice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if RUN_PRAC
        load td_practice_runsheet.mat trials
        td_prac(trials, window, width, height, ioObj, address, h);
        DR_prac(ioObj, address, h, window, width, height, INTERVALS, NUM_REPEATS, participants_cond)
        start_main_part(window, width, height, h);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Trigger experiment on
        io32(ioObj,address, 20);
        time_of_trigger = GetSecs;
        WaitSecs(0.01);
        io32(ioObj,address,0);
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % run TD first time
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if RUN_TD1
        
        %Trigger TD experiment on
        io32(ioObj,address, 22);
        time_of_trigger = GetSecs;
        WaitSecs(0.01);
        io32(ioObj,address,0);
        
        trials = build_runsheet_calib_v0(DELAYS, THRESHOLDS);
        save
        
        [trials timematrixtd] = td_rc_calib_v0(trials, window, width, height, ioObj, address, h);
        TD(1).delay1 = trials;
        for round = 1:TD(1).delay1.lasttrial
            timematrixtd(round,6) = sum(timematrixtd(round,:));
        end
        TD(1).timematrix1 = timematrixtd;
        save(logfilename,'TD');
        take_break(window, width, height, h);
    end
    
    %Trigger TD experiment off
    io32(ioObj,address, 23);
    time_of_trigger = GetSecs;
    WaitSecs(0.01);
    io32(ioObj,address,0);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % run duration reproduction task
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if RUN_DR
 
        [DATA, timematrix] = DR_Task_Cedrus(reply, ioObj, address, h, window, width, height, INTERVALS, NUM_REPEATS, participants_cond);
        TD(1).time1 = DATA;
        TD(1).timematrixdr = timematrix;
        save(logfilename,'TD');
        %take_break(window, width, height, h);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % run TD second time
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if RUN_TD2
        
        %Trigger TD experiment on
        io32(ioObj,address, 22);
        time_of_trigger = GetSecs;
        WaitSecs(0.01);
        io32(ioObj,address,0);
        
        trials = build_runsheet_calib_v0(DELAYS, THRESHOLDS);
        [trials timematrixtd2] = td_rc_calib_v0(trials, window, width, height, ioObj, address, h);
        TD(1).delay2 = trials;
%         for round = 1:TD(1).delay1.lasttrial
%         timematrixtd2(round,6) = sum(timematrixtd2(round,:));
%         end
%         TD(1).timematrix2 = timematrixtd2;
        save(logfilename,'TD');
    end
    
    %Trigger TD experiment off
    io32(ioObj,address, 23);
    time_of_trigger = GetSecs;
    WaitSecs(0.01);
    io32(ioObj,address,0);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % thank you
    %Trigger experiment off
        io32(ioObj,address, 21);
        time_of_trigger = GetSecs;
        WaitSecs(0.01);
        io32(ioObj,address,0);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    thank_you(window, width, height);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % close PTB window
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
end % PTB try catch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save data to disk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save(logfilename,'TD');
