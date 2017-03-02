%% QT Data analyses (old)
% Bowen J Fung, June 2015
blue = [0 113 189];
orange = [217 83 25];
teal = [113,203,153];
magenta = [203 81 171];

%% Get data
participants = 1:4;
trialData = table;
thirst = [];
for x = participants
    oldcd = cd('/Users/Bowen/Documents/MATLAB/QT/data');
    try % If there was a restart in one of the files load the second file
        name = sprintf('%.0f_2_*', x);
        loadname = dir(name);
        load(loadname.name,'data');
        fprintf('Loaded restarted data for participant %.0f.\n',x);
    catch
        % Load first try
        name = sprintf('%.0f_1_*', x);
        loadname = dir(name);
        load(loadname.name,'data');
    end
    cd(oldcd);
    thirst = cat(1,thirst,data.blockThirst);
    trialData = cat(1,trialData,data.trialLog);
    params = data.params; % Take params from last participant
end

%% Clean data and add variables
numD = numel(params.D);
% First remove incomplete blocks and NaN responses
for p = participants
    for b = 1:numel(unique(trialData.block(trialData.id == p)))
        if nansum(trialData.rt(trialData.id == p & trialData.block == b)) == 0
            trialData(trialData.id == p & trialData.block == b,:) = [];
        end
    end
end
trialData(isnan(trialData.rt),:) = [];

trialData.rr = trialData.totalReward ./ trialData.blockTime; % Empirical reward rate
trialData.pr = nan(height(trialData),1);
for p = participants
    for b = 1:numel(unique(trialData.block(trialData.id == p)))
        i = trialData.id == p & trialData.block == b;
        trialData.pr(i) = tsmovavg(trialData.reward(i)./(trialData.rt(i) + params.iti), 'e', 5, 1); % Perceived reward rate (moving average); tsmovavg takes arg(ts, exponential, lag, dim)
    end
end

% Recode distribution
trialData.distName = trialData.distribution;
temp = strcmp(trialData.distribution,params.D{2}.DistributionName);
temp = temp + 1;
trialData.distribution = temp;

% Chronological trials
allTrial = NaN(size(trialData,1),1);
for p = participants
    for d = 1:numD
        i = trialData.id == p & trialData.distribution == d;
        allTrial(i) = 1:size(trialData(i,:),1);
    end
end
trialData.allTrial = allTrial;

%% Get optimal stopping time and max reward rate
numD = numel(params.D);
[optimTime, rStar, expectedReturn, expectedCost, rT, T] = getOptimal(params);
for d = 1:numD
    fprintf('Maximum possible return for %s distribution: $%.2f.\n',params.D{d}.DistributionName,rStar(d)*params.blockTime);
end

clearvars -except participants numD trialData optimTim rStar thirst
initialVars = who;
initialVars{end+1} = 'initialVars';
clearvars('-except',initialVars{:});

%% Plot all participant data
scores = table;
numD = numel(params.D);
figure;
z = 1;
for p = participants
    subplot(2,2,z);
    % Plot survivor functions
    AUC = NaN(numD,1);
    for d = 1:numD
        temp = trialData(trialData.id == p &...
            trialData.distribution == d &...
            trialData.block > 2,:);
        [f,x,flo,fup] = ecdf(temp.rt,'censoring', temp.censor,'function','survivor');
        %[f,x,flo,fup] = ecdf(temp.rt,'function','survivor');
        h(d) = stairs(x,f); set(h(d),'Color',params.colours{d}./255); hold on;
        stairs(x,flo,'k:','Color',params.colours{d}./255); stairs(x,fup,'k:','Color',params.colours{d}./255); % Plot confidence bounds
        AUC(d) = trapz(x,f);
        l{d} = sprintf('AUC: %.3f',AUC(d));
        %line([optimTime(d) optimTime(d)],get(gca,'YLim'),'Color',params.colours{d}./255,'LineStyle',:); % Indicate maximum
    end
    h_legend = legend(h(1:numD),l);
    set(h_legend,'FontSize',10);
    xlabel('Elapsed time (deciseconds)'); ylabel('Probability of waiting');
    
    % Calculate empirical vs optimal
    for d = 1:numD
        fprintf('%s deviation from optimality: %.2f seconds.\n',...
            params.D{d}.DistributionName,AUC(d) - optimTime(d));
    end
    scores(z,:) = {p,AUC(1)-optimTime(1),AUC(2)-optimTime(2)};
    z = z + 1;
