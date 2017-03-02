%% PIP Individual differences
oldcd = cd('/Users/Bowen/Documents/MATLAB/PIPW/data');
% Read data and recode ids
load('trialDataJuice');
load('juiceThirst');
jthirst = thirst(:,end);
trialDataJuice.id(trialDataJuice.id > 17) = trialDataJuice.id(trialDataJuice.id > 17) - 1;
load('trialDataMoney');
load('moneyThirst');
trialDataMoney.id = trialDataMoney.id + 25;
load('trialDataWater');
load('waterThirst');
wthirst = thirst(:,end);
trialDataWater.id = trialDataWater.id + 50;

% Read questionairre data and calculate AUCs
load('imagine.csv')
min_delay = 10;
max_delay = 180;
x = [0 10/10 18/10 30/10 55/10 100/10 180/10]; % Objective time
subj_auc = zeros(length(imagine),1);
zth = zeros(length(imagine),numel(x));
for i = 1:length(imagine)
    zth(i,2:end) = imagine(i,:)/imagine(i,1);
end
for i = 1:length(zth);
    auc(i,1) = zaub_auc(x,zth(i,:),min_delay,max_delay);
end

trialData = [trialDataJuice;trialDataMoney;trialDataWater];
clearvars thirst
thirst = [jthirst;moneyThirst';wthirst];
type(1:6000) = 1;
type(6001:12000) = 2;
type(12001:18000) = 3;
trialData = [array2table(type','VariableNames',{'type'}),trialData];

participants = unique(trialData.id);

% Time perception measures
TIME = table;
for x = 1:numel(participants)
    temp = trialData(trialData.id == x,:);
    ID(x,1) = table(x,'VariableNames',{'id'});
    ind = getTimeData(temp.delay(~isnan(temp.response))./2,...
        temp.response(~isnan(temp.response)));
    TIME = [TIME;ind];
end
TIME = [ID TIME array2table(thirst) array2table(auc)];
TIME.Properties.VariableNames(1) = {'id'};


%% Create new variables
for tidiness = 1
    delays = unique(trialData.delay);
    
    % Preallocate new variables
    % Response variables
    trialData.accuracy = trialData.response - trialData.delay./2;
    trialData.normResponse = nan(height(trialData),1); % Normalised by participant
    trialData.normAccuracy = nan(height(trialData),1); % Normalised by delay (within participant)
    trialData.lagResponse = nan(height(trialData),1);
    trialData.lagNormAccuracy = nan(height(trialData),1);
    trialData.lagReward = nan(height(trialData),1);
    trialData.lagReward2 = nan(height(trialData),1);
    trialData.lagReward3 = nan(height(trialData),1);
    trialData.lagDelay = nan(height(trialData),1);
    trialData.rewardRate = nan(height(trialData),1);
    trialData.lagRewardRate = nan(height(trialData),1);
    trialData.windowReward = nan(height(trialData),1);
    
    participants = unique(trialData.id)';
    for x = participants
        for d = 1:numel(delays)
            trialData.normAccuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                = zscore(trialData.accuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response)));
        end
        temp = trialData(trialData.id == x,:);
        trialData.normResponse(trialData.id == x & ~isnan(trialData.response))...
            = zscore(trialData.response(trialData.id == x & ~isnan(trialData.response)));
        % Condition variables
        trialData.lagResponse(trialData.id == x) = lagmatrix(temp.response,1);
        trialData.lagNormAccuracy(trialData.id == x) = lagmatrix(temp.normAccuracy,1);
        trialData.lagReward(trialData.id == x) = lagmatrix(temp.reward,1);
        trialData.lagReward2(trialData.id == x) = lagmatrix(temp.reward,2);
        trialData.lagReward3(trialData.id == x) = lagmatrix(temp.reward,3);
        trialData.lagDelay(trialData.id == x) = lagmatrix(temp.delay,1);
        trialData.windowReward(trialData.id == x) = tsmovavg(trialData.reward(trialData.id == x),'s',3,1);
    end
    
    % Theoretically relevant condition variables
    trialData.rewardRate = trialData.reward ./ (trialData.delay);
    trialData.lagRewardRate = trialData.lagReward ./ (trialData.lagDelay);
end

%% Carry-over bias
for p = 1:numel(participants)
    temp = trialData(trialData.id == p & trialData.flag == 0,:);
    lm = fitlm([temp.delay, temp.lagResponse, temp.lagDelay],temp.response,'linear');
    coefs(p,1:4) = table2array(lm.Coefficients(1:4,1));
    sds(p,1:4) = table2array(lm.Coefficients(1:4,2));
end

TIME = [TIME array2table(coefs(:,3:4))];
TIME.Properties.VariableNames(end-1:end) = {'Decisional','Perceptual'};


%% Look for correlations (hah)
for x = 1:numel(TIME.Properties.VariableNames)
    [r,p] = corr(TIME.thirst, TIME.(TIME.Properties.VariableNames{x}), 'type','spearman');
    if p < 0.1
        fprintf('Spearman correlation between thirst and %s:\nr = %.3f\np = %.3f\n',TIME.Properties.VariableNames{x},r,p);
    end
    [r,p] = corr(TIME.auc, TIME.(TIME.Properties.VariableNames{x}), 'type','spearman');
    if p < 0.1
        fprintf('Spearman correlation between auc and %s:\nr = %.3f\np = %.3f\n',TIME.Properties.VariableNames{x},r,p);
    end
    [r,p] = corr(TIME.Decisional, TIME.(TIME.Properties.VariableNames{x}), 'type','spearman');
    if p < 0.1
        fprintf('Spearman correlation between decisional carry over and %s:\nr = %.3f\np = %.3f\n',TIME.Properties.VariableNames{x},r,p);
    end
    [r,p] = corr(TIME.Perceptual, TIME.(TIME.Properties.VariableNames{x}), 'type','spearman');
    if p < 0.1
        fprintf('Spearman correlation between perceptual carry over and %s:\nr = %.3f\np = %.3f\n',TIME.Properties.VariableNames{x},r,p);
    end
end



%% Change reward coding
for tidiness = 1
    trialData.lagReward(isnan(trialData.lagReward)) = 0;
    for t = 1:height(trialData)
        switch trialData.reward(t)
            case 0
                T{t} = 'no reward';
            case {0.5, 5}
                T{t} = 'small reward';
            case {1.2, 15}
                T{t} = 'medium reward';
            case {2.3, 30}
                T{t} = 'large reward';
        end
        switch trialData.lagReward(t)
            case 0
                T2{t} = 'no reward';
            case {0.5, 5}
                T2{t} = 'small reward';
            case {1.2, 15}
                T2{t} = 'medium reward';
            case {2.3, 30}
                T2{t} = 'large reward';
        end
    end
    trialData.reward = T';
    trialData.lagReward = T2';
    a = unique(trialData.reward);
    amounts(1) = a(3);
    amounts(2) = a(4);
    amounts(3) = a(2);
    amounts(4) = a(1);
    clearvars -except trialData amounts delays errorColour barColour
    initialVars = who;
    initialVars{end+1} = 'initialVars';
    clearvars('-except',initialVars{:});
end


cd(oldcd);

%% Thirst and pleasantness
clearvars thirst
load('juiceThirst');
jthirst = thirst;
load('waterThirst');
wthirst = thirst;
thirst = [jthirst;wthirst];
load('waterPleasantness');
wpls = pleasantness;
load('juicePleasantness');
jpls = pleasantness;
pls = [jpls;wpls];


for x = 1:50
    norm1Thirst(x,:) = (thirst(x,:) - min(thirst(x,:)));
    normThirst(x,:) = norm1Thirst(x,:)./max(norm1Thirst(x,:));
    norm1Pls(x,:) = (pls(x,:) - min(pls(x,:))) ./max(pls(x,:));
    normPls(x,:) = norm1Pls(x,:)./max(norm1Pls(x,:));
end