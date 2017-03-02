% [availPorts busyPorts] = FindSerialPorts [(USBserialOnly=1)];
% 
% Returns available serial port names in cell string, used by IOPort, such
% as handle=IOPort('OpenSerialPort',availPorts{1}). The second output
% contains port names which are unavailable to IOPort, either used by other
% user program or by OS. The optional input tells whether to return
% USB-serial ports only (default), or all serial ports.
% 
% Note for MS Windows: COM1 and COM2 are reserved for onboard ports, and
% USB-serial ports start from COM3. This is our assumption in the code. If
% you assigned a USB-serial port to COM1 or COM2, we have no way to know.  
% 
% Example to open a USB-serial port automatically:
% ports=FindSerialPorts; % USBserial ports cellstr
% nPorts=length(ports);  % number of ports
% if nPorts==0
%     error('No USB serial ports available.');
% elseif nPorts>1
%     % If more than 1, will open 1st. You can choose another port by:
%     % ports{1}=ports{2}; % open 2nd instead of 1st
%     str=strrep(ports,'\\.\',''); % remove Windows path
%     str=sprintf(' %s,',str{:});
%     warning(['Multiple ports available:%s\b. The first will be used.'],str);
% end
% handle=IOPort('OpenSerialPort',ports{1}); % open 1st in ports
% 
% Xiangrui Li, 07/2008

% We use IOPort('OpenSerialPort') to try the ports.
% OpenSerialPort also configures serial port with default parameters, and
% restores setting when closed. These are a little slow, at least for
% Windows. It may take a second for several ports.

function [availPorts busyPorts] = FindSerialPorts (USBserialOnly)
if nargin<1, USBserialOnly=1; end
if IsWin
    startN=1; if USBserialOnly, startN=3; end
    ports=cellstr(num2str((startN:256)','\\\\.\\COM%i'));
    ports=regexprep(ports,' ',''); % needed for matlab 2009b
elseif IsOSX
    if USBserialOnly, ports=dir('/dev/cu.usbserial*');
    else ports=dir('/dev/cu*');
    end
    ports=strcat('/dev/',{ports.name});
elseif IsLinux
    ports=dir('/dev/ttyUSB*');
    if ~USBserialOnly  % does Linux have specific str for PCI ports?
        ports=[dir('/dev/ttyS*'); ports];
    end
    ports=strcat('/dev/',{ports.name});
else error('Unsupported system: %s.', computer);
end

% for OSX and Linux, it is easy to get all existing ports, while for
% Windows, there seems no way to get the list. So we try all possible ports
% one by one. Fortuanately, it won't take much time if a port doesn't exist. 
availPorts={}; busyPorts={}; % assign empty cell, will grow later
verbosity=IOPort('Verbosity',0); % shut up screen output and error
for i=1:length(ports)
    [h, errmsg]=IOPort('OpenSerialPort',ports{i});
    if h>=0  % open succeed
        IOPort('close',h); % test only, so close it
        availPorts{end+1}=ports{i}; %#ok
    elseif isempty(strfind(errmsg,'ENOENT')) % failed to open but port exists
        busyPorts{end+1}=ports{i}; %#ok
    end
end
IOPort('Verbosity',verbosity); % restore Verbosity
