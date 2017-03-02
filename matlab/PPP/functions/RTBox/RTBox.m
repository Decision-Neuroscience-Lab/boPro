function varargout = RTBox (varargin)
% RTBox: Control USTC Response Time Box. 
% 
% For principle of the hardware, check the Behavior Research Methods paper
% at http://lobes.usc.edu/Journals/BRM10.pdf
%  
% The syntax for RTBox is similar to most functions in Psychtoolbox, i.e.,
% each command for RTBox will perform a certain task. To get help for a
% command, also use the similar method to those for Psychtoolbox. For
% example, to get help for RTBox('clear'), you can type either
% RTBox('clear?') or RTBox clear?
% 
% This is a list for all currently supported commands:
% 
% RTBox('clear');
% RTBox('ButtonNames',{'1' '2' '3' '4'});
% RTBox('ClockRatio' [, seconds]);
% [timing events] = RTBox (timeout);
% RTBox('nEventsRead', nEvents);
% RTBox('UntilTimeout', false);
% nEvents = RTBox('EventsAvailable');
% [timing events] = RTBox('BoxSecs', timeout);
% [timing events] = RTBox('light', timeout);
% [timing events] = RTBox('sound', timeout);
% RTBox('DebounceInterval', intervalSecs);
% RTBox('enable', {'release' 'light'});
% RTBox('disable', 'release');
% enabledEvents = RTBox('EnableState');
% isDown = RTBox('ButtonDown', buttons);
% timeSent = RTBox('start');
% timeSent = RTBox('TTL', eventCode);
% RTBox('TTLWidth', widthSecs);
% RTBox('TTLResting', 0);
% timing = RTBox('WaitTR');
% RTBox('test');
% RTBox('info');
% RTBox('reset');
% RTBox('close');
% RTBox('fake', 1);
% keys = RTBox('KeyNames');
% [ ... =] RTBox([ ... ,] 'device2');
% RTBox('CloseAll');
% 
% Following are detail description for all supported commands.
%  
% RTBox('clear', nSyncTrial);
% - Clear serial buffer, prepare for receiving response. To avoid fake
% response, always clear buffer right before stimulus onset. This also
% synchronizes the clocks of computer and device, and enables the detection
% of trigger event if applicable. The optional second input nSyncTrial,
% default 20, is the number of trials to synchronize clocks. If you want
% RTBox('clear') to return quickly, you can set it to a smaller number,
% such as 3. In case the synchronization is not good, you can try larger
% number, such as RTBox('clear',50), but it will take longer time. If you
% want to skip the synchronization, for example when you measure RT
% relative to a trigger, or when you want to return 'BoxSecs', you should
% set nSyncTrial to 0. Optionally, this command returns a 4-element row
% vector: the first is the time difference between computer and device
% clocks; the second is the device time when the difference was measured;
% the third is the upper bound of the difference; and the last one is the
% time difference from another synchronization method (selecting a trial by
% min(tpost-tpre), and using its mean as tsend).
% 
% RTBox('purge');
% - Clear serial buffer. This is obsolete. Use RTBox('clear',0) instead.
% 
% [oldName =] RTBox('ButtonNames',{'left' 'left' 'right' 'right'}); 
% - Set/get four button names. The default names are {'1' '2' '3' '4'}. You
% can use any names, except 'sound', 'pulse', 'light', '5', and 'serial',
% which are reserved for other events. Also don't use 'device*' and any
% RTBox sub-commands as button names. If no button names are passed, this
% will return current button names.
% 
% [ratio =] RTBox('ClockRatio', seconds);
% - Measure the clock ratio of computer/RTBox, and save the ratio into the
% device (v1.3 or later) or a file. The program will warn you to perform
% ClockRatio test when it is necessary. This happens when the box loses
% power from USB port. However, you can do this anytime. The optional
% second input specifies how long the test will last (default 30 s). If you
% want to return computer time, it is better to do this test once before
% experiment. The program will automatically use the test result to correct
% device time. For version 1.1 or earlier, you need the write privilege to 
% save the ratio to a file, so the code can retrieve it next time. If you
% don't have this privilege, you have to correct the ratio each time after
% you close the device.
% 
% [timing events] = RTBox('secs', timeout);
% - Return computer time and names of events. events are normally button
% press, but can also be button release, serial trigger, light signal,
% external TTL pulse (or sound for v3.0+), and TR (v3.0+). If you changed
% button names by RTBox('ButtonNames'), the button-down and up events will
% be your button names. If you enable both button down and up events, the
% name for a button-up event will be its button name plus 'up', such as
% '1up', '2up' etc. timing are for each event, using GetSecs timestamp. If
% there is no event, both output will be empty.
% 
% Both input are optional. You can omit 'secs' since it is the default.
% timeout can have two meanings. By default, timeout is the seconds
% (default 0.1 s) to wait from the evocations of the command. Sometimes,
% you may like to wait until a specific time. Then you can use
% RTBox(TillSecs-GetSecs), but it is better to set the timeout to until
% time, so you can simply use RTBox(TillSecs). You do this by
% RTBox('UntilTimeout',1). During timeout wait, you can press ESC to abort
% your program. RTBox('secs',0) will take couple of milliseconds to return
% after several evokes, but this is not guaranteed. If you want to check
% response between two video frames, use RTBox('EventsAvailable') instead.
% 
% This subfunction will return when either time is out, or required events
% are detected, whichever is earlier. If there are events available in the
% buffer, this function will read back all of them. To set the number of
% events to wait, use RTBox('nEventsRead',n).
%
% [oldValue=] RTBox('nEventsRead', nEvents); 
% - Set the number of events (default 1) to wait for during read functions.
% For RTBox('trigger'), this refers the number of events besides the
% trigger. If you want the read functions to wait for more events, set
% nEvents accordingly. Limitation: the repeated events due to button
% bouncing are counted as different events.
% 
% [oldBool=] RTBox('UntilTimeout', newBool); 
% - By default, read functions don't use until timeout, but use relative
% timeout. For example, RTBox('secs',2) will wait for 2 seconds from now.
% In your code, you may like to wait till a specific time point. For this
% purpose, you set newBool to 1. Then RTBox('secs',timeout) will wait until
% the GetSecs clock reaches timeout.
% 
% nEvents = RTBox('EventsAvailable'); 
% - Return the number of available events. Unlike other read functions,
% the events will be left untouched in the buffer after this call. This
% normally takes about 1 ms after two evocations, so it is safe to call
% between video frames. Note that the returned nEvents may have a fraction,
% which normally indicates the port is receiving data.
% 
% [timing events] = RTBox('BoxSecs', timeout);
% - This is the same as RTBox('secs'), except that the returned time is
% based on the box clock, normally the seconds since the device is powered.
% 
% [timing events] = RTBox('light', timeout); 
% [timing events] = RTBox('sound', timeout); 
% [timing events] = RTBox('pulse', timeout); 
% - These are the same as RTBox('secs'), except that the returned time is
% relative to the provided trigger, 'light' or 'sound'. 'pulse' is the same
% as 'sound'. The trigger can also be any enabled event. Since the
% timing is relative to the provided trigger, both the trigger timing,
% which is 0, and the trigger event are omitted in output. Normally the
% trigger indicates the onset of stimulus, so the returned time will be
% response time. By default, this will wait for one event besides the
% trigger event. The n in RTBox('nEventsRead',n) doesn't include the
% trigger event. If the trigger event is not detected, you will see a
% warning and both output will be empty, no matter whether there are other
% events.
% 
% [oldValue=] RTBox('DebounceInterval', intervalSecs); 
% - Set/get debounce interval in seconds. RTBox will ignore both button
% down and up events within intervalSecs window after a button event of the
% same button. The valid intervalSecs is from 0 to about 0.283 (283 ms),
% default 0.05. intervalSecs=0 will disable debouncing. The debouncing is
% performed in Matlab code for version 1.4 and earlier, and in device
% firmware for later versions. Note that our debounce schemes won't cause
% time delay for button response.
% 
% [enabledEvents =] RTBox('enable', eventsToEanble); 
% [enabledEvents =] RTBox('disable', eventsToDisable);
% - Enable/disable the detection of passed events. The events to enable /
% disable can be one of these strings: 'press' 'release' 'sound' 'pulse'
% 'light' and 'TR', or cellstr containing any of these strings. The string
% 'all' is a shortcut for all the events. By default, only 'press' is
% enabled. If you want to detect button release time instead of button
% press time, you need to enable 'release', and better to disable 'press'.
% The optional output returns enabled events. If you don't provide any
% events, it means to query the current enabled events. Note that the
% device will disable a trigger itself after receiving it. RTBox('clear')
% will implicitly enable those triggers you have enabled.
% 
% enabledEvents = RTBox('EnableState');
% - Query the enabled events in the hardware. This may not be consistent
% with those returned by RTBox('enable'), since an external trigger will
% disable the detection of itself in the hardware, while the state in the
% Matlab code is still enabled. RTBox('clear') will enable events
% implicitly. This command is mainly for firmware debug purpose.
% 
% isDown = RTBox('ButtonDown', buttons);
% - Check button(s) status, 1 for down, 0 for not. If optional buttons is
% provided, only those button state will be reported. For example, if you
% want to wait till button down, you can use 
% while ~any(RTBox('ButtonDown')) % wait any button down 
%     WaitSecs('YieldSecs', 0.01); 
% end
% while ~RTBox('ButtonDown','4') % wait only button 4 down
%     WaitSecs('YieldSecs', 0.01); 
% end
% 
% The button status query will work no matter button-down event is enabled
% or not.
%
% [timeSent timeSentUb=] RTBox('start');
% - Send a trigger to RTBox via the serial port. Normally you don't use
% this, although you could use it to indicate the start of stimulus, if
% you don't have a convenient way to return stimulus onset time. The
% optional output are computer time when the trigger was sent, and its
% upper bound.
% 
% [timeSent timeSentUb=] RTBox('TTL', eventCode);
% - Send TTL to DB-25 port (pin 8 is bit 0). The second input is event code
% (default 1 if omitted), 4-bit (0~15) for v<5, and 8-bit (0~255) for v>=5.
% It can also be equivalent binary string, such as '0011'. The optional
% output are the time the TTL was sent, and its upper bound. The width of
% TTL is controlled by RTBox('TTLWidth') command. TTL function is supported
% only for v3.0 and later, which was designed for EEG event code.
% 
% [oldValue=] RTBox('TTLWidth', widthSecs);
% - Set/get TTL width in seconds. The default width is 0.97e-3 when device
% is opened. The actual width may have some small variation. The supported
% width ranges from 0.14e-3 to 35e-3. The infinite width is also supported.
% Infinite width means the TTL will stay until it is changed by next
% RTBox('TTL') command, such as RTBox('TTL',0).
% 
% In v<5, the TTL width at DB-25 pins 17~24 is controlled by a
% potentiometer inside the box. In v>=5, the width is also controlled by
% 'TTLWidth' command. 
% 
% [oldValue=] RTBox('TTLResting', newLevel); 
% - Set/get TTL polarity for DB-25 pins 1~8. The default is 0, meaning the
% TTL resting is low. If you set newLevel to nonzero, the resting TTL will
% be high level. If you need different polarity for different pins, let us
% know.
% 
% In v>=5, newLevel has second value, which is the polarity for pins 17~24.
% 
% [timing =] RTBox('WaitTR');
% - Wait for TR (TTL input from pin 7 of DB-9 port), and optionally return
% accurate TR time based on computer clock. This command will enable TR
% detection automatically, so you do not need to do it by yourself. You can
% press key 5 to simulate TR for testing.
% 
% RTBox('test');
% - This can be used as a quick command line check for events. It will wait
% for incoming event, and display event name and time when available.
% 
% [oldPara =] RTBox('info' [, newPara]);
% - Display some information of the device for debug purpose. If output is
% provided, this will return a struct containing all info. You could change
% a value in the struct and pass it in, but this is not recommended unless
% you know the detail about how the code works.
% 
% RTBox('reset');
% - Reset the device clock to zero. You rarely need this. 
% 
% RTBox('close');
% - Close the device.
% 
% [isFake =] RTBox('fake',1);
% - This allows you to test your code without a device connected. If you
% set fake to 1, you code will run without "device not found" complain, and
% you can use keyboard to respond. The time and button name will use those
% from KbCheck. To allow your code works under fake mode, the button names
% must be supported key names returned by RTBox('KeyNames'). Some commands
% will be ignored silently at fake mode. It is recommended you set fake to
% 1 in the Command Window before you test your code. Then you can simply
% clear all to exit fake mode. If you want to use keyboard for experiment,
% you can insert RTBox('fake',1) in your code before any RTBox call. Then
% if you want to switch to response box, remember to change 1 to 0. 
% 
% keys = RTBox('KeyNames');
% - Return all supported key names on your system. The button names at
% fake mode must use supported key names. Most key names are consistent
% across different OS. This won't distinguish the number keys on main
% keyboard from those on number pad.
% 
% RTBox('clear','device2'); % clear buffer of device 2
% [timing events] = RTBox('device2'); % read from device 2
% [ ... =] RTBox( [ ... ,] 'device2');
% - If you need more than one device simultaneously, you must include a
% device ID string as the last input argument for all the RTBox subfunction
% calls. The string must be in format of 'device*', or 'device*:portname',
% where * must be a single number or letter, and the optional portname is a
% serial port name of the box you want to open. If 'device*' is not
% provided, it is equivalent to having 'device1'.
% 
% If portname is provided when the code opens a device, it will try to open
% the box at the specified port. You can use RTBoxPorts to list all port
% names for RTBox. For example, RTBox('clear','device2:COM4') will try to
% open the box at COM4 and assign it as device2. The portname is ignored if
% the device is already open.
% 
% If portname is not provided, the code will open the first available port
% in the list returned by RTBoxPorts. 
% 
% RTBox('CloseAll');
% - Close all devices.

