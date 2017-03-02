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
        error('Perceptual_Calibration_fMRI: Cannot find port to which button box is connected.\n');
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

%%

%First, send a 0:
io32(ioObj,address,0);   %reset TTL to 0
WaitSecs(0.01);

%For each trigger:
io32(ioObj,address, TRIGGER NUMBER HERE); 
time_of_trigger = GetSecs;
WaitSecs(0.01);
io32(ioObj,address,0);   %reset TTL to 0

        % clear button box queue (do it here as we are waiting anyway)
        CedrusResponseBox('FlushEvents', h);
        %     fprintf('Flushed event queue.\n')
        
        EVT = struct();
        EVT.raw = [];
        EVT.port = [];
        EVT.action = [];
        EVT.button = [];
        EVT.buttonID = [];
        EVT.rawtime = [];
        EVT.ptbtime = [];
        EVT.ptbfetchtime = [];
        
                % Set up response containers
        key = -1;
        response = -1;
        rawtime = -1;
        ptbtime = -1;
        ptbfetchtime = -1;
        rt = -1;
        button = -1;
        
 %% Record Response
 
   
        check = 1;
        i = 1;
        while check
            evt = CedrusResponseBox('GetButtons', h);
            if isempty(evt), break; end
            EVT(i) = evt;
            i = i + 1;
        end
        
        for i = 1:numel(EVT)
            evt = EVT(i);
            if ~isempty(evt)
           %             fprintf('Event %d: \nraw time: %1.4f \nptbtime: %1.4f \nptbfetchtime: %1.4f \n\n',i,evt.rawtime,evt.ptbtime,evt.ptbfetchtime)
                    button = evt.button;
                    key = button - 1; % we expect buttons 1 and 2 -> substract 1 so that 1 -> 0 and 2 -> 1
                    io32(ioObj,address,  20 + 11 + key);
                    rawtime = evt.rawtime;
                    ptbtime = evt.ptbtime;
                    ptbfetchtime = evt.ptbfetchtime;
                    rt = ptbtime - response_screen_onset;
              
            end
        end
        
        WaitSecs(0.01);
        io32(ioObj,address,0);   %reset TTL to 0        