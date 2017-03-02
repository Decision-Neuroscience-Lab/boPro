%% Set included participants and graph settings
participants = [1:10];
set(0,'DefaultAxesColorOrder',...
    [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
set(0,'defaultfigurecolor',[1 1 1]);
%% Identify unique amounts and delays
amounts = unique(trialData.reward);
delays = unique(trialData.delay);
%% MUST FIX OUTLIER IDENTIFICATION - PLOT IS NOT REPRESENTATIVE OF EXCLUDED DATA
%% Removed missed and identify outliers using an arbitrary threshold and add exclusion variable to trialData
% Add exclusion variables to trialData
trialData.flag = zeros(size(trialData,1),1);
trialData.flag(isnan(trialData.response)) = 1; % Mark missed responses as excluded
TH = 2.5;
ploton = 0;
for x = participants
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
            fprintf('Could not fit gaussian, not enough data.\n');
            continue;
        end
        if ploton
            figure;
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
clearvars -except trialData amounts delays participants
%% Create new variables
for tidiness = 1
    trialData.accuracy = trialData.response - trialData.delay./2;
    trialData.normResponse = nan(height(trialData),1); % Normalised per participant, without accounting for delay
    trialData.normAccuracy = nan(height(trialData),1); % Normalised per participant, accounting for delay
    trialData.normThirst = nan(height(trialData),1);
    trialData.normPleasantness = nan(height(trialData),1);
    trialData.intThirst = nan(height(trialData),1);
    trialData.intPleasantness = nan(height(trialData),1);
     trialData.normIntThirst = nan(height(trialData),1);
    trialData.normIntPleasantness = nan(height(trialData),1);
    
    for x = participants
        trialData.normResponse(trialData.id == x & ~isnan(trialData.response))...
            = zscore(trialData.response(trialData.id == x & ~isnan(trialData.response)));
        for d = 1:numel(delays)
            trialData.normAccuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                = zscore(trialData.accuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response)));
        end
        trialData.normThirst(~isnan(trialData.thirst)) = (trialData.thirst(~isnan(trialData.thirst)) - min(trialData.thirst(~isnan(trialData.thirst))))...
            ./ (max(trialData.thirst(~isnan(trialData.thirst))) - min(trialData.thirst(~isnan(trialData.thirst))));
        trialData.normPleasantness(~isnan(trialData.thirst)) = (trialData.pleasantness(~isnan(trialData.pleasantness)) - min(trialData.pleasantness(~isnan(trialData.pleasantness))))...
            ./ (max(trialData.pleasantness(~isnan(trialData.pleasantness))) - min(trialData.pleasantness(~isnan(trialData.pleasantness))));
    end
    
    % Time perception measures
    TIME = table;
    for x = participants
        temp = trialData(trialData.id == x,:);
        ID(x,1) = table(x,'VariableName',{'id'});
        ind = getTimeData(temp.delay(~isnan(temp.response))./2,...
            temp.response(~isnan(temp.response)));
        TIME = [TIME;ind];
    end
    TIME = [ID TIME];
    TIME.Properties.VariableNames(1) = {'id'};
    
    % Interpolate thirst and pleasantness ratings
    for x = participants
        temp = trialData(trialData.id == x & ~isnan(trialData.thirst),:);
        trialData.intThirst(trialData.id == x & ismember(trialData.trial,[60:200])) = interp1(60:20:200,temp.thirst,60:1:200,'spline');
        trialData.intPleasantness(trialData.id == x & ismember(trialData.trial,[60:200])) = interp1(60:20:200,temp.pleasantness,60:1:200,'spline');
    end
    
     % Interpolate normalised thirst and pleasantness ratings
    for x = participants
        temp = trialData(trialData.id == x & ~isnan(trialData.thirst),:);
        trialData.normIntThirst(trialData.id == x & ismember(trialData.trial,[60:200])) = interp1(60:20:200,temp.normThirst,60:1:200,'spline');
        trialData.normIntPleasantness(trialData.id == x & ismember(trialData.trial,[60:200])) = interp1(60:20:200,temp.normPleasantness,60:1:200,'spline');
    end
    
end
clearvars -except trialData amounts delays participants TIME
initialVars = who;
initialVars{end+1} = 'initialVars';
clearvars('-except',initialVars{:});
%% Binned accuracy and pleasantness mk2
factor =[];
dependentVar = 'normAccuracy';
ratingsVar = {'normThirst', 'normPleasantness'};
numBins = 10;
normalise2baseline = 0;
ratingScaleY = 0.3;
ratingShift = 0.7;
for tidiness = 1

temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:); % Select participant without outliers
temp = sortrows(temp,[2 3]); % Make sure data is in chronological order (ignore id)
divisions = round(linspace(min(temp.trial),max(temp.trial),numBins+1));

for bin = 1:numBins
    divLabels{bin} = sprintf('%.0f - %.0f',divisions(bin),divisions(bin+1));
    subtemp = temp(temp.trial > divisions(bin) &  temp.trial < divisions(bin+1),:);
    
    if ~isempty(factor)
        factorConditions = unique(subtemp(:,factor)); % Identify conditions unique to factor
        for c = 1:numel(factorConditions)
            i = ismember(subtemp(:,factor),factorConditions(c,:));
            meanBin(bin,c) = nanmean(table2array(subtemp(i,dependentVar)));
            semBin(bin,c) = nanstd(table2array(subtemp(i,dependentVar))) / (sqrt(numel(subtemp(i,dependentVar))));
        end
    elseif normalise2baseline
        meanBin(bin) = nanmean(table2array(subtemp(subtemp.reward~=0,dependentVar))) - nanmean(table2array(subtemp(subtemp.reward==0,dependentVar)));
        semBin(bin) = nanstd(table2array(subtemp(subtemp.reward~=0,dependentVar))) / (sqrt(numel(subtemp(subtemp.reward~=0,dependentVar))));
    else
        meanBin(bin) = nanmean(table2array(subtemp(:,dependentVar)));
        semBin(bin) = nanstd(table2array(subtemp(:,dependentVar))) / (sqrt(numel(subtemp(:,dependentVar))));
    end
