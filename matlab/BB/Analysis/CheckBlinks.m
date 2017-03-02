function [BBALL] = CheckBlinks(participants)

BB = struct();

for x = participants

    name1 = sprintf('p%.0f_clipped.set', x);
    name2 = sprintf('p%.0f.set',x);

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
try
    EEG = pop_loadset('filename',name1,'filepath','Q:\\DATA\\BB\\data\\EOG\\');
catch
    EEG = pop_loadset('filename',name2,'filepath','Q:\\DATA\\BB\\data\\EOG\\');
end
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

[blinkRate, returnThreshold, threshold] = GetBlinks(EEG, 1);


BB.blinkRate = blinkRate;
BB.returnThreshold = returnThreshold;
BB.threshold = threshold;

cd('Q:\DATA\BB\data\EBR');
filename = sprintf('BB%.0f', x);
save(filename, 'BB')

end

% BBALL = struct();
% for y = participants
%     loadname = sprintf('F:\\DATA\\BB\\data\\EBR\\BB%.0f.mat', y)
%     load(loadname)
%     BBALL(y).blinkRate = BB.blinkRate;
%     BBALL(y).returnThreshold = BB.returnThreshold
%     BBALL(y).threshold = BB.threshold;
% end
% 
%  save('BBALL', 'BBALL');