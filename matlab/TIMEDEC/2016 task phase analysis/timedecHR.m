function timedecHR(id)

ecgLoc = '/Volumes/333-fbe/DATA/TIMEDEC/data/ECG';
loadname = sprintf('t%.0f.edf',id);

% Read in edf file
oldcd = cd(ecgLoc);
fprintf('Loading data for participant %.0f...\n', id);

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_biosig(loadname, 'ref',68);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
EEG = eeg_checkset( EEG );
EEG = pop_select( EEG,'channel',{'EXG1' 'EXG2'}); % Select channels
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, 1,'keepref','on'); % 1 is reference channel
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','HR','overwrite','on','gui','off');

EEG = eeg_checkset( EEG ); % Note EEGLAB changes events to strings here

% Experiment and DR on
if ~isempty(EEG.event)
expOn = find(ismember([EEG.event.type], 20)); % For exp and DR on (should be 2 of these)
tdOn = find(ismember([EEG.event.type], 22)); % Should be 2
tdOff = find(ismember([EEG.event.type], 23)); % Should be 2
drOff = find(ismember([EEG.event.type], 30));
expOff = find(ismember([EEG.event.type], 21)); % For exp and DR off (should be 2 of these)
else
    fprintf('NO EVENTS FOR PARTICIPANT %.0f!\n',id);
end

% Other triggers
% DR interval presentation - 24:29
% DR response start - 31
% DR response end - 32

%% Get non-task
phaseStart = EEG.event(expOn(1)).latency; % Select most recent expOn trigger (in case of restarts)
phaseEnd = EEG.event(expOff(2)).latency;

EEG = pop_select( EEG,'nopoint',[phaseStart phaseEnd] );
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','nonTask','gui','off');

% Save as .edf (trimmed)
savename = sprintf('/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/phases/nonTask/t%.0f_nonTask.edf',id);
pop_writeeeg(EEG, savename, 'TYPE','EDF');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data

%% Get on task
phaseStart = EEG.event(expOn(1)).latency;
phaseEnd = EEG.event(expOff(2)).latency;

EEG = pop_select( EEG,'point',[phaseStart phaseEnd] );
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','task','gui','off');

% Save as .edf (trimmed)
savename = sprintf('/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/phases/fullTask/t%.0f_task.edf',id);
pop_writeeeg(EEG, savename, 'TYPE','EDF');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data

%% Get TD 1
phaseStart = EEG.event(tdOn(1)).latency;
phaseEnd = EEG.event(tdOff(1)).latency;

EEG = pop_select( EEG,'point',[phaseStart phaseEnd] );
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','TD1','gui','off');

% Save as .edf (trimmed)
savename = sprintf('/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/phases/TD1/t%.0f_TD1.edf',id);
pop_writeeeg(EEG, savename, 'TYPE','EDF');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data

%% Get DR
phaseStart = EEG.event(expOn(2)).latency;
phaseEnd = EEG.event(drOff).latency;

EEG = pop_select( EEG,'point',[phaseStart phaseEnd] );
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','Dr','gui','off');

% Save as .edf (trimmed)
savename = sprintf('/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/phases/DR/t%.0f_DR.edf',id);
pop_writeeeg(EEG, savename, 'TYPE','EDF');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data

%% Get TD 2
phaseStart = EEG.event(tdOn(2)).latency; 
phaseEnd = EEG.event(tdOff(2)).latency;

EEG = pop_select( EEG,'point',[phaseStart phaseEnd] );
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','TD2','gui','off');

% Save as .edf (trimmed)
savename = sprintf('/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/phases/TD2/t%.0f_TD2.edf',id);
pop_writeeeg(EEG, savename, 'TYPE','EDF');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); % Revert to original data


cd(oldcd);
fprintf('Finished participant %.0f.\n',id);
return