end
% Concatenate thirst and pleasantness ratings
zThirst = [];
zPleasantness = [];
for x = participants
    temp2 = table2array(trialData(trialData.id == x & ~isnan(table2array(trialData(:,ratingsVar{1}))),ratingsVar{1}));
    temp3 = table2array(trialData(trialData.id == x & ~isnan(table2array(trialData(:,ratingsVar{2}))),ratingsVar{2}));
    zThirst = cat(2,zThirst,temp2);
    zPleasantness = cat(2,zPleasantness,temp3);
end

% Interpolate mean thirst and pleasantness over trial
thirstVal = mean(zThirst,2);
pleasantnessVal = mean(zPleasantness,2);
semThirst = std(zThirst,0,2)./sqrt(size(zThirst,2));
semPlesantness = std(zPleasantness,0,2)./sqrt(size(zPleasantness,2));
intThirst = interp1(60:20:200,thirstVal,60:1:200,'spline');
intPleasantness = interp1(60:20:200,pleasantnessVal,60:1:200,'spline');

% Plot task
figure;
hold on
hBar = bar(meanBin);
colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
for c = 1:numel(hBar)
    set(hBar(c),'FaceColor',colors(c,:),'EdgeColor',[1 1 1]);
end
xlim([0 numel(divisions)]);
set(gca,'XTick',1:numel(divisions)-1);
set(gca,'XTickLabel', divLabels);
ylabel('Deviation (seconds)');
xlabel('Trial number');

if ~isempty(factor)
barWidth = 0.09;
dist = [-3*barWidth -1*barWidth 1*barWidth 3*barWidth];
for d = 1:size(meanBin,1)
    for f = 1:size(meanBin,2)
        h = errorbar(d + dist(f), meanBin(d,f),semBin(d,f));
        set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
    end
end
else
     h = errorbar(1:numBins, meanBin,semBin);
        set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
end

% Plot thirst and pleasantness
%plot(linspace(2,numBins-1,8), (thirstVal-ratingShift)./ratingScaleY,'LineStyle','none', 'Marker', 'o','Color',[0 0.447 0.741]);
%t = plot(linspace(2,numBins-1,141),(intThirst-ratingShift)./ratingScaleY);
plot(linspace(2,numBins-1,8),(pleasantnessVal-ratingShift)./ratingScaleY,'LineStyle','none','Marker','o');
p = plot(linspace(2,numBins-1,141),(intPleasantness-ratingShift)./ratingScaleY);
if strcmp(factor,'reward')
    title('Mean accuracy by reward');
    legend([hBar(1),hBar(2),hBar(3),hBar(4),p],...
        {'No reward','Small reward','Medium reward','Large reward','Pleasantness'});
elseif strcmp(factor,'delay')
    title('Mean accuracy by delay');
    legend([hBar(1),hBar(2),hBar(3),hBar(4),p],...
        {'4 seconds','6 seconds','8 seconds','10 seconds','Pleasantness'});
else
      title('Mean accuracy');
    legend([hBar,p],...
        {'Accuracy','Pleasantness'});
