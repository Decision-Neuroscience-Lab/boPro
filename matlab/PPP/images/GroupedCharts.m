% Plot settings
set(0,'DefaultAxesColorOrder',...
    [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
set(0,'DefaultTextFontName','Helvetica');
set(0,'DefaultAxesFontName','Helvetica')
colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultAxesFontSize',20);
delays = unique(trialData.delay);
barColour = {[0.15 0.15 0.15],[.3 .3 .3],[.45 .45 .45],[.6 .6 .6],[0.75 0.75 0.75],[0.9 0.9 0.9]};
%barColour = {[0.6824 0.1961 0.3255],[0.8431 0.3412 0.2980],[0.9686 0.7294 0.4157],...
 %   [0.9490 0.8039 0.5686],[0.7647 0.6941 0.5961],[0.3255 0.5255 0.5647]};
errorColour = [0.4 0.4 0.4];

figure;

%% Anti reward
t = 1;
IV = 'reward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(t,a) = nanmean(ME(:,a));
        sems(t,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    subplot(3,1,2);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    h = errorbar(means,sems);
    set(h,'linestyle','none','Color', errorColour);
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'None','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
ylabel('Time estimate difference (SD)','FontSize',17);
    ylim([-.05 .25]);
end
% lag reward

t = 1;
IV = 'lagReward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(t,a) = nanmean(ME(:,a));
        sems(t,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    
    subplot(3,1,3);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    h = errorbar(means, sems);
    set(h,'linestyle','none','Color', errorColour);
    
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'None','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
ylabel('Time estimate difference (SD)','FontSize',17);
    ylim([-.05 .25]);
end

% BAseline
t = 1;
temp = trialData(trialData.flag == 0,:);
inputVar = {'normAccuracy'};
groupVar = {'session','id','type'};
M = varfun(@nanmean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);


for s = 1:3
    ME(:,s) = M.nanmean_normAccuracy(M.session == s & M.type == t);
end

% Collapse across baselines
ME(:,1) = mean([ME(:,1),ME(:,3)],2);
ME(:,3) = [];
for s = 1:2
SD(t,s) = nanstd(ME(:,s)) ./ sqrt(numel(ME(:,s)));
MEANS(t,s) = nanmean(ME(:,s));
end

clearvars ME

subplot(3,1,1);
hBar = bar(MEANS');
set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
set(gca,'XTick',1:2);
set(gca,'XTickLabel',...
    {'Baseline','Main task'});

ylabel('Time estimate difference (SD)','FontSize',17);
hold on
h = errorbar(MEANS, SD);
set(h,'linestyle','none','Color', errorColour);
ylim([-0.35, 0.3]);

%% temporal context

t = 1;
IV = 'lagDelay';
factor = delays;
for tidiness = 1
    temp = trialData(trialData.flag == 0, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(t,a) = nanmean(ME(:,a));
        sems(t,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    
    subplot(2,2,1);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'None','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
ylabel('Time estimate difference (SD)');
    ylim([-.15 .25]);
end


%% Control experiments
clearvars('-except',initialVars{:});

figure;
% Anti reward
t = 2;
IV = 'reward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(1,a) = nanmean(ME(:,a));
        sems(1,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    subplot(2,2,1);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
    ylabel('Normalised difference');
    ylim([-.05 .25]);
end
% lag reward

t = 2;
IV = 'lagReward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(1,a) = nanmean(ME(:,a));
        sems(1,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    
    subplot(2,2,2);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
    ylabel('Normalised difference');
    ylim([-.05 .25]);
end
% Anti reward
t = 3;
IV = 'reward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(1,a) = nanmean(ME(:,a));
        sems(1,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    subplot(2,2,3);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
    ylabel('Normalised difference');
    ylim([-.05 .25]);
end
% lag reward

t = 3;
IV = 'lagReward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(factor)
        if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
        elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
        end
        means(1,a) = nanmean(ME(:,a));
        sems(1,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    clearvars ME
    
    
    subplot(2,2,4);
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
    ylabel('Normalised difference');
    ylim([-.05 .25]);
end
