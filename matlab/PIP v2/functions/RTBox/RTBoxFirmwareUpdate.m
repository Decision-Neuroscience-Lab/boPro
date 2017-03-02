% RTBoxFirmwareUpdate (hexFileName)
% 
% Update firmware for RTBox v1.4 and later. 
% The optional input is the file name of firmware hex. If you omit it, you
% will be asked to browse it.

% History:
% 12/2009 wrote it (Xiangrui Li)
% 01/2010 remove dependence on avrdude (xl)
% 08/2011 check hardware version compatibility (xl)

% intel HEX format:
% :10010000214601360121470136007EFE09D2190140
% Start code(:), Byte count(1 byte), Address(2 bytes), Record type(1 byte),
%   Data (bytes determined by Byte count), Checksum(1 byte).
% Record type (00, data record; 01, End Of File record)

function RTBoxFirmwareUpdate(hexFileName)    
if nargin<1 || isempty(hexFileName)
    [hexFileName,pname]=uigetfile('RTBOX*.hex','Select HEX file');
    if ~ischar(hexFileName), return; end % user cancelled
    v=str2double(hexFileName(6:7))/10; % firmware version
    hexFileName=fullfile(pname,hexFileName);
elseif ~exist(hexFileName,'file') % check hex file
    error(' Provided HEX file not exists.');
end

fprintf(' Checking HEX file ...\n');
fid=fopen(hexFileName);
hex=textscan(fid,'%s',-1); % read all
fclose(fid);
hex=hex{1};
C=255*ones(length(hex),16,'uint8'); % 16 bytes/page, pad FF to last page
strtAddr=[]; clipind=[];
for i=1:length(hex)
    ln=hex{i}; % get a line (a page for Amtel)
    nb=hex2dec(ln(2:3)); % number of bytes for the page
    if (nb*2+11 ~= length(ln)), error('HEX file corrupted at line %g.',i); end
    ln=hex2dec(ln(reshape(2:end,2,nb+5)'));
    chksum=mod(256-sum(ln(1:end-1)),256);
    if chksum~=ln(end), error('Checksum error at line %g. HEX file corrupted',i); end
    if ln(4), clipind=[clipind i]; %#ok not data record
    else C(i,1:nb)=uint8(ln(5:end-1))'; % data
    end
    if isempty(strtAddr)
        if nb~=16, error('Invalid hex file: buffer size is not 0x10.'); end
        strtAddr=ln(2:3)'; 
    end
end
C(clipind,:)=[]; % remove non-data lines
nPage=length(C);
clear hex;

% check connected RTBox 
verbo=IOPort('Verbosity',0); % shut up screen output and error
port=RTBoxPorts(1); % get all ports for boxes
if isempty(port)
    err=sprintf(['No working RTBox found. If your box is connected, '...
        'please unplug it now. If not, plug it while pressing down buttons 1 and 2.\n\n']);
    fprintf(WrapString(err));
    ports=FindSerialPorts; nports=length(ports); % find USB-serial ports
    while 1
        portsNew=FindSerialPorts;
        if length(portsNew)<nports % unplugged
            fprintf(' Detected that a port has been unplugged.\n');
            fprintf(' Now plug it while pressing down buttons 1 and 2.\n');
            ports=portsNew; nports=length(ports);
        elseif length(portsNew)>nports % plugged
            fprintf(' Plugged port detected.\n');
            break;
        end
        if ReadKey('esc'), error('User pressed ESC. Exiting ..'); end
    end
    ind=[];
    for i=1:nports
        ind=[ind strmatch(ports{i},portsNew)]; %#ok
    end
    portsNew(ind)=[];
    port=portsNew{1}; % found the new-plugged port name
    s=IOPort('OpenSerialPort',port,'BaudRate=115200');
    IOPort('Write',s,'S'); % ask 'AVRBOOT'
elseif length(port)==1 % one RTBox
    port=port{1};
    s=IOPort('OpenSerialPort',port,'BaudRate=115200');
    if ~isnan(v) % check compatibility if we have version info
        IOPort('Write',s,'X');
        b=IOPort('Read',s,1,21);
        vv=str2double(char(b(19:21)));
        if round(v)~=round(vv) % major version different
            cleanup('Hardware and firmware not compatible.'); 
        end
    end
    IOPort('Write',s,'x'); % make sure we enter simple mode
    IOPort('Write',s,'B'); % jump to boot loader from simple mode
    IOPort('Write',s,'S'); % enter boot mode and ask 'AVRBOOT'
else % more than one boxes connected
    error(' More than one RTBoxes found. Please plug only one.');
end
idn=IOPort('Read',s,1,7); % read boot id
if ~strcmp(char(idn),'AVRBOOT')
    cleanup('Failed to enter boot loader.'); 
end
% now we are in AVRBOOT, ready to upload firmware HEX

IOPort('Write',s,'Tt'); % set device type
checkerr('set device type');
fprintf(' Erasing flash ...\n');
IOPort('Write',s,'e'); % erase
checkerr('erase flash');

IOPort('Write',s,uint8(['A' strtAddr])); % normally 0x0000 
checkerr('set address');

fprintf(' Writing flash ...   0%%');
cmd=uint8(['B' 0 16 'F']); % cmd high/low bytes, Flash
for i=1:nPage
    IOPort('Write',s,cmd);
    IOPort('Write',s,C(i,:)); % write a page
    checkerr(sprintf('write flash page %g',i));
    fprintf('\b\b\b\b%3.0f%%',i/nPage*100); % progress
end

IOPort('Write',s,uint8(['A' strtAddr])); % set start address to verify
checkerr('set address');

fprintf('\n Verifying flash ...   0%%');
cmd=uint8(['g' 0 16 'F']); % cmd high/low bytes, Flash
for i=1:nPage
    IOPort('Write',s,cmd);
    ln=IOPort('Read',s,1,16); % read a page back
    if length(ln)<16 || ~all(ln==C(i,:))
        cleanup(sprintf('Failed to verify page %g. Please try again.',i)); 
    end
    fprintf('\b\b\b\b%3.0f%%',i/nPage*100);
end
fprintf('\n Done.\n');
cleanup('');

    function cleanup(err)
        IOPort('Write',s,'R'); % jump to application
        IOPort('Close',s);
        IOPort('Verbosity',verbo); % restore verbosity
        error(err);
    end

    % check returned '\r', close port in case of error
    function checkerr(str)
        back=IOPort('Read',s,1,1); % read '\r'
        if isempty(back) || back~=13
            cleanup(sprintf('\n Failed to %s.',str));
        end
    end
end
