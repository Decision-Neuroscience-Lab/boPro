function [ move_rate ] = calc_bpm_ma( loadfile )
% 20 - experiment on
% 21 - experiment off
% 22 - TD on
% 23 - TD off
% 24-29 - DR on for each condition
% 30 - DR off
% 31 response on
% 32 response off
% 100 - heartbeat

%This function takes a moving average of heart rate across the entire
%experiment and plots it as a graph

 %loadfile = '/Users/Bowen/Desktop/t0 Data/t03.edf'


references = [67 68];
qrs_channel = 65;
qrs_event = '100';

% read in edf file
close all
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_biosig(loadfile, 'ref', references ,'blockepoch','off');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
EEG=pop_fmrib_qrsdetect(EEG, qrs_channel, qrs_event,'no');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

%Check for start trigger
if ~EEG.event(1).type == 20;
    
earliest_latency = EEG.event(1).latency;
EEG.event(end + 1).type = 20;
EEG.event(end + 1).latency = earliest_latency - 1;
EEG = eeg_checkset(EEG, 'eventconsistency');
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw

end

%Set window width
npoints = 2000;
nseconds = 20;
window_width = EEG.srate*nseconds;

% find event indices
all_events = str2double( char( {EEG.event(1:end).type} ) );
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
exp_start_latency = [EEG.event(exp_start).latency];
exp_end_latency = [EEG.event(exp_end).latency];

%Search through experiment


exp_duration = exp_end_latency - exp_start_latency;
% total_samples = floor(exp_duration/npoints);
starts = linspace(exp_start_latency, exp_end_latency, npoints);

% window_start = exp_start_latency;
% window_end = window_start + window_width;

for x = 1:npoints
    
    window_start = starts(x);
    window_end = starts(x) + window_width;
  
    qrs_count = numel(find(qrs_latency >= window_start & qrs_latency <= window_end));
    RATE(x, 1) = qrs_count;
    RATE(x, 2) = qrs_count/(window_width/EEG.srate)*60;
  
    
end

%Plot HR
figure
plot(RATE)

end

