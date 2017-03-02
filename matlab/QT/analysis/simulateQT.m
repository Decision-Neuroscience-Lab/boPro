function [data] = simulateQT(memory)

%% Set task parameters and create delay distributions
smallReward = 0.01; % Reward size (dollars)
largeReward = 0.15;
iti = 2; % Intertrial interval
blockTime = 2000;
quartileSampling = 1;
blue = [0 113 189];
orange = [217 83 25];
teal = [113,203,153];
colours = {blue,orange,teal,[246.993,185.997,106.0035]};
% Uniform dist
a = 0;
b = 12;
D1 = makedist('Uniform',a,b);
% Pareto dist
k = 8;
sigma = 3.4;
theta = 0; % Lower bound
D2 = makedist('Generalized Pareto',k,sigma,theta);
D2 = truncate(D2,0,90); % Truncate at 90
D = {D1, D2}; % Distribution wrapper

% Create quartile randomisation
if quartileSampling == 1
    qtList = [];
    for q = 1:round((blockTime/iti)/16) + 1
        qtList = cat(1,qtList,deBruijn(4,2)); % Balance first-order transition statistics
    end
end

%% Choose algorithm and simulate data
% Preallocate data structure
trialLog = table;
for d = D
    % Reset trial variables
    t = 0;
    totalReward = 0;
    totalTime = 0;
    while totalTime < blockTime
        t = t + 1; % Trial counter
        % Sample delay
        if quartileSampling == 1
            switch qtList(t)
                case 1
                    delay(t) = random(truncate(d{1},0,icdf(d{1},0.25)));
                case 2
                    delay(t) = random(truncate(d{1},icdf(d{1},0.25),icdf(d{1},0.5)));
                case 3
                    delay(t) = random(truncate(d{1},icdf(d{1},0.5),icdf(d{1},0.75)));
                case 4
                    delay(t) = random(truncate(d{1},icdf(d{1},0.75),icdf(d{1},1)));
            end
        else
            delay(t) = random(d{1}); % Choose a random reward delay from distribution
        end
        
        % Update memory
        if t <= memory + 1 % If not yet enough memory, wait to receive reward
            rt = delay(t);
            reward = largeReward;
            totalTime = totalTime + rt;
            censor(t) = 1;
            aveRate(t) = NaN;
        else
            aveRate = tsmovavg(rewardRate,'s',memory);
            timeCost = rewardRate(end) * (delay(t)); % aveRate(end) * (delay(t)); % + iti
            if timeCost > largeReward % If cost is higher than reward
                rt = largeReward./aveRate(end);
                reward = smallReward;
                totalTime = totalTime + rt;
                censor(t) = 0;
            elseif timeCost <= largeReward % If threshold is reached first
                rt = delay(t);
                reward = largeReward;
                totalTime = totalTime + rt;
                censor(t) = 1;
            end
        end
        
        % Perform action
%         for i = 0:0.1:delay(t)
%             timeCost = aveRate(t) * (i + iti);
%             if timeCost > largeReward
%                
%                 quitTime = i; % aveRate(t) * largeReward
%                 
%             end
%         end
%         
        % r/t = R
        % r = t*R
        % r/R = t
        
       
        
        % Record data
        totalReward = totalReward + reward;
        totalTime = totalTime + iti;
        rewardRate(t) = totalReward./totalTime;
        trialLog = cat(1,trialLog,{t, {d{1}.DistributionName}, delay(t), rt, logical(censor(t)), reward, totalReward, totalTime, rewardRate(t),aveRate(end)});
        
    end % Block timer
end % Distribution loop

trialLog.Properties.VariableNames = {'trial','distribution','delay','rt','censor','reward','totalReward','blockTime','rewardRate','aveRate'};

%% Analyse and plot simulated data

% Recode distribution
numD = numel(D);

trialLog.distName = trialLog.distribution;
temp = strcmp(trialLog.distribution,D{2}.DistributionName);
temp = temp + 1;
trialLog.distribution = temp;

% Plot survivor function and get AUCs
figure;
subplot(2,2,1);
AUC = NaN(numD,1);
for d = 1:numD
    temp = trialLog(trialLog.distribution == d,:);
    [f,x,flo,fup] = ecdf(temp.rt,'censoring', temp.censor,'function','survivor');
    h(d) = stairs(x,f); set(h(d),'Color',colours{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d) = trapz(x,f);
    l{d} = sprintf('AUC: %.3f',AUC(d));
end
legend(h(1:numD),l);
xlabel('Elapsed time'); ylabel('Probability of quitting');
title('Surivor function');

% WTW
inputVar = {'rt'};
groupVar = {'distribution','trial'};
M = varfun(@nanmean, trialLog, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
SD = varfun(@nanstd, trialLog, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
SE = SD.nanstd_rt ./ SD.GroupCount;

subplot(2,2,2);
for d = 1:numD
    h(d) = plot(1:max(M.trial(M.distribution == d)),...
        M.nanmean_rt(M.distribution == d));
    set(h(d),'Color',colours{d}./255); hold on;
    % Plot standard error
    su(d) = plot(1:max(SD.trial(SD.distribution == d)),...
        M.nanmean_rt(SD.distribution == d)...
        + SE(SD.distribution == d));
    sd(d) = plot(1:max(SD.trial(SD.distribution == d)),...
        M.nanmean_rt(SD.distribution == d)...
        - SE(SD.distribution == d));
    set(su(d),'Color',[0 0 0],'LineStyle',':'); set(sd(d),'Color',[0 0 0],'LineStyle',':');
end
title('Willingness to wait');
ylabel('WTW (secs)');
xlabel('Trial');

% % Autocorr
% subplot(2,2,3);
% for d = 1:numD
%     autocorr(trialData.rt(trialData.distribution == d &...
%         trialData.censor == 0 &...
%         ~isnan(trialData.rt)));
% end

% Plot response distribution against reward distribution
z = 1;
for d = 1:numD
    subplot(2,2,2+z);
    nhist({trialLog.rt(trialLog.distribution == d & trialLog.censor == 0)},'smooth','pdf',...
        'noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap'); hold on;
    lim = get(gca,'XLim');
    plot(0:0.01:lim(2),pdf(D{d},0:0.01:lim(2)),'Color',colours{d}./255,'LineWidth',2);
    ylim([0 0.15]);
    z = z + 1;
end

return
