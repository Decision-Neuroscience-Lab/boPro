function [heartData] = getHR(id)
% Outputs mean BPM, mean HRV, latency of R waves, BPM moving average,
% reward epoch average bpm and reward epoch latencies
% Bowen J Fung, 2016

%% Load in file
try
    dataLoc = '/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological/processed';
    oldcd = cd(dataLoc);
catch
    fprintf('Not connected to server!\n');
    return
end

loadname = sprintf('PPP_%.0f.set',id);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',loadname,'filepath',dataLoc);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = pop_select( EEG,'channel',{'EXG1' 'EXG2'}); % Remove other channels
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, 1); % 1 is reference channel
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','HR','overwrite','on','gui','off');

%% Select region of analysis

% Remove volume testing and breaks
volStart = [EEG.event([EEG.event.type] == 11).latency];
volEnd = [EEG.event([EEG.event.type] == 12).latency];

if any([EEG.event.type] == 26) % If there are break triggers
    
    % Find breaks
    breakStart = [EEG.event([EEG.event.type] == 26).latency];
    breakEnd = [EEG.event([EEG.event.type] == 27).latency];
    
    volStart = cat(2,volStart,breakStart);
    volEnd = cat(2,volEnd,breakEnd);
end

EEG = pop_select( EEG,'nopoint',[volStart',volEnd'] );
EEG = eeg_checkset( EEG ); % Note EEGLAB changes events to strings here
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','HR','overwrite','on','gui','off');

% Select region of interest
for phase = 1:4
    switch phase
        case 1 % If analysing all
            phaseStart = [EEG.event(strcmp({EEG.event.type},'13')).latency];
            phaseEnd = [EEG.event(strcmp({EEG.event.type},'18')).latency];
        case 2 % If analysing first baseline
            phaseStart = [EEG.event(strcmp({EEG.event.type},'13')).latency];
            phaseEnd = [EEG.event(strcmp({EEG.event.type},'14')).latency];
        case 3 % If analysing main task
            phaseStart = [EEG.event(strcmp({EEG.event.type},'15')).latency];
            phaseEnd = [EEG.event(strcmp({EEG.event.type},'16')).latency];
        case 4 % If analysing second baseline
            phaseStart = [EEG.event(strcmp({EEG.event.type},'17')).latency];
            phaseEnd = [EEG.event(strcmp({EEG.event.type},'18')).latency];
    end
    
    
    EEG = pop_select( EEG,'point',[phaseStart phaseEnd] );
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','phaseData','gui','off');
    
    %% Detrend signal (this doesn't seem to make any difference)
    heartChannel = 1;
    channelData = EEG.data(heartChannel,:);
    %     if detrend
    %     [p,~,mu] = polyfit((1:numel(channelData)),channelData,6);
    %     f_y = polyval(p,(1:numel(channelData)),[],mu);
    %
    %     channelData = channelData - f_y; % Detrend data
    %     end
    
    %% Find peaks
    Fs = 1; % Sample rate
    MPP = 900; % Minimum peak prominence
    MAXW = 100; % Minimum peak width
    MPD = 250; % Minumum peak distance
    [PKS,LOCS{phase}] = findpeaks(double(channelData),Fs,...
        'MinPeakProminence',MPP,'MaxPeakWidth',MAXW,'MinPeakDistance',MPD);
    
    % Calculate mean measures
    HR(phase) = numel(LOCS{phase}) ./ ((numel(EEG.data)./EEG.srate)./60);
    RR = diff((LOCS{phase}./EEG.srate));
    HRV(phase) = std(RR);
    
    % Calculate average time series and event related changes
    if phase == 1
        % Calculate bpm moving average
        timeWindow = 60; % This sets how wide the bpm computation window is
        bmpCorrection = 60./ (timeWindow*2);
        c = 1;
        for tw = 1:EEG.srate:LOCS{phase}(end)
            % This takes the sum of all R waves that occur within the time window, per second
            tsHR(1,c) = sum(LOCS{1} > tw - timeWindow*EEG.srate & LOCS{1} < tw + timeWindow*EEG.srate)...
                * bmpCorrection; % This corrects the value to BPM (or estimated if the timeWindow is less than 60)
            c = c + 1;
        end
        
        % Find and insert trigger times
        phaseBounds = [EEG.event(ismember({EEG.event.type},{'13','14','15','16','17','18'})).latency] ./ EEG.srate;
        phaseTimes = round(phaseBounds);
        phaseTimes(1) = 1;
        tsHR(2,:) = 0;
        tsHR(2,phaseTimes) = [100];
        
        % Trim ends (where averaging doesn't work)
        tsHR(:,1:timeWindow) = [];
        tsHR(:,end-timeWindow:end) = [];
        
        % Plot moving average
        %                 plot(tsHR(1,:))
        %                 hold on
        %                 plot(tsHR(2,:))
        %                 ylim([60 100]);
        
        % Add R peaks as new trigger
        fprintf('Inserting R wave triggers...\n');
        for b = 1:numel(PKS)
            EEG = pop_editeventvals_nocheck(EEG,'insert',{1 [] [] []},...
                'changefield',{1 'latency' (LOCS{phase}(b)./(EEG.srate))},'changefield',{1 'type' num2str(50)});
        end
        EEG = eeg_checkset( EEG );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','Rpeaks','gui','off');
        fprintf('Done.\n');
        % Epoch the data and calculate average bpm for each reward level
        rewardTrigs = {'40','41','42','43'};
        
        for r = 1:4
            event = rewardTrigs{r};
            
            epochLength = [0 5]; % In seconds
            
            EEG = pop_epoch( EEG, {  event  }, epochLength, 'newname', 'rewardEpoch', 'epochinfo', 'yes');
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname','rewardEpoch','gui','off');
            EEG = eeg_checkset( EEG );
            
            heartEvents = EEG.event(ismember({EEG.event.type}, '50')); % Get heart beat events in epochs
            numBeats = size(heartEvents,2); % Enumerate R waves
            HRR(r) = (numBeats / 32) * (60./epochLength(2));
            
            heartIndex = strcmp([EEG.epoch.eventtype],'50');
            eventTimes = [EEG.epoch.eventlatency];
            heartTimes{r} = cell2mat(eventTimes(heartIndex));
            
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve', 3,'study',0); % Revert to r-wave data
        end
        
    end
    
    % Frequency components
    
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data
    
end

heartData.id = id;
heartData.heartRate = HR;
heartData.hrv = HRV;
heartData.locations = LOCS;
heartData.timeSeries = tsHR;
heartData.rewardHeartRate = HRR;
heartData.rewardHeartTimes = heartTimes;

cd(oldcd);

end