% portCellStr = RTBoxPorts ([allPorts=0]);
%
% Return available USB serial port names for RTBox. If allPorts is set to
% ture, this will close any opened RTBox, and return all USB serial port
% names for RTBox.

% 09/2009 Wrote it (XL)
% 01/2010 use non-block write to avoid problem of some ports

function portCellStr = RTBoxPorts(allPorts)
if nargin<1, allPorts=0; end
if allPorts
    RTBox('CloseAll'); 
    try RTBoxSimple('close'); end %#ok
end
if IsWin
    ports=cellstr(num2str((1:256)','\\\\.\\COM%i'));
    ports=regexprep(ports,' ',''); % needed for matlab 2009b
elseif IsOSX
    ports=dir('/dev/cu.usbserialRTBox*');
    if ~isempty(ports), ports=dir('/dev/cu.usbserial*'); end
    if ~isempty(ports), ports=strcat('/dev/',{ports.name}); end
elseif IsLinux
    ports=dir('/dev/ttyUSB*');
    if ~isempty(ports), ports=strcat('/dev/',{ports.name}); end
else error('Unsupported system: %s.', computer);
end
portCellStr={};
verbo=IOPort('Verbosity',0); % shut up screen output and error
for i=1:length(ports)
    s=IOPort('OpenSerialPort',ports{i},'BaudRate=115200 ReceiveTimeout=0.3');
    if s<0, continue; end
    IOPort('Write',s,'X',0); % ask identity
    idn=IOPort('Read',s,1,21); % contains 'USTCRTBOX'
    IOPort('Close',s);
    if strfind(idn,'USTCRTBOX')
        portCellStr{end+1}=ports{i}; %#ok
    end
end
IOPort('Verbosity',verbo);
