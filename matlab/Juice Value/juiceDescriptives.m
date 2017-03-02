function [means zMeans] = juiceDescriptives(participants)

for x = participants
id = x;
 
% Load calibration file for participant
cd('/Users/Bowen/Documents/MATLAB/Juice Value/data');
name = sprintf('%.0f_*', id);
loadname = dir(name);
load(loadname.name);
par = sprintf('%0.f',x);

% Select variables and delete missed responses
thirst(x,1:2) = [data.startThirst, data.endThirst];
data = [1:length(data.trialLog); data.trialLog.volume; data.trialLog.value; data.trialLog.rt; data.trialLog.totalvolume]';
i =data(:,3) == -1; % Locate and remove missing responses
data(i,:) = [];

volumes = unique(data(:,2))'; % Get volumes used in experiment

% Normalise all pleasantness ratings
zScore = (data(:,3) - min(data(:,3))) ./ (max(data(:,3)) - min(data(:,3)));

% Get descriptives for whole experiment (or subset)
subset = data;
for y = 1:numel(volumes) 
    means(x,y) = mean(subset(subset(:,2) == volumes(y),3));
    sd(x,y) = std(subset(subset(:,2) == volumes(y),3));
    sem(x,y) = sd(x,y) / sqrt(size(subset,1));
    zMeans(x,y) =  mean(zScore(subset(:,2) == volumes(y)));
    zSd(x,y) =  std(zScore(subset(:,2) == volumes(y)));
    zSem(x,y) =  zSd(x,y) / sqrt(size(subset,1));
end
figure;
errorbar(volumes, means(x,:), sem(x,:), 'bo');
title(par);
xlabel('Volume');
ylabel('Pleasantness');
ylim([1 9]);

figure;
errorbar(volumes, zMeans(x,:), zSem(x,:), 'bo');
title('Normalised');
xlabel('Volume');
ylabel('Pleasantness');
ylim([0 1]);
    
% Track means for each volume (moving average). If set to half the size of
% trialLog, will calculate std and sem for each half, for each volume
window = 3;
for v = 1:length(volumes)
    text{v} = sprintf('%.1fmL',volumes(v));
    set = data(data(:,2) == volumes(v),:);
    zSet = zScore(data(:,2) == volumes(v));
    for y = 1:(size(set,1) - window)
        movave(y,v) = mean(set(y:y+window, 3));
        movZscore(y,v) = mean(zSet(y:y+window));
        movsd(y,v) = std(set(y:y+window, 3));
        movsem(y,v) = movsd(y,v) / sqrt(size(set,1));
    end
end

timeseries{x} = movZscore;

figure;
hold on;
plot(movave(:,1), 'r-')
plot(movave(:,2), 'g-')
plot(movave(:,3), 'b-')
plot(movave(:,4), 'm-')
title(par);
xlabel('Trial');
ylabel('Average Pleasantness');
legend(text{1},text{2},text{3},text{4});

end

% Thirst rating differences
quench = diff(thirst,1,2);

% All participants means
figure;
errorbar(volumes, mean(means), mean(sem), 'bo');
title('All participants means');
xlabel('Volume');
ylabel('Pleasantness');

% All participants normalised means
figure;
errorbar(volumes, mean(zMeans), mean(zSem), 'o');
hold on
xx = 0:0.01:4;
z = a*xx.^b;
plot(xx, z);
title('All participants normalised means', 'FontSize', 20);
xlabel('Volume', 'FontSize', 20);
ylabel('Pleasantness', 'FontSize', 20);
t = legend('data', sprintf('y = %.2fx^{%.2f}',a,b));
set(t, 'FontSize', 14);
ylim([0 1]);

% All participants normalised means
figure;
errorbar(1:4, mean(zMeans), mean(zSem), 'bo');
title('All participants normalised means');
xlabel('JND / logVolume');
ylabel('Pleasantness');
ylim([0 1]);

% Normalised time series
y = 1;
for x = participants   
    volume1(:,y) = timeseries{x}(:,1);
    volume2(:,y) = timeseries{x}(:,2);
    volume3(:,y) = timeseries{x}(:,3);
    volume4(:,y) = timeseries{x}(:,4);
    y = y + 1;
end
figure;
hold on;
plot(mean(volume1'))
plot(mean(volume2'))
plot(mean(volume3'))
plot(mean(volume4'))
title('All participants', 'FontSize', 20);
xlabel('Trial', 'FontSize', 20);
ylabel('Average Pleasantness', 'FontSize', 20);
t = legend(text{1},text{2},text{3},text{4});
t.FontSize = 15;
