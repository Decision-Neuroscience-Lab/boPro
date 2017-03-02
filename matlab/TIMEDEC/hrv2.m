function [X,HRV,RRI] = hrv2(id)

P = '/Volumes/333-fbe/DATA/TIMEDEC/data/ECG';
if id < 10
    F = sprintf('t0%.0f.bdf',id);
else
    F = sprintf('t%.0f.bdf',id);
end

% load file
CHAN = [65];
HDR = sopen(fullfile(P,F),'r',CHAN,'OVERFLOWDETECTION:OFF');
[s,HDR] = sread(HDR);
HDR = sclose(HDR);

% QRS-Detection
H2 = qrsdetect(s,HDR.SampleRate,2);
% resampling to 4 Hz using the Berger algorithm 
[HRV,RRI] = berger(H2,4);
% compute HRV parameters 
[X] = heartratevariability(H2);
% Extract QRS-info according to BIOSIG/T200/EVENTCODES.TXT
idx = find(H2.EVENT.TYP == hex2dec('0501'));
qrsindex = H2.EVENT.POS(idx)/H2.EVENT.SampleRate; 
return