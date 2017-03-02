%% Data analysis for writeup
set(0,'DefaultAxesColorOrder',...
    [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultAxesFontSize',20);
amounts = unique(trialData.reward);
delays = unique(trialData.delay);

%% Data cleaning
participants = [1:10];

% Add exclusion variables to trialData
trialData.flag = zeros(size(trialData,1),1);
trialData.flag(isnan(trialData.response)) = 1; % Mark missed responses as excluded
TH = 2.5;
ploton = 0;
warning('off',char('MATLAB:legend:IgnoringExtraEntries'));
for x = participants
    if ploton
    figure;
    end
    temp = trialData(trialData.id == x & trialData.flag == 0,:);
    for d = 1:numel(delays)
        temp2 = temp(temp.delay == delays(d),:);
        i = trialData.id == x & trialData.delay == delays(d) & trialData.flag == 0;
        
        % Get mean and std for each delay
        M(x,d) = mean(temp2.response);
        SD(x,d) = std(temp2.response);
        
        [N,X] = hist(temp2.response,10);
        try
            f1 = fit(X', N', ...
                'gauss1', 'Exclude',...
                X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d))); % Fit to included data
        catch
            fprintf('Could not fit gaussian, not enough data.\nThis may be because delays are ill-defined\n');
            continue;
        end
        if ploton
            subplot(2,2,d);
            h = plot(f1,X,N,X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d)));
            if size(h,1) == 3
                set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o');...
                    set(h(2), 'Color', [0.443 0.82 0.6], 'Marker', '*');...
                    set(h(3), 'Color', [0.85 0.325 0.098]);
                legend('Data','Excluded data','Fitted normal distribution');
            else
                set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o');...
                    set(h(2), 'Color', [0.85 0.325 0.098]);
                legend('Data','Fitted normal distribution');
            end
            hold on
            plot(repmat(delays(d)./2, 1, max(N) + 1), 0:max(N),...
                'LineStyle', '--', 'Color', [0.85 0.325 0.098]);
            ylabel('Response frequency');
            xlabel('Response (secs)');
            title(sprintf('Participant %.0f, %.0f seconds', x, delays(d)));
        end
        trialData.flag(i) = trialData.flag(i) + temp2.response...
            < (M(x,d) - TH.*SD(x,d)) | temp2.response > (M(x,d) + TH.*SD(x,d)); % Create exclusion logical
        fprintf('%.0f trials excluded for participant %.0f in delay %.0f.\n',...
            sum(temp2.response < (M(x,d) - TH.*SD(x,d)) | temp2.response > (M(x,d) + TH.*SD(x,d))),x,delays(d));
    end
    clearvars -except trialData amounts delays participants TH x exclude M SD ploton
end
fprintf('Total of %.0f trials excluded. %.0f were missed\n',sum(trialData.flag), sum(isnan(trialData.response)));
warning('on',char('MATLAB:legend:IgnoringExtraEntries'))
clearvars -except trialData amounts delays errorColour barColour participants

%% Create new variables
for tidiness = 1
    % Preallocate new variables
    % Response variables
    trialData.accuracy = trialData.response - trialData.delay./2;
    trialData.normResponse = nan(height(trialData),1); % Normalised per participant, without accounting for delay
    trialData.normAccuracy = nan(height(trialData),1); % Normalised per participant, accounting for delay
    trialData.relResponse =  nan(height(trialData),1); % Normalised per participant, accounting for delay by division
    trialData.lagResponse = nan(height(trialData),1); % Previous response, for correcting autocorrelation
    trialData.lagResponse2 = nan(height(trialData),1); % Previous response, for correcting autocorrelation
    trialData.lagAccuracy = nan(height(trialData),1); % Previous accuracy, for correcting autocorrelation
    trialData.lagAccuracy2 = nan(height(trialData),1); % Previous accuracy, for correcting autocorrelation
    trialData.lagAccuracy3 = nan(height(trialData),1); % Previous accuracy, for correcting autocorrelation
    % Condition variables
    trialData.lagReward = nan(height(trialData),1); % Previous reward, i.e. most recently experienced (not anticipated) reward prior to time estimation
    trialData.lagDelay = nan(height(trialData),1); % Previous delay, i.e. most recently experienced (not anticipated) delay prior to time estimation
    trialData.lagDelay2 = nan(height(trialData),1); % Second previous delay, i.e. most recently experienced (not anticipated) delay prior to time estimation
    trialData.windowReward = nan(height(trialData),1); % Moving average of reward, currently set to a window of past 3 rewards and an exponential weighting
    trialData.RPE = nan(height(trialData),1); % RPE from Fiorillo
    trialData.conventionalRPE = nan(height(trialData),1); % RPE from Fiorillo - not scaled
    
    % Loops for conditions specific calculations
    for x = participants
        temp = trialData(trialData.id == x,:);
        % Response variables
        trialData.normResponse(trialData.id == x & ~isnan(trialData.response))...
            = zscore(trialData.response(trialData.id == x & ~isnan(trialData.response)));
        trialData.lagResponse(trialData.id == x) = cat(1,[0],temp.response(1:end-1));
        trialData.lagResponse2(trialData.id == x) = cat(1,[0;0],temp.response(1:end-2));
        trialData.lagAccuracy(trialData.id == x) = cat(1,[0],temp.accuracy(1:end-1));
        trialData.lagAccuracy2(trialData.id == x) = cat(1,[0;0],temp.accuracy(1:end-2));
                trialData.lagAccuracy3(trialData.id == x) = cat(1,[0;0;0],temp.accuracy(1:end-3));
        % Condition variables
        trialData.lagReward(trialData.id == x) = cat(1,0,temp.reward(1:end-1));
        trialData.lagDelay(trialData.id == x) = cat(1,0,temp.delay(1:end-1));
        trialData.lagDelay2(trialData.id == x) = cat(1,[0;0],temp.delay(1:end-2));
        trialData.windowReward(trialData.id == x) = tsmovavg(trialData.reward(trialData.id == x),'s',3,1);
        for d = 1:numel(delays)
            trialData.normAccuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                = zscore(trialData.accuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response)));
            trialData.relResponse(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                = trialData.response(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                ./trialData.delay(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response));
        end
        % trialData.relResponse(trialData.id == x & ~isnan(trialData.response)) = zscore(trialData.relResponse(trialData.id == x & ~isnan(trialData.response)));
    end
    
    % Time perception measures
    TIME = table;
    c = 1;
    for x = participants
        temp = trialData(trialData.id == x,:);
        ID(c,1) = table(x,'VariableNames',{'id'});
        ind = getTimeData(temp.delay(~isnan(temp.response))./2,...
            temp.response(~isnan(temp.response)));
        TIME = [TIME;ind];
        c = c + 1;
    end
    TIME = [ID TIME];
    TIME.Properties.VariableNames(1) = {'id'};
    
    % Theoretically relevant condition variables
    trialData.rateReward = trialData.reward ./ (trialData.delay); % Reward rate with ITI
    trialData.lagRateReward = trialData.lagReward ./ (trialData.lagDelay); % Reward rate with ITI
    trialData.TIMERR = (trialData.reward - (tsmovavg(trialData.rateReward,'s',3,1).*trialData.delay))...
        ./(1+(trialData.delay/((7+9)*5))); % Subjective value as per TIMMER, uses an average trial length to calculate window of integration
    trialData.predError = trialData.reward - tsmovavg(trialData.rateReward,'e',4,1);
    
    trialData.RPE = (trialData.delay - 1) ./ 0.2; % RPE from Fiorillo
    trialData.conventionalRPE = trialData.reward - (trialData.reward./trialData.delay); % RPE from Fiorillo - not scaled
end
clearvars -except trialData amounts delays participants TIME errorColour barColour

barColour = [.5 .5 .5];
%[0 0.447 0.741]
errorColour = [0 0 0];
initialVars = who;
initialVars{end+1} = 'initialVars';
clearvars('-except',initialVars{:});

%% CV
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
inputVar = {'response'};
groupVar = {'delay','id'};
STD = varfun(@nanstd, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

M = varfun(@nanmean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
for d = 1:numel(delays)
    CV(:,d) = STD.nanstd_response(STD.delay == delays(d)) ./ M.nanmean_response(M.delay == delays(d));
end
[p,table,stats] = anova1(CV);

M = mean(CV);
SD = std(CV) ./ sqrt(length(CV));

figure;
hBar = plot(M);
set(hBar(1),'Color',[0 0 0],...
    'LineStyle',':',...
    'Marker','o');
set(gca,'XTick',1:4);
set(gca,'XTickLabel',...
    {'4 seconds','6 seconds','8 seconds','10 seconds'});
%title('Coefficient of variation');
ylabel('Coefficient of variation');
hold on
h = errorbar(M,SD);
set(h,'linestyle','none','linewidth',1.5);
set(h, 'Color', errorColour);

clearvars('-except',initialVars{:});

%% Central tendency
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
inputVar = {'accuracy'};
groupVar = {'delay'};

M = varfun(@nanmean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
S = varfun(@nanstd, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

for d = 1:numel(delays)
    A(:,d) = M.nanmean_accuracy(M.delay == delays(d));
    ME(d) = nanmean(M.nanmean_accuracy(M.delay == delays(d)));
    SD(d) = nanstd(M.nanmean_accuracy(M.delay == delays(d)));
    SE(d) = SD(d) ./ sqrt(numel(M.nanmean_accuracy(M.delay == delays(d))));
    SEM(d) = S.nanstd_accuracy(S.delay == delays(d)) ./ sqrt(M.GroupCount(M.delay == delays(d)));
    [h{d},p{d},ci{d},stats{d}] = ttest(temp.accuracy(temp.delay==delays(d)));
end

figure;
hBar = bar(ME);
set(hBar(1),'FaceColor',barColour,'EdgeColor','none');
set(gca,'XTick',1:4);
set(gca,'XTickLabel',...
    {'4 seconds','6 seconds','8 seconds','10 seconds'});
%title('Central tendency');
ylabel('Deviation (seconds)');
hold on
h = errorbar(ME,SEM);
set(h,'linestyle','none');
set(h, 'Color', errorColour);
clearvars('-except',initialVars{:});

%% Baseline vs main task
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
inputVar = {'normAccuracy'};
groupVar = {'session','id'};
M = varfun(@nanmean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

for s = 1:3
        ME(:,s) = M.nanmean_normAccuracy(M.session == s);
    SD(s) = nanstd(ME(:,s)) ./ sqrt(numel(ME(:,s)));
end

[h,p,ci,stats] = ttest2(cat(1,ME(:,1),ME(:,3)),ME(:,2))

[h,p,ci,stats] = ttest2(ME(:,1),ME(:,2))
[h,p,ci,stats] = ttest2(ME(:,2),ME(:,3))

figure;
hBar = bar(mean(ME));
set(hBar(1),'FaceColor',barColour,'EdgeColor','none');
set(gca,'XTick',1:3);
set(gca,'XTickLabel',...
    {'First baseline','Main Task','Second baseline'});
%title('Baseline vs Main task');
ylabel('Deviation (secs)');
hold on
h = errorbar(mean(ME),SD);
set(h,'linestyle','none');
set(h, 'Color', errorColour);
ylim([-.4 .15]);
% 
% % Draw brackets
% x1 = 1;
% x2 = 3;
% y = 0.12;
% height = 0.01;
% % Make some x-data and y-data
% line_y = y  + [0, 0.5, 0.5, 1, 0.5, 0.5, 0] * height;
% line_x = x1 + [0, 0.02, 0.48, 0.5, 0.52, 0.98, 1]*(x2-x1);
% % Draw the brace and some text, too, for fun.
% line(line_x, line_y, 'Color', 'k')
% 
% text(1-0.04, mean(ME(:,1))-SD(1)-0.03, '*','FontSize',50);

clearvars('-except',initialVars{:});

%% Visualize regression results (by delay)
figure;
for d = 1:numel(delays)
temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
    id = unique(trialData.id(ismember(trialData.id, participants)));
    for x = 1:numel(id)
        for a = 1:numel(amounts)
            i = temp.id == id(x) & temp.lagReward == amounts(a) & temp.delay == delays(d);
            M(x,a) = nanmean(temp.normAccuracy(i));
        end
    end
    ME = nanmean(M);
    SD = nanstd(M);
    SEM = SD ./ sqrt(size(M,1));
    CI = (1.96 .* SEM);
    subplot(2,2,d);
    bar(ME,'FaceColor',barColour,'EdgeColor',[1 1 1], 'BarWidth',0.8);
    hold on;
    errorbar(1:4,ME,SEM,'Color',errorColour ,'LineWidth',1,'LineStyle', 'none');
    set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
ylabel('Normalised accuracy');
ylim([-.2 .3]);
title(sprintf('%.0f seconds',delays(d)));
blue = [0 0.447 0.741];
og = [0.85 0.325 0.098];
end
suptitle('The effect of previous reward on time estimations at different delays');
clearvars('-except',initialVars{:});

%% Visualize regression results (by reward)
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
inputVar = {'normAccuracy'};
groupVar = {'id','lagReward'};
M = varfun(@nanmean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

   for a = 1:numel(amounts)
      ME(:,a) = M.nanmean_normAccuracy(M.lagReward == amounts(a));
      SEM(a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
   end
[p,table,stats] = anova1(ME);

    CI = (1.96 .* SEM);
    figure;
    bar(mean(ME),'FaceColor',barColour,'EdgeColor','none');
    hold on;
    h = errorbar(mean(ME),SEM);
set(h,'linestyle','none');
set(h, 'Color', errorColour);
    set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
ylabel('Normalised deviation');
ylim([-.15 .2]);
clearvars('-except',initialVars{:});

%% Histogram

    delayStrings = {'4 seconds','6 seconds','8 seconds','10 seconds'};
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
    for d = 1:numel(delays)
        temp2 = temp(temp.delay == delays(d),:);
        D{d} = temp2.response;
    end
    
    % Plot responses split by delay
    figure;
    nhist(D,'smooth','legend',delayStrings,...
        'decimalplaces',0,'xlabel','Response (secs)','ylabel','Probability density function','color','colormap','fsize',25);
    objs = findobj;
    objs(4).XGrid = 'on';
    
    %% Autocorr dependent on reward
temp = trialData(trialData.flag == 0 & trialData.type == 1 & trialData.session == 2,:);
figure;
for r = 1:numel(amounts)
    [acf,lags,bounds] = autocorr(temp.response(strcmp(temp.lagReward, amounts(r))),2);
    plot(lags,acf);
    hold on;
end
legend('No reward','Small','Medium','Large');

% Individuals
C = unique(trialData.id(trialData.type == 1))';
c = 1;
for x = C
    temp = trialData(trialData.id == x & trialData.type == 1 & trialData.flag == 0 & trialData.session == 2,:);
    temp = sortrows(temp,3);
    for r = 1:numel(amounts)
        [acf,~,~] = autocorr(temp.response(strcmp(temp.lagReward, amounts(r))),5);
        lag1(c,r) = acf(2);
        lag2(c,r) = acf(3);
        lag3(c,r) = acf(4);
    end
    c = c + 1;
end

% Differences between trials, binned by lagged reward
for t = 1:3
    C = unique(trialData.id(trialData.type == t))';
    c = 1;
    for x = C
        temp = trialData(trialData.id == x & trialData.type == t & trialData.flag == 0 & trialData.session == 2,:);
        temp = sortrows(temp,3);
        DIFF = diff(temp.normAccuracy);
        for r = 1:numel(amounts)
            i = strcmp(temp.reward, amounts(r));
            i(end) = [];
            ME(c,r) = mean(DIFF(i));
        end
        c = c + 1;
    end
    means(t,:) = mean(ME);
    sems(t,:) = std(ME);
    [p,table,stats] = anova1(ME,[],'off');
    if t == 1
        fprintf('Juice: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    elseif t == 2
        fprintf('Money: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    elseif t == 3
        fprintf('Water: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    end
end
figure;
hBar = bar(means');
set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
set(hBar(3),'FaceColor',barColour{3},'EdgeColor','none');
hold on;
for e = 1:size(sems,2)
    h = errorbar(e - 0.22, means(1,e), sems(1,e));
    set(h,'linestyle','none','Color', errorColour);
    h = errorbar(e, means(2,e), sems(2,e));
    set(h,'linestyle','none','Color', errorColour);
    h = errorbar(e + 0.22, means(3,e), sems(3,e));
    set(h,'linestyle','none','Color', errorColour);
end
set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
ylabel('Mean difference between trials');
legend({'Juice','Money','Water'});
clearvars('-except',initialVars{:});