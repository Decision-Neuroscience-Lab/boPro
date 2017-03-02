% This is a demo showing how to use RTBox as EEG interface. 
% The task is to identify the orientation of garbor. If garbor tilts to 11
% o'clock, press a left button; if to 1 o'clock, press a right button. 
% The result will be displayed in command window.
% Xiangrui Li, 3/2009
   
function RTBoxdemo_EEG(scrn)
if nargin<1, scrn=max(Screen('screens')); end % find last screen
radius=3;   % garbor radius in degree
dAngle=5; % tilt degree from vertical
sf=1.5; % spatial freq: cycles per deg
stimDur=0.1; % stimulus duration in sec
trialDur=2;    % length of trial
ppd=42; % pixels per degree: depending on distance, screen size and resolution
% ppd=distance*tan(1/180*pi)/screenWidth*screnResX;
contrast=[0.05 0.2 0.8]; % garbor contrast
ncond=length(contrast);
trialsPerCond=5; % # of trials per condition
ntrials=trialsPerCond*ncond;  % # of trials
randSeed=ClockRandSeed; % set seed for rand and randn

% record contains stim info and response. 
% We assign NaN to missed and unreasonable response.
record=nan(ntrials,7); 
%columns: iTrial cond tiltRight respCorrect RT trialStartSecs dt
recLabel='trial cond tiltRight respCorrect respTime startSecs dt';
record(:,1)=1:ntrials; % # of trial
seq=ones(ntrials,1); 
for i=2:ncond
    seq(trialsPerCond*(i-1)+(1:trialsPerCond))=i;
end
seq=Shuffle(seq); % you may use other better method for random seq
record(:,2)=seq; % 
LR=ones(ntrials,1); LR(1:round(ntrials/2))=0; % half ones, half zeros
record(:,3)=Shuffle(LR); % 1 for tilt right, 0 left

% RTBox('fake',1); % set RTBox to fake mode: use keyboard to simulate
RTBox('clear'); % Open RT box if hasn't
RTBox('ButtonNames',{'left' 'left' 'right' 'right'}); % make first 2 and last 2 equivalent
t_onset=RTBox('TTL',1); %#ok
t_onset=RTBox('TTL',1); %#ok practice the code for better timing

try % avoid dead screen in case of error
    [w r]=Screen('OpenWindow',scrn,127);  % open a screen
    HideCursor;
    ifi=Screen('GetFlipInterval',w); % flip interval
    
    % print some instruction
    Screen('TextSize',w,round(24/r(4)*1024)); % proportional font size 
    Screen('TextFont',w,'Times'); % seems needed for Windows
    str='This will test your RT to garbor orientation identification.';
    DrawFormattedText(w,str,'center',r(4)*0.3,[255 0 0]);
    str=sprintf('We will do %d trials. When you see a tilted garbor:',ntrials);
    DrawFormattedText(w,str,'center',r(4)*0.35,[255 0 0]);
    str=sprintf('press a green button if it tilts to left,');
    DrawFormattedText(w,str,'center',r(4)*0.4,[255 0 0]);
    str=sprintf('press a red button if it tilts to right');
    DrawFormattedText(w,str,'center',r(4)*0.45,[255 0 0]);
    DrawFormattedText(w,'Press any button to start trials', 'center', r(4)*0.6, 255);
    Screen('Flip',w); % show instruction
 
    txtsz=Screen('Textbounds',w,'M');
    ycenter=round(r(4)/2-txtsz(4)/2); % vertical center for feedback

    % generate texture tilted to left, will rotate 2*dAngle to tilt right
    imgsz=round(radius*ppd*2); % image size in pixels
    rect=CenterRect([0 0 imgsz imgsz],r); % stim rect
    [x,y]=meshgrid(linspace(-radius,radius,imgsz)); % symmetric coordinates
    mask=exp(-(x.^2 + y.^2)/(radius/2)^2);  % gaussian mask: 0 to 1
    angl=-dAngle/180*pi; % radian of -dAngle
    img=sin(2*pi*sf*(x*cos(angl)+y*sin(angl))); % grating tilted left from vertical
    img=img.*mask; % apply mask
    for i=1:ncond
        img0=img*contrast(i); % apply contrast
        img0=round((img0+1)*127); % convert from [-1 1] to [0 254]
        tex(i)=Screen('MakeTexture',w,img0); %#ok texture
        Screen('FrameOval',tex(i),140,[0 0 imgsz imgsz]); % circle
    end
    clear x y mask img img0; % later, we need texture only

    Priority(MaxPriority(w));   % raise priority for better timing
    RTBox(999); % wait for any button press
    t0=RTBox('TTL',ncond+1); % mark the beginnin of a run
    Screen('FrameOval',w,140,rect); % circle
    vbl=Screen('Flip',w);  % turn off instruction
    
    stimDur=(round(stimDur/ifi)-0.5)*ifi; % half refresh interval shorter

    for i=1:ntrials
        cond=record(i,2);
        angl=dAngle*record(i,3)*2; % 0 or dAngle*2 in deg
        Screen('DrawTexture',w,tex(cond),[],rect,angl); % draw to buffer
        Screen('DrawingFinished',w);
        
        WaitTill(vbl+trialDur+rand);  % wait some time bewteen trials
        RTBox('clear');   % clear right before stimulus onset
        vbl=Screen('Flip',w);  % show stim, return onset time
        t_onset=RTBox('TTL',cond); % mark stim onset with condition number
        Screen('FrameOval',w,140,rect); % circle
        Screen('Flip',w,vbl+stimDur); % turn off stim and show circle
        Screen('FrameOval',w,140,rect); % circle
        
        record(i,6)=vbl-t0;  % stim start secs
        record(i,7)=t_onset-vbl;  % diff between vbl and TTL
        
        [t, btn]=RTBox(trialDur-0.2); % return computer time and button

        % check response
        str='Missed';
        if ~isempty(t)
            t=t-vbl; % RT now
            if length(t)>1 % more than 1 response
                fprintf(' #trial %2g: RT=',i); fprintf('%8.4f',t); fprintf('\n');
                ind=find(t>0.1, 1); % find the 1st proper rt
                % you may set your criterion, for example t>0.2
                if isempty(ind), continue; end  % no reasonable response, skip trial
                t=t(ind); btn=btn{ind}; % use the first reasonable response
            end
        
            % record correctness and RT
            correct=record(i,3)==strcmp(btn,'right');
            record(i,4:5)=[correct t];

            % feedback
            if correct, str='Correct'; else str='Wrong'; end
        end
        DrawFormattedText(w,str,'center',ycenter,0);
        Screen('Flip',w);    
    end
catch me
end
WaitTill(vbl+trialDur);
Screen('CloseAll');
Priority(0);      % restore normal priority

% save myresult record t0 randSeed;  % save a MAT file

if exist('me','var'), rethrow(me); end % show error message if any

% display or save result
fid=1; % display in command window
% fid=fopen('myresult.txt','w+'); % you should save result in a file
fprintf(fid,'randSeed=%d\n',randSeed);
fprintf(fid,'t0=%.4f\n\n',t0); % start time. Useful with RTBoxWarningLog.txt
fprintf(fid,' %s\n',recLabel);
fprintf(fid,'%6g %4g %9g %11g %8.4f %9.4f %9.4f\n',record'); % one trial per row
fprintf(fid,'\nFinished at %s\n',datestr(now));
fclose('all'); % no complain for fid=1