end
end
clearvars('-except',initialVars{:});
%% Binned accuracy and thirst / pleasantness measures for all participants
separateFactor =[];
numBins = 8;
ratingScaleY = 1;
ratingShift = 1;
scale2Baseline = 1;
for tidiness = 1
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:); % Select participant without outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order (ignore id)
    firstPractice = temp(temp.session == 1,:);
    mainTask = temp(temp.session == 2,:);
    secondPractice = temp(temp.session == 3,:);
    
    % Index, create and map conditions for each factor separately
    if ~isempty(separateFactor)
        factorColumn = mainTask(:,separateFactor); % Isolate factors
        factorConditions = unique(factorColumn); % Identify conditions
        for condition = 1:numel(factorConditions)
            splitConditions{condition} = mainTask.normAccuracy(ismember(mainTask(:,separateFactor), factorConditions(condition,:))); % Split into conditions for each factor
        end
        
        % Create mean bins for each factor, thirst / pleasantness and plot
        for f = 1:numel(factorConditions)
            if mod(numel(splitConditions{f}), numBins) == 0
                bins = reshape(splitConditions{f},numel(splitConditions{f})/numBins,numBins);
                meanBin(f,:) = nanmean(bins);
                semBin(f,:) = nanstd(bins) / (sqrt(numel(bins)));
            else
                splitConditions{f}(end+1:end+(numBins-mod(numel(splitConditions{f}),numBins))) = NaN; % Add NaN until even
                bins = reshape(splitConditions{f},numel(splitConditions{f})/numBins,numBins);
                meanBin(f,:) = nanmean(bins);
                semBin(f,:) = nanstd(bins) / (sqrt(numel(bins)));
            end
        end
        
        % Thirst and pleasantness
        zThirst = [];
        zPleasantness = [];
        
        for x = participants
            zThirst = cat(2,zThirst,trialData.normThirst(trialData.id == x & ~isnan(trialData.normThirst)));
            zPleasantness = cat(2,zPleasantness,trialData.normPleasantness(trialData.id == x & ~isnan(trialData.normPleasantness)));
        end
        
        % Interpolate mean thirst and pleasantness over trial
        mThirst = mean(zThirst,2);
        mPleasantness = mean(zPleasantness,2);
        semThirst = std(zThirst,0,2)./sqrt(size(zThirst,2));
        semPlesantness = std(zPleasantness,0,2)./sqrt(size(zPleasantness,2));
        thirstPoints = unique(trialData.trial(~isnan(trialData.thirst)));
        pleasantnessPoints = unique(trialData.trial(~isnan(trialData.pleasantness)));
        thirstVal = mThirst;
        pleasantnessVal = mPleasantness;
        intVecT = min(thirstPoints):max(thirstPoints);
        intVecP = min(pleasantnessPoints):max(pleasantnessPoints);
        intThirst = interp1(thirstPoints,thirstVal,intVecT,'spline');
        intPleasantness = interp1(pleasantnessPoints,pleasantnessVal,intVecP,'spline');
        
        % Generate practice means and add to main task
        if strcmp(separateFactor,'delay');
            factorColumn2 = firstPractice(:,separateFactor); % Isolate factors
            factorConditions2 = unique(factorColumn); % Identify conditions
            for condition = 1:numel(factorConditions2)
                splitConditions2{condition} = firstPractice.normAccuracy(ismember(firstPractice(:,separateFactor), factorConditions2(condition,:))); % Split into conditions for each factor
            end
            for f = 1:numel(factorConditions)
                meanBin2(f,:) = nanmean(splitConditions2{f});
                semBin2(f,:) = nanstd(splitConditions2{f}) / (sqrt(numel(splitConditions2{f})));
            end
            for condition = 1:numel(factorConditions2)
                splitConditions3{condition} = secondPractice.normAccuracy(ismember(secondPractice(:,separateFactor), factorConditions2(condition,:))); % Split into conditions for each factor
            end
            for f = 1:numel(factorConditions)
                meanBin3(f,:) = mean(splitConditions3{f});
                semBin3(f,:) = nanstd(splitConditions3{f}) / (sqrt(numel(splitConditions3{f})));
            end
            meanBin = [meanBin2 meanBin meanBin3];
            semBin = [semBin2 semBin semBin3];
            figure;
        else
            meanBin2 = mean(firstPractice.normAccuracy);
            meanBin3 = mean(secondPractice.normAccuracy);
            semBin2 = nanstd(firstPractice.normAccuracy) / (sqrt(numel(firstPractice.normAccuracy)));
            semBin3 = nanstd(secondPractice.normAccuracy) / (sqrt(numel(secondPractice.normAccuracy)));
            % Plot practice
            figure;
            jBar = bar(1,meanBin2);
            hold on
            set(jBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1], 'BarWidth',0.5);
            kBar = bar(numBins+2,meanBin3);
            set(kBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1], 'BarWidth',0.5);
        end
        
        % Plot task
        if strcmp(separateFactor,'delay')
                    hBar = bar(meanBin');
        else
        hBar = bar(2:numBins+1,meanBin');
        end
        colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
        for c = 1:numel(hBar)
            set(hBar(c),'FaceColor',colors(c,:),'EdgeColor',[1 1 1]);
        end
        xlim([0 11]);
        set(gca,'XTick',1:numBins+2);
        set(gca,'XTickLabel',...
            {'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eighth','Ninth','Tenth','Eleventh','Twelfth'});
        ylabel('Deviation (seconds)');
        hold on
        
        barWidth = 0.09;
        dist = [-3*barWidth -1*barWidth 1*barWidth 3*barWidth];
        for d = 1:size(meanBin,2)
            for f = 1:size(meanBin,1)
                if ~strcmp(separateFactor,'delay')
                    h = errorbar(d + 1 + dist(f), meanBin(f,d),semBin(f,d));
                else
                    h = errorbar(d + dist(f), meanBin(f,d),semBin(f,d));
                end
                set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
            end
        end

        % Plot thirst and pleasantness
        plot(linspace(2,numBins+1,8), (thirstVal-ratingShift)./ratingScaleY,'LineStyle','none', 'Marker', 'o','Color',[0 0.447 0.741]);
        t = plot(linspace(2,numBins+1,numel(intVecT)),(intThirst-ratingShift)./ratingScaleY);
        plot(linspace(2,numBins+1,8),(pleasantnessVal-ratingShift)./ratingScaleY,'LineStyle','none','Marker','o');
        p = plot(linspace(2,numBins+1,numel(intVecP)),(intPleasantness-ratingShift)./ratingScaleY);
        if strcmp(separateFactor,'reward')
            title('Mean accuracy by reward');
            legend([hBar(1),hBar(2),hBar(3),hBar(4),t,p],...
                {'No reward','Small reward','Medium reward','Large reward','Thirst','Pleasantness'});
        elseif strcmp(separateFactor,'delay')
            title('Mean accuracy by delay');
            legend([hBar(1),hBar(2),hBar(3),hBar(4),t,p],...
                {'4 seconds','6 seconds','8 seconds','10 seconds','Thirst','Pleasantness'});
        end
        
    else % If plotting all conditions
        
        if mod(numel(mainTask.normAccuracy), numBins) == 0
            bins = reshape(mainTask.normAccuracy,numel(mainTask.normAccuracy)/numBins,numBins);
            meanBin = nanmean(bins);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
        else
            mainTask(end+1:end+(numBins-mod(numel(mainTask.normAccuracy),numBins)),:) = {NaN}; % Add NaN until even
            bins = reshape(mainTask.normAccuracy,numel(mainTask.normAccuracy)/numBins,numBins);
            meanBin = nanmean(bins);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
        end
        
         % Generate practice means and add to main task
            meanBin2 = mean(firstPractice.normAccuracy);
            meanBin3 = mean(secondPractice.normAccuracy);
            semBin2 = nanstd(firstPractice.normAccuracy) / (sqrt(numel(firstPractice.normAccuracy)));
            semBin3 = nanstd(secondPractice.normAccuracy) / (sqrt(numel(secondPractice.normAccuracy)));
             % Plot practice
             figure;
             jBar = bar(1,meanBin2);
             set(jBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1]);
             hold on
             j = errorbar(1,meanBin2,semBin2);
             set(j,'linestyle','none','Color', [0 0 0]);
             kBar = bar(numBins+2,meanBin3);
             set(kBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1]);
             k = errorbar(numBins+2,meanBin3,semBin3);
             set(k,'linestyle','none','Color', [0 0 0]);
             
        % Thirst and pleasantness
        zThirst = [];
        zPleasantness = [];
        
        for x = participants
            zThirst = cat(2,zThirst,trialData.normThirst(trialData.id == x & ~isnan(trialData.normThirst)));
            zPleasantness = cat(2,zPleasantness,trialData.normPleasantness(trialData.id == x & ~isnan(trialData.normPleasantness)));
        end
        
        % Interpolate mean thirst and pleasantness over trial
        mThirst = mean(zThirst,2);
        mPleasantness = mean(zPleasantness,2);
        semThirst = std(zThirst,0,2)./sqrt(size(zThirst,2));
        semPlesantness = std(zPleasantness,0,2)./sqrt(size(zPleasantness,2));
        
        thirstPoints = unique(trialData.trial(~isnan(trialData.thirst)));
        pleasantnessPoints = unique(trialData.trial(~isnan(trialData.pleasantness)));
        thirstVal = mThirst;
        pleasantnessVal = mPleasantness;
        intVecT = min(thirstPoints):max(thirstPoints);
        intVecP = min(pleasantnessPoints):max(pleasantnessPoints);
        intThirst = interp1(thirstPoints,thirstVal,intVecT,'spline');
        intPleasantness = interp1(pleasantnessPoints,pleasantnessVal,intVecP,'spline');
        
        % Plots
        hBar = bar(2:numBins+1,meanBin);
        set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
        set(gca,'XTick',1:numBins+2,...
            'XTickLabel',{'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eighth','Ninth','Tenth','Eleventh','Twelfth'});
        ylabel('Deviation (seconds)');
        hold on
        h = errorbar(2:numBins+1,meanBin,semBin);
        set(h,'linestyle','none');
        set(h, 'Color', [0 0 0]);
        
        plot(linspace(2,numBins+1,8), (thirstVal-ratingShift)./ratingScaleY,'LineStyle','none', 'Marker', 'o', 'Color', [0 0.447 0.741]);
        t = plot(linspace(2,numBins+1,numel(intVecT)),(intThirst-ratingShift)./ratingScaleY);
        plot(linspace(2,numBins+1,8),(pleasantnessVal-ratingShift)./ratingScaleY,'LineStyle','none','Marker','o');
        p = plot(linspace(2,numBins+1,numel(intVecP)),(intPleasantness-ratingShift)./ratingScaleY);
        legend([t p],'Thirst','Pleasantness');
    end
end
clearvars('-except',initialVars{:});
%% Binned accuracy and thirst / pleasantness measures for all participants, normalised to 'no reward' condition
numBins = 10;
ratingScaleY = 0.5;
ratingShift = 0.75;
dependentVar = 'normAccuracy';
for tidiness = 1
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:); % Select participant without outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order (ignore id)
    firstPractice = table2array(temp(temp.session == 1,dependentVar));
    mainTask = table2array(temp(temp.session == 2,dependentVar));
    mainTask(temp.reward == 0) = NaN;
    noReward = table2array(temp(temp.session == 2,dependentVar));
    noReward(temp.reward ~= 0) = NaN;
    secondPractice = table2array(temp(temp.session == 3,dependentVar));
        
    % Bin main task
        if mod(numel(mainTask), numBins) == 0
            bins = reshape(mainTask,numel(mainTask)/numBins,numBins);
            meanBin = nanmean(bins);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
        else
            mainTask(end+1:end+(numBins-mod(numel(mainTask),numBins))) = NaN; % Add NaN until even
            bins = reshape(mainTask,numel(mainTask)/numBins,numBins);
            meanBin = nanmean(bins);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
        end
        
        % Bin no reward condition
        if mod(numel(noReward), numBins) == 0
            bins = reshape(noReward,numel(noReward)/numBins,numBins);
            meanBin0 = nanmean(bins);
            semBin0 = nanstd(bins) / (sqrt(numel(bins)));
        else
            noReward(end+1:end+(numBins-mod(numel(noReward),numBins))) = NaN; % Add NaN until even
            bins = reshape(noReward,numel(noReward)/numBins,numBins);
            meanBin0 = nanmean(bins);
            semBin0 = nanstd(bins) / (sqrt(numel(bins)));
        end
        
         % Generate practice means and add to main task
            meanBin2 = mean(firstPractice);
            meanBin3 = mean(secondPractice);
            semBin2 = nanstd(firstPractice) / (sqrt(numel(firstPractice)));
            semBin3 = nanstd(secondPractice) / (sqrt(numel(secondPractice)));
             % Plot practice
             figure;
             jBar = bar(1,meanBin2);
             set(jBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1]);
             hold on
             j = errorbar(1,meanBin2,semBin2);
             set(j,'linestyle','none','Color', [0 0 0]);
             kBar = bar(numBins+2,meanBin3);
             set(kBar,'FaceColor',[0.494 0.184 0.556], 'EdgeColor',[1 1 1]);
             k = errorbar(numBins+2,meanBin3,semBin3);
             set(k,'linestyle','none','Color', [0 0 0]);
             
        % Thirst and pleasantness
        zThirst = [];
        zPleasantness = [];
        
        for x = participants
            zThirst = cat(2,zThirst,trialData.normThirst(trialData.id == x & ~isnan(trialData.normThirst)));
            zPleasantness = cat(2,zPleasantness,trialData.normPleasantness(trialData.id == x & ~isnan(trialData.normPleasantness)));
        end
        
        % Interpolate mean thirst and pleasantness over trial
        mPleasantness = mean(zPleasantness,2);
        semPlesantness = std(zPleasantness,0,2)./sqrt(size(zPleasantness,2));
        
        pleasantnessPoints = unique(trialData.trial(~isnan(trialData.pleasantness)));
        pleasantnessVal = mPleasantness;
        intVecP = min(pleasantnessPoints):max(pleasantnessPoints);
        intPleasantness = interp1(pleasantnessPoints,pleasantnessVal,intVecP,'spline');
        
        % Plots
        meanBin = meanBin - meanBin0;
        hBar = bar(2:numBins+1,meanBin);
        set(hBar,'FaceColor',[0.443 0.82 0.6],'EdgeColor',[1 1 1]);
        set(gca,'XTick',1:numBins+2,...
            'XTickLabel',{'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eighth','Ninth','Tenth','Eleventh','Twelfth'});
        ylabel('Deviation (seconds)');
        hold on
        h = errorbar(2:numBins+1,meanBin,semBin);
        set(h,'linestyle','none');
        set(h, 'Color', [0 0 0]);
        
        plot(linspace(2,numBins+1,8),(pleasantnessVal-ratingShift)./ratingScaleY,'LineStyle','none','Marker','o');
        p = plot(linspace(2,numBins+1,numel(intVecP)),(intPleasantness-ratingShift)./ratingScaleY);
        legend([p],'Pleasantness');
        
end
clearvars('-except',initialVars{:});
%% Thirst and pleasantness plots - All participants
for tidiness = 1
    zThirst = [];
    zPleasantness = [];
    
    for x = participants
        zThirst = cat(2,zThirst,trialData.normThirst(trialData.id == x & ~isnan(trialData.normThirst)));
        zPleasantness = cat(2,zPleasantness,trialData.normPleasantness(trialData.id == x & ~isnan(trialData.normPleasantness)));
    end
    
    % Interpolate mean thirst and pleasantness over trial
    mThirst = mean(zThirst,2);
    mPleasantness = nanmean(zPleasantness,2);
    semThirst = std(zThirst,0,2)./sqrt(size(zThirst,2));
    semPlesantness = std(zPleasantness,0,2)./sqrt(size(zPleasantness,2));
    
    thirstPoints = unique(trialData.trial(~isnan(trialData.thirst)));
    pleasantnessPoints = unique(trialData.trial(~isnan(trialData.pleasantness)));
    thirstVal = mThirst;
    pleasantnessVal = mPleasantness;
    intVecT = min(thirstPoints):max(thirstPoints);
    intVecP = min(pleasantnessPoints):max(pleasantnessPoints);
    intThirst = interp1(thirstPoints,thirstVal,intVecT,'spline');
    intPleasantness = interp1(pleasantnessPoints,pleasantnessVal,intVecP,'spline');
    
    figure;
    plot(thirstPoints, thirstVal,'LineStyle','none', 'Marker', 'o');
    hold on
    t = plot(intVecT,intThirst);
    plot(pleasantnessPoints,pleasantnessVal,'LineStyle','none','Marker','o');
    p = plot(intVecP,intPleasantness);
    xlim([min(thirstPoints) max(thirstPoints)]);
    ylim([0 1]);
    xlabel('Trial');
    legend([t p],'Thirst','Pleasantness');
    title('All participants');
    teb = errorbar(thirstPoints,thirstVal,semThirst);
    set(teb, 'LineStyle','none','Color',[0 0.447 0.741]);
    peb = errorbar(pleasantnessPoints,pleasantnessVal,semPlesantness);
    set(peb, 'LineStyle','none','Color',[0.443 0.82 0.6]);
end
clearvars('-except',initialVars{:});
%% Thirst and pleasantness plots - Individual participants
for x = participants
    temp = trialData(trialData.id == x,:);  % Include flagged trials here
    
    % Interpolate thirst and pleasantness over trial
    thirstPoints = temp.trial(~isnan(temp.thirst));
    pleasantnessPoints = temp.trial(~isnan(temp.pleasantness));
    thirstVal = temp.thirst(~isnan(temp.thirst));
    pleasantnessVal = temp.pleasantness(~isnan(temp.pleasantness));
    intVecT = min(thirstPoints):max(thirstPoints);
    intVecP = min(pleasantnessPoints):max(pleasantnessPoints);
    intThirst = interp1(thirstPoints,thirstVal,intVecT,'spline');
    intPleasantness = interp1(pleasantnessPoints,pleasantnessVal,intVecP,'spline');
    
    figure;
    plot(thirstPoints, thirstVal,'LineStyle','none', 'Marker', 'o');
    hold on
    t = plot(intVecT,intThirst);
    plot(pleasantnessPoints,pleasantnessVal,'LineStyle','none','Marker','o');
    p = plot(intVecP,intPleasantness);
    xlim([min(thirstPoints) max(thirstPoints)]);
    ylim([0 10]);
    xlabel('Trial');
    legend([t p],'Thirst','Pleasantness');
    title(sprintf('Participant %.0f',x));
end
clearvars('-except',initialVars{:});
%% Binned accuracy - All participants
separateReward = 1;
for tidiness = 1
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:); % Select participant without outliers
    
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    noreward = [];
    
    % Index, create and map no reward condition separately
    if separateReward
        i = temp.reward == 0;
        noreward = temp.normAccuracy; % Create 'no reward' responses
        noreward(~i) = NaN; % Remove normal responses
        temp.normAccuracy(i) = NaN; % Remove 'no reward' responses
    end
    
    numBins = 8;
    if mod(numel(temp.normAccuracy), numBins) == 0
        bins = reshape(temp.normAccuracy,numel(temp.normAccuracy)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(bins)));
    else
        temp(end+1:end+(numBins-mod(numel(temp.normAccuracy),numBins)),:) = {NaN}; % Add NaN until even
        bins = reshape(temp.normAccuracy,numel(temp.normAccuracy)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(bins)));
    end
    if mod(numel(noreward), numBins) == 0
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin0 = nanmean(bins0);
        semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
    else
        noreward(end+1:end+(numBins-mod(numel(noreward),numBins))) = NaN; % Add NaN until even
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin0 = nanmean(bins0);
        semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
    end
        
    figure;
    if separateReward
        meanBin = [meanBin;meanBin0]';
        semBin = [semBin;semBin0]';
    end
    hBar = bar(meanBin);
    set(hBar(1),'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',...
        {'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eighth','Ninth','Tenth'});
    title('Mean accuracy');
    ylabel('Deviation (seconds)');
    hold on
    if separateReward
        set(hBar(2),'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1]);
        barWidth = 0.14;
        dist = [-1*barWidth 1*barWidth];
        for d = 1:size(meanBin,1)
            for f = 1:size(meanBin,2)
                h = errorbar(d + dist(f), meanBin(d,f),semBin(d,f));
                set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
            end
        end
        legend([hBar(1) hBar(2)],'Reward','No Reward');
        
    else
        h = errorbar(meanBin,semBin);
        set(h,'linestyle','none');
        set(h, 'Color', [0 0 0]);
    end
end
clearvars('-except',initialVars{:});
%% Binned absolute accuracy - Individual participants
separateReward = 0;
c = 1;
figure;
for x = participants
    temp = trialData(ismember(trialData.id,x) & trialData.flag == 0,:); % Select participant without outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    noreward = [];
    
    % Index, create and map no reward condition separately
    if separateReward
        i = temp.reward == 0;
        noreward = temp.accuracy; % Create 'no reward' responses
        noreward(~i) = NaN; % Remove normal responses
        temp.accuracy(i) = NaN; % Remove 'no reward' responses
    end
    
    numBins = 8;
    if mod(numel(temp.accuracy), numBins) == 0
        bins = reshape(temp.accuracy,numel(temp.accuracy)/numBins,numBins);
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin = nanmean(bins);
        meanBin0 = nanmean(bins0);
        semBin = nanstd(bins) / (sqrt(numel(bins)));
        semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
    else
        temp(end+1:end+(numBins-mod(numel(temp.accuracy),numBins)),:) = {NaN}; % Add NaN until even
        noreward(end+1:end+(numBins-mod(numel(noreward),numBins))) = NaN; % Add NaN until even
        bins = reshape(temp.accuracy,numel(temp.accuracy)/numBins,numBins);
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin = nanmean(bins);
        meanBin0 = nanmean(bins0);
        semBin = nanstd(bins) / (sqrt(numel(bins)));
        semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
    end
    
    subplot(3,4,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',{'1','2','3','4','5','6','7','8','9','10'});
    title(sprintf('Participant %.0f',x));
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    set(h, 'Color', [0 0 0]);
    
    if separateReward
        % Plot 'no reward'
        gBar = plot(meanBin0);
        set(gBar,'Color',[0 0.447 0.741]);
        g = errorbar(meanBin0,semBin0);
        set(g,'linestyle','none');
        set(g, 'Color', [0 0.447 0.741]);
        if ~isempty(noreward)
            legend([hBar gBar],'Reward','No Reward');
        end
    end
    c = c + 1;
end
suptitle('Mean accuracy');
clearvars('-except',initialVars{:});
%% Accuracy by trial - All participants
for tidiness = 1;
    for t = 1:max(trialData.trial)
        i = trialData.trial == t;
        M(t) = nanmean(trialData.normResponse(i));
    end
    
    figure;
    plot(1:max(trialData.trial),M);
    hold on
    plot(1:max(trialData.trial), zeros(1,max(trialData.trial)), 'LineStyle','--');
    xlim([0 max(trialData.trial)]);
    ylim([-5 5]);
    ylabel('Devation (secs)');
    xlabel('Trial number');
    title('All participants');
    
    for s = [1, 2, 3]
        i = trialData.session == s;
        subTrials = trialData.trial(i);
        subScore = trialData.normAccuracy(i);
        for t = 1:max(subTrials)
            j = subTrials == t;
            score(t) = nanmean(subScore(j));
        end
        plot(1:max(subTrials),score);
    end
end
clearvars('-except',initialVars{:});
%% Accuracy by trial - Individual participants
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0,:); % Select participant without outliers
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
%% Compare response and SD across conditions - All participants
DV = 'response';
for tidiness = 1
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp.delay == delays(d) & temp.reward == amounts(a);
            M(d,a) = nanmean(table2array(temp(i,DV)));
            SD(d,a) = nanstd(table2array(temp(i,DV)));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(table2array(temp(i,DV))));
        end
    end
    
    figure;
    % Plot means
    subplot(2,1,1);
    hBar = bar(M);
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
    for cc = 1:size(hBar,2)
        set(hBar(cc),'FaceColor',colors(cc,:),'EdgeColor',[1 1 1], 'BarWidth',1);
    end
    set(gca,'XTick',1:numel(delays));
    set(gca,'XTickLabel',{sprintf('%.0f secs',delays(1)), sprintf('%.0f secs',delays(2)),sprintf('%.0f secs',delays(3)),sprintf('%.0f secs',delays(4))});
    ylabel('Mean response');
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    for d = 1:numel(delays)
        plot(0.5:4.5, ones(1,5).*(delays(d)./2), 'LineStyle','--','Color',[0.9 0.9 0.9]); % Plot accuracy line
    end
    
    dist = [-3.1*0.0875 -1*0.0875 1*0.0875 3.1*0.0875];
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            h = errorbar(d + dist(a), M(d,a),SEM(d,a));
            set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
        end
    end
    
    % Plot SDs
    subplot(2,1,2);
    hBar = bar(SD);
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
    for cc = 1:size(hBar,2)
        set(hBar(cc),'FaceColor',colors(cc,:),'EdgeColor',[1 1 1], 'BarWidth',1);
    end
    set(gca,'XTick',1:numel(delays));
    set(gca,'XTickLabel',{sprintf('%.0f secs',delays(1)), sprintf('%.0f secs',delays(2)),sprintf('%.0f secs',delays(3)),sprintf('%.0f secs',delays(4))});
    ylabel('Standard deviation');
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    
    dist = [-3.1*0.0875 -1*0.0875 1*0.0875 3.1*0.0875];
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            h = errorbar(d + dist(a), SD(d,a),SEM(d,a));
            set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
        end
    end
