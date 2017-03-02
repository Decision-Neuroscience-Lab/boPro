%% Get data, setup and clean
for tidiness = 1
    cd('/Users/Bowen/Documents/MATLAB/PIPM');
    load('trialDataJuice.mat');
    participants = 1:25;
    [trialData, thirst] = getData(participants);
    
    % Plot settings
    set(0,'DefaultAxesColorOrder',...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
    colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
    set(0,'DefaultFigureColor',[1 1 1]);
    %set(0,'DefaultAxesFontSize',20);
    delays = unique(trialData.delay);
    barColour = {[.3 .3 .3],[.8 .8 .8]};
    errorColour = [0 0 0];
    
    % Clean data
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
        clearvars -except trialData amounts delays participants TH x exclude M SD ploton errorColour barColour trialDataJuice thirst
    end
    fprintf('Total of %.0f trials excluded. %.0f were missed\n',sum(trialData.flag), sum(isnan(trialData.response)));
    warning('on',char('MATLAB:legend:IgnoringExtraEntries'))
    clearvars -except trialData amounts delays errorColour barColour participants trialDataJuice thirst
    
    % Merge data
    T = table(ones(height(trialData),1),'VariableNames',{'type'});
    T.type = T.type + 1;
    T2 = table(ones(height(trialDataJuice),1),'VariableNames',{'type'});
    trialData = [T,trialData;T2,trialDataJuice];
    
    % Create new variables
    for tidiness = 1
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
        
        for t = 1:2
            participants = unique(trialData.id(trialData.type == t))';
            for x = participants
                for d = 1:numel(delays)
                    trialData.normAccuracy(trialData.id == x & trialData.type == t & trialData.delay == delays(d) & ~isnan(trialData.response))...
                        = zscore(trialData.accuracy(trialData.id == x & trialData.type == t & trialData.delay == delays(d) & ~isnan(trialData.response)));
                end
                temp = trialData(trialData.id == x & trialData.type == t,:);
                trialData.normResponse(trialData.id == x & trialData.type == t & ~isnan(trialData.response))...
                    = zscore(trialData.response(trialData.id == x & trialData.type == t & ~isnan(trialData.response)));
                % Condition variables
                trialData.lagResponse(trialData.id == x & trialData.type == t) = lagmatrix(temp.response,1);
                trialData.lagNormAccuracy(trialData.id == x & trialData.type == t) = lagmatrix(temp.normAccuracy,1);
                trialData.lagReward(trialData.id == x & trialData.type == t) = lagmatrix(temp.reward,1);
                trialData.lagReward2(trialData.id == x & trialData.type == t) = lagmatrix(temp.reward,2);
                trialData.lagReward3(trialData.id == x & trialData.type == t) = lagmatrix(temp.reward,3);    
                trialData.lagDelay(trialData.id == x & trialData.type == t) = lagmatrix(temp.delay,1);
                trialData.windowReward(trialData.id == x & trialData.type == t) = tsmovavg(trialData.reward(trialData.id == x & trialData.type == t),'s',3,1);
            end
        end
        % Theoretically relevant condition variables
        trialData.rewardRate = trialData.reward ./ (trialData.delay);
        trialData.lagRewardRate = trialData.lagReward ./ (trialData.lagDelay);
        
    end
    clearvars -except trialData amounts delays errorColour barColour thirst
    initialVars = who;
    initialVars{end+1} = 'initialVars';
    clearvars('-except',initialVars{:});
end

%% Output text file for R (must do without changing reward variable coding)
writetable(trialData(trialData.type == 1 & trialData.session==2 & trialData.flag == 0,:),'/Users/Bowen/Documents/R scripts/trialDataJuice(clean)');
writetable(trialData(trialData.type == 2 & trialData.session==2 & trialData.flag == 0,:),'/Users/Bowen/Documents/R scripts/trialDataMoney(clean)');

%% Check accuracies
t = 2; % Analyse either juice (1) or money (2) or water (3)
for tidiness = 1
C = unique((trialData.id(trialData.type == t)))';
for x = C
    temp = trialData(trialData.type == t & trialData.id == x,:); % Select participant WITH outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    figure;
    plot(temp.accuracy);
    hold on
    plot(1:size(temp.accuracy,1), zeros(1,size(temp.accuracy,1)), 'LineStyle','--');
    xlim([0 size(temp.accuracy,1)]);
    ylim([-5 5]);
    ylabel('Devation (secs)');
    xlabel('Trial number');
    title(sprintf('Participant %.0f',x));
    
    allTrials = 1:size(temp.session);
    
    for s = [1, 2, 3]
        temp2 = temp(temp.session == s,:);
        subTrials = allTrials(temp.session == s);
        accuracy = temp2.response - (temp2.delay./2);
        plot(subTrials,accuracy);
    end
end
clearvars('-except',initialVars{:});
end

%% Individual regression stats (must do without changing reward variable coding)
t = 2; % Analyse either juice (1) or money (2) or water (3)
for tidiness = 1
vars = {'reward','delay','lagReward','lagDelay','totalvolume','lagResponse'};
plotVar = 2;
C = unique((trialData.id(trialData.type == t)))';
for x = C
    temp = trialData(trialData.id == x & trialData.type == t & trialData.flag == 0 & trialData.session == 2,:);
    for v = 1:numel(vars)
    predMatrix(:,v) = table2array(temp(:,vars{v}));
    end
    [beta{x},~,stats{x}] = glmfit(predMatrix,temp.response);
    clearvars predMatrix
end
c = 1;
for x = C
    coeffs(c,:) = beta{x};
    probs(c,:) = stats{x}.p;
    se(c,:) = stats{x}.se;
    c = c + 1;
end
% Plot coefficients
for plotVar = 2:numel(vars)+1
figure;
[dBar] = bar(coeffs(:,plotVar));
set(dBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
hold on
[hBar] = errorbar(coeffs(:,plotVar),se(:,plotVar));
set(hBar,'LineStyle','none');
for t = 1:numel(probs(:,plotVar))
    if probs(t,plotVar) < 0.1
        text(t - 0.1,0,'*','fontSize',25);
    end
end
xlim([0 26]);
title(sprintf('%s beta coefficients',vars{plotVar-1}));
xlabel('Participant');
[h,p] = ttest(coeffs(:,plotVar)); % Print ttest results
fprintf('%s\nh: %.0f\np: %.3f\n',vars{plotVar-1},h,p);
end
% Plot residuals
% figure;
% c = 1;
% for x = participants
%     subplot(5,5,c);
%     plot(stats{x}.resid);
%     xlim([0 160]);
%     title(sprintf('Participant %.0f',x));
%     c = c + 1;
% end
clearvars('-except',initialVars{:});
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

%% Histograms
for tidiness = 1
    delayStrings = {'4 seconds','6 seconds','8 seconds','10 seconds'};
    temp = trialData(trialData.flag == 0,:);
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
    clearvars('-except',initialVars{:});
end

%% CV
t = 1;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.type == t,:);
    inputVar = {'response'};
    groupVar = {'delay','id','type'};
    STD = varfun(@nanstd, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    for d = 1:numel(delays)
        CV(:,d) = STD.nanstd_response(STD.delay == delays(d)) ./ M.nanmean_response(M.delay == delays(d));
    end
    [p,table,stats] = anova1(CV,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    
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
    ylim([0.16 0.28]);
    ylabel('Coefficient of variation');
    hold on
    h = errorbar(M,SD);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', errorColour);
    clearvars('-except',initialVars{:});
end

%% Central tendency
t = 1;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.type == t,:);
    inputVar = {'accuracy'};
    groupVar = {'delay','type','id'};
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for d = 1:numel(delays)
        A(:,d) = M.nanmean_accuracy(M.delay == delays(d));
        ME(d) = nanmean(M.nanmean_accuracy(M.delay == delays(d)));
        SEM(d) = nanstd(A(:,d)) ./ sqrt(numel(A(:,d)));
        [h,p,~,~] = ttest(A(:,d));
        if h == 1
            fprintf('Accuracies at the %.0f second delay are significantly different from 0, p = %.5f.\n',delays(d),p);
        else
            fprintf('Accuracies at the %.0f second delay are not significantly different from 0, p = %.5f\n',delays(d),p);
        end
    end
    
    figure;
    hBar = bar(ME);
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
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
end

%% Baseline vs main task
for tidiness = 1
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'normAccuracy'};
    groupVar = {'session','id','type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:2
        for s = 1:3
            ME(:,s) = M.nanmean_normAccuracy(M.session == s & M.type == t);
            SD(t,s) = nanstd(ME(:,s)) ./ sqrt(numel(ME(:,s)));
            MEANS(t,s) = nanmean(ME(:,s));
        end
        if t == 1
            [h,p,~,stats] = ttest2(ME(:,1),ME(:,2));
            fprintf('First baseline vs main task (juice), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,2),ME(:,3));
            fprintf('Second baseline vs main task (juice), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        elseif t == 2
            [h,p,~,stats] = ttest2(ME(:,1),ME(:,2));
            fprintf('First baseline vs main task (money), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,2),ME(:,3));
            fprintf('Second baseline vs main task (money), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        end
        
        clearvars ME
    end
    
    figure;
    hBar = bar(MEANS');
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',...
        {'First baseline','Main Task','Second baseline'});
    ylabel('Deviation (secs)');
    hold on
    legend({'Juice','Money'});
    for e = 1:size(SD,2)
        h = errorbar(e - 0.14, MEANS(1,e), SD(1,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e + 0.14, MEANS(2,e), SD(2,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    
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
end

%% Visualize regression results (by delay)
IV = 'lagReward';
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2,:);
    inputVar = {'normAccuracy'};
    groupVar = {'delay','id','type',IV};
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:2
        for d = 1:numel(delays)
            for r = 1:numel(amounts)
                ME(t,d,r) = nanmean(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r))));
                SD(t,d,r) = nanstd(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r))))...
                    ./ sqrt(numel(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r)))));
            end
        end
    end
    for d = 1:numel(delays)
        subplot(2,2,d);
        means = [ME(1,d,1), ME(1,d,2), ME(1,d,3), ME(1,d,4); ME(2,d,1), ME(2,d,2), ME(2,d,3), ME(2,d,4)];
        sems = [SD(1,d,1), SD(1,d,2), SD(1,d,3), SD(1,d,4); SD(2,d,1), SD(2,d,2), SD(2,d,3), SD(2,d,4)];
        hBar = bar(means');
        set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
        set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
        hold on;
        for e = 1:size(sems,2)
            h = errorbar(e - 0.14, means(1,e), sems(1,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e + 0.14, means(2,e), sems(2,e));
            set(h,'linestyle','none','Color', errorColour);
        end
        set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
        ylabel('Normalised deviation');
        title(sprintf('%.0f seconds',delays(d)));
        ylim([-.2 .4]);
        if d == 1
            legend({'Juice','Money'});
        end
    end
    clearvars('-except',initialVars{:});
end

%% Visualize regression results (collapsed)
IV = 'lagReward';
factor = amounts;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2,:);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:2
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
        if t == 1
            fprintf('Juice: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
        elseif t == 2
            fprintf('Money: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
        end
            [h,p,~,stats] = ttest2(ME(:,1),ME(:,2));
            fprintf('None vs small, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,1),ME(:,3));
            fprintf('None vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,1),ME(:,4));
            fprintf('None vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,2),ME(:,3));
            fprintf('Small vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,2),ME(:,4));
            fprintf('Small vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest2(ME(:,3),ME(:,4));
            fprintf('Medium vs Large, t(%.0f) = %.3f, p = %.3f.\n\n',stats.df,stats.tstat,p);
        clearvars ME
    end
    
    figure;
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e - 0.14, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e + 0.14, means(2,e), sems(2,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});  
    end
    ylabel('Normalised deviation');
    %ylim([-.05 .25]);
    legend({'Juice','Money'});
    clearvars('-except',initialVars{:});
end

%% Moving average
for tidiness = 1
    % Individual participants
    window = 20;
    for T = 1:2
        figure;
        C = unique((trialData.id(trialData.type == T)))';
        c = 1;
        for x = C
            temp = trialData(trialData.id == x & trialData.type == T & trialData.flag == 0,:);
            temp = sortrows(temp,3);
            
            averageT = tsmovavg(temp.normAccuracy,'s',window,1); % 's' is static, 'e' is exponential decay
            
            subplot(5,5,c);
            ax = plot(1:size(averageT,1),averageT);
            xlim([1,size(averageT,1)]);
            ylabel('Moving average of accuracy');
            title(sprintf('Participant %.0f',x));
            c = c + 1;
        end
    end
    % All participants
    window = 20;
    for T = 1:2
        temp = trialData(trialData.type == T & trialData.flag == 0,:);
        c = 1;
        for t = min(temp.trial):max(temp.trial)
            i = temp.trial == t;
            M(T,c) = nanmean(temp.normAccuracy(i));
            c = c + 1;
        end
    end
    averageJuice = tsmovavg(M(1,:),'s',window,2); % 's' is static, 'e' is exponential decay
    averageMoney = tsmovavg(M(2,:),'s',window,2); % 's' is static, 'e' is exponential decay
    
    figure;
    p1 = plot(1:size(averageJuice,2),averageJuice);
    hold on
    p2 = plot(1:size(averageMoney,2),averageMoney);
    lims = [-.4, .3];
    startMain = 40+(window./2);
    endMain = 200+(window./2);
    ylim(lims);
    t1 = plot([startMain,startMain],lims,'k:'); t2 = plot([endMain,endMain],lims,'k:');
    text(startMain+5, lims(1), 'Start main task','FontSize',15,'Rotation',90);
    text(endMain+5, lims(1), 'End main task','FontSize',15,'Rotation',90);
    ylabel('Moving average of normalised deviation');
    legend({'Juice','Money'});
    clearvars('-except',initialVars{:});
end
