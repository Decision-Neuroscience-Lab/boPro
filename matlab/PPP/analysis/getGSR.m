function [skinData] = getGSR(id,ploton)
% Bowen J Fung, 2016

%% Load in file
dataLoc = '/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological/processed';
oldcd = cd(dataLoc);

loadname = sprintf('PPP_%.0f.set',id);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',loadname,'filepath',dataLoc);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = pop_select( EEG,'channel',{'GSR1' 'GSR2'}); % Remove other channels
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, 2); % 2 is reference channel?
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','GSR','overwrite','on','gui','off');

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
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','GSRtrimmed','overwrite','on','gui','off');

%% Get mean SCL for each task phase
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
    
    % Get max, min and mean
    maxSCL(phase) = max(EEG.data);
    minSCL(phase) = min(EEG.data);
    meanSCL(phase) = mean(EEG.data);
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve', 1,'study',0); % Revert to original data
end

%% Get mean ERP for each response
event = '24';
epochLength = [-3 10]; % In seconds
baseline = [-3000 0]; % In milliseconds

EEG = pop_epoch( EEG, {  event  }, epochLength, 'newname', 'responseEpoch', 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','responseEpoch','gui','off');
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, baseline);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off');

if ploton
    % Plot
    figure;
    plot(EEG.times, mean(EEG.data,3));
    title('Response-locked SCL');
end

rERP = mean(EEG.data,3);
rTime = EEG.times;

ALLEEG = pop_delset( ALLEEG, 2 ); % Delete epoched data (and revert to un-epoched data)

%% Get mean ERP for each reward delivery level
rewardTrigs = {'40','41','42','43'};

for r = 1:4
    event = rewardTrigs{r};
    
    epochLength = [-3 10]; % In seconds
    baseline = [-3000 0]; % In milliseconds
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'retrieve',1,'study',0); % Revert to original data
    
    EEG = pop_epoch( EEG, {  event  }, epochLength, 'newname', 'rewardEpoch', 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','rewardEpoch','gui','off');
    EEG = eeg_checkset( EEG );
    EEG = pop_rmbase( EEG, baseline);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off');
    
    dERP{r} = mean(EEG.data,3);
    dTime{r} = EEG.times;
    
    ALLEEG = pop_delset( ALLEEG, 2 ); % Delete epoched data (and revert to un-epoched data)
end

if ploton
    % Plot
    figure;
    for r = 1:4
        plot(dTime{r}, dERP{r});
        hold on;
    end
    legend({'No reward','Small','Medium','Large'});
    title('Reward-locked SCL');
end

skinData.id = id;
skinData.meanSCL = meanSCL;
skinData.maxSCL = maxSCL;
skinData.minSCL = minSCL;
skinData.response = rERP;
skinData.reward = dERP;
skinData.responseTime = rTime;
skinData.rewardTime = dTime;

cd(oldcd);

end