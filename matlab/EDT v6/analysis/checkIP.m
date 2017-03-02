function [accuracy, ipLogit, ipPsi, ipSE, ipPsiAverage, ipQuest] = checkIP(id)

ploton = 0;

% Load calibration file for participant
oldcd = cd('/Users/Bowen/Documents/MATLAB/EDT v6/data');
name = sprintf('%.0f_1_*', id); % 1 is session number for calibration
loadname = dir(name);
load(loadname.name);
cd(oldcd);

% Put variables in matrix
X = [data.trialLog.A; data.trialLog.fA; data.trialLog.D; data.trialLog.fD]';
Y = [data.trialLog.choice]';
% Locate and remove missing responses
i = Y == 3;
Y(i) = [];
X(i,:) = [];
D = unique(X(:,3));

discard = 5; % First choices to discard
[accuracy, ipLogit, ~] = modelEDT(X(discard:end,3),X(discard:end,2),Y(discard:end),0,ploton); % Get indifference points, to plot, set last argument to 1

if ploton
figure;
end
for d = 1:numel(D)
    ipPsi(d) = data.trialLog(end).PM(d).threshold(end);
    ipSE(d) = data.trialLog(end).PM(d).seThreshold(end);
    ipPsiAverage(d) =  mean(data.trialLog(end).PM(d).threshold(end-9:end)); % If using Psi, take the average threshold of the last third of trials
    ipQuest(d) = QuestMean(data.trialLog(end).q(d)); % If using QUEST
    
    
    % Psi IP over experiment
    if ploton
        line = {'r-', 'g-', 'b-'};
        words{d} = sprintf('%0.f seconds, %.0f mL', D(d), unique(X(:,1)));
        plot(1:size([data.trialLog(end).PM(d).threshold],2), [data.trialLog(end).PM(d).threshold], line{d});
        xlabel('Trial');
        ylabel('Estimated Indifference Point');
        hold on;
    end
end
if ploton
    legend(words{1},words{2},words{3}, 'Location','SouthEast');
    title(sprintf('Participant %0.f', id));
end

return