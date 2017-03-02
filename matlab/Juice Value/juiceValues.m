function [minParams, fval, exitflag, output]= juiceValues(x)

id = x;
 
% Load calibration file for participant
cd('/Users/Bowen/Documents/MATLAB/Juice Value/data');
name = sprintf('%.0f_*', id);
loadname = dir(name);
load(loadname.name);

% Select variables and delete missed responses
data = [1:length(data.trialLog); data.trialLog.volume; data.trialLog.value; data.trialLog.rt; data.trialLog.totalvolume]';
i =data(:,3) == -1; % Locate and remove missing responses
data(i,:) = [];

volumes = unique(data(:,2))'; % Get volumes used in experiment

% Get descriptives for whole experiment (or subset)
subset = data;
for y = 1:numel(volumes) 
    means(y) = mean(subset(subset(:,2) == volumes(y),3));
    sd(y) = std(subset(subset(:,2) == volumes(y),3));
    sem(y) = sd(y) / sqrt(size(subset,1));
end
figure;
errorbar(volumes, means, sem, 'bo');
    
% Track means for each volume (moving average). If set to half the size of
% trialLog, will calculate std and sem for each half, for each volume
window = 3;
for v = 1:length(volumes)
    set = data(data(:,2) == volumes(v),:);
    for y = 1:(size(set,1) - window)
        movave(y,v) = mean(set(y:y+window, 3));
        movsd(y,v) = std(set(y:y+window, 3));
        movsem(y,v) = movsd(y,v) / sqrt(size(set,1));
    end
end
figure;
hold on;
plot(movave(:,1), 'r-')
plot(movave(:,2), 'g-')
plot(movave(:,3), 'b-')
plot(movave(:,4), 'm-')
xlabel('Trial');
ylabel('Average Pleasantness');
legend(text{1},text{2},text{3},text{4});

%% Satiety modeling

for v = 1:length(volumes) % For each volume
    set = data(data(:,2) == volumes(v),:);
% Set parameters
R = set(:,2); % Reward volume
window = 3; % Moving average window size
for y = 1:size(set,1)
    if y <= (size(set,1)-window) 
    P(y,1) = mean(set(y:y+window, 3)); % Average pleasantness
    else % If window exceeds size
        P(y,1) = mean(set(y-window:y,3));
    end
end

% Calculate normalised reward
normR = @(Rcumt,Rmax) Rcumt/Rmax;
for y = 1:size(set,1)
    S(y,1) = normR(set(y,5),set(length(set),5)); % Normalised reward
end

minFun = @(par) CostFunction(par,R,S,P);

x0 = rand(1,2); % Initial values for parameter search

lowerBound = [0 0];
upperBound = [inf inf];
[minParams, fval, exitflag, output] = fmincon(minFun,x0,[],[],[],[],lowerBound,upperBound);


% Plot fitted function
newfunc = R.*((1+exp(-(S-minParams(1))./minParams(2)))./(1+exp(-minParams(1)./minParams(2)))); % Generate data with new model
figure;
hold on;
plot(newfunc, 'b--'); % Plot model
plot(P, 'r-'); % Plot data
end

function [cost] = CostFunction(par,R,S,P)
    
Rm = R.*((1+exp(-(S-par(1))./par(2)))./(1+exp(-par(1)./par(2)))); % Discount function
cost = sum( (P - Rm) .^ 2);
end

end