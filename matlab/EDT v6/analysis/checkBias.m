function [propBias, nonOpt] = checkBias(id)

% Load calibration file for participant
oldcd = cd('/Users/Bowen/Documents/MATLAB/EDT v6/data');
name = sprintf('%.0f_3_*', id);
loadname = dir(name);
load(loadname.name);
cd(oldcd);

% Check whether choices biased
bias = [data.trialLog.choiceBias]';
choice = [data.trialLog.choice]';
i = choice == bias;
propBias = mean(i);
[modeDelay,f] = mode([data.trialLog(i).D]);
propDelay = f/sum(i);
[modeAmount,f] = mode([data.trialLog(i).A]);
propAmount = f/sum(i);

bssA = [data.trialLog(~i).fA]';
bssD = [data.trialLog(~i).fD]';
bllA = [data.trialLog(~i).A]';
bllD = [data.trialLog(~i).D]';

nonOpt = [bssA,bssD,bllA,bllD];
return