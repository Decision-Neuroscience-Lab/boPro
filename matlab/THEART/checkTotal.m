function winnings = checkTotal(id)

oldcd = cd('/Users/Bowen/Documents/MATLAB/QT/data');
try % If there was a restart in one of the files load the second file
    name = sprintf('%.0f_2_*', id);
    loadname = dir(name);
    load(loadname.name,'data');
    fprintf('Loaded restarted data for participant %.0f.\n',id);
catch
    % Load first try
    name = sprintf('%.0f_1_*', id);
    loadname = dir(name);
    load(loadname.name,'data');
end
cd(oldcd);

trialData = data.trialLog;
blocks = unique(trialData.block);
for b = 3:numel(blocks)
    lastTrial = max(trialData.trial(trialData.block == b));
    blockWinnings(b) = trialData.totalReward(trialData.trial == lastTrial & trialData.block == b);
end

winnings = sum(blockWinnings);
fprintf('You won:\n');
for b = 3:numel(blocks)
    fprintf('$%.2f in block %.0f\n',blockWinnings(b),b);
end
fprintf('Total: $%.2f.\n', winnings./2);
return