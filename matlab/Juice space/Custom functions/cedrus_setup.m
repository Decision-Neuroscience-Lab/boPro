function [ioObj, address, h] = cedrus_setup

% Open parallel port (ioport)
fprintf('Opening parallel port...\n')
% Create an instance of the io32 object
ioObj = io32;
% Initialize the hwinterface.sys kernel-level I/O driver
status = io32(ioObj);
if status
    error('Perceptual_Calibration_fMRI: Cannot initialise io32.\n');
end
% If status = 0 you are now ready to write and read to a hardware port
% Set parallel port address (should be d010 on LPT3)
address = hex2dec('d010');          % Standard LPT1 output port address (0x378)
% Write value 0 to part to reset
data_out = 0;                                 % Sample data value
io32(ioObj,address,data_out);   % Output command

fprintf('Done.\n')

if IsOSX
    devs = dir('/dev/cu.usbserial*');
elseif IsWin
    % Ok, no way of really enumerating what's there, so we simply predefine the first 7 hard-coded port names:
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
else % Only one candidate: Choose it.
    if ~IsWin
        port = ['/dev/' char(devs(1).name)];
    else
        port = char(devs(1));
    end
end

h = CedrusResponseBox('Open', port, 0, 1);

% Check roundtriptime
CedrusResponseBox('RoundTripTest', h)

% First, send a 0:
io32(ioObj,address,0);   % Reset TTL to 0
WaitSecs(0.01);
