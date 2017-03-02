% This is a demo showing how to measure reaction time using RTBox.
% Run the program and follow the instruction in the command window.
% The program will measure and plot your RT.
% The result RT is a little longer since the start time is recorded 
% before sound play. The gaussian envolop also causes a small delay.
% Xiangrui Li, 3/2008
   
function RTBoxdemo_audio
ntrials=10;  % # of trials
timeout=1;    % timeout for RT reading
fs=22254.54; % frequency
dur=0.04;   % duration of beep
np=dur*fs/2;
x=-np:np;
y=sin(x); % sound wave
y=y.*exp(-(x/(np*0.75)).^4); % gaussian envolop
rt=nan(ntrials,1);
RTBox('clear');  % initialize device
Snd('Open');
Priority(1);   % raise priority for better timing

% print some instruction in Command Window
fprintf('This will test your response time to %g beeps.\n',ntrials);
fprintf('When you hear a beep, press a button as soon as possible.\n');
fprintf('Press any button to start.\n');
RTBox(1000);  % wait 1000s, or till any enabled event
fprintf('Trial No:   ');

for i=1:ntrials
    fstr=repmat('\b',1,length(num2str(i-1))+1); 
    fprintf([fstr '%g\n'],i); % replace old No with new one
    WaitSecs(1+rand*2);     % random interval
    RTBox('clear');         % clear fake response and synchronize clocks
    Snd('Quiet'); % stop any sound playing
    t0=GetSecs; Snd('Play',y,fs,16);  % record time and play sound
    t=RTBox(timeout);   % read time
    if isempty(t), continue; end  % no response, skip it
    t=t-t0; % RT
    if length(t)>1
        % in case more than 1 press, print some information
        fprintf(' trial %2g: RT=',i); fprintf('%8.4f',t); fprintf('\n');
        ind=find(t>0.02,1);  % find first proper rt
        if isempty(ind), continue; end  % no reasonable response, skip it
        t=t(ind);   % use good one
    end
    rt(i)=t;
end
Priority(0);  % restore normal priority
Snd('Close');

% plot result
h=figure(1); set(h,'color',[1 1 1]); 
plot(rt,'+-');
set(gca,'box','off','tickdir','out');
ylabel('Reaction Time (s)'); xlabel('Trials');
rt(isnan(rt))=[]; % remove NaNs due to missed trials
str=sprintf('Your median RT: %.3f %s %.3f s',median(rt),char(177),std(rt));
title(str);