% History:
% 03/2008, start to write it. Xiangrui Li
% 07/2008, use event disable feature for firmware v>1.1 according to MK
% 03/2009, TTL functions added for v3.0 (XL)
% 04/2009, fake mode added (XL)
% 06/2009, fake mode and real mode can work for multi-boxes (XL)
% 06/2009, online help available in the same way as PTB functions (XL)
% 06/2009, add EventsAvailable, UntilTimeout and nEventsRead (XL)
% 08/2009, add 'info' and changed 'test' (XL)
% 09/2009, impliment method to set latencyTimer (XL)
% 09/2009, impliment portname to open (XL)
% 10/2009, use 'now' instead of GetSecs to save clkRatio for v1.1 (XL)
% 11/2009, add HardwareDebounce for v1.4+, except v3.0 (XL)
% 11/2009, add TTLresting for v3.1+ to control TTL polarity (XL)
% 11/2009, start to use 1/921600 of clock unit (XL)
% 12/2009, implement EnableState for firmware and Matlab code (XL)
% 12/2009, firmware update implemented in RTBoxFirmwareUpdate (XL)
% 01/2010, reset implemented for v1.5+ (XL)
% 01/2010, merge HardwareDebounce into DebounceInterval (XL) 
% 02/2010, bug fix for ButtonDown when repeated button names used (XL) 
% 06/2010, don't need to reverse TTL bit order for v>3.1 (XL) 
% 11/2010, take the advantage of WaitSecs('YieldSecs') (XL) 
% 02/2011, replace all strmatch with strcmp (XL) 
% 03/2011, LatencyTimer updated for Windows (XL) 
% 03/2011, use onCleanup for 2007a and later(XL) 
% 04/2011, remove the minimum repeats of 3 for syncClocks (XL) 
% 05/2011, make 'sound' subcommand equivalent to 'pulse' (XL) 
% 07/2011, bug fix in subFuncHelp (XL) 
% 08/2011, remove arbituary debouncing in 'test' (XL) 
% 08/2011, allow 8-bit TTL and two TTL resting input for v5.0+ (XL) 
% 09/2011, simplify enable method for v4.1+, add aux for v5.0+, could be buggy (XL) 
% 09/2011, bug fix for v1.4- in openRTBox, 8-byte info (XL) 
% 10/2011, remove dependence on new regexptranslate for Windows LatencyTimer (XL) 
% 10/2011, remove dependence on robustfit or regress (according to Craig Arnold) 

nIn=nargin; % # of input
if nIn<1 || ~ischar(varargin{nIn}) || ~strncmpi('device',varargin{nIn},6)
    boxID='device1'; portname=''; % no device specified, use default
else
    boxID=varargin{nIn};
    ind=strfind(boxID,':'); portname='';
    if ~isempty(ind), portname=boxID(ind+1:end); boxID=boxID(1:ind-1); end
    if ~any(boxID=='?'), nIn=nIn-1; end % don't count 'device*'
end

switch nIn % deal with variable number of input
    case 0, in1=[]; in2=[];
    case 1 % could be cmd or timeout
        if ischar(varargin{1}), in1=varargin{1}; in2=[];
        else in1=[]; in2=varargin{1};
        end
    case 2, [in1 in2]=varargin{1:2};
    otherwise, error('Too many input arguments.');
end
if isempty(in1), in1='secs'; end % default command
cmd=lower(in1);  % make command and trigger case insensitive
if strcmp(cmd,'pulse'), cmd='sound'; end
if any(cmd=='?'), subFuncHelp(mfilename,in1); return; end % online help

persistent info; % struct containing important device info
persistent eventcodes cmds events4enable tpreOffset infoDft; % only to save time
if isempty(info) % no any opened device
    info=struct('events',{{'1' '2' '3' '4' '1' '2' '3' '4' 'sound' 'light' '5' 'aux' 'serial'}},...
        'enabled',logical([1 0 0 0 0 0]),'ID',boxID,'handle',[],'portname','','sync',[], ...
        'version',[],'clkRatio',1,'TTLWidth',0.00097,'debounceInterval',0.05,...
        'latencyTimer',0.001,'fake',false,'nEventsRead',1,'untilTimeout',false,...
        'TTLresting',logical([0 1]),'clockUnit',1/115200,'cleanObj',[]);
    infoDft=info;
    eventcodes=[49:2:55 50:2:56 97 48 57 98 89]; % code for 13 events
    cmds={'close' 'closeall' 'clear' 'start' 'test' 'buttondown' ...
        'buttonnames' 'enable' 'disable' 'clockratio' 'ttl' 'fake' 'keynames' ...
        'ttlwidth' 'waittr' 'debounceinterval' 'eventsavailable' ...
        'neventsread' 'untiltimeout' 'info' 'ttlresting' 'sound'...
        'enablestate' 'reset' 'purge'}; % for check only
    events4enable={'press' 'release' 'sound' 'light' 'tr' 'aux'};
    evalc('GetSecs;KbCheck;WaitSecs(0.001);IOPort(''Verbosity'');now;'); % initialize timing functions
    tpreOffset=10/115200; % time for 1-byte serial write: 10 bits (1+8+1)
    tpreOffset=tpreOffset+5.5e-6; % time for execution of write cmd (measured shortest)
    % tpreOffset=tpreOffset+1.1e-6; % time for execution of GetSecs in C (measured shortest)
end

id=find(strcmpi(boxID,{info.ID})); % which device?
if isempty(id), id=length(info)+1; info(id)=infoDft; end % add a slot

read=[lower(info(id).events) {'secs' 'boxsecs'}]; % triggers and read commands
if ~any(strcmp(cmd,[cmds read])) % if invalid cmd, we won't open device
    RTBoxError('unknownCmd',in1,cmds,info(id).events); % invalid command
end

if info(id).fake || strcmp('fake',cmd) % fake mode?
    if strcmp('fake',cmd)
        if isempty(in2), varargout{1}=info(id).fake; return; end
        info(id)=RTBoxFake('fake',info(id),in2); 
        if nargout, varargout{1}=info(id).fake; end
        return; 
    end
    if nargout==0, info(id)=RTBoxFake(cmd,info(id),in2);
    else
        [foo varargout{1:nargout}]=RTBoxFake(cmd,info(id),in2);
        info(id)=foo; % Strange: this can solve the slow problem for some MAC
    end
    return; 
end

s=info(id).handle; % serial port handle for current device
if isempty(s) && ~strncmp('close',cmd,5) % open device unless asked to close
    openRTBox; % open a device and store information into struct info
end

