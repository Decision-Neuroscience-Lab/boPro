function [TD1_rate DR_rate TD2_rate] = calc_bpm(loadname, savename, qrscheck, qrsname)
% 20 - experiment on
% 21 - experiment off
% 22 - TD on
% 23 - TD off
% 24-29 - DR on for each condition
% 30 - DR off
% 31 response on
% 32 response off
% 100 - heartbeat

%loadfile = '/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/t12.edf';
% /Users/Bowen/Desktop/t0 Data
references = [67 68];
qrs_channel = 65;
qrs_event = '100';


if qrscheck == 0
    
    % read in edf file
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_biosig(loadname, 'ref', references ,'blockepoch','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
    EEG=pop_fmrib_qrsdetect(EEG,qrs_channel,qrs_event,'no');
    % save as qrs
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'savenew',savename,'gui','off'); 
    
end


if qrscheck == 1
    
    % read in qrs file
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',qrsname,'filepath','F:\\DATA\\TIMEDEC\\data\\ECG\\');
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
end
try trything = EEG.event(1).type;
    
catch
    
    error('No events in file %s', loadname)
    
end


%Check for start trigger
if EEG.event(1).type ~= 20;
    
    earliest_latency = EEG.event(1).latency;
    EEG.event(end + 1).type = 20;
    EEG.event(end + 1).latency = earliest_latency - 1;
    EEG = eeg_checkset(EEG, 'eventconsistency');
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    eeglab redraw
    
end

% find event indices

% all_events = str2double(char({EEG.event(1:end).type} ) );
all_events = str2double({EEG.event.type});

%all_events = [EEG.event(1:end).type];
exp_start = all_events == 20;
exp_end = all_events == 21;
TD_on = all_events == 22;
TD_off = all_events == 23;
DR_on = ismember(all_events, [24:29]);
DR_off = all_events == 30;
resp_on = all_events == 31;
resp_off = all_events == 32;
qrs = all_events == 100;

% find latencies for onset and offset events

TD_on_latency = [EEG.event(TD_on).latency];
TD_off_latency = [EEG.event(TD_off).latency];
DR_on_latency = [EEG.event(DR_on).latency];
DR_off_latency = [EEG.event(DR_off).latency];
qrs_latency = [EEG.event(qrs).latency];

% find duration of each task type

TD_1_dur = (TD_off_latency(1) - TD_on_latency(1))/EEG.srate;
TD_2_dur = (TD_off_latency(2) - TD_on_latency(2))/EEG.srate;
DR_dur = (DR_off_latency(1) - DR_on_latency(1))/EEG.srate;

% find number of qrs events in each task

TD1_qrs = numel(find(qrs_latency <= TD_off_latency(1) & qrs_latency >= TD_on_latency(1)));
TD2_qrs = numel(find(qrs_latency <= TD_off_latency(2) & qrs_latency >= TD_on_latency(2)));
DR_qrs = numel(find(qrs_latency <= DR_off_latency(1) & qrs_latency >= DR_on_latency(1)));

% calculate rate in bpm
TD1_rate = TD1_qrs/TD_1_dur * 60;
TD2_rate = TD2_qrs/TD_2_dur * 60;
DR_rate = DR_qrs/DR_dur * 60;



end
