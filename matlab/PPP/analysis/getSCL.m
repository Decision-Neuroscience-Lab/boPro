function [meanSCL, maxSCL, minSCL] = getSCL(id)
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
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','GSR','overwrite','on','gui','off'); 

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

% Get max, min and mean
maxSCL(phase) = max(EEG.data);
minSCL(phase) = min(EEG.data);
meanSCL(phase) = mean(EEG.data);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data

end

cd(oldcd);

end