switch cmd
    case 'start' % send serial trigger to device
        [nw tpost err tpre]=IOPort('Write',s,'Y');
        twin=tpost-tpre-tpreOffset;
        if nargout, varargout={tpre twin}; end
        if twin>0.003, RTBoxWarn('USBoverload',twin); end
    case 'eventsavailable'
        varargout{1}=IOPort('BytesAvailable',s)/7;
    case 'ttl' % send TTL
        if isempty(in2), in2=1; end % default event code
        if ischar(in2), in2=bin2dec(in2); end % can be binary string
        maxTTL=255; if info(id).version<5, maxTTL=15; end
        if in2<0 || in2>maxTTL || in2~=round(in2), RTBoxError('invalidTTL',maxTTL); end
        if info(id).version<3.2
            in2=dec2bin(in2,4);
            in2=bin2dec(in2(4:-1:1)); % reverse bit order
        end
        if info(id).version>=5, in2=[1 in2]; end
        [nw tpost err tpre]=IOPort('Write',s,uint8(in2)); % send
        twin=tpost-tpre-tpreOffset;
        if nargout, varargout={tpre twin}; end
        if info(id).version<3, RTBoxWarn('notSupported',in1,3); return; end
        if twin>0.003, RTBoxWarn('USBoverload',twin); end
    case 'clear'
        if isempty(in2), in2=20; end % # of sync
        if in2>0, syncClocks(1:6,in2); % clear buffer, sync clocks
        elseif any(info(id).enabled(3:6))
            enableByte(2.^(0:5)*info(id).enabled'); % enable trigger if applicable
        else purgeRTBox;
        end 
        if nargout, varargout{1}=info(id).sync; end
    case 'waittr' % wait for scanner TR, for v3.0 or later
        enableByte(16); % enable only TR
        FlushEvents; % in case we use key '5'
        while 1
            if IOPort('BytesAvailable',s)>=7
                b7=IOPort('Read',s,0,7);
                syncClocks([],20); % new sync
                t=bytes2secs(b7(2:7)')+info(id).sync(1);
                break;
            end
            [key t]=ReadKey({'5' 'esc'}); % check key press
            if any(strcmp(key,'5')), break
            elseif strcmp(key,'esc'), error('User Pressed ESC. Exiting.'); 
            end
            WaitSecs('YieldSecs',info(id).latencyTimer); % allow serial buffer updated
        end
        enableByte(2.^(0:1)*info(id).enabled(1:2)'); % restore button
        if nargout, varargout{1}=t; end
    case read % 13 trigger events, plus 'secs' 'boxsecs'
        tnow=GetSecs;
        cmdInd=find(strcmp(cmd,read),1,'last'); % which command
        nEventsRead=info(id).nEventsRead;
        if cmdInd<14 % relative to trigger
            nEventsRead=nEventsRead+1; % detect 1 more event
            ind=[cmdInd<5 (cmdInd<9 && cmdInd>4) cmdInd==9:12];
            if ~any(info(id).enabled(ind)) && cmdInd~=13
                RTBoxError('triggerDisabled',events4enable{ind}); 
            end
        end
        if isempty(in2), in2=0.1; end % default timeout
        if info(id).untilTimeout, tout=in2;
        else tout=tnow+in2; % stop time
        end
        varargout={[] ''}; % return empty if no event detected
        isreading=false;
        byte=IOPort('BytesAvailable',s);
        while (tnow<tout && byte<nEventsRead*7 || isreading)
            WaitSecs('YieldSecs',info(id).latencyTimer); % update serial buffer
            byte1=IOPort('BytesAvailable',s);
            isreading= byte1>byte; % wait if reading
            byte=byte1;
            [key tnow]=ReadKey('esc');
            if ~isempty(key), RTBoxError('escPressed'); end
        end
        nevent=floor(byte/7);
        if nevent<nEventsRead, return; end  % return if not enough events
        b7=IOPort('Read',s,0,nevent*7);
        b7=reshape(b7,[7 nevent]); % each event contains 7 bytes
        timing=[];
        for i=1:nevent % extract each event and time
            ind=find(b7(1,i)==eventcodes,1); % which event
            if isempty(ind)
                RTBoxWarn('invalidEvent',b7(:,i));
                break; % not continue, rest must be messed up
            end
            event{i}=info(id).events{ind}; %#ok event name
            timing(i)=bytes2secs(b7(2:7,i)); %#ok box time
            eventInd(i)=ind; %#ok for debouncing
        end
        if isempty(timing), return; end

        % software debouncing for <v1.5
        if info(id).version<1.5 && info(id).debounceInterval>0 && length(unique(eventInd))<length(eventInd)
            rmvInd=[];
            for i=1:8 % 8 button down and up events
                ind=find(eventInd==i);
                if length(ind)<2, continue; end
                bncInd=find(diff(timing(ind))<info(id).debounceInterval);
                rmvInd=[rmvInd ind(bncInd+(i<5))]; %#ok
            end
            event(rmvInd)=[]; timing(rmvInd)=[];
        end
        
        if cmdInd==14 % secs: convert into computer time
            if timing(end)-info(id).sync(2)>9 % sync done too long before?
                sync=info(id).sync(1:2); % remember last sync for interpolation
                syncClocks(1:2,20); % update sync
                sync(2,:)=info(id).sync(1:2); % append current sync
                tdiff=interp1(sync(:,2),sync(:,1),timing); % linear interpolation
            else tdiff=info(id).sync(1);
            end
            timing=timing+tdiff; % computer time
        elseif cmdInd<14 % relative to trigger
            ind=find(strcmpi(cmd,event),1); % trigger index
            if isempty(ind), RTBoxWarn('noTrigger',cmd); return; end
            trigT=timing(ind); % time of trigger event
            event(ind)=[]; timing(ind)=[]; % omit trigger and its time from output
            if isempty(event), return; end % if only trigger event, return empty
            timing=timing-trigT;   % relative to trigger time
        end
        
        if length(event)==1, event=event{1}; end % if only 1 event, use string
        varargout={timing event};
    case 'purge' % this may be removed in the future. Use RTBox('clear',0)
        if any(info(id).enabled(3:6))
            enableByte(2.^(0:5)*info(id).enabled'); % enable trigger if applicable
        else purgeRTBox; % clear buffer
        end
    case 'buttondown'
        enableByte(0); % disable all detection
        IOPort('Write',s,'?'); % ask button state: '4321'*16 63
        b2=IOPort('Read',s,1,2); % ? returns 2 bytes
        enableByte(2.^(0:1)*info(id).enabled(1:2)'); % enable detection
        if length(b2)~=2 || ~any(b2==63), RTBoxError('notRespond'); end
        b2=b2(b2~=63); % '?' is 2nd byte for old version 
        b2=bitget(b2,5:8); % most significant 4 bits are button states
        if nIn<2, in2=read(1:4); end % not specified which button
        in2=cellstr(in2); % convert it to cellstr if it isn't
        for i=1:length(in2)
            ind=strcmpi(in2{i},read(1:4));
            if ~any(ind), RTBoxError('invalidButtonName',in2{i}); end
            bState(i)=any(b2(ind)); %#ok
        end
        varargout{1}=bState;
    case 'enablestate'
        if info(id).version<1.4, RTBoxWarn('notSupported',in1,1.4); return; end
        for i=1:4
            IOPort('Purge',s);
            IOPort('Write',s,'E'); % ask enable state
            b2=IOPort('Read',s,1,2); % return 2 bytes
            if length(b2)==2 && b2(1)=='E', break; end
            if i==4, RTBoxError('notRespond'); end
        end
        b2=logical(bitget(b2(2),1:6)); % least significant 5 bits
        varargout{1}=events4enable(b2);
    case 'buttonnames' % set or query button names
        oldNames=info(id).events(1:4);
        if nIn<2, varargout{1}=oldNames; return; end
        if isempty(in2), in2={'1' '2' '3' '4'}; end % default
        if length(in2)~=4 || ~iscellstr(in2), RTBoxError('invalidButtonNames'); end
        info(id).events(1:8)=[in2 in2];
        if all(info(id).enabled(1:2))
            info(id).events(5:8)=strcat(in2,'up');
        end
       if nargout, varargout{1}=oldNames; end
    case {'enable' 'disable'} % enable/disable event detection
        if nIn<2 % no event, return current state
            varargout{1}=events4enable(info(id).enabled);
            return;
        end
        isEnable=strcmp(cmd,'enable');
        if strcmpi(in2,'all'), in2=events4enable; end
        in2=lower(cellstr(in2));
        in2=strrep(in2,'pulse','sound');
        foo=uint8(2.^(0:5)*info(id).enabled');
        for i=1:length(in2)
            ind=find(strcmp(in2{i},events4enable));
            if isempty(ind), RTBoxError('invalidEnable',events4enable); end
            foo=bitset(foo,ind,isEnable); info(id).enabled(ind)=isEnable;
        end
        enableByte(foo);
        if nargout, varargout{1}=events4enable(info(id).enabled); end
        if ~any(info(id).enabled), RTBoxWarn('allDisabled',info(id).ID); end
        if all(info(id).enabled(1:2))
            info(id).events(5:8)=strcat(info(id).events(1:4),'up');
        else
            info(id).events(5:8)=info(id).events(1:4);
        end
    case 'clockratio' % measure clock ratio computer/box
        if nargout, varargout{1}=info(id).clkRatio; return; end
        if isempty(in2), in2=30; end % default trials for clock test
        interval=1; % interval between trials
        ntrial=max(10,round(in2/interval)); % # of trials
        fprintf(' Measuring clock ratio. ESC to stop. Trials remaining:%4.f',ntrial);
        enableByte(0); % disable all
        i0=1; t0=GetSecs;
        % if more trials, we use first 10 trials to update ratio, then do
        % the rest using the new ratio
        if ntrial>=20 && info(id).clkRatio==1
            for i=1:10
                syncClocks([],10); % update info.sync, less trial
                fprintf('\b\b\b\b%4d',ntrial-i);
                t(i,:)=info(id).sync(1:2); %#ok
                WaitTill(t0+interval*i,'esc',0); % disable esc exit
            end
            info(id).clkRatio=1+linearfit(t); % update ratio
            i0=i+1; % start index for next test
        end
        for i=i0:ntrial
            syncClocks([],40); % update info.sync
            fprintf('\b\b\b\b%4d',ntrial-i);
            t(i,:)=info(id).sync(1:2); %#ok
            if i<ntrial, key=WaitTill(t0+interval*i,'esc'); end
            if isempty(key), continue; end
            if i-i0<10, RTBoxWarn('ratioTestAbort'); return;
            else RTBoxWarn('ratioTestStop',i); break;
            end
        end
        fprintf('\n');
        [slope se]=linearfit(t(i0:end,:));
        
        info(id).clkRatio=info(id).clkRatio*(1+slope); % update clock ratio
        if nargout, varargout{1}=info(id).clkRatio;
        else fprintf(' Clock ratio (computer/box): %.8f %s %.8f\n',info(id).clkRatio,char(177),se);
        end

        if se>1e-4, RTBoxWarn('ratioBigSE',se); end
        if abs(slope)>0.01, info(id).clkRatio=1; RTBoxError('ratioErr',slope); end
        
        if info(id).version>1.1 % store ratio in the device
            b4=round((info(id).clkRatio-0.99)*1e10);
            b4=dec2hex(b4,8); 
            b4=hex2dec(b4(reshape(1:8,2,4)'));
            b8=get8bytes;
            b8(4:8)=[115; b4]; % b8(4)=='s' to indicate ratio saved
            set8bytes(b8);
        else % store into a file for version<=1.1
            folderRTBox=fileparts(which(mfilename));
            [foo a]=fileattrib(folderRTBox);
            if ~a.UserWrite, folderRTBox=pwd; end % this is not effective for Windows
            fileName=fullfile(folderRTBox,'infoSave.mat');
            try %#ok<*TRYNC> % load saved info
                i=1;
                load(fileName);
                i=find(strcmp(info(id).portname,{infoSave.portname})); %#ok
                if isempty(i), i=length(infoSave)+1; end
            end
            infoSave(i).portname=info(id).portname;
            infoSave(i).clkRatio=info(id).clkRatio;
            dt=now; dt=now*24*3600-GetSecs;
            [nw foo err tpre]=IOPort('Write',s,'Y');
            infoSave(i).secs=dt+tpre;
            b7=IOPort('Read',s,1,7);
            infoSave(i).BoxSecs=byte2secs(b7(2:7)',1); %#ok
            try save(fileName,'infoSave'); end % save all
        end
        syncClocks([],10); % update info.sync using new ratio
        enableByte(2.^(0:1)*info(id).enabled(1:2)'); % restore button detection
    case 'ttlwidth'
        if nIn<2, varargout{1}=info(id).TTLWidth; return; end
        if nargout, varargout{1}=info(id).TTLWidth; end
        if info(id).version<3, RTBoxWarn('notSupported',in1,3); return; end
        wUnit=1/7200; % 0.139e-3 s, width unit, not very accurate
        if isempty(in2), in2=0.00097; end
        if isinf(in2), in2=0; end
        if (in2<wUnit*0.9 || in2>wUnit*255*1.1) && in2>0, RTBoxWarn('invalidTTLwidth',wUnit); end
        width=double(uint8(in2/wUnit))*wUnit; % real width
        b8=get8bytes;
        b8(1)=width/wUnit;
        if info(id).version>4, b8(1)=255-b8(1); end
        set8bytes(b8);
        if in2>0 && abs(width-in2)/in2>0.1, RTBoxWarn('widthOffset',width); end
        if width==0, width=inf; end
        info(id).TTLWidth=width;
        if nargout, varargout{1}=width; end
        purgeRTBox;
    case 'ttlresting'
        if nIn<2, varargout{1}=info(id).TTLresting; return; end
        if nargout, varargout{1}=info(id).TTLresting; end
        if info(id).version<3.1, RTBoxWarn('notSupported',in1,3.1); return; end
        if isempty(in2), in2=logical([0 1]); end
        info(id).TTLresting=in2;
        b8=get8bytes;
        if info(id).version<5, b8(3)=in2(1)*240; % '11110000'
        else
            b8(3)=bitset(b8(3),1,in2(1));
            b8(3)=bitset(b8(3),2,in2(2));
        end
        set8bytes(b8);
    case 'reset'
        if info(id).version<1.4, RTBoxWarn('notSupported',in1,1.4); return; end
        b8=get8bytes; % to restore later
        IOPort('Write',s,'xBS'); % simple mode, boot, bootID
        IOPort('Write',s,'R'); % return, so restart
        IOPort('Write',s,'X'); % advanced mode
        IOPort('Read',s,1,7+21); % clear buffer
        set8bytes(b8); % restore param
        syncClocks(1:2,10);
    case 'debounceinterval'
        oldVal=info(id).debounceInterval;
        if nIn<2, varargout{1}=oldVal; return; end
        if isempty(in2), in2=0.05; end
        if ~isscalar(in2) || ~isnumeric(in2) || in2<0, RTBoxError('invalidValue',in1); end
        info(id).debounceInterval=in2;
        if info(id).version>=1.5
            if in2>0.2833, RTBoxWarn('invalidDebounceInterval'); end
            b8=get8bytes;
            b8(2)=uint8(in2*921600/1024);
            info(id).debounceInterval=b8(2)*1024/921600;
            set8bytes(b8);
            purgeRTBox;
        end
        if nargout, varargout{1}=oldVal; end
    case 'untiltimeout'
        oldVal=info(id).untilTimeout;
        if nIn<2, varargout{1}=oldVal; return; end
        if isempty(in2), in2=0; end
        info(id).untilTimeout=in2;
        if nargout, varargout{1}=oldVal; end
    case 'neventsread'
        oldVal=info(id).nEventsRead;
        if nIn<2, varargout{1}=oldVal; return; end
        if isempty(in2), in2=1; end
        info(id).nEventsRead=in2;
        if nargout, varargout{1}=oldVal; end
    case 'test' % quick test for events
        t0=GetSecs;
        fprintf(' Waiting for events. Press ESC to stop.\n');
        fprintf('%9s%9s-%.4f\n','Event','secs',t0);
        while isempty(ReadKey('esc'))
            WaitSecs('YieldSecs',0.02);
            if IOPort('BytesAvailable',s)<7, continue; end
            b7=IOPort('Read',s,0,7); % read data
            t=bytes2secs(b7(2:7)')+info(id).sync(1);
            ind=find(b7(1)==eventcodes); % which event
            if isempty(ind)
                ind=nan; event='invalid'; t=nan; %purgeRTBox; % no complain
                disp(b7);
            else event=info(id).events{ind}; % event ID
            end
            fprintf('%9s%12.4f\n',event,t-t0);
        end
    case 'info'
        oldVal=info(id);
        if nIn<2
            if nargout, varargout{1}=oldVal; return; end
            fprintf(' Computer: %s (%s)\n',computer,getenv('OS'));
            fprintf(' Matlab: %s\n',version);
            fprintf(' RTBox.m last updated on 9/27/2011\n');
            fprintf(' ID(%g): %s, v%3.1f\n',id,info(id).ID,info(id).version);
            fprintf(' Serial port: %s\n',info(id).portname);
            fprintf(' IOPort handle: %g\n',s);
            fprintf(' Latency Timer: %g\n',info(id).latencyTimer);
            fprintf(' Box clock unit: %g\n',info(id).clockUnit);
            fprintf(' Debounce interval: %g\n',info(id).debounceInterval);
            fprintf(' GetSecs/Box clock unit ratio: %.8g\n',info(id).clkRatio);
            fprintf(' GetSecs-Box clock offset: %.5f+%.5f\n',info(id).sync([1 3]));
            fprintf(' Events enabled: %s\n',cell2str(events4enable(info(id).enabled)));
            fprintf(' Number of events to wait: %g\n',info(id).nEventsRead);
            fprintf(' Use until-timeout for read: %g\n',info(id).untilTimeout);
            fprintf(' Number of events available: %g\n\n',IOPort('BytesAvailable',s)/7);
            return; 
        end
        if ~isstruct(in2), RTBoxError('invalidInfoStuct'); end
        fd1=fieldnames(info(id)); fd2=fieldnames(in2);
        if length(fd1)~=length(fd2), RTBoxError('invalidInfoStuct'); end
        bool=regexp(fd1,fd2); % compare fields
        if sum([bool{:}])~=length(fd1), RTBoxError('invalidInfoStuct'); end
        info(id)=in2; % accept it, but may still have invalid values
        if nargout, varargout{1}=oldVal; end
    case 'close' % close one device
        if isempty(info(id).cleanObj) % for earlier matlab version
            closeRTBox(s,info(id).version,info(id).portname)
        else
            info(id)=[]; % delete the slot, invoke closeRTBox
        end
    case 'closeall' % close all devices
        if isempty(info(id).cleanObj)
            for i=1:length(info)
                closeRTBox(s,info(i).version,info(i).portname)
            end
        else
            clear RTBox; % clear info etc, invoke closeRTBox
        end
    case 'keynames'
        varargout{1}=ReadKey('keynames');
    otherwise, RTBoxError('unknownCmd',in1,cmds,info(id).events); % impossible to reach here
end % end of switch. Following are nested functions called by main function

    function syncClocks(enableInd,nr)
        if any(info(id).enabled), enableByte(0); end % disable all
        %oldPriority=Priority(MaxPriority('GetSecs')); % raise priority
        tt=zeros(nr,3);

        IOPort('Purge',s);
        for ic=1:nr
            for ir=1:4
                WaitSecs(rand/1000); % 0~1 ms random interval
                [nw tt(ic,2) err tt(ic,1)]=IOPort('Write',s,'Y',1);
                b7=IOPort('Read',s,1,7);
                if length(b7)==7 && b7(1)==89, break; end
                purgeRTBox;
                if ir==4, RTBoxError('notRespond'); end
            end
            tt(ic,3)=bytes2secs(b7(2:7)');
        end
        %Priority(oldPriority); % restore priority
        tt(:,1)=tt(:,1)+tpreOffset; % correct tpre
        [tdiff ic]=max(tt(:,1)-tt(:,3)); % the latest tpre is the closest to real write
        twin=diff(tt(ic,1:2)); % tpost-tpre for the selected sample: upper bound
        tbox=tt(ic,3); % used for linear fit and time check
        tdiff_ub=min(tt(:,2)-tt(:,3))-tdiff; % earliest tpost - lastest tpre
        [foo ic]=min(tt(:,2)-tt(:,1)); % find minwin index
        method3_1=mean(tt(ic,1:2))-tt(ic,3)-tdiff; % diff between methods 3 and 1
        info(id).sync=[tdiff tbox tdiff_ub method3_1]; % remember tdiff, its tbox and ub's
        if twin>0.003 && tdiff_ub>0.001, RTBoxWarn('USBoverload',twin,tdiff_ub); end
        if isempty(enableInd), return; end
        foo=0:5; foo=foo(enableInd); foo=2.^foo*info(id).enabled(enableInd)';
        enableByte(foo); % restore enable
    end

    % send enable byte
    function enableByte(enByte)
        enByte=uint8(enByte);
        if info(id).version<4.1
            if info(id).version>=1.4
                for ir=1:4
                    purgeRTBox;
                    IOPort('Write',s,'E');
                    oldByte=IOPort('Read',s,1,2);
                    if length(oldByte)==2 && oldByte(1)=='E', break; end
                    if ir==4, RTBoxError('notRespond'); end
                end
                foo=bitxor(enByte,oldByte(2));
            else foo=uint8(15); % 4 events
            end
            enableCode='DUPOF'; % char to enable events, lower case to disable
            for ie=1:5
                if bitget(foo,ie)==0, continue; end
                str=enableCode(ie);
                if bitget(enByte,ie)==0, str=lower(str); end
                for ir=1:4
                    purgeRTBox; % clear buffer
                    IOPort('Write',s,str); % send single char
                    if IOPort('Read',s,1,1)==str, break; end % feedback
                    if ir==4, RTBoxError('notRespond'); end
                end
            end
        else % >=4.1
            for ir=1:4 % try in case of failure
                purgeRTBox; % clear buffer
                IOPort('Write',s, 'e');
                if IOPort('Read',s,1,1)=='e', break; end % feedback
                if ir==4, RTBoxError('notRespond'); end
            end
            IOPort('Write',s, enByte);
        end
    end

    % purge only when idle, prevent from leaving residual in buffer
    function purgeRTBox
        byte=IOPort('BytesAvailable',s);
        tout=GetSecs+1; % if longer than 1s, something is wrong
        while 1
            WaitSecs('YieldSecs',info(id).latencyTimer); % allow buffer update
            byte1=IOPort('BytesAvailable',s);
            if byte1==byte, break; end % not receiving
            if GetSecs>tout, RTBoxError('notRespond'); end
            byte=byte1;
        end
        IOPort('Purge',s);
    end

    % convert 6-byte b6 into secs according to time unit of box clock.
    function secs=bytes2secs(b6,ratio)
        if nargin<2, ratio=info(id).clkRatio; end
        secs=256.^(5:-1:0)*b6*info(id).clockUnit*ratio;
    end

    function b8=get8bytes
        purgeRTBox;
        IOPort('Write',s,'s');
        b8=IOPort('Read',s,1,8);
    end

    function set8bytes(b8)
        IOPort('Write',s,'S');
        IOPort('Write',s,uint8(b8));
        IOPort('Read',s,1,1);
        IOPort('Purge',s);
    end

    function closeRTBox(s, v, port)
        if isempty(s) || s<0, return; end
        verbo=IOPort('Verbosity',0); % IOPort may be cleared before RTBox
        s0=IOPort('OpenSerialPort',port,'BaudRate=115200');
        IOPort('Verbosity',verbo);
        if s0>=0, s=s0; end
        IOPort('Write',s,'a'); % disable all event
        if v>1.3
            IOPort('Write',s,'Dx'); % enable down, switch to simple mode
        end
        IOPort('Close',s); % close port
    end

    function openRTBox
        % get possible port list for different OS
        if IsWin
            % suppose you did not assign RTBox to COM1 or 2
            ports=cellstr(num2str((3:256)','\\\\.\\COM%i'));
            ports=strtrim(ports); % needed for matlab 2009b
        elseif IsOSX
            ports=dir('/dev/cu.usbserialRTBox*');
            macLatFail=0;
            if isempty(ports), ports=dir('/dev/cu.usbserial*'); macLatFail=1; end
            if ~isempty(ports), ports=strcat('/dev/',{ports.name}); end
        elseif IsLinux
            ports=dir('/dev/ttyUSB*');
            if ~isempty(ports), ports=strcat('/dev/',{ports.name}); end
        else error('Unsupported system: %s.', computer);
        end
        if ~isempty(portname)
            foo=lower(ports);
            ind=strcmpi(portname,foo);
            if ~any(ind)
                foo=strrep(foo,'\\.\','');
                foo=strrep(foo,'/dev/','');
                ind=strcmpi(portname,foo);
            end
            if ~any(ind), RTBoxError('portNotExist',portname); end
            ports=ports(ind); % use the provided port
        end

        nPorts=length(ports);
        if nPorts==0, RTBoxError('noUSBserial'); end
        deviceFound=0; 
        rec=struct('avail','','busy',''); % for error record only
        verbo=IOPort('Verbosity',0); % shut up screen output and error
        cfgStr='BaudRate=115200 ReceiveTimeout=1 PollLatency=0';
        for ic=1:nPorts
            port=ports{ic};
            % this also solves multiple open problem in MAC/Linux
            if any(strcmp(port,{info(1:id-1).portname})), continue; end
            [s errmsg]=IOPort('OpenSerialPort',port,cfgStr);
            if s>=0  % open succeed
                IOPort('Purge',s); % clear port
                IOPort('Write',s,'X',0); % ask identity, switch to advanced mode
                idn=IOPort('Read',s,1,21); % contains 'USTCRTBOX'
                if ~IsWin && isempty(strfind(idn,'USTCRTBOX'))
                    IOPort('Close',s); % try to fix ID failure in MAC and Linux
                    s=IOPort('OpenSerialPort',port,cfgStr);
                    IOPort('Write',s,'X',0);
                    idn=IOPort('Read',s,1,21);
                end
                if length(idn)==1 && idn=='?' % maybe in boot
                    IOPort('Write',s,'R',0); % return to application
                    IOPort('Write',s,'X',0);
                    idn=IOPort('Read',s,1,21);
                end
                if strfind(idn,'USTCRTBOX'), deviceFound=1; break; end
                rec.avail{end+1}=port; % exist but not RTBox
                IOPort('Close',s); % not RTBox, close it
            elseif isempty(strfind(errmsg,'ENOENT'))
                rec.busy{end+1}=port; % open failed but port exists
            end
        end
        if ~deviceFound % issue error
            info(id)=[];
            if isempty(portname), RTBoxError('noDevice',rec,info);  end
            RTBoxError('invalidPort',rec,info,portname);  % Windows only
        end
        try [oldVal err]=LatencyTimer(port,1); % set it to 1 ms
        catch oldVal=nan; err=lasterr; %#ok, just in case of LatencyTimer error
        end
        latency=1;
        if ~isempty(err) % failed to change
            if isnan(oldVal), oldVal=16; end % best guess
            latency=oldVal;
            if latency>2, RTBoxWarn('LatencyTimerFail',err); end
        end
        if IsOSX && macLatFail, latency=16; end
        if IsWin && oldVal~=latency  % close/reopen to make change effect
            IOPort('Close',s);
            s=IOPort('OpenSerialPort',port,cfgStr);
        end
        info(id).latencyTimer=latency/1000;
        info(id).handle=s; info(id).portname=port; info(id).ID=boxID; % store info
        ind=strfind(idn,',v')+2;
        if isempty(ind) % strange problem for MAC, maybe Lunix too
            IOPort('Purge',s);
            IOPort('Write',s,'X',0);
            idn=IOPort('Read',s,1,21);
            ind=strfind(idn,',v')+2;
        end
        v=str2double(char(idn(ind+(0:2)))); % firmware version
        info(id).version=v;
        if strfind(idn,'921600'), info(id).clockUnit=1/921600; end
        if exist('verLessThan','file') && ~verLessThan('matlab', '7.4') % 2007a +
            info(id).cleanObj=onCleanup(@()closeRTBox(s,v,port)); % clean up automatically
        end

        if v>1.1
            b8=get8bytes; setB8=0;
            if v>=5.0 && any(b8(1:3)~=[248 45 2])
                b8(1:3)=[248 45 2]; setB8=1;
            elseif v>4 && any(b8(1:3)~=[248 45 0])
                b8(1:3)=[248 45 0]; setB8=1;
            elseif v>1.4 && any(b8(1:3)~=[7 45 0])
                b8(1:3)=[7 45 0]; setB8=1; % default TTL width, debounceMS & TTLresting
            elseif v<=1.4 && any(b8(1:2)~=[7 16])
                b8(1:2)=[7 16]; setB8=1; % default TTL width, scanNum
            end
            if setB8, set8bytes(b8); end
            if b8(4)==115 % clock ratio saved
                info(id).clkRatio=256.^(3:-1:0)*b8(5:8)'/1e10+0.99;
            end
        else % version<=1.1
            fname=fullfile(fileparts(which(mfilename)),'infoSave.mat');
            if ~exist(fname,'file'), fname=fullfile(pwd,'infoSave.mat'); end
            if exist(fname,'file')
                S=load(fname); S=S.infoSave;
                ic=strcmp(port,{S.portname});
                if any(ic)
                    S=S(ic);
                    dt=now; dt=now*24*3600-GetSecs;
                    [nw foo err tpre]=IOPort('Write',s,'Y'); %#ok
                    b7=IOPort('Read',s,1,7);
                    td=bytes2secs(b7(2:7)',1)-S.BoxSecs;
                    drift=abs((tpre+dt-S.secs)/td-1);
                    if drift<0.01, info(id).clkRatio=S.clkRatio; end % retrieve ratio
                end
            end
        end
        syncClocks([],5);
        if info(id).clkRatio==1 && ~strcmp(cmd,'clockratio')
            RTBoxWarn('clockRatioUncorrected');
            sync=info(id).sync(1:2); 
            WaitSecs('YieldSecs',0.5);
            syncClocks([],5); sync(2,1:2)=info(id).sync(1:2);
            info(id).clkRatio=diff(sync(:,1))/diff(sync(:,2))+1;
        end
        enableByte(1); % enable button press after open
        IOPort('Verbosity',verbo); % restore verbosity
        % fprintf(' %s opened at %s.\n',boxID,cell2str(port));
    end
end % end of main function

% put verbose error message here, to make main code cleaner
function RTBoxError(err,varargin)
switch err
    case 'noUSBserial'
        str='No USB-serial ports found. Is your device connected, or driver installed from http://www.ftdichip.com/Drivers/VCP.htm?';
    case 'noDevice'
        [p info]=deal(varargin{:});
        if isempty(p.avail) && isempty(p.busy) && isempty(info)
            RTBoxError('noUSBserial'); % Windows only
        end
        str='';
        if ~isempty(p.avail) % have available ports
            str=sprintf(['%s Port(s) available: %s, but failed to get identity. ' ...
            'Is any of them the RT device? If yes, try again. ' ...
            'It may help to unplug then plug the device. '],str,cell2str(p.avail));
        end
        if ~isempty(p.busy) % have busy ports
            str=sprintf(['%s Port(s) unavailable: %s, probably used by other program. ' ...
            'Is any of them the RT device? If yes, try ''clear all'' to close the port.'], str, cell2str(p.busy));
        end
        if isempty(str), str='No available port found. '; end
        if ~isempty(info) % have opened RTBox
            str=sprintf('%s Already opened RT device:', str);
            for i=1:length(info)
                str=sprintf('%s %s at %s,',str,info(i).ID,cell2str(info(i).portname));
            end
            str(end)='.';
        else
            str=sprintf(['%s If you like to test your code without RTBox connected, '...
                'check RTBox fake? for more information.'], str);
        end
    case 'invalidPort'
        [p info portname]=deal(varargin{:});
        if isempty(p.avail) && isempty(p.busy) && isempty(info)
            RTBoxError('portNotExist',cell2str(portname)); % Windows only
        end
        str='';
        if ~isempty(p.avail) % available
            str=sprintf([' Port %s is available, but failed to get identity. ' ...
            'Is it the RT device? If yes, try again. It may help to unplug then plug the device. '],cell2str(p.avail));
        end
        if ~isempty(p.busy) % is busy
            str=sprintf(['%s Port %s is not available, probably used by other program. ' ...
            'Is it the RT device? If yes, try ''clear all'' to close the port.'], str, cell2str(p.busy));
        end
        if ~isempty(info) % have opened RTBox
            str=sprintf('%s %s is already open.', str, cell2str(portname));
        end
    case 'unknownCmd'
        str=sprintf(['Unknown command or trigger: ''%s''. '...
         'The first string input must be one of the commands or events: %s, %s.'],...
         varargin{1},cell2str(varargin{2}),cell2str(unique(varargin{3})));
    case 'invalidButtonNames'
        str=sprintf('ButtonNames requires a cellstr containing four button names.');
        subFuncHelp('RTBox','buttonNames?');
    case 'invalidButtonName'
        str=sprintf('Invalid button name: %s.',varargin{1});
    case 'notRespond'
        str=sprintf('Failed to communicate with device. Try to close and re-connect the device.');
    case 'invalidEnable'
        str=sprintf('Valid events for enable/disable: %s.',cell2str(varargin{1}));
        subFuncHelp('RTBox','Enable?');
    case 'triggerDisabled'
        str=sprintf('Trigger is not enabled. You need to enable ''%s''.',varargin{1});
    case 'ratioErr'
        str=sprintf('The clock ratio difference is too high: %2g%%. Your computer timing probably has problem.',abs(varargin{1})*100);
    case 'invalidTTL'
        str=sprintf('TTL output must be integer from 0 to %g, or equivalent binary string.',varargin{1});
        subFuncHelp('RTBox','TTL?');
    case 'invalidValue'
        str=sprintf('The value for %s must be a numeric scalar.',varargin{1});
        subFuncHelp('RTBox',[varargin{1} '?']);
    case 'invalidInfoStuct'
        str=sprintf('The input for info must be a struct with the same fields as the one returned by RTBox(''info'').');
        subFuncHelp('RTBox','info?');
    case 'portNotExist'
        str=sprintf('The specified port %s does not exsit.',varargin{1});
    case 'escPressed'
        str='User Pressed ESC. Exiting.';
    otherwise, str=err;
end
error(['RTBox:' err],WrapString(str));
end

% Show warning message, but code will keep running.
% For record, this may write warning message into file 'RTBoxWarningLog.txt'
function RTBoxWarn(err,varargin)
switch err
    case 'invalidEvent'
        str=sprintf(' %g',varargin{1});
        str=sprintf('Events not recognized:%s. Please do RTBox(''clear'') before showing stimulus.\nGetSecs = %.1f',str,GetSecs);
    case 'noTrigger'
        str=sprintf('Trigger ''%s'' not detected. GetSecs = %.1f', varargin{1}, GetSecs);
    case 'allDisabled'
        str=sprintf('All event detection has been disabled for %s.', varargin{1});
    case 'USBoverload'
        str=sprintf('Possible system overload detected. This may affect clock sync.\n twin=%.1fms, ',varargin{1}*1000);
        if length(varargin)>1, str=sprintf('%stdiff_ub: %.1fms, ',str,varargin{2}*1000); end
        str=sprintf('%sGetSecs=%.1f',str,GetSecs);
    case 'invalidTTLwidth'
        str=sprintf('Supported TTL width is from %.2fe-3 to %.2fe-3 s .',[1 255]*varargin{1}*1000);
    case 'widthOffset'
        str=sprintf('TTL width will be about %.5f s', varargin{1});
    case 'clockRatioUncorrected'
        str=sprintf('Clock ratio has not been corrected. Please run RTBox(''ClockRatio'').');
    case 'ratioTestAbort'
        str=sprintf('User pressed ESC. Too less trials for clock ratio test. Aborted!'); 
    case 'ratioTestStop'
        str=sprintf('User pressed ESC. %g trials are used for clock ratio test.',varargin{1}); 
    case 'fakeMode'
        str=sprintf('RTBox %s working in keyboard simulation mode.',varargin{1});
    case 'ratioBigSE'
        str=sprintf('The slope SE is large: %2g. Try longer time for ClockRatio.',varargin{1});
    case 'notSupported'
        str=sprintf('The command %s is supported only for v%.1f or later.',varargin{1:2});
    case 'LatencyTimerFail'
        str=sprintf('%s This simply means failure to speed up USB-serial port reading. It won''t affect RTBox function.',varargin{1});
    case 'invalidDebounceInterval'
        str=sprintf('The debounce interval should be between 0 and 0.2833.');
    otherwise
        str=sprintf('%s. GetSecs = %.1f',err,GetSecs);
end
str=WrapString(str);
% warning(['RTBox:' err],str);
fprintf(2,'\n Warning: %s\n',str);
fid=fopen(fullfile(fileparts(which(mfilename)),'RTBoxWarningLog.txt'),'a'); 
if fid<0, return; end
fprintf(fid,'%s\n%s\n\n',datestr(now),str); % write warning into log file
fclose(fid);
end

% return str from cellstr for printing, also remove port path
function str=cell2str(Cstr)
    if isempty(Cstr), str=''; return; end
    str=cellstr(Cstr);
    str=strrep(str,'\\.\',''); % Windows path for ports
    str=strrep(str,'/dev/','');  % MAC/Linux path for ports
    str=sprintf('%s, ',str{:}); % convert cell into str1, str2,
    str(end+(-1:0))=''; % delete last comma and space
end

function [slope se]=linearfit(t)
    x=t(:,2)-t(1,2); y=t(:,1)-t(1,1);
    b=polyfit(x,y,1);
    slope=b(1);
    se=std(x*b(1)+b(2)-y)/length(x); % rough estimate of se
end

% This will call WaitTill to read keyboard
function [info varargout]=RTBoxFake(cmd,info,in2)
    keys=unique(info.events(1:4));
    switch cmd
        case 'eventsavailable'
            varargout{1}=length(ReadKey(keys));
        case 'buttondown'
            if isempty(in2), in2=info.events(1:4); end
            key=cellstr(ReadKey(in2));
            down=zeros(1,length(in2));
            for i=1:length(key)
                if isempty(key{i}), break; end
                down(strncmp(key{i},in2,length(key{i})))=1;
            end
            varargout{1}=down;
        case {'secs' 'boxsecs'}
            if isempty(in2), in2=0.1; end
            if info.untilTimeout, tout=in2;
            else tout=GetSecs+in2;
            end
            k={}; t=[];
            nEvents=info.nEventsRead;
            while 1
                [kk tt]=ReadKey(keys);
                if ~isempty(kk)
                    kk=cellstr(kk); n=length(kk);
                    k(end+(1:n))=kk; t(end+(1:n))=tt; %#ok
                    if length(k)>=nEvents, break; end
                    KbReleaseWait; % avoid detecting the same key
                end
                if tt>tout, break; end
            end
            if isempty(k), t=[]; k=''; end
            varargout={t k};
        case info.events([1:8 11]) % buttons and TR as trigger
            if isempty(in2), in2=0.1; end
            [k t0]=WaitTill(in2+GetSecs,cmd);
            if isempty(k), varargout={[] ''}; return; end
            KbReleaseWait; % avoid catch the first key 
            [k t1]=WaitTill(in2+GetSecs,keys);
            if isempty(k), t=[]; else t=t1-t0; end
            varargout={t k};
        case info.events([9 10 12 13]) % light, sound, aux and serial
            if isempty(in2), in2=0.1; end
            t0=GetSecs; % fake trigger time
            if info.untilTimeout, tout=in2;
            else tout=t0+in2;
            end
            k={}; t1=[];
            nEvents=info.nEventsRead-1;
            if isempty(nEvents), nEvents=1; end
            while GetSecs<tout
                [kk tt]=WaitTill(GetSecs+0.01,keys);
                if ~isempty(kk)
                    kk=cellstr(kk); n=length(kk);
                    k(end+(1:n))=kk; t1(end+(1:n))=tt; %#ok
                    if length(k)>=nEvents, break; end
                    KbReleaseWait; % avoid detecting the same key
                end
            end
            if isempty(k), t=[]; else t=t1-t0; end
            varargout={t k};
        case 'waittr'
            [k, varargout{1}]=WaitTill('5'); %#ok<ASGLU>
        case {'start' 'ttl'}
            if nargout>1, varargout={GetSecs 0}; end
        case {'debounceinterval' 'ttlwidth' 'neventsread' 'untiltimeout' 'ttlresting'}
            params={'debounceInterval' 'TTLWidth' 'nEventsRead' 'untilTimeout' 'TTLresting'};
            ind=strcmpi(cmd,params);
            oldVal=info.(params{ind});
            if isempty(in2), varargout{1}=oldVal; return; end
            info.(params{ind})=in2;
            if nargout>1, varargout{1}=oldVal; end
        case 'clear'
            if nargout>1, varargout{1}=[0 GetSecs 0 0]; end
        case 'buttonnames'
            varargout{1}=info.events(1:4);
            if isempty(in2), return; end
            if length(in2)~=4 || ~iscellstr(in2), RTBoxError('invalidButtonNames'); end
            info.events(1:8)=[in2 in2];
        case {'enable' 'disable' 'enablestate'}
            if isempty(in2) || nargout>1
                varargout{1}='press';
            end
        case {'close' 'closeall'}
            clear RTBox;
        case 'fake'
            if in2 && info.fake==0, RTBoxWarn('fakeMode',info.ID); end
            info.fake=in2;
        case 'keynames'
            varargout{1}=ReadKey('keynames');
        case 'test'
            t0=GetSecs;
            fprintf(' Waiting for events. Press ESC to stop.\n');
            fprintf('%9s%9s-%.4f\n','Event','secs',t0);
            while 1
                [event t]=ReadKey({info.events{1:4} 'esc'});
                if isempty(event), WaitSecs('YieldSecs',0.005); continue; 
                elseif strcmp(event,'esc'), break;
                else
                    fprintf('%9s%12.4f\n',event,t-t0);
                    KbReleaseWait;
                end
            end
        case 'info'
            if nargout>1, varargout{1}=info; end
        otherwise % purge, clockratio etc
            if nargout>1, varargout{1}=1; end
    end
end

% Show help for a subfuction. This requires that the help text for each
% subfunction starts with mfilename('subfunc') line(s), is followed by a
% '- ' line, and ends with a blank line.
function subFuncHelp(mfile,subcmd)
    str=help(mfile);
    while 1
        if isempty(strfind(str, '  ')), break; end
        str=strrep(str,'  ', ' '); % replace 2 space by one
    end
    % reduce 2+ blank lines to 2
    cr=char([10 32]);
    while 1
        if isempty(strfind(str, [cr cr cr])), break; end
        str=strrep(str,[cr cr cr], [cr cr]);
    end
    str=strrep(str,[mfile ' ('], [mfile '(']); % remove space before (
    str=strrep(str,[mfile '( '], [mfile '(']); % remove space after (

    prgfs=strfind(str,[cr cr]); % blank lines
    topics=strfind(str,[cr '-']); % new lines followed by -

    cmd=strrep(subcmd,'?',''); % remove ?
    if isempty(cmd) % help for main function
        ind=find(prgfs<topics(1),2,'last');
        disp(str(1:prgfs(ind(1)))); % subfunction list before any topic
        return; 
    end

    cmd=sprintf('%s(''%s''', mfile,cmd);
    ind=regexpi(str,cmd); % find syntax RTBox('clear'
    if isempty(ind)
        fprintf(2,' Unknown command for %s: %s\n',mfile,subcmd); 
        return;
    elseif length(ind)>1 % find one with syntax beits topic before next paragraph end
        for i=1:length(ind)
            i1=find(prgfs>ind(i),1); % end of next paragraph
            i2=find(topics>ind(i),1); % next ' -' line
            if prgfs(i1)>topics(i2), break; end % found it
        end
        ind=ind(i);
    end

    % now ind is the syntax location, we find the beginning of the topic
    i1=find(prgfs<ind,1,'last');
    if isempty(i1), i1=1; % first paragraph
    else i1=prgfs(i1)+2; % skip first char(10) and space
    end

    % find the beginning of next topic
    i2=find(topics>ind,2); % find next 2 topics
    if length(i2)<2, i2=length(str); % last paragraph
    else i2=prgfs(find(prgfs<topics(i2(2)),1,'last'));
    end
    disp(str(i1:i2));
end

% [oldVal err =] LatencyTimer(portname [,msecs]);
% Query/change FDTI USB-serial port latency timer. The query can be done with
% restricted users, but the change requires administrator privilege.
function varargout=LatencyTimer(port,msecs)
mfile=mfilename;
if nargin<1, help(mfile); return; end
errmsg=''; oldVal=nan;
warnID=[mfile ':RestrictedUser'];
warnmsg='Failed to change latency timer due to insufficient privilege.';
if IsWin
    port= strrep(port,'\\.\','');
    rootkey='HKEY_LOCAL_MACHINE';
    ftdikey='\SYSTEM\CurrentControlSet\Enum\FTDIBUS';
    [err txt]=system(['reg query ' rootkey ftdikey]);
    if err
        errmsg=txt;
        if nargout<2, warning([mfile ':NoVendor'],errmsg); end
        if nargout, varargout={oldVal txt}; end
        return; 
    end
       
    % find subkey for 'port'
    ftdikey=[ftdikey(2:end) '\VID_0403+PID_6001'];
    ind=strfind(txt, ftdikey);
    n=length(ind);
    for i=1:n
        i1=regexp(txt(ind(i):end), char(10), 'once');
        subkey=txt(ind(i)+(0:i1-2));
        subkey=[subkey '\0000\Device Parameters']; %#ok
        if strcmp(winqueryreg(rootkey,subkey,'PortName'),port), break; end
        if i==n % did not match port
            errmsg='Invalid port name.';
            if nargout<2, warning([mfile ':invaildPort'],errmsg); end
            if nargout, varargout={nan errmsg}; end
            return; 
        end
    end
    
    oldVal=double(winqueryreg(rootkey,subkey,'LatencyTimer')); % query it
    if nargin<2, varargout={oldVal errmsg}; return; end % query only
    if isempty(msecs), msecs=16; end % default
    msecs=uint8(msecs); % round it and make it within 255
    if oldVal~=msecs % need to change it
        fid=fopen('temp.reg','w'); % create a reg file
        fprintf(fid,'REGEDIT4\n');
        fprintf(fid,'[%s\\%s]\n',rootkey,subkey);
        fprintf(fid,'"LatencyTimer"=dword:%08x\n',msecs); % dword hex
        fclose(fid);
        % change registry, which will fail if not administrator
        [err txt]=system('reg import temp.reg');
        delete('temp.reg');
        if err
            errmsg=[warnmsg ' ' txt 'You need to start Matlab by right-clicking'...
                ' its shortcut or executable, and Run as administrator.'];
            if nargout<2, warning(warnID,WrapString(errmsg)); end
        end
    end
elseif IsOSX
    % port not needed. After the change, all FTDI serial ports may be affected.
    folder='/System/Library/Extensions';
    vendor='/FTDIUSBSerialDriver.kext'; % it may work if changed to other vendor
    fname=fullfile(folder,vendor,'/Contents/Info.plist');
    fid=fopen(fname);
    str=fread(fid,'*char')';
    fclose(fid);
    
    ind=regexp(str,'<key>FTDI2XXB','once');
    if isempty(ind), ind=regexp(str,'<key>FT2XXB','once'); end
    if isempty(ind)
        errmsg='Failed to detect product key.';
        if nargout<2, warning([mfile ':NoVendor'],errmsg); end
        if nargout, varargout={oldVal errmsg}; end
        return; 
    end
    % find first LatencyTimer key after FTDI2XXB key
    ind=ind+regexp(str(ind:end),'<key>LatencyTimer</key>','once');
    ind=ind+regexp(str(ind:end),'<integer>','once');
    i0=ind+8; % skip <integer>
    i1=ind+regexp(str(ind:end),'</integer>','once');
    i1=i1-2;
    oldVal=str2double(str(i0:i1)); % the value
    if nargin<2, varargout={oldVal errmsg}; return; end % query only
    msecs=uint8(msecs);
    if oldVal~=msecs
        tmp=fullfile(folder,vendor,'/Contents/tmpfoo');
        fid=fopen(tmp,'w+'); % test privilege
        if fid<0
            fprintf(' You will be asked for sudo password to change the latency timer.\n');
            fprintf(' Ctrl-C or Enter to skip the change.\n');
            err=system('sudo -v');
            if err
                errmsg=warnmsg;
                if nargout<2, warning(warnID,WrapString(errmsg)); end
                if nargout, varargout={oldVal errmsg}; end
                return;
            end
        else
            fclose(fid); delete(tmp);
        end
        tmp='/tmp/tmpfoo';
        fid=fopen(tmp,'w+');
        fprintf(fid,'%s',str(1:i0-1));
        fprintf(fid,'%i',msecs);
        if strcmp(mfile,'RTBox') % add PortName key for RTBox
            % allow to write RTBox folder to saver clock ratio
            system(['sudo chmod a+rw ' fileparts(which(mfile))]);
            ind=i1+regexp(str(i1:end),'</dict>','once');
            ind=i1+regexp(str(i1:ind),'>'); ind=ind(end);
            if isempty(regexp(str(i1:ind),'PortName','once'))
                fprintf(fid,'%s',str(i1+1:ind));
                fprintf(fid,'                <key>PortName</key>\n');
                fprintf(fid,'                <string>usbserialRTBox</string>\n');
                i1=ind;
            end
        end
        fprintf(fid,'%s',str(i1+1:end));
        fclose(fid);
        system(['sudo cp -f ' tmp ' ' fname]);
        system(['sudo rm ' tmp]);
        system(['sudo touch ' folder vendor]);
        system(['sudo touch ' folder]);
        system('sudo -k');
        errmsg='The change will take effect after you reboot the computer.';
        if nargout<2, warning([mfile ':rebootNeeded'],errmsg); end
    end
elseif IsLinux
    % for linux, no vendor related info needed, only the port name
    port=strrep(port,'/dev/','');
    str=sprintf('cd /sys/bus/usb-serial/devices/%s;',port);
    [err lat]=system([str 'cat latency_timer']); % query
    if err % unlikely happen
        errmsg=['Failed to read latency timer: ' lat];
        if nargout<2, warning([mfile ':readFail'],WrapString(errmsg)); end
        if nargout, varargout={nan errmsg}; end
        return;
    end
    oldVal=str2double(lat);
    if nargin<2, varargout={oldVal errmsg}; return; end % query only
    msecs=uint8(msecs);
    if oldVal~=msecs
        % change it. works only for su. But it seems su needed su anyway
        system([str 'echo ' num2str(msecs) ' > latency_timer']);
        [err lat]=system([str 'cat latency_timer']); %#ok check for sure
        if msecs~=str2double(lat)
            errmsg=[warnmsg ' You need to run Matlab as superuser.'];
            if nargout<2, warning(warnID,WrapString(errmsg)); end
        end
    end
else error('Unsupported system: %s.',computer);
end
if nargout, varargout={oldVal errmsg}; end
end
