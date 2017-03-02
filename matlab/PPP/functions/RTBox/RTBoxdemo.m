function RTBoxdemo(scrn)
% This is a demo showing how to measure reaction time using RTBox.
% Run the program. When you see flash on screen, press a button.
% Your RT will be plotted after the assigned number of trials.
% Xiangrui Li, 3/2008
   
if nargin<1, scrn=max(Screen('screens')); end % find last screen
ntrials=10;  % # of trials2
timeout=1;   % timeout for RT reading
sq=[0 0 100 100];   % square
rt=nan(ntrials,1);
RTBox('clear');  % in case it has not been initialized
% RTBox('enable','light');

try    % avoid dead screen in case of error
    [w rect]=Screen('OpenWindow',scrn,0);  % open a dark screen
    sq=CenterRect(sq,rect);
    HideCursor;
    ifi=Screen('GetFlipInterval',w); % flip interval
    
    % print some instruction
    Screen('TextSize',w,24); Screen('TextFont',w,'Times');
    str='This will test your response time to flash at the center of the screen.';
    DrawFormattedText(w,str,'center',rect(4)*0.4,[255 0 0]);
    str=sprintf('We will do %d trials. When you see a flash, press a button as soon as possible.',ntrials);
    DrawFormattedText(w,str,'center',rect(4)*0.45,[255 0 0]);
    DrawFormattedText(w,'Press any button to start', 'center', rect(4)*0.55, 255);
    Screen('Flip',w); % show instruction
    
    Priority(MaxPriority(w));   % raise priority for better timing
    RTBox(1000);  % wait 1000 s, or till any enabled event
    vbl=Screen('Flip',w);  %#ok turn off instruction
    
    for i=1:ntrials
        WaitSecs(1+rand); % random interval for subject
        Screen('FillRect',w,255,sq);
        RTBox('clear'); % clear buffer and sync clocks before stimulus onset
        vbl=Screen('Flip',w);  % show stim, return stim start time
        Screen('Flip',w,vbl+ifi*0.5); % turn off square after 2 frames
        
        % here you can prepare stim for next trial before you read RT
        t=RTBox(timeout);  % computer time of button response

        % check response
        if isempty(t), continue; end % no response, skip it
        t=t-vbl;  %  response time
        if length(t)>1 % more than 1 response
            fprintf(' trial %2g: RT=',i); fprintf('%8.4f',t); fprintf('\n');
            ind=find(t>0,1);  % take the first proper rt in case of more than 1 response
            if isempty(ind), continue; end  % no reasonable response, skip it
            t=t(ind);
        end
        rt(i)=t; % record the RT
    end
catch me
end
Screen('CloseAll');
Priority(0); % restore normal priority

if exist('me','var'), rethrow(me); end % show error message if any

% plot result
h=figure(9); set(h,'color',[1 1 1]); 
plot(rt,'+-');
set(gca,'box','off','tickdir','out');
ylabel('Response Time (s)'); xlabel('Trials');
rt(isnan(rt))=[]; % remove NaNs due to missed trials
str=sprintf('Your median RT: %.3f %s %.3f s',median(rt),char(177),std(rt));
title(str);
