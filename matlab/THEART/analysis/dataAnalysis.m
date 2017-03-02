%% QT Data analyses
% Bowen J Fung, 2015

participants = 1:50;
% Note that participant 19 has missed practice blocks. It may be advisable
% to eliminate these from all analyses.

% Participant 6, 32, 34 did not quit at any point - clearly misunderstood the
% task. Participant 28 quit very few times - may not be enough data.

%% Get data, clean and add variables
% NEED TO ADD MORE CHECKS AGAINST WEIRD BEHAVIOUR (e.g. rt too long after
% maturation)
for tidiness = 1
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
    
    % Check for abberant behaviours
    
    % Add new variables
    trialData.rr = trialData.totalReward ./ trialData.blockTime; % Empirical reward rate
    trialData.pr = nan(height(trialData),1); % Perceived reward rate
    trialData.meanDelay = nan(height(trialData),1); % Mean delay so far
    trialData.geoMeanDelay = nan(height(trialData),1); % Geometric (root of products) mean delay so far
    trialData.lagDelay = nan(height(trialData),1); % Previous delay
    trialData.drink = zeros(height(trialData),1); % Drink flag
    trialData.drink(ismember(trialData.block,[5,6,7,8])) = 1;
    trialData.drinkDecay = nan(height(trialData),1); % Hypothetical drink effect model (decays over time)
    %     drinkModel = @(t) t.^-0.2; % Exponential decay
    drinkModel = @(t) 1 - (t*0.003); % Linear decay
    
    for p = participants
        blocks = unique(trialData.block(trialData.id == p));
        for b = blocks(1):blocks(end)
            i = trialData.id == p & trialData.block == b;
            trialData.pr(i) = tsmovavg(trialData.reward(i)./(trialData.rt(i) + params.iti), 'e', 5, 1); % Perceived reward rate (moving average); tsmovavg takes arg(ts, exponential, lag, dim)
            trialData.lagDelay(i) = lagmatrix(trialData.rt(i),1);
            if ismember(b,[5,6,7,8])
                trialData.drinkDecay(i) = drinkModel(trialData.blockTime(i));
            end
            expDelay = trialData.rt(i); % Create a vector of rts for this block
            for t = 1:sum(i) % Loop through trials to get means
                meanDelay(t) = mean(expDelay(1:t));
                gmeanDelay(t) = geomean(expDelay(1:t));
            end
            trialData.meanDelay(i) = meanDelay;
            trialData.geoMeanDelay(i) = gmeanDelay;
            clearvars meanDelay gmeanDelay
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
    [optimTime, rStar, expectedReturn, expectedCost, rT, T] = getOptimal(params); close all;
    for d = 1:numD
        fprintf('Maximum possible return for %s distribution: $%.2f.\n',params.D{d}.DistributionName,rStar(d)*params.blockTime);
    end
    
    %% Add other variables and cement
    blue = [0 113 189];
    orange = [217 83 25];
    teal = [113,203,153];
    magenta = [203 81 171];
    redR = [246, 129, 121];
    blueR = [41, 194, 298];
    C = {blue,orange,magenta,teal};
    D = params.D;
    
    clearvars -except participants numD trialData optimTime rStar thirst C D
    initialVars = who;
    initialVars{end+1} = 'initialVars';
    clearvars('-except',initialVars{:});
end

%% Export for R
% writetable(trialData,'/Users/Bowen/Documents/R/QT/trialData.csv');
 
%% Check censored data for each participant, and remove those with too many censored trials
for d = 1:numD
    for p = 1:50
        propCensored(p,d) = sum(trialData.censor(trialData.id == p & trialData.distribution == d))...
            ./ size(trialData.censor(trialData.id == p & trialData.distribution == d),1);
    end
end
% i = find(propCensored(:,2) > 0.75);
% trialData(ismember(trialData.id, i),:) = [];

%% Get basic data
temp = trialData(trialData.block > 4 & trialData.block < 9 & trialData.censor == 0,:);
    inputVar = {'rt'};
    groupVar = {'id','distribution'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);