end
scores.Properties.VariableNames = {'id','uniformAUC','paretoAUC'};
clearvars('-except',initialVars{:});

%% Autocorr
figure;
z = 1;
for p = participants
    subplot(2,2,z); z = z + 1;
    for d = 1:numD
        autocorr(trialData.rt(trialData.id == p &...
            trialData.distribution == d &...
            trialData.censor == 0 &...
            ~isnan(trialData.rt)));
    end
end
clearvars('-except',initialVars{:});


%% All participants
figure;
subplot(2,1,1);
% Survivor
AUC = NaN(numD,1);
for d = 1:numD
    temp = trialData(trialData.distribution == d,:);
    [f,x,flo,fup] = ecdf(temp.rt,'censoring', temp.censor,'function','survivor');
    h(d) = stairs(x,f); set(h(d),'Color',params.colours{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d) = trapz(x,f);
    l{d} = sprintf('%s AUC: %.3f',params.D{d}.DistributionName,AUC(d));
    % line([optimTime(d) optimTime(d)],get(gca,'YLim'),'Color',params.colours{d}./255,'LineStyle',:); % Indicate maximum
end
legend(h(1:numD),l);
xlabel('Elapsed time'); ylabel('Probability of quitting');
for d = 1:numD
    fprintf('%s deviation from optimality: %.2f seconds.\n',...
        params.D{d}.DistributionName,AUC(d) - optimTime(d));
end
title('Surivor function');

% WTW
inputVar = {'rt'};
groupVar = {'distribution','allTrial'};
M = varfun(@nanmean, trialData, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
SD = varfun(@nanstd, trialData, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);
SE = SD.nanstd_rt ./ SD.GroupCount;

subplot(2,1,2);
for d = 1:numD
    h(d) = plot(1:max(M.allTrial(M.distribution == d)),...
        M.nanmean_rt(M.distribution == d));
    set(h(d),'Color',params.colours{d}./255); hold on;
    % Plot standard error
    su(d) = plot(1:max(SD.allTrial(SD.distribution == d)),...
        M.nanmean_rt(SD.distribution == d)...
        + SE(SD.distribution == d));
    sd(d) = plot(1:max(SD.allTrial(SD.distribution == d)),...
        M.nanmean_rt(SD.distribution == d)...
        - SE(SD.distribution == d));
    set(su(d),'Color',[0 0 0],'LineStyle',':'); set(sd(d),'Color',[0 0 0],'LineStyle',':');
    % line(get(gca,'XLim'),[optimTime(d) optimTime(d)],'Color',params.colours{d}./255,'LineStyle',:); % Indicate maximum
end
title('Willingness to wait');
ylabel('WTW (secs)');
xlabel('Trial');
%  figure;
% crosscorr(M.nanmean_rt(strcmp(M.distribution,'Uniform') & M.allTrial < 101),M.nanmean_rt(strcmp(M.distribution,'Generalized Pareto') & M.allTrial < 101));
% plot(lags,r);
clearvars('-except',initialVars{:});

%% Check empirical delay distributions
figure;
z = 1;
for p = participants
    temp = trialData(trialData.id == p,:);
    for d = 1:numD
        subplot(5,4,z);
        nhist(temp.delay(temp.distribution == d),'smooth','pdf',...
            'noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap'); hold on;
        lim = get(gca,'XLim');
        plot(0:0.01:lim(2),pdf(params.D{d},0:0.01:lim(2)),'Color',params.colours{d}./255,'LineWidth',2);
        ylim([0 0.15]);
        z = z + 1;
    end
end
clearvars('-except',initialVars{:});

%% Plot response distribution against reward distribution
figure;
z = 1;
for p = participants
    temp = trialData(trialData.id == p,:);
    for d = 1:numD
        subplot(5,4,z);
        nhist(temp.rt(temp.distribution == d & temp.censor == 0),'smooth','pdf',...
            'noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap'); hold on;
        lim = get(gca,'XLim');
        plot(0:0.01:lim(2),pdf(params.D{d},0:0.01:lim(2)),'Color',params.colours{d}./255,'LineWidth',2);
        ylim([0 0.15]);
        z = z + 1;
    end
end
% All
figure;
z = 1;
for d = 1:numD
    subplot(2,1,z);
    nhist(trialData.rt(trialData.distribution == d & trialData.censor == 0),'smooth','pdf',...
        'noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap'); hold on;
    title(trialData.distName(trialData.distribution == d));
    lim = get(gca,'XLim');
    plot(0:0.01:lim(2),pdf(params.D{d},0:0.01:lim(2)),'Color',params.colours{d}./255,'LineWidth',2);
    ylim([0 0.15]);
    z = z + 1;
end
clearvars('-except',initialVars{:});

%% Check reward rate stability
figure;
for p = participants
    subplot(3,3,p);
    for d = 1:numD
        plot(trialData.allTrial(trialData.id == p & trialData.distribution == d),...
            trialData.rr(trialData.id == p & trialData.distribution == d),'Color',...
            params.colours{d}./255); hold on;
    end
end
clearvars('-except',initialVars{:});

%% Descriptive modelling (regression)
for d = 1:numD
    temp = trialData(trialData.distribution == d,:);
    for p = participants
        temp2 = temp(temp.id ==p,:);
        % Linear regression
        lm = fitlm([temp2.pr],temp2.rt,'linear');
        betaLin(:,p) = lm.Coefficients.Estimate;
        pLin(:,p) = lm.Coefficients.pValue;
        % Cox regression
        [b,logl,H,stats] = coxphfit([temp2.pr], temp2.rt, 'censoring', temp2.censor);
        betaCox(:,p) = stats.beta;
        pCox(:,p) = stats.p;
    end
end

for d = 1:numD
    temp = trialData(trialData.distribution == d,:);
    % Mixed model
    model = @(PHI,t) PHI(1) + PHI(2)*t(:,1) + PHI(3)*t(:,2) + PHI(4)*t(:,3);
    beta0 = [1 1 1 1];
    [beta,PSI,stats,B] = nlmefit([temp.id temp.totalReward temp.pr],temp.rt,categorical(temp.id),...
        [],model,beta0,'REParamsSelect',[1],'ErrorModel','Proportional');
    plotResiduals(stats);
end

% Stepwise

mdl = stepwiselm(temp,'constant',...
    'ResponseVar','response',...
    'PredictorVars',{'delay','reward','lagReward','totalvolume','lagDelay','lagResponse'},...
    'CategoricalVars',{'delay','reward','lagReward','lagDelay'})
plotResiduals(mdl,'fitted');
plotSlice(mdl);
plotEffects(mdl);
clearvars('-except',initialVars{:});

%% Plot practice vs main
figure;
effectCol = {magenta,teal};
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    practice = temp(temp.block <= 2,:);
    main = temp(temp.block >= 3,:);
    
    [f,x,flo,fup] = ecdf(practice.rt,'censoring', practice.censor,'function','survivor');
    h = stairs(x,f,'Color',effectCol{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(main.rt,'censoring', main.censor,'function','survivor');
    g = stairs(x,f,'Color',params.colours{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    legend([h,g],'Practice','Main task');
    
    AUC(d,2) = trapz(x,f);
    fprintf('%s\nPractice: %.2f seconds.\nMain: %.2f seconds.\n',...
        params.D{d}.DistributionName,AUC(d,1),AUC(d,2));
    
    xlabel('Elapsed time'); ylabel('Probability of quitting');
end
title('Practice vs main');
clearvars('-except',initialVars{:});

%% Plot baseline vs drink
figure;
effectCol = {magenta,teal};
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    baseline = temp(ismember(temp.block,[3,4,9,10]),:);
    drink = temp(ismember(temp.block,5:8),:);
    
    [f,x,flo,fup] = ecdf(baseline.rt,'censoring', baseline.censor,'function','survivor');
    h = stairs(x,f,'Color',params.colours{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(drink.rt,'censoring', drink.censor,'function','survivor');
    g = stairs(x,f,'Color',effectCol{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    legend([h,g],'Main task','Drink');
    
    AUC(d,2) = trapz(x,f);
    fprintf('%s\nMain: %.2f seconds.\nDrink: %.2f seconds.\n',...
        params.D{d}.DistributionName,AUC(d,1),AUC(d,2));
    
    xlabel('Elapsed time'); ylabel('Probability of quitting');
end
title('Main vs Drink');
clearvars('-except',initialVars{:});

%% Baselines separated
figure;
effectCol = {magenta,teal};
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    baseline1 = temp(ismember(temp.block,[3,4]),:);
    baseline2 = temp(ismember(temp.block,[9,10]),:);
    drink = temp(ismember(temp.block,5:8),:);
    
    [f,x,flo,fup] = ecdf(baseline1.rt,'censoring', baseline1.censor,'function','survivor');
    g = stairs(x,f,'Color',effectCol{1}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(drink.rt,'censoring', drink.censor,'function','survivor');
    h = stairs(x,f,'Color',params.colours{d}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,2) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(baseline2.rt,'censoring', baseline2.censor,'function','survivor');
    j = stairs(x,f,'Color',effectCol{2}./255); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,3) = trapz(x,f);
    
    legend([g,h,j],'Baseline','Drink','Baseline');
    
    fprintf('%s\nBaseline 1: %.2f seconds.\nDrink: %.2f seconds.\nBaseline 2: %.2f seconds.\n',...
        params.D{d}.DistributionName,AUC(d,1),AUC(d,2),AUC(d,3));
    
    xlabel('Elapsed time'); ylabel('Probability of quitting');
end
title('Baselines vs Drink');

% Plot AUCs
figure;
bar(AUC,'FaceColor', teal./255, 'EdgeColor', 'none');
clearvars AUC

clearvars('-except',initialVars{:});

%% Plot by block
figure;
effectCol = barColour;

for d = 1:numD
    c = 1;
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    if d == 1
        fprintf('%s\n',params.D{d}.DistributionName);
        for b = 1:2:10
            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
            g = stairs(x,f,'Color',effectCol{c}); hold on;
            xlabel('Elapsed time'); ylabel('Probability of quitting');
            AUC(1,c) = trapz(x,f);
            fprintf('%.2f seconds.\n',AUC(1,c));
            l{c} = sprintf('Block %.0f',b);
            c = c + 1;
        end
        title('Across blocks');
        legend(l);
    elseif d == 2
        fprintf('%s\n',params.D{d}.DistributionName);
        for b = 2:2:10
            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
            g = stairs(x,f,'Color',effectCol{c}); hold on;
            xlabel('Elapsed time'); ylabel('Probability of quitting');
            AUC(2,c) = trapz(x,f);
            fprintf('%.2f seconds.\n',AUC(2,c));
            l{c} = sprintf('Block %.0f',b);
            c = c + 1;
        end
        legend(l);
    end
end
clearvars('-except',initialVars{:});

%% Calculate all AUCs for each participant
set(0,'DefaultFigureVisible','off');  % all subsequent figures "off"
z = 1;
for p = participants
    % Plot survivor functions
    for d = 1:numD
        temp = trialData(trialData.id == p &...
            trialData.distribution == d,:);
        c = 1;
        if d == 1
            for b = 1:2:10
                if temp.censor(ismember(temp.block,b)) == 1
                uniformMat(z,c) = NaN;
                c = c + 1;
                else
                [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                    'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
                uniformMat(z,c) = trapz(x,f);
                c = c + 1;
                end
            end
        elseif d == 2
            for b = 2:2:10
                if temp.censor(ismember(temp.block,b)) == 1
                paretoMat(z,c) = NaN;
                c = c + 1;
                else
                [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                    'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
                paretoMat(z,c) = trapz(x,f);
                c = c + 1;
                end
            end
        end         
    end
    z = z + 1;
end
uniform = array2table([participants',uniformMat],'VariableNames',{'id','block1','block2','block3','block4','block5'});
pareto = array2table([participants',paretoMat],'VariableNames',{'id','block1','block2','block3','block4','block5'});
set(0,'DefaultFigureVisible','on');  % all subsequent figures "on"
clearvars -except participants numD trialData optimTim rStar thirst uniform pareto
initialVars = who;
initialVars{end+1} = 'initialVars';
clearvars('-except',initialVars{:});

%% Plot AUCs
UM = nanmean(table2array(uniform));
USTD = nanstd(table2array(uniform));

figure;
hBar = bar(UM(2:end),'FaceColor',[0.5, 0.5, 0.5],'EdgeColor','none'); hold on
errorbar(1:5,UM(2:end),USTD(2:end),'LineStyle','none');
set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
title('Uniform');

PM = nanmean(table2array(pareto));
PSTD = nanstd(table2array(pareto));

figure;
hBar = bar(PM(2:end),'FaceColor',[0.5, 0.5, 0.5],'EdgeColor','none'); hold on
errorbar(1:5,PM(2:end),PSTD(2:end),'LineStyle','none');
set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
title('Pareto');

% pareto.drink = mean([pareto.block3, pareto.block4],2);
% uniform.drink = mean([uniform.block3, uniform.block4],2);

