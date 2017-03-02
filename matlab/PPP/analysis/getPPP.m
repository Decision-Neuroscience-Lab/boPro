function getPPP(id)

ecgLoc = '/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological';
loadname = sprintf('PPP_%.0f.edf',id);
savename = sprintf('PPP_%.0f.edf',id);

% Read in edf file
oldcd = cd(ecgLoc);
fprintf('Loading data for participant %.0f...\n', id);

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_biosig(loadname, 'ref',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
EEG = eeg_checkset( EEG );
if  strcmp(EEG.chanlocs(end).labels,'GSR2')
    EEG = pop_select( EEG,'channel',{'EXG1' 'EXG2' 'EXG3' 'EXG4' 'GSR1' 'GSR2'}); % Select useful channels (ECG1 ECG2*, EOG1*, EOG2, GSR1, GSR2)
else
    EEG = pop_select( EEG,'channel',{'EXG1' 'EXG2' 'EXG3' 'EXG4'}); % Select channels without GSR
    fprintf('Participant has no GSR!\n');
end
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');

%% Code reward magnitude triggers
oldcd = cd('/Volumes/333-fbe/DATA/TIMEJUICE/PPP/behavioural');
name = sprintf('%.0f_1_*', id);
loadname = dir(name);
load(loadname.name,'data');
cd(oldcd);
fprintf('Reading in behavioural data and recoding triggers...\n');

% Remove non-task data
expOn = find(ismember([EEG.event.type], 13));
expOn = EEG.event(expOn(end)).latency; % Select most recent expOn trigger (in case of restarts)
expEnd = EEG.event(end).latency;
EEG = pop_select( EEG,'point',[expOn expEnd]);
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','trimmedData','gui','off');

% Find stimulus presentation events
stimPresEvents = find(ismember({EEG.event.type}, {'20','21','22','23'}));
stimPresEvents = stimPresEvents(33:160); % Cut out baseline trials

rewardPresTrigs = data.params.stimuli(:,1); % Presentation triggers are 30:33
rewardPresTrigs(rewardPresTrigs == 0.05) = 30;
rewardPresTrigs(rewardPresTrigs == 0.7) = 31;
rewardPresTrigs(rewardPresTrigs == 1.4) = 32;
rewardPresTrigs(rewardPresTrigs == 2.8) = 33;

% Insert new triggers
c = 1;
for a = stimPresEvents
    EEG.event(end + 1) = EEG.event(a);
    EEG.event(end).latency = EEG.event(a).latency + 0.01*EEG.srate;
    EEG.event(end).type = num2str(rewardPresTrigs(c));
    c = c + 1;
end
EEG = eeg_checkset(EEG, 'eventconsistency'); % Check all events for consistency
EEG = eeg_checkset( EEG );

% Find stimulus delivery events
stimDelEvents = find(ismember({EEG.event.type}, '25'));
rewardDelTrigs = rewardPresTrigs + 10; % Delivery triggers are 40:43

% Insert new triggers
c = 1;
for b = stimDelEvents
    EEG.event(end + 1) = EEG.event(b);
    EEG.event(end).latency = EEG.event(b).latency + 0.01*EEG.srate;
    EEG.event(end).type = num2str(rewardDelTrigs(c));
    c = c + 1;
end

EEG = eeg_checkset(EEG, 'eventconsistency'); % Check all events for consistency
EEG = eeg_checkset( EEG );

[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset

%% Recode delays in baseline task
if id < 43 % For participants with incorrectly coded triggers
    clearvars stimPresEvents
    stimPresEvents = find(ismember({EEG.event.type}, {'20','21','22','23'})); % Find stimulus presentation events
    base{1} = stimPresEvents(1:32); % Separate into baselines
    base{2} = stimPresEvents(161:end);
    
    for b = 1:2
        % Get behavioural stimuli
        switch b
            case 1
                actualDelay = data.params.practiceStim1;
            case 2
                actualDelay = data.params.practiceStim2;
        end
        % Assign trigger codes
        actualDelay(actualDelay == 4) = 20;
        actualDelay(actualDelay == 6) = 21;
        actualDelay(actualDelay == 8) = 22;
        actualDelay(actualDelay == 10) = 23;
        
        % Recode triggers
        c = 1;
        for a = base{b}
            EEG.event(a).type = num2str(actualDelay(c));
            c = c + 1;
        end
        EEG = eeg_checkset(EEG, 'eventconsistency'); % Check all events for consistency
        EEG = eeg_checkset( EEG );
    end
    
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset
end
%% Save as .set
EEG = pop_saveset( EEG, 'filename',savename,'filepath','/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological/processed');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% Save as .edf (trimmed)
% savename = sprintf('/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological/trimmed/PPP_%.0f.gdf',id);
% pop_writeeeg(EEG, savename, 'TYPE','GDF');

cd(oldcd);
fprintf('Finished participant %.0f.\n',id);
return