function [pump] = pumpSetup

if IsOSX
    devs = dir('/dev/cu.usbserial*');
elseif IsWin
    % Ok, no way of really enumerating what's there, so we simply predefine the first 7 hard-coded port names:
    devs = {'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7'};
else
    error('Cannot find port to which pump is connected.\n');
end

% Let user choose if there are multiple potential candidates:
if length(devs) > 1
    fprintf('Following devices are potentially a syringe pump: Please choose one.\n\n');
    for i=1:length(devs)
        fprintf('%i: %s\n', i, char(devs(i)));
    end
    fprintf('\n');
    
    while 1
        devidxs = input('Type the number + ENTER:', 's');
        devid = str2double(devidxs);
        if isempty(devid)
            fprintf('Type a number please, not something else!\n');
        end 
        if ~isnumeric(devid)
            fprintf('Type a number please, not something else!\n');
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

pump = serial(port);
fopen(pump);
fprintf('Pump is now controllable.\n');
return