%% Calculate all AUCs for each participant
for tidiness = 1
    set(0,'DefaultFigureVisible','off');  % all subsequent figures "off"
    z = 1;
    for p = participants
        for d = 1:numD
            temp = trialData(trialData.id == p &...
                trialData.distribution == d,:);
            c = 1;
            if d == 1
                for b = 1:2:10
                    try
                        if temp.censor(ismember(temp.block,b)) == 1
                            uniformMat(z,c) = NaN;
                            c = c + 1;
                        else
                            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
                            uniformMat(z,c) = trapz(x,f);
                            c = c + 1;
                        end
                    catch
                        uniformMat(z,c) = NaN; % If missing block
                        fprintf('Block %.0f missing for participant %.0f.\n',b,p);
                        c = c + 1;
                        continue;
                    end
                end
            elseif d == 2
                for b = 2:2:10
                    try
                        if temp.censor(ismember(temp.block,b)) == 1
                            paretoMat(z,c) = NaN;
                            c = c + 1;
                        else
                            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
                            paretoMat(z,c) = trapz(x,f);
                            c = c + 1;
                        end
                    catch
                        paretoMat(z,c) = NaN; % If missing block
                        fprintf('Block %.0f missing for participant %.0f.\n',b,p);
                        c = c + 1;
                        continue;
                    end
                end
            end
        end
        z = z + 1;
    end
    uniform = array2table([participants',uniformMat],'VariableNames',{'id','block1','block2','block3','block4','block5'});
    pareto = array2table([participants',paretoMat],'VariableNames',{'id','block1','block2','block3','block4','block5'});
    initialVars{end+1} = 'uniform';
    initialVars{end+1} = 'pareto';
    
    set(0,'DefaultFigureVisible','on');  % all subsequent figures "on"
    clearvars('-except',initialVars{:});
    
    %% Plot AUCs
    UM = nanmean(table2array(uniform));
    USTD = nanstd(table2array(uniform));
    
    figure;
    hBar = bar(UM(2:end),'FaceColor',[0.5, 0.5, 0.5],'EdgeColor','none'); hold on
    errorbar(1:5,UM(2:end),USTD(2:end),'LineStyle','none','Color',[0 0 0]);
    set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
    title('Uniform');
    
    PM = nanmean(table2array(pareto));
    PSTD = nanstd(table2array(pareto));
    
    figure;
    hBar = bar(PM(2:end),'FaceColor',[0.5, 0.5, 0.5],'EdgeColor','none'); hold on
    errorbar(1:5,PM(2:end),PSTD(2:end),'LineStyle','none','Color',[0 0 0]);
    set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
    title('Pareto');
    
    % pareto.drink = mean([pareto.block3, pareto.block4],2);
    % uniform.drink = mean([uniform.block3, uniform.block4],2);
end

%% Plot survivor functions for each distribution
figure;
for d = 1:numD
    temp = trialData(trialData.distribution == d & ismember(trialData.block, [5,6,7,8]),:);
    
    [f,x,flo,fup] = ecdf(temp.rt,'censoring', temp.censor,'function','survivor');
    h = stairs(x,f,'Color',C{d}./255,'LineWidth',2); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    
    xlabel('Elapsed time'); ylabel('Probability of waiting');
end
xlim([0,15]);

clearvars('-except',initialVars{:});

%% Plot all participant data
for tidiness = 1
    scores = table;
    numD = numel(D);
    figure;
    z = 1;
    for p = participants
        subplot(5,10,p);
        % Plot survivor functions
        AUC = NaN(numD,1);
        for d = 1:numD
            temp = trialData(trialData.id == p &...
                trialData.distribution == d &...
                trialData.block > 2,:);
            [f,x,flo,fup] = ecdf(temp.rt,'censoring', temp.censor,'function','survivor');
            %[f,x,flo,fup] = ecdf(temp.rt,'function','survivor');
            h(d) = stairs(x,f); set(h(d),'Color',C{d}./255); hold on;
            stairs(x,flo,'k:','Color',C{d}./255); stairs(x,fup,'k:','Color',C{d}./255); % Plot confidence bounds
            AUC(d) = trapz(x,f);
            l{d} = sprintf('AUC: %.3f',AUC(d));
            % line([optimTime(d) optimTime(d)],get(gca,'YLim'),'Color',params.colours{d}./255,'LineStyle',:); % Indicate maximum
        end
        xlim([0,40]);
        % h_legend = legend(h(1:numD),l);
        % set(h_legend,'FontSize',10);
        % xlabel('Elapsed time (deciseconds)'); ylabel('Probability of waiting');
        
        % Calculate empirical vs optimal
        %         for d = 1:numD
        %             fprintf('%s deviation from optimality: %.2f seconds.\n',...
        %                 D{d}.DistributionName,AUC(d) - optimTime(d));
        %         end
        %scores(z,:) = {p,AUC(1)-optimTime(1),AUC(2)-optimTime(2)};
        z = z + 1;
    end
    % scores.Properties.VariableNames = {'id','uniformAUC','paretoAUC'};
    clearvars('-except',initialVars{:});
end

%% Plot response distribution (uncensored) against reward distribution
for tidiness = 1
    for d = 1:numD
        figure;
        z = 1;
        for p = participants
            temp = trialData(trialData.id == p & trialData.block > 2,:);
            subplot(5,10,z);
            nhist(temp.rt(temp.distribution == d & temp.censor == 0),'smooth','pdf',...
                'noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap'); hold on;
            lim = get(gca,'XLim');
            plot(0:0.01:lim(2),pdf(D{d},0:0.01:lim(2)),'Color',C{d}./255,'LineWidth',2);
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
        title(D{d}.DistributionName);
        lim = get(gca,'XLim');
        plot(0:0.01:lim(2),pdf(D{d},0:0.01:lim(2)),'Color',C{d}./255,'LineWidth',2);
        z = z + 1;
    end
    clearvars('-except',initialVars{:});
end


%% Get individual winnings
% NEED TO CHANGE TO EACH DISTRIBUTION
for p = participants
    win(p) = checkTotal(p);
end
%% Check reward rate stability
% INSPECT SPIKES - NEED ALTERED REWARD RATE MEASURE
figure;
for p = participants
    subplot(2,3,p);
    for d = 1:numD
        plot(trialData.allTrial(trialData.id == p & trialData.distribution == d),...
            trialData.rr(trialData.id == p & trialData.distribution == d),'Color',...
            C{d}./255); hold on;
    end
end
clearvars('-except',initialVars{:});

%% Descriptive modelling (regression)
for tidiness = 1
    vars = {'drink'};
    for d = 1:numD
        temp = trialData(trialData.distribution == d & trialData.block > 2,:);
        for p = participants
            temp2 = temp(temp.id ==p,:);
            % Linear regression
            lm = fitlm(temp2{:,vars},temp2.rt,'linear');
            betaLin(:,p) = lm.Coefficients.Estimate;
            pLin(:,p) = lm.Coefficients.pValue;
            seLin(:,p) = lm.Coefficients.SE;
            % Cox regression
            [b,logl,H,stats] = coxphfit(temp2{:,vars}, temp2.rt, 'censoring', temp2.censor);
            betaCox(:,p) = stats.beta;
            pCox(:,p) = stats.p;
            seCox(:,p) = stats.se;
        end
    end
    
    % Plot linear effects
    for plotVar = 2:size(betaLin,1)
        figure;
        [dBar] = bar(betaLin(plotVar,:));
        set(dBar,'FaceColor',C{3}./255,'EdgeColor',[1 1 1]);
        hold on
        [hBar] = errorbar(betaLin(plotVar,:),seLin(plotVar,:),'Color',[0 0 0]);
        set(hBar,'LineStyle','none');
        for i = 1:size(pLin,2)
            if pLin(plotVar,i) < 0.1
                text(i - 0.3,min(betaLin(plotVar,i)) - 0.5,'*','fontSize',25);
            end
        end
        title(sprintf('%s effect (linear)',vars{plotVar-1}));
        xlabel('Participant');
        [~,p] = ttest(betaLin(plotVar,:)); % Print ttest results
        fprintf('%s effect\np: %.3f\n',vars{plotVar-1},p);
    end
    
    % Plot cox effects
    for plotVar = 1:size(betaCox,1)
        figure;
        [dBar] = bar(betaCox(plotVar,:));
        set(dBar,'FaceColor',C{4}./255,'EdgeColor',[1 1 1]);
        hold on
        [hBar] = errorbar(betaCox(plotVar,:),seCox(plotVar,:),'Color',[0 0 0]);
        set(hBar,'LineStyle','none');
        for i = 1:size(pCox,2)
            if pCox(plotVar,i) < 0.1
                text(i - 0.3,max(betaCox(plotVar,i)) + 0.3,'*','fontSize',25);
            end
        end
        title(sprintf('%s effect (Cox)',vars{plotVar}));
        xlabel('Participant');
        [~,p] = ttest(betaCox(plotVar,:)); % Print ttest results
        fprintf('%s effect\np: %.3f\n',vars{plotVar},p);
    end
    
    %stairs(H(:,1),exp(-H(:,2)),'LineWidth',2, 'LineStyle',lStyle{d}, 'Color',lCol{a});
    
    
    % Stepwise
    figure;
    temp = trialData(trialData.censor == 0 & trialData.block > 2,:);
    mdl = stepwiselm(temp,'constant',...
        'ResponseVar','rt',...
        'PredictorVars',{'pr','lagDelay','drink','drinkDecay'});
    plotResiduals(mdl,'fitted');
    plotSlice(mdl);
    plotEffects(mdl);
end
clearvars('-except',initialVars{:});

%% Plot practice vs main
figure;
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    practice = temp(temp.block <= 2,:);
    main = temp(temp.block >= 3,:);
    
    [f,x,flo,fup] = ecdf(practice.rt,'censoring', practice.censor,'function','survivor');
    h = stairs(x,f,'Color',C{2+d}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(main.rt,'censoring', main.censor,'function','survivor');
    g = stairs(x,f,'Color',C{d}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    legend([h,g],'Practice','Main task');
    
    AUC(d,2) = trapz(x,f);
    fprintf('%s\nPractice: %.2f seconds.\nMain: %.2f seconds.\n',...
        D{d}.DistributionName,AUC(d,1),AUC(d,2));
    
    xlabel('Elapsed time'); ylabel('Probability of waiting');
end
%suptitle('Practice vs main');
set(gcf,'NextPlot','add');
axes;
h = title('Practice vs main','FontSize',20);
set(gca,'Visible','off');
set(h,'Visible','on');

clearvars('-except',initialVars{:});

%% Plot baseline vs drink
figure;
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    type1 = temp(ismember(temp.block,[3,4,9,10]),:);
    type2 = temp(ismember(temp.block,5:8),:);
    
    [f,x,flo,fup] = ecdf(type1.rt,'censoring', type1.censor,'function','survivor');
    h = stairs(x,f,'Color',C{d}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(type2.rt,'censoring', type2.censor,'function','survivor');
    g = stairs(x,f,'Color',C{d+2}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    legend([h,g],'Main task','Drink');
    
    AUC(d,2) = trapz(x,f);
    fprintf('%s\nMain: %.2f seconds.\nDrink: %.2f seconds.\n',...
        D{d}.DistributionName,AUC(d,1),AUC(d,2));
    
    xlabel('Elapsed time'); ylabel('Probability of waiting');
end
%suptitle('Main vs Drink');
set(gcf,'NextPlot','add');
axes;
h = title('Main vs Drink','FontSize',20);
set(gca,'Visible','off');
set(h,'Visible','on');

clearvars('-except',initialVars{:});

%% Baselines separated
figure;
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    baseline1 = temp(ismember(temp.block,[3,4]),:);
    baseline2 = temp(ismember(temp.block,[9,10]),:);
    type2 = temp(ismember(temp.block,5:8),:);
    
    [f,x,flo,fup] = ecdf(baseline1.rt,'censoring', baseline1.censor,'function','survivor');
    g = stairs(x,f,'Color',C{3}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(type2.rt,'censoring', type2.censor,'function','survivor');
    h = stairs(x,f,'Color',C{d}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,2) = trapz(x,f);
    
    [f,x,flo,fup] = ecdf(baseline2.rt,'censoring', baseline2.censor,'function','survivor');
    j = stairs(x,f,'Color',C{4}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,3) = trapz(x,f);
    
    legend([g,h,j],'Baseline','Drink','Baseline');
    
    fprintf('%s\nBaseline 1: %.2f seconds.\nDrink: %.2f seconds.\nBaseline 2: %.2f seconds.\n',...
        D{d}.DistributionName,AUC(d,1),AUC(d,2),AUC(d,3));
    
    xlabel('Elapsed time'); ylabel('Probability of waiting');
end
set(gcf,'NextPlot','add');
axes;
h = title('Baselines vs Drink','FontSize',20);
set(gca,'Visible','off');
set(h,'Visible','on');

clearvars('-except',initialVars{:});

%% Plot by block
figure;
blockC = {[.1,.1,.1],[.3,.3,.3],[.5,.5,.5],[.7,.7,.7],[.9,.9,.9]};

for d = 1:numD
    c = 1;
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d,:);
    if d == 1
        fprintf('%s\n',D{d}.DistributionName);
        for b = 1:2:10
            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
            g = stairs(x,f,'Color',blockC{c},'LineWidth',3); hold on;
            xlabel('Elapsed time'); ylabel('Probability of waiting');
            AUC(1,c) = trapz(x,f);
            fprintf('%.2f seconds.\n',AUC(1,c));
            l{c} = sprintf('Block %.0f',b);
            c = c + 1;
        end
        title('Across blocks');
        legend(l);
    elseif d == 2
        fprintf('%s\n',D{d}.DistributionName);
        for b = 2:2:10
            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,b)),...
                'censoring', temp.censor(ismember(temp.block,b)),'function','survivor');
            g = stairs(x,f,'Color',blockC{c},'LineWidth',3); hold on;
            xlabel('Elapsed time'); ylabel('Probability of waiting');
            AUC(2,c) = trapz(x,f);
            fprintf('%.2f seconds.\n',AUC(2,c));
            l{c} = sprintf('Block %.0f',b);
            c = c + 1;
        end
        legend(l);
    end
end
clearvars('-except',initialVars{:});

%% Between group analyses
% Add drink type varaible
trialData.type = nan(height(trialData),1);
uniform.type = nan(height(uniform),1);
pareto.type = nan(height(pareto),1);
trialData.type(ismember(trialData.id,1:25)) = 1; % Malto+Aspartame
uniform.type(ismember(uniform.id,1:25)) = 1; % Malto+Aspartame
pareto.type(ismember(pareto.id,1:25)) = 1; % Malto+Aspartame
trialData.type(trialData.id > 25) = 2; % Water
uniform.type(uniform.id > 25) = 2; % Water
pareto.type(pareto.id > 25) = 2; % Water

%% Export for R
% writetable(trialData,'/Users/Bowen/Documents/R scripts/QT/trialData.csv');

%% Glucose vs Water
figure;
names = {'Uniform','Pareto'};
for d = 1:numD
    subplot(2,1,d);
    temp = trialData(trialData.distribution == d & ismember(trialData.block,[5 6 7 8]),:);
    type1 = temp(temp.type == 1,:);
    type2 = temp(temp.type == 2,:);
    
    [f,x,flo,fup] = ecdf(type1.rt,'censoring', type1.censor,'function','survivor');
    h = stairs(x,f,'Color',C{2}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d,1) = trapz(x,f);
    ks1 = f;
    
    [f,x,flo,fup] = ecdf(type2.rt,'censoring', type2.censor,'function','survivor');
    g = stairs(x,f,'Color',C{1}./255,'LineWidth',3); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    legend([h,g],'Glucose','Water');
    ks2 = f;
    
    AUC(d,2) = trapz(x,f);
    [h,p] = kstest2(ks1,ks2);
    fprintf('%s\nMain: %.2f seconds.\nDrink: %.2f seconds.\nKS test p: %.3f.\n',...
        D{d}.DistributionName,AUC(d,1),AUC(d,2),p);
    
    title(names{d});
    xlabel('Elapsed time'); ylabel('Probability of waiting');
end

clearvars('-except',initialVars{:});

%% Non-parametric test for AUCs
for p = participants
    for d = 1:numD
        i = trialData.distribution == d & trialData.id == p & ismember(trialData.block,[5 6 7 8]);
        M(p,d) = nanmean(trialData.rt(i));
        try
            [f,x,flo,fup] = ecdf(trialData.rt(i),...
                'censoring', trialData.censor(i),'function','survivor');
            auc(p,d) = trapz(x,f);
        catch
            auc(p,d) = NaN;
            continue;
        end
    end
end
M(:,3) = 1;
M(26:end,3) = 2;
p = ranksum(M(M(:,3) == 1,1),M(M(:,3) == 2,1))
p = ranksum(M(M(:,3) == 1,2),M(M(:,3) == 2,2))

auc(:,3) = 1;
auc(26:end,3) = 2;
p = ranksum(auc(auc(:,3) == 1,1),auc(auc(:,3) == 2,1))
p = ranksum(auc(auc(:,3) == 1,2),auc(auc(:,3) == 2,2))

clearvars('-except',initialVars{:});

%% Plot mean AUCs for each drink
for tidiness = 1
    for t = 1:2
        UM(t) = mean(nanmean(table2array(uniform(uniform.type == t,{'block3','block4'}))),2); % Columns 4 and 5 for drinking blocks
        USTD(t) = mean(nanstd(table2array(uniform(uniform.type == t,{'block3','block4'}))),2);
    end
    
    figure;
    bar(UM','EdgeColor','none','FaceColor',[.6 .6 .6]); hold on
    errorbar(1:2,UM,USTD,'LineStyle','none','Color',[0 0 0]);
    set(gca,'XTickLabel',{'Glucose','Water'});
    title('Uniform');
    
    for t = 1:2
        PM(t) = mean(nanmean(table2array(pareto(pareto.type == t,:))),2);
        PSTD(t) = mean(nanstd(table2array(pareto(pareto.type == t,:))),2);
    end
    
    figure;
    bar(PM','EdgeColor','none','FaceColor',[.6 .6 .6]); hold on
    errorbar(1:2,PM,PSTD,'LineStyle','none','Color',[0 0 0]);
    set(gca,'XTickLabel',{'Glucose','Water'});
    title('Pareto');
    
    U1 = nanmean(uniform{1:25,2:6},2);
    U2 = nanmean(uniform{26:50,2:6},2);
    
    P1 = nanmean(pareto{1:25,2:6},2);
    P2 = nanmean(pareto{26:50,2:6},2);
    
    [p,h] = ranksum(U1,U2)
    [p,h] = ranksum(P1,P2)
end

% clearvars('-except',initialVars{:});

% T-test between random effects from mixed model
% Mixed accelerated failure time model
% Fit each participant to weibull or other and compare parameters
% Cognitive talk - focus on Juice and QT
% Abstract - write abstract for TIMEDEC (HRV vs K)

%% Plot AUCs for each block
for tidiness = 1
    for t = 1:2
        UM(t,:) = nanmean(table2array(uniform(uniform.type == t,:)));
        USTD(t,:) = nanstd(table2array(uniform(uniform.type == t,:)));
    end
    
    figure;
    hBar = bar(UM(:,2:end-1)','EdgeColor','none');
    hBar(1).FaceColor = [0.2, 0.2, 0.2];
    hBar(2).FaceColor = [0.8, 0.8, 0.8];
    hold on
    legend('Glucose','Water');
    for d = 1:5
        errorbar(d - 0.15, UM(1,1 + d), USTD(1,d),'LineStyle','none','Color',[0 0 0]);
        errorbar(d + 0.15, UM(2,1 + d), USTD(2,d),'LineStyle','none','Color',[0 0 0]);
    end
    set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
    title('Uniform');
    
    for t = 1:2
        PM(t,:) = nanmean(table2array(pareto(pareto.type == t,:)));
        PSTD(t,:) = nanstd(table2array(pareto(pareto.type == t,:)));
    end
    
    figure;
    hBar = bar(PM(:,2:end-1)','EdgeColor','none');
    hBar(1).FaceColor = [0.2, 0.2, 0.2];
    hBar(2).FaceColor = [0.8, 0.8, 0.8];
    legend('Glucose','Water');
    hold on
    for d = 1:5
        errorbar(d - 0.15, PM(1,1 + d), PSTD(1,d),'LineStyle','none','Color',[0 0 0]);
        errorbar(d + 0.15, PM(2,1 + d), PSTD(2,d),'LineStyle','none','Color',[0 0 0]);
    end
    set(gca,'XTickLabel',{'Practice','Baseline1','Drink1','Drink2','Baseline2'});
    title('Pareto');
end

clearvars('-except',initialVars{:});

%% Calculate survivor funcitons for each participant and plot group means
surv = {};
surv{1} = nan(50,150);
surv{2} = nan(50,150);
for d = 1:numD
    for p = participants
        temp = trialData(trialData.id == p &...
            trialData.distribution == d,:);
        try
            [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,[5,6,7,8])),...
                'censoring', temp.censor(ismember(temp.block,[5,6,7,8])),'function','survivor');
        catch
            fprintf('Can''t fit participant %.0f.\n',p);
            continue;
        end
        surv{d}(p,1:size(f,1)) = f';
    end
end
for d = 1:numD
    figure;
    m1 = nanmean(surv{d}(1:25,:));
    m2 = nanmean(surv{d}(26:50,:));
    sd1 = nanstd(surv{d}(1:25,:));
    sd2 = nanstd(surv{d}(26:50,:));
    h = stairs(1:150,m1,'Color',C{2}./255,'LineWidth',3); hold on;
    stairs(1:150,m1+sd1,'Color',C{2}./255,'LineStyle',':'); stairs(1:150,m1-sd1,'Color',C{2}./255,'LineStyle',':'); % Plot confidence bounds
    
    j = stairs(1:150,m2,'Color',C{1}./255,'LineWidth',3); hold on;
    stairs(1:150,m2+sd2,'Color',C{1}./255,'LineStyle',':'); stairs(1:150,m2-sd2,'Color',C{1}./255,'LineStyle',':'); % Plot confidence bounds
    legend([h,j],{'Glucose','Water'});
    [h,p] = kstest2(m1,m2)
end

%% Check distribution of mean RTs
for p = participants
    for d = 1:numD
    M(d,p) = nanmean(trialData.rt(trialData.id == p & trialData.distribution == d & trialData.censor == 0 & ismember(trialData.block, [5,6,7,8])));
    end
end
figure;
histfit(M(1,:),5,'gamma');
figure;
histfit(M(2,:),15,'gamma');

for d = 1:numD
    P{d} = trialData.rt(trialData.distribution == d & trialData.censor == 0 & ismember(trialData.block, [5,6,7,8]));
end
figure;
nhist(P,'smooth','pdf','noerror','decimalplaces',0,'xlabel','Delay (secs)','ylabel','PDF','color','colormap');

%% Get AUCs again (just one lot this time)

for d = 1:numD
    for p = participants
        temp = trialData(trialData.id == p & trialData.distribution == d,:);
        try
         [f,x,flo,fup] = ecdf(temp.rt(ismember(temp.block,[5,6,7,8])),...
                                'censoring', temp.censor(ismember(temp.block,[5,6,7,8])),'function','survivor');
        AUC(d,p) = trapz(x,f);
        catch
            AUC(d,p) = NaN;
            continue;
        end
    end
end

%% Questionnaire measures
load('qtQualtrics.mat');
% Select relevant questions
qtQualtrics = qtQualtrics(3:end,24:end-4);

drinkQuestions = qtQualtrics(:,1:11);

% BISBAS
temp = qtQualtrics{:,16:39};

% Reverse coded items
reverse = [1:13,15:18,20:24];
for r = reverse
    temp(:,r) = 5 - temp(:,r);
end

% Compute scores
bisbas = nan(size(temp,1),4);
bisbas(:,1) = mean(temp(:,14:20),2); % BIS
bisbas(:,2) = mean(temp(:,1:4),2); % Drive
bisbas(:,3) = mean(temp(:,5:8),2); % Fun
bisbas(:,4) = mean(temp(:,9:13),2); % Reward

% UPPS (missing question from lack of premediation)
temp = qtQualtrics{:,44:62};

% Reverse coded items
reverse = [1:2,4:6,12];
for r = reverse
    temp(:,r) = 6 - temp(:,r);
end

% Compute scores
supps = nan(size(temp,1),5);
supps(:,1) = mean(temp(:,[7:8,13,15]),2); % Negative urgency
supps(:,2) = mean(temp(:,[1:2,4,11]),2); % Lack of perserverence
supps(:,3) = mean(temp(:,[5:6,12]),2); % Lack of premediation
supps(:,4) = mean(temp(:,[9,14,16,18]),2); % Sesation seeking
supps(:,5) = mean(temp(:,[3,10,17]),2); % Positive urgency

% Zauberman (is this finished? Who knows.)
imagine = qtQualtrics{:,78:83};
x = [10 18 30 55 100 180]; % Delays
auc = zeros(length(imagine),1);
for i = 1:length(imagine)
    nImagine(i,:) = imagine(i,:)/imagine(i,1); % Normalise by lowest distance
    AUC(i) = trapz(x,nImagine(i,:));
    %     f = figure;
    %     plot(x,nImagine(i,:));
    %     title(sprintf('AUC: %.1f',AUC(i)));
    %     pause(2)
    %     close(f)
end

qtQuestionnaires = table([bisbas, supps, AUC']);
    writetable(qtQuestionnaires,'/Users/Bowen/Documents/R/QT/qtQuestionnaires.csv');