end
clearvars('-except',initialVars{:});
%% Mean response and SD across conditions - Individual participants
for x = participants
    figure;
    temp = trialData(trialData.id == x & trialData.flag == 0,:); % Select participant without outliers
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp.delay == delays(d) & temp.reward == amounts(a);
            M(d,a) = nanmean(temp.response(i));
            SD(d,a) = nanstd(temp.response(i));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(temp.response(i)));
        end
    end
    
    % Plot means
    subplot(2,1,1);
    hBar = bar(M);
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
    for cc = 1:size(hBar,2)
        set(hBar(cc),'FaceColor',colors(cc,:),'EdgeColor',[1 1 1], 'BarWidth',1);
    end
    set(gca,'XTick',1:numel(delays));
    set(gca,'XTickLabel',{sprintf('%.0f secs',delays(1)), sprintf('%.0f secs',delays(2)),sprintf('%.0f secs',delays(3)),sprintf('%.0f secs',delays(4))});
    ylabel('Mean response');
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    
    for d = 1:numel(delays)
        plot(0.5:4.5, ones(1,5).*(delays(d)./2), 'LineStyle','--','Color',[0.9 0.9 0.9]); % Plot accuracy line
    end
    
    dist = [-3.1*0.0875 -1*0.0875 1*0.0875 3.1*0.0875];
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            h = errorbar(d + dist(a), M(d,a),SEM(d,a));
            set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
        end
    end
    
    % Plot SDs
    subplot(2,1,2);
    hBar = bar(SD);
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
    for cc = 1:size(hBar,2)
        set(hBar(cc),'FaceColor',colors(cc,:),'EdgeColor',[1 1 1], 'BarWidth',1);
    end
    set(gca,'XTick',1:numel(delays));
    set(gca,'XTickLabel',{sprintf('%.0f secs',delays(1)), sprintf('%.0f secs',delays(2)),sprintf('%.0f secs',delays(3)),sprintf('%.0f secs',delays(4))});
    ylabel('Standard deviation of response');
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    
    dist = [-3.1*0.0875 -1*0.0875 1*0.0875 3.1*0.0875];
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            h = errorbar(d + dist(a), SD(d,a),SEM(d,a));
            set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
        end
    end
    suptitle(sprintf('Participant %.0f',x));
end
clearvars('-except',initialVars{:});
%% Standardise responses and perform ANOVA
for tidiness = 1
    
    temp = trialData(trialData.flag == 0,:); % Select all without outliers
    reward = categorical(temp.reward,'Ordinal',1);
    delay = categorical(temp.delay,'Ordinal',1);
    id = categorical(temp.id);
    
    % Test all participants
    anovan(temp.accuracy, {reward, delay, id}, ...
        'model', 'full', 'random', [3],...
        'varnames', char('Reward', 'Delay', 'id'));
    
    % Test all participants without 'Zero reward' group
    z = reward ~= '0';
    anovan(temp.response(z), {reward(z), delay(z), id(z)}, 'model', 'full', 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));
    
    % Test all participants with reward as continuous variable instead of
    % categorical
    conreward = trialData.reward(trialData.flag == 0);
    anovan(temp.response(z), {conreward(z), delay(z), id(z)}, 'model', 'full', 'continuous', [1], 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));
    
    % Paired t-tests between reward conditions
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:); % Select participant without outliers
    tests = combnk(unique(temp.reward),2);
    for r = 1:size(tests,1)
        i = temp.reward == tests(r,1);
        j = temp.reward == tests(r,2);
        [h(r),p(r)] = ttest2(temp.response(i), temp.response(j));
    end
    sig = tests(logical(h),:);
end
clearvars('-except',initialVars{:});
%% Fit psychophysical functions to individual participants
c = 1;
for x = participants
    temp = trialData(trialData.id==x & trialData.flag == 0,:); % Select participant without outliers
    temp.delay = temp.delay./2; % Divide objT by 2
    group = categorical(temp.reward,'Ordinal',1);
    
    % Fit function to all data
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp.delay, temp.response);
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    allFit(1,1:3) = [FO.k, FO.b, G.adjrsquare];
    
    % Fit function to each reward group
    for r = 1:4
        stevens =  'k*(x^b)'; % 3 parameter power function
        [xData, yData] = prepareCurveData(temp.delay(temp.reward == amounts(r)), temp.response(temp.reward == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    % subplot(5,4,c);
    g = gscatter(temp.delay,temp.response, group, [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    legend('Location','NorthWest');
    scatter(temp.delay(temp.flag==1),temp.response(temp.flag==1),'k*');
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556];
    xx = 0:0.001:5.5;
    y = allFit(1,1).*xx.^allFit(1,2);
    plot(xx,y, 'Color', [0.929 0.694 0.1250], 'LineStyle', '--');
    rewardFit = flipud(rewardFit);
    cc = 1;
    for z = 1:4
        y = rewardFit(z,1).*xx.^rewardFit(z,2);
        h = plot(xx,y,'Color', colors(cc,:));
        cc = cc + 1;
    end
    
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    title(sprintf('Psychophysical function for participant %.0f',x));
    
    c = c + 1;
end
clearvars('-except',initialVars{:});
%% Fit psychophysical functions to all normalised data, with histogram as third dimension
zScore = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData.id==x & trialData.flag == 0,:); % Select participant without outliers
        
        accuracy = zscore(temp.response - temp.delay./2);
        zScore = cat(1,zScore, accuracy);
        clearvars -except trialData participants zScore delays amounts
    end
    
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
    group = categorical(temp.reward,'Ordinal',1);
    zScore(temp.delay == delays(1),:) = zScore(temp.delay == delays(1),:) + 2;
    zScore(temp.delay == delays(2),:) = zScore(temp.delay == delays(2),:) + 3;
    zScore(temp.delay == delays(3),:) = zScore(temp.delay == delays(3),:) + 4;
    zScore(temp.delay == delays(4),:) = zScore(temp.delay == delays(4),:) + 5;
    temp.delay = temp.delay./2; % Divide objT by 2
    
    % Fit function to all data
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp.delay, zScore);
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    allFit(1,1:3) = [FO.k, FO.b, G.adjrsquare];
    
    % Fit function to each reward group
    for r = 1:4
        stevens =  'k*(x^b)'; % 3 parameter power function
        [xData, yData] = prepareCurveData(temp.delay(temp.reward == amounts(r)),...
            zScore(temp.reward == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    g = gscatter(temp.delay,zScore, group,...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    scatter(temp.delay(temp.flag==1),temp.response(temp.flag==1),'k*');
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556];
    xx = 0:0.001:5.5;
    y = allFit(1,1).*xx.^allFit(1,2);
    plot(xx,y, 'Color', [0.929 0.694 0.1250], 'LineStyle', '--');
    rewardFit = flipud(rewardFit);
    cc = 1;
    for z = 1:4
        y = rewardFit(z,1).*xx.^rewardFit(z,2);
        h = plot(xx,y,'Color', colors(cc,:));
        cc = cc + 1;
    end
    
    hist3(gca,[temp.delay,temp.response],[4 25],...
        'FaceAlpha', 0.2, 'EdgeAlpha',0.2, 'FaceColor',[0.9 0.9 0.9]);
    set(gca,'CameraPosition', [-0.6831 -22.3766 255.8894]);
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    title('Psychophysical function for all participants');
end
clearvars('-except',initialVars{:});
%% Fit psychophysical functions to individual participants, with histogram as third dimension
for x = participants
    temp = trialData(trialData.id==x & trialData.flag == 0,:); % Select participant without outliers
    group = categorical(temp.reward,'Ordinal',1);
    temp.delay = temp.delay./2; % Divide objT by 2
    
    % Fit function to all data
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp.delay, temp.response);
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    allFit(1,1:3) = [FO.k, FO.b, G.adjrsquare];
    
    % Fit function to each reward group
    for r = 1:4
        stevens =  'k*(x^b)'; % 3 parameter power function
        [xData, yData] = prepareCurveData(temp.delay(temp.reward == amounts(r)),...
            temp.response(temp.reward == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    % subplot(5,4,c);
    g = gscatter(temp.delay,temp.response, group,...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    scatter(temp.delay(temp.flag==1),temp.response(temp.flag==1),'k*');
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556];
    xx = 0:0.001:5.5;
    y = allFit(1,1).*xx.^allFit(1,2);
    plot(xx,y, 'Color', [0.929 0.694 0.1250], 'LineStyle', '--', 'LineWidth',1);
    rewardFit = flipud(rewardFit);
    cc = 1;
    for z = 1:4
        y = rewardFit(z,1).*xx.^rewardFit(z,2);
        h = plot(xx,y,'Color', colors(cc,:), 'LineWidth',3);
        cc = cc + 1;
    end
    
    hist3(gca,[temp.delay,temp.response], 'FaceAlpha', 0.2,...
        'EdgeAlpha',0.2, 'FaceColor',[0.9 0.9 0.9]);
    set(gca,'CameraPosition', [-0.6831 -22.3766 255.8894]);
    
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    zlabel('Response frequency');
    set(gcf, 'Color', [1 1 1]);
    title(sprintf('Psychophysical function for participant %.0f',x));
end
clearvars('-except',initialVars{:});
%% Calculate means and summary stats
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
temp.accuracy = temp.response - temp.delay./2;
summary(temp);

inputVar = {'accuracy'};
groupVar = {'id','delay','reward'};

output = varfun(@mean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

%% Correlations
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);

% Accuracy and reward
X = temp.normAccuracy;
Y = temp.reward;
lag = 1;

[r, p] = corr(X, Y, 'rows', 'complete');
[r1, p1] = corr(X, cat(1,repmat([0],lag,1), Y(1:end-lag)), 'rows', 'complete');
fprintf('Correlation of accuracy and reward.\nr:%.3f\np:%.3f\n',r,p);
fprintf('Correlation of accuracy and reward with lag of %.0f.\nr:%.3f\np:%.3f\n',lag,r1,p1);

% Accuracy and pleasantness
X = temp.normAccuracy;
Y = temp.normIntPleasantness;
lag = 1;

[r, p] = corr(X, Y, 'rows', 'complete');
fprintf('Correlation of accuracy and pleasantness.\nr:%.3f\np:%.3f\n',r,p);

% Binned accuracy and pleasantness
dependentVar = 'normAccuracy';
temp = sortrows(temp,[2 3]); % Make sure data is in chronological order (ignore id)
divisions = round(linspace(60,200,8+1));

for bin = 1:8
    divLabels{bin} = sprintf('%.0f - %.0f',divisions(bin),divisions(bin+1));
    subtemp = temp(temp.trial > divisions(bin) &  temp.trial < divisions(bin+1),:);
    meanBin(bin) = nanmean(table2array(subtemp(:,dependentVar)));
end

% Concatenate pleasantness ratings
zPleasantness = [];
for x = participants
    zPleasantness = cat(2,zPleasantness,trialData.pleasantness(trialData.id == x & ~isnan(trialData.pleasantness)));
end
pleasantnessVal = mean(zPleasantness,2);

[r, p] = corr(meanBin', pleasantnessVal, 'rows', 'complete');
fprintf('Correlation of binned accuracy and pleasantness.\nr:%.3f\np:%.3f\n',r,p);
clearvars('-except',initialVars{:});

%% History effects

iti = 9; % Trial time (not including delay)
window = 60; % Moving window in seconds


