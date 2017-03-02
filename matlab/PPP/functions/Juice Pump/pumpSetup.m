function [pump] = pumpSetup

addpath(genpath('/Applications/MATLAB_R2012b.app/toolbox/shared/instrument/')); % Make sure serial loader is on path

if ismac
    devs = dir('/dev/cu.usbserial*');
    if length(devs) > 1
        fprintf('Multiple devices detected. Please choose one.\n');
        for i = 1:length(devs)
            fprintf('%i: %s\n', i, char(devs(i)));
        end
        fprintf('\n');
        
        devidxs = input('Type the number corresponding to the pump:\n','s');
        devid = str2double(devidxs);
        portNum = devs(devid);
    end
elseif ispc
    devidxs = input('Please input the COM port number of the syringe pump: ', 's');
    portNum = devidxs;
else
    error('Cannot identify operating system.\n');
end

if ~ispc
    port = ['/dev/COM' portNum];
else
    port = ['COM' portNum];
end

pump = serial(port);
fopen(pump);
fprintf('Pump is now controllable.\n');
return