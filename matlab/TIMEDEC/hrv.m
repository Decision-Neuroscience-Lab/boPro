function [heartBeatVariability, meanBeatRate] = hrv(id,mode)

ecgLoc = '/Volumes/333-fbe/DATA/TIMEDEC/data/ECG';
if id < 10
    loadname = sprintf('t0%.0f.bdf',id);
    savename = sprintf('t0%.0f.bdf',id);
else
    loadname = sprintf('t%.0f.bdf',id);
    savename = sprintf('t%.0f.bdf',id);
end

% Parameters
references = [67 68];
qrs_channel = 65;
qrs_event = '100';

% Read in bdf file
oldcd = cd(ecgLoc);
fprintf('Loading data...\n');
EEG = pop_biosig(loadname, 'ref', references,'refoptions',{'keepref' 'off'});
EEG = eeg_checkset( EEG );

switch mode
    case 'qrs'
        
        EEG = pop_fmrib_qrsdetect(EEG,qrs_channel,qrs_event,'no');
        EEG.setname='QRS';
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',savename,'filepath','/Volumes/333-fbe/DATA/TIMEDEC/data/ECG/QRS/');
        EEG = eeg_checkset( EEG );

        try EEG.event(1).type;
        catch
            error('No events in file %s', loadname)
        end
        
        % Find event indices
        qrs = str2double({EEG.event.type}) == 100;
        
        % Find latencies for hearbeats
        start_latency = EEG.event(1).latency;
        end_latency = EEG.event(end).latency;
        qrs_latency = [EEG.event(qrs).latency];
        
        % Get duration and mean hearbeat rate
        dur = (end_latency - start_latency)/EEG.srate;
        numBeats = numel(find(qrs_latency <= end_latency(1) & qrs_latency >= start_latency(1)));
        meanBeatRate = (numBeats / dur) * 60;
        
        % Get interbeat intervals and variaability
        heartBeatDifferences = diff(qrs_latency/EEG.srate);
        heartBeatVariability = std(heartBeatDifferences); % Changed to std from var (July, 2015)
        
        fs = EEG.srate;
        m = length(heartBeatDifferences);          % Window length
        n = pow2(nextpow2(m));  % Transform length
        y = fft(heartBeatDifferences,n);           % DFT
        f = (0:n-1)*(fs/n);     % Frequency range
        power = y.*conj(y)/n;   % Power of the DFT
        plot(f,power)
        xlabel('Frequency (Hz)');
        ylabel('Power');

    case 'pt'
        
        ECGvector = double(EEG.data(65,:));
        fprintf('Running Pan-Tompkins algorithm...\n');
        [~,qrs_i_raw,~] = pan_tompkin(ECGvector,EEG.srate,0);
        
        % Get mean heart rate
        dur = (qrs_i_raw(end) - qrs_i_raw(1))/EEG.srate;
        numBeats = numel(qrs_i_raw);
        meanBeatRate = (numBeats / dur) * 60;
        
        % Get interbeat intervals and variaability
        heartBeatDifferences = diff(qrs_i_raw/EEG.srate);
        heartBeatVariability = std(heartBeatDifferences);
        spectral = fft(qrs_i_raw/EEG.srate);
        plot(abs(spectral));
        fprintf('Done.\n');
end

cd(oldcd);
return