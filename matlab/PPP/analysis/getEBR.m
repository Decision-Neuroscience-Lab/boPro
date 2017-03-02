function [blinkData] = getEBR(id)
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
EEG = pop_select( EEG,'channel',{'EXG3' 'EXG4'}); % Remove other channels
EEG = eeg_checkset( EEG );
if id == 9
    EEG = pop_reref( EEG, 1); % Swapped electrodes
else
    EEG = pop_reref( EEG, 2); % 2 is reference channel (lateral EOG)
end
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','HR','overwrite','on','gui','off');


%% Select region of analysis (ADD WINDOW FOR JUST BASELINE AND TASK - REMOVE VOLUME TEST)

% Find volume test
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
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','trimmedData','gui','off');
    
    % Find peaks
    blinkChannel = 1;
    channelData = EEG.data(blinkChannel,:);
    
    Fs = 1; % Sample rate
    MPP = 100; % Minimum peak prominence
    MINW = 12; % Minimum peak width
    MPD = 200; % Minumum peak distance
    [PKS,LOCS{phase}] = findpeaks(double(channelData),Fs,...
        'MinPeakProminence',MPP,'MinPeakWidth',MINW,'MinPeakDistance',MPD);
    
    % Calculate mean measures
    blinkRate(phase) = numel(LOCS{phase}) ./ (numel(EEG.data)./EEG.srate);
    
    % Calculate EBR moving average
    if phase == 1
        timeWindow = 60; % This sets how wide the bpm computation window is
        ebrCorrection = 60./ (timeWindow*2);
        c = 1;
        for tw = 1:EEG.srate:LOCS{phase}(end)
            % This takes the sum of all eyeblinks that occur within the time window, per second
            tsEBR(1,c) = sum(LOCS{1} > tw - timeWindow*EEG.srate & LOCS{1} < tw + timeWindow*EEG.srate)...
                * ebrCorrection; % This corrects the value to eyeblinks per minute (or estimated if the timeWindow is less than 60)
            c = c + 1;
        end
        
        % Find and insert trigger times
        phaseBounds = [EEG.event(ismember({EEG.event.type},{'13','14','15','16','17','18'})).latency] ./ EEG.srate;
        phaseTimes = round(phaseBounds);
        phaseTimes(1) = 1;
        tsEBR(2,:) = 0;
        tsEBR(2,phaseTimes) = [100];
        
        % Trim ends (where averaging doesn't work)
        tsEBR(:,1:timeWindow) = [];
        tsEBR(:,end-timeWindow:end) = [];
        
        % Plot moving average
%         plot(tsEBR(1,:))
%         hold on
%         plot(tsEBR(2,:))
%         ylim([20 60]);
        
        % Add peaks as new trigger
        fprintf('Inserting eyeblink triggers...\n');
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
            
            epochLength = [0 6]; % In seconds
            
            EEG = pop_epoch( EEG, {  event  }, epochLength, 'newname', 'rewardEpoch', 'epochinfo', 'yes');
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname','rewardEpoch','gui','off');
            EEG = eeg_checkset( EEG );
            
            EBREvents = EEG.event(ismember({EEG.event.type}, '50')); % Get eyeblink events in epochs
            numBeats = size(EBREvents,2); % Enumerate eyeblinks
            ERB(r) = (numBeats / 32) * (60./epochLength(2)); % Event evoked blinks in blinks per minute
            ERB(r) = ERB(r) ./ 60; % Event evoked blinks in blinks per second
            
            % Get times
            blinkIndex = strcmp([EEG.epoch.eventtype],'50');
            eventTimes = [EEG.epoch.eventlatency];
            blinkTimes{r} = cell2mat(eventTimes(blinkIndex));
            
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve', 3,'study',0); % Revert to original eyeblink data
        end
        
    end
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data
    
end

blinkData.id = id;
blinkData.blinkRate = blinkRate;
blinkData.locations = LOCS;
blinkData.timeSeries = tsEBR;
blinkData.rewardBlinkRate = ERB;
blinkData.rewardBlinkTimes = blinkTimes;

cd(oldcd);
end