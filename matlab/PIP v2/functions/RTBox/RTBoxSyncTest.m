% RTBoxSyncTest (measuringSecs, interval, nSyncTrial)
% This tests the reliability of the synchronization between the computer
% and device clocks. If the variation range is within 1 ms, it should be
% okay for most RT measurement. A good setup could achieve a result with
% range less than 0.05 ms. This also measures clock difference between
% computer and RT box. The clock difference (ratio-1) is normally within ±
% 1e-4. This does the same as RTBox('ClockRatio'), but it won't apply
% correction, and it won't block Matlab. Also, after you correct the clock
% difference by RTBox('ClockRatio'), you should get very small difference
% (<1e-6). The measuringSecs should be long enough to measure the
% difference reliably. The default normally gives consistent result. The
% numbers in the parenthesis on the result figure are before removing
% linear drift.

% 05/2008 xl   wrote it
% 04/2011 xl   change xlabel from trials to seconds
% 10/2011 xl   remove dependence on robustfit

function RTBoxSyncTest(secs,interval,nSyncTrial)
if nargin<1 || isempty(secs), secs=30; end % default measuring time
persistent t obj h nSync
switch secs
    case 'stopfcn' % executed when timer stops for whatever reason
        try % fit a line and plot residual
            % slope is clock difference, residual is the variation
            x=t(:,2)-t(1,2); y=t(:,1)-t(1,1);
            b=polyfit(x,y,1);  % fit a line
            resid=x*b(1)+b(2)-y;
            se=std(resid)/length(x); % rough estimate of se            
            figure(9); 
            set(gcf,'color','white','userdata',t,'filename','RTBoxSyncTestResult');
            dt=resid*[1 1 1]; dt(:,1:2)=dt(:,1:2)+t(:,3:4); % methods 2,3 1 in ms
            plot(t(:,2)-t(1,2),dt*1e3,'.');
            set(gca,'box','off','tickdir','out','ylim',[-1 1]);
            xlabel('Seconds'); ylabel('Time Variation (ms)');
            str=sprintf('Variation range: %.2g ms (%.2g)',range(resid*1e3),range(t(:,1))*1e3); % in ms
            text(0.05,0.2,str,'units','normalized');
            pow=ceil(-log10(abs(b(1)))); sub=sprintf('^%c',num2str(pow));
            str=sprintf('Clock difference (x10^-%s): %.2f %s %.2f',sub, b(1)*10^pow,char(177),se*10^pow);
            text(0.05,0.1,str,'units','normalized');
            legend({'min(tpost-tbox)' 'min(tpost-pre)' 'max(tpre-tbox)'},'location','best')
        catch %#ok
            fprintf(2,'%s\n',lasterr); %#ok print error, then clean up
        end
        stop(obj); delete(obj); clear obj;  % done, stop and close timer
        try close(h); end %#ok, try to close Measuring dialog
        munlock;  % unlock it from memory
    case 'timerfcn'  % executed at each timer call
        t(end+1,:)=RTBox('clear',nSync); % add a row
    otherwise  % secs for timer: set and start timer
        mfile=mfilename;
        if mislocked
            fprintf(2,' %s is already running.\n',mfile); 
            return; 
        end
        if nargin<3 || isempty(nSyncTrial), nSync=20; else nSync=nSyncTrial; end
        if nargin<2 || isempty(interval), interval=1; end % timer interval
        RTBox('clear'); % open device if hasn't
        repeats=max(3,round(secs/interval)); % # of trials
        
        % define timer: functions, interval and trials
        obj=timer('TimerFcn',[mfile '(''timerfcn'')'], ...
            'StopFcn',[mfile '(''stopfcn'')'], ...
            'ExecutionMode','FixedRate', ...
            'Period',interval,'TasksToExecute',repeats);
        t=[];
        start(obj);    % start timer

        str=datestr(now+(repeats-1)*interval/86400,'HH:MM:SS PM');
        str=sprintf('The result will be shown by %s.\nDon''t quit Matlab till then.',str);
        h=helpdlg(str,'Measuring ...');

        mlock; % lock m file, avoid being cleared
end
