%% Set included participants and graph settings
participants = [1:17,19:26];
% So far, participant 4 and 9 have relatively high autocorrelation
% functions. Participant 6 chronically underestimates (also has "U-shaped"
% response curve).
set(0,'DefaultAxesColorOrder',...
    [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
%colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
colormap = [0 60 100; 0 113.985 188.955; 0 153 255; 160 210 255]./255;
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultAxesFontSize',20);
%% Identify unique amounts and delays
amounts = unique(trialData.reward);
delays = unique(trialData.delay);
%% Removed missed and identify outliers using an arbitrary threshold and add exclusion variable to trialData
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
clearvars -except trialData amounts delays participants

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
    trialData.normThirst = nan(height(trialData),1);
    trialData.normPleasantness = nan(height(trialData),1);
    trialData.intThirst = nan(height(trialData),1);
    trialData.intPleasantness = nan(height(trialData),1);
    trialData.normIntThirst = nan(height(trialData),1);
    trialData.normIntPleasantness = nan(height(trialData),1);
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
        trialData.normThirst(~isnan(trialData.thirst)) = (trialData.thirst(~isnan(trialData.thirst)) - min(trialData.thirst(~isnan(trialData.thirst))))...
            ./ (max(trialData.thirst(~isnan(trialData.thirst))) - min(trialData.thirst(~isnan(trialData.thirst))));
        trialData.normPleasantness(~isnan(trialData.thirst)) = (trialData.pleasantness(~isnan(trialData.pleasantness)) - min(trialData.pleasantness(~isnan(trialData.pleasantness))))...
            ./ (max(trialData.pleasantness(~isnan(trialData.pleasantness))) - min(trialData.pleasantness(~isnan(trialData.pleasantness))));
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
    
    % Theoretically relevant condition variables
    trialData.rateReward = trialData.reward ./ (trialData.delay); % Reward rate with ITI
    trialData.lagRateReward = trialData.lagReward ./ (trialData.lagDelay); % Reward rate with ITI
    trialData.TIMERR = (trialData.reward - (tsmovavg(trialData.rateReward,'s',3,1).*trialData.delay))...
        ./(1+(trialData.delay/((7+9)*5))); % Subjective value as per TIMMER, uses an average trial length to calculate window of integration
    trialData.predError = trialData.reward - tsmovavg(trialData.rateReward,'e',4,1);
    
    trialData.RPE = (trialData.delay - 1) ./ 0.2; % RPE from Fiorillo
    trialData.conventionalRPE = trialData.reward - (trialData.reward./trialData.delay); % RPE from Fiorillo - not scaled
end
clearvars -except trialData amounts delays participants TIME
initialVars = who;
initialVars{end+1} = 'initialVars';
clearvars('-except',initialVars{:});

%% Truncate trials with smaller than median pleasantness
for x = participants
    i = trialData.id == x & trialData.flag == 0;
   mPleasantness = nanmedian(trialData.pleasantness(i));
   trialData.flag(i) = trialData.flag(i) + trialData.intPleasantness(i) < mPleasantness;
   clearvars i mPleasantness cutIndex
end

%% Binned accuracy and pleasantness
factor =[];
dependentVar = 'normAccuracy';
ratingsVar = {'normThirst', 'normPleasantness'};
numBins = 6;
normalise2baseline = 0;
ratingScaleY = 1;
ratingShift = 0.65;
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
    c = plot((temp.totalvolume./max(temp.totalvolume))*10);
    xlim([40, 200]);
    ylim([0 10]);
    xlabel('Trial');
    legend([t p c],'Thirst','Pleasantness','Cumulative reward');
    title(sprintf('Participant %.0f',x));
end
clearvars('-except',initialVars{:});
%% Binned accuracy with no reward - All participants
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
    set(hBar(1),'FaceColor',[0.85 0.325 0.098],'EdgeColor','none');
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',...
        {'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eighth','Ninth','Tenth'});
    title('Mean accuracy');
    ylabel('Deviation (seconds)');
    hold on
    if separateReward
        set(hBar(2),'FaceColor',[0 0.447 0.741],'EdgeColor','none', 'BarWidth',1);
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
%% Binned accuracy with no reward - Individual participants
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
        
    subplot(5,5,c);
    if separateReward
        meanBin = [meanBin;meanBin0]';
        semBin = [semBin;semBin0]';
    end
    hBar = bar(meanBin);
    set(hBar(1),'FaceColor',[0.85 0.325 0.098],'EdgeColor','none');
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',...
        {'1','2','3','4','5','6','7','8','9','10'});
    title(sprintf('Participant %.0f',x));
    ylabel('Deviation (seconds)');
    ylim([-1 1]);
    hold on
    if separateReward
        set(hBar(2),'FaceColor',[0 0.447 0.741],'EdgeColor','none','BarWidth',1);
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
    c = c + 1;
end
suptitle('Mean accuracy');
clearvars('-except',initialVars{:});
%% No reward conditions - All participants
for tidiness = 1
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:); % Select participant without outliers
    
    M(1) = nanmean(temp.normAccuracy(temp.session == 1));
    M(2) = nanmean(temp.normAccuracy(temp.session == 2 & temp.reward == 0));
    M(3) = nanmean(temp.normAccuracy(temp.session == 3));
    S(1) = nanstd(temp.normAccuracy(temp.session == 1)) ./ sqrt(numel(temp.accuracy(temp.session == 1)));
    S(2) = nanstd(temp.normAccuracy(temp.session == 2 & temp.reward == 0))...
        ./ sqrt(numel(temp.normAccuracy(temp.session == 2 & temp.reward == 0)));
    S(3) = nanstd(temp.normAccuracy(temp.session == 3)) ./ sqrt(numel(temp.accuracy(temp.session == 3)));
    
    figure;
    hBar = bar(M);
    set(hBar(1),'FaceColor',[0 0.447 0.741],'EdgeColor','none');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',...
        {'First baseline','Main Task','Second baseline'});
    title('No reward conditions');
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(M,S);
    set(h,'linestyle','none');
    set(h, 'Color', [0 0 0]);
end
clearvars('-except',initialVars{:});
%% No reward conditions - Individuals participants
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0,:); % Select participant without outliers

    M(1) = nanmean(temp.accuracy(temp.session == 1));
    M(2) = nanmean(temp.accuracy(temp.session == 2 & temp.reward == 0));
    M(3) = nanmean(temp.accuracy(temp.session == 3));
    S(1) = nanstd(temp.accuracy(temp.session == 1)) ./ sqrt(numel(temp.accuracy(temp.session == 1)));
    S(2) = nanstd(temp.accuracy(temp.session == 2 & temp.reward == 0))...
        ./ sqrt(numel(temp.accuracy(temp.session == 2 & temp.reward == 0)));
    S(3) = nanstd(temp.accuracy(temp.session == 3)) ./ sqrt(numel(temp.accuracy(temp.session == 3)));
    
    figure;
    hBar = bar(M);
    set(hBar(1),'FaceColor',[0 0.447 0.741],'EdgeColor','none');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',...
        {'First baseline','Main Task','Second baseline'});
    title(sprintf('Participant %.0f, no reward conditions',x));
    ylabel('Deviation (seconds)');
    hold on
        h = errorbar(M,S);
        set(h,'linestyle','none');
        set(h, 'Color', [0 0 0]);
end
clearvars('-except',initialVars{:});
%% Accuracy by trial - All participants
for tidiness = 1;
    for t = 1:max(trialData.trial)
        i = trialData.trial == t;
        M(t) = nanmean(trialData.normAccuracy(i));
    end
    
    figure;
    plot(1:max(trialData.trial),M);
    hold on
    plot(1:max(trialData.trial), zeros(1,max(trialData.trial)), 'LineStyle','--');
    xlim([0 max(trialData.trial)]);
    ylim([-1 1]);
    ylabel('Devation (secs)');
    xlabel('Trial number');
    title('All participants');
    
    for s = [1, 2, 3]
        i = trialData.session == s;
        subTrials = trialData.trial(i);
        subScore = trialData.normAccuracy(i);
        c = 1;
        for t = min(subTrials):max(subTrials)
            j = subTrials == t;
            score(c) = nanmean(subScore(j));
            c = c + 1;
        end
        plot(min(subTrials):max(subTrials),score);
        clearvars subTrials subScore score c
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
IV = 'lagReward';
DV = 'response';
for tidiness = 1
    temp = trialData(ismember(trialData.id, participants),:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp.delay == delays(d) & ismember(table2array(temp(:,IV)),amounts(a));
            M(d,a) = nanmean(table2array(temp(i,DV)));
            SD(d,a) = nanstd(table2array(temp(i,DV)));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(table2array(temp(i,DV))));
        end
    end
    
    % Plot means
    figure;
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
    if strcmp(DV,'normAccuracy')
        ylim([-0.3 0.3]);
    elseif strcmp(DV,'accuracy')
        ylim([-0.5 0.5]);
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
%% Compare normalised responses across rewards - All participants
DV = 'normAccuracy';
for tidiness = 1
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    
    for a = 1:numel(amounts)
        i = ismember(temp.lagReward,amounts(a));
        M(a) = nanmean(table2array(temp(i,DV)));
        SD(a) = nanstd(table2array(temp(i,DV)));
        SEM(a) = SD(a) ./ sqrt(numel(table2array(temp(i,DV))));
    end
    
    % Plot means
    figure;
    hBar = bar(M');
    set(hBar,'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1], 'BarWidth',1);
    set(gca,'XTick',1:numel(amounts));
  set(gca,'XTickLabel',{'No reward','Small reward','Medium reward','Large reward'})
  ylabel('Normalised response');
    hold on
    h = errorbar(M,SEM);
    set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
    
%     % Plot SDs
%         subplot(2,1,2);
%         hBar = bar(SD);
%         set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1], 'BarWidth',1);
%         set(gca,'XTick',1:numel(amounts));
%         set(gca,'XTickLabel',{sprintf('%.2f mL',amounts(1)), sprintf('%.2f mL',amounts(2)),sprintf('%.2f mL',amounts(3)),sprintf('%.2f mL',amounts(4))});
%         ylabel('Standard deviation');
%         hold on
%         h = errorbar(SD,SEM);
%         set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
%     
end
clearvars('-except',initialVars{:});
%% Compare normalised responses across rewards - Individual participants
DV = 'response';
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0,:);
    
    for a = 1:numel(amounts)
        i = temp.lagReward == amounts(a);
        M(a) = nanmean(table2array(temp(i,DV)));
        SD(a) = nanstd(table2array(temp(i,DV)));
        SEM(a) = SD(a) ./ sqrt(numel(table2array(temp(i,DV))));
    end
    
    % Plot means
    figure;
    hBar = bar(M');
    set(hBar,'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1], 'BarWidth',1);
    set(gca,'XTick',1:numel(amounts));
  set(gca,'XTickLabel',{'No reward','Small reward','Medium reward','Large reward'})
  ylabel('Normalised response');
    hold on
    h = errorbar(M,SEM);
    set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
    title(sprintf('Participant %.0f',x));
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
    
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:); % Select all without outliers
    reward = categorical(temp.reward,'Ordinal',1);
    lagReward = categorical(temp.lagReward,'Ordinal',1);
    delay = categorical(temp.delay,'Ordinal',1);
    id = categorical(temp.id);
    lagDelay = categorical(temp.lagDelay);
    
    % Test all participants
    [P,T,STATS,TERMS] = anovan(temp.response, {reward, delay, id}, ...
        'model', 2, 'random', [3],...
        'varnames', char('Reward', 'Delay', 'id'));
    
    % Test all participants without 'Zero reward' group
    z = reward ~= '0';
    [P,T,STATS,TERMS] = anovan(temp.response(z), {lagReward(z), delay(z), id(z)}, 'model', 'full', 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));
    
    % Test all participants with reward as continuous variable instead of
    % categorical
    conreward = trialData.lagReward(trialData.flag == 0);
   [P,T,STATS,TERMS] = anovan(temp.response(z), {conreward(z), delay(z), id(z)}, 'model', 'full', 'continuous', [1], 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));
    
    % Independent samples t-tests between reward conditions
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:); % Select participant without outliers
    tests = combnk(unique(temp.reward),2);
    for d = 1:numel(delays)
    temp2 = trialData(ismember(trialData.id, participants) & trialData.delay == delays(d) & trialData.flag == 0,:); % Select participant without outliers
    for r = 1:size(tests,1)
        i = temp2.reward == tests(r,1);
        j = temp2.reward == tests(r,2);
        [h(r,d),p(r,d)] = ttest2(temp2.normResponse(i), temp2.normResponse(j));
    end
    end
   % sig = tests(logical(h),:);
end
clearvars('-except',initialVars{:});
%% Paired t-tests
DV = 'normAccuracy';
for tidiness = 1
    % Paired tests within each delay condition
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    id = unique(trialData.id(ismember(trialData.id, participants)));
    
    for x = 1:numel(id)
        for d = 1:numel(delays)
            for a = 1:numel(amounts)
                i = temp.id == id(x) & temp.delay == delays(d) & temp.lagReward == amounts(a);
                M(x,a,d) = nanmean(table2array(temp(i,DV)));
            end
        end
    end
    
    figure;
    %limits = {[-2 0.25],[-0.8 0.2],[0 0.7],[0 1.7]};
    for d = 1:numel(delays)
         MEANS = nanmean(M(:,:,d));
         SEM = nanstd(M(:,:,d))./sqrt(size(M,1));
        % Plot means
    subplot(2,2,d);
    hBar = bar(MEANS);
    set(hBar,'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1], 'BarWidth',1);
    set(gca,'XTick',1:numel(amounts));
    set(gca,'XTickLabel',{'No reward','Small','Medium','Large'});
    ylabel('Normalised response');
   
   % ylim(limits{d});
   ylim([-.2 .3]);
    hold on
    h = errorbar(MEANS,SEM);
    set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
    
    % Check significance
      tests = combnk(1:4,2);
        for r = 1:size(tests,1)
            [h,p] = ttest(M(:,tests(r,1),d),M(:,tests(r,2),d));
            if h == 1
            fprintf('Between rewards %.1fmL and %.1fmL at %.0f seconds\nh: %.0f\np: %.5f\n',...
            amounts(tests(r,1)),amounts(tests(r,2)),delays(d),h,p);
            end
        end
        
    title(sprintf('%.0f seconds',delays(d)));
    clearvars MEANS SEM
    end
    
    % Paired tests collapsing delay condition
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    id = unique(trialData.id(ismember(trialData.id, participants)));
    
    for x = 1:numel(id)
        for a = 1:numel(amounts)
            i = temp.id == id(x) & temp.reward == amounts(a);
            M(x,a) = nanmean(table2array(temp(i,'normResponse')));
        end
    end
    
    tests = combnk(1:4,2);
    for r = 1:size(tests,1)
        [h,p] = ttest(M(:,tests(r,1)),M(:,tests(r,2)));
        if h == 1
            fprintf('Between rewards %.1fmL and %.1fmL\nh: %.0f\np: %.5f\n',...
                amounts(tests(r,1)),amounts(tests(r,2)),h,p);
        end
    end
end
%% Fit psychophysical functions - All participants
for tidiness = 1
    
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
    group = categorical(temp.lagReward,'Ordinal',1);
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
        [xData, yData] = prepareCurveData(temp.delay(temp.lagReward == amounts(r)),...
            temp.response(temp.lagReward == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    g = gscatter(temp.delay,temp.response, group,...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    scatter(temp.delay(temp.flag==1),temp.response(temp.flag==1),'k*');
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556];
    xx = 0:0.001:5.5;
    y = allFit(1,1).*xx.^allFit(1,2);
    plot(xx,y, 'Color', [0.929 0.694 0.1250], 'LineStyle', '--');
    cc = 1;
    for z = 1:4
        y = rewardFit(z,1).*xx.^rewardFit(z,2);
        h = plot(xx,y,'Color', colors(cc,:));
        cc = cc + 1;
    end
    
    ylim([0 10]);
    
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    title('Psychophysical function for all participants');
end
clearvars('-except',initialVars{:});
%% Fit psychophysical functions - Individual participants
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
        [xData, yData] = prepareCurveData(temp.delay(temp.lagReward == amounts(r)), temp.response(temp.lagReward == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
        psychFits(c,r) = FO.b;
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
%clearvars('-except',initialVars{:});
%% Fit psychophysical functions with histogram as third dimension - All participants
zScore = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData.id==x & trialData.flag == 0,:); % Select participant without outliers
        
        accuracy = zscore(temp.response - temp.delay./2);
        zScore = cat(1,zScore, accuracy);
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
%% Fit psychophysical functions with histogram as third dimension - Individual participants
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
summary(temp);

inputVar = {'response'};
groupVar = {'delay'};

output = varfun(@mean, temp, ...
    'InputVariables', inputVar,...
    'GroupingVariables',groupVar);

%% Calculate and plot summary stats
for tidiness = 1
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);

    % Means
    inputVar = {'response'};
    groupVar = {'delay'};
    output = varfun(@mean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    M = output.mean_response;
    % SD
    output = varfun(@std, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    SD = output.std_response;
    % Range
    inputVar = {'response'};
    groupVar = {'delay','id'};
    output = varfun(@mean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    for d = 1:4
        range(d,1:2) = [min(output.mean_response(output.delay == delays(d))),max(output.mean_response(output.delay == delays(d)))];
    end
    % Plot
    figure;
    hBar = bar(M);
    set(hBar,'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1], 'BarWidth',1);
    set(gca,'XTick',1:numel(amounts),'XTickLabel',{'4 seconds','6 seconds','8 seconds','10 seconds'});
    ylabel('Mean response (secs)');
    hold on
    h = errorbar(M,SD,'Color', [0.85 0.325 0.098],'LineWidth',3,'LineStyle', 'none');
     for d = 1:numel(delays)
        plot(0.5:4.5, ones(1,5).*(delays(d)./2), 'LineStyle','--','Color',[0.8 0.8 0.8]); % Plot accuracy line
    end
end
clearvars('-except',initialVars{:});

%% Correlations
for tidiness = 1
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);

% Accuracy and reward
X = temp.normAccuracy;
Y = temp.reward;
lag = [1:5];

[r, p] = corr(X, Y, 'rows', 'complete','type','spearman');
fprintf('Correlation of accuracy and reward.\nr:%.3f\np:%.3f\n',r,p);
for l = 1:numel(lag)
[r1, p1] = corr(X, cat(1,repmat([0],lag(l),1), Y(1:end-lag(l))), 'rows', 'complete','type','spearman');
fprintf('Correlation of accuracy and reward with lag of %.0f.\nr:%.3f\np:%.3f\n',lag(l),r1,p1);
end

% Accuracy and pleasantness
X = temp.accuracy;
Y = temp.intPleasantness;

[r, p] = corr(X, Y, 'rows', 'complete','type','spearman');
fprintf('Correlation of accuracy and interpolated pleasantness.\nr:%.3f\np:%.3f\n',r,p);

% Binned accuracy and pleasantness
dependentVar = 'accuracy';
temp = sortrows(temp,[2 3]); % Make sure data is in chronological order (ignore id)
divisions = round(linspace(40,200,8+1));

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

[r, p] = corr(meanBin', pleasantnessVal, 'rows', 'complete','type','spearman');
fprintf('Correlation of binned accuracy and pleasantness.\nr:%.3f\np:%.3f\n',r,p);
clearvars('-except',initialVars{:});
end

%% Moving averages of pleasantness and accuracy - All participants
window = 1; % 47
for tidiness = 1
temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
temp = sortrows(temp,3);

% Averages for each trial 
c = 1;
for t = min(temp.trial):max(temp.trial)
        i = temp.trial == t;
        M(c) = nanmean(temp.normAccuracy(i));
        R(c) = nanmean(temp.intPleasantness(i));
        c = c + 1;
end

averageR = tsmovavg(R,'s',window,2); % 's' is static, 'e' is exponential decay
averageT = tsmovavg(M,'s',window,2); % 's' is static, 'e' is exponential decay
[r,p] = corr(R',M','type','pearson','rows','complete');
if p < 0.05
    fprintf('Pearson correlation at window %.0f\nr: %.3f\np: %.3f\n',window,r,p);
end
[r,p] = corr(R',M','type','spearman','rows','complete');
if p < 0.05
    fprintf('Spearman correlation at window %.0f\nr: %.3f\np: %.3f\n',window,r,p);
end
figure;
ax = plotyy(0:size(averageR,2)-window, averageR(window:end), 0:size(averageT,2)-window,averageT(window:end));
ylabel(ax(1),'Moving average of pleasantness');
ylabel(ax(2),'Moving average of accuracy');
xlabel('Trial');
end
%clearvars('-except',initialVars{:});

%% Moving averages of pleasantness and accuracy - Individual pariticpants
window = 1;
figure;
c = 1;
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0 & trialData.session == 2,:);
    temp = sortrows(temp,3);    
    averageR = tsmovavg(temp.intPleasantness,'s',window,1); % 's' is static, 'e' is exponential decay
    averageT = tsmovavg(temp.accuracy,'s',window,1); % 's' is static, 'e' is exponential decay
    [r,p] = corr(averageT,averageR,'type','pearson','rows','complete');
    if p < 0.05
        fprintf('Participant %.0f\nPearson correlation at window %.0f\nr: %.3f\np: %.3f\n',x,window,r,p);
    end
    [r,p] = corr(averageT,averageR,'type','spearman','rows','complete');
    if p < 0.05
        fprintf('Participant %.0f\nSpearman correlation at window %.0f\nr: %.3f\np: %.3f\n',x,window,r,p);
    end
    
subplot(5,5,c);
ax = plotyy(-sum(isnan(averageR(10:end))):size(averageR,1)-window-sum(isnan(averageR(10:end))), averageR(window:end),...
    0:size(averageT,1)-window,averageT(window:end));
ylabel(ax(1),'Pleasantness');
ylabel(ax(2),'Accuracy');
xlabel('Trial');
xlim(ax(1),[0 160-window]);
xlim(ax(2),[0 160-window]);
c = c + 1;
end
clearvars('-except',initialVars{:});

%% History effects - All participants
window = 1;
for tidiness = 1
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
% Averages for each trial 
c = 1;
for t = min(temp.trial):max(temp.trial)
        i = temp.trial == t;
        M(c) = nanmean(temp.normAccuracy(i));
        R(c) = nanmean(temp.lagRateReward(i));
        c = c + 1;
 end
 
averageR = tsmovavg(R,'s',window,2); % 's' is static, 'e' is exponential decay
averageT = tsmovavg(M,'s',window,2); % 's' is static, 'e' is exponential decay

figure;
subplot(311);
ax = plotyy(1:size(averageR,2), averageR, 1:size(averageT,2),averageT);
ylabel(ax(1),'Moving average of reward');
ylabel(ax(2),'Moving average of accuracy');

maxLag = 4;
[acf,lags,bounds] = autocorr(averageR(window:end));
[acor,lag] = xcorr(averageR(window:end),averageT(window:end),maxLag,'unbiased');
[r,p] = corrcoef(averageR,averageT,'rows','pairwise');
fprintf('Cross correlation:\nr: %.3f\np: %.3f\n',r(2),p(2));
% [r,p] = corr(averageR',averageT','rows','complete');
% fprintf('Pearson correlation:\nr: %.3f\np: %.3f\n',r,p);
diff = abs((averageR - nanmean(averageR))-(averageT - nanmean(averageT)));
    [~,I] = max(abs(acor));
    timeDiff = lag(I)
%     figure;
%     subplot(311); plot(averageR); title('Average reward');
%     subplot(312); plot(averageT); title('Accuracy');
subplot(312); plot(diff); ylabel('Difference');
    subplot(313); plot(lag,acor); ylabel('Correlation'); xlabel('Lags');
end
clearvars('-except',initialVars{:});

%% History effects - Individual participants
window = 3;
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0 & trialData.session == 2,:);
    temp = sortrows(temp,3);
    
    averageR = tsmovavg(temp.reward,'s',window,1); % 's' is static, 'e' is exponential decay
    averageT = tsmovavg(temp.normAccuracy,'s',window,1); % 's' is static, 'e' is exponential decay
figure;
subplot(211);
ax = plotyy(1:size(averageR,1), averageR, 1:size(averageT,1),averageT);
ylabel(ax(1),'Moving average of reward');
ylabel(ax(2),'Moving average of accuracy');
[acor,lag] = xcorr(averageR(window:end), averageT(window:end),3);
    [~,I] = max(abs(acor));
    subplot(212);
    plot(lag,acor);
    title(sprintf('Participant %.0f',x));
    fprintf('Participant %.0f\nMaximum xcorr at lag of %.0f\n',x,lag(I));
end
clearvars('-except',initialVars{:});

%% Histograms - All participants
for tidiness = 1
    rewardStrings = {'No reward','Small reward','Medium reward','Large reward'};
    delayStrings = {'2 seconds','3 seconds','4 seconds','5 seconds'};
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
    for d = 1:numel(delays)
        temp2 = temp(temp.delay == delays(d),:);
        D{d} = temp2.response;
        for a = 1:numel(amounts)
            temp3 = temp(temp.lagReward == amounts(a),:);
            R{a} = temp3.accuracy;
            temp4 = temp(temp.lagReward == amounts(a) & temp.delay == delays(d),:);
            DR{d,a} = temp4.response;
        end
    end
    
    % Plot responses split by delay
    figure;
    nhist(D,'smooth','legend',delayStrings,...
        'decimalplaces',0,'xlabel','Response (secs)','ylabel','Probability density function','color','colormap','fsize',25);
    objs = findobj;
    objs(4).XGrid = 'on';
    %objs(4).XMinorTick = 'off';
    %objs(4).XTick = [0:0.5:8];
    %title('Delays');
    
    % Plot responses split by reward
    figure;
    nhist(R,'smooth','legend',rewardStrings,...
        'precision',3,'xlabel','Seconds','ylabel','PDF','color','colormap','serror','fsize',20);
    objs = findobj;
    objs(5).XGrid = 'on';
    objs(5).XMinorTick = 'on';
    objs(5).XTick = [-4:0.5:4];
    title('Rewards');
    
    % Plot responses normalised by delay (scalar superimposition)
    for s = 1:4
        S{s} = (D{s})./(delays(s)./2);
    end
    figure;
    [~,N,X] = nhist(S,'smooth','legend',delayStrings,...
        'decimalplaces',1,'xlabel','Seconds','ylabel','PDF','color','colormap','fsize',20);
    objs = findobj;
    objs(6).XGrid = 'on';
    objs(6).XMinorTick = 'on';
    objs(6).XTick = [0:0.5:8];
    title('Relative delays');
    % (With relative responses)
    figure;
    for s = 1:4
        N{s} = N{s}./max(N{s});
        plot(X{s},N{s});hold on;
    end
        
    
    % Plot response split by delay and reward
    figure;
    for d = 1:numel(delays)
        subplot(2,2,d);
        nhist(DR(d,:),'smooth',...
            'precision',3,'xlabel','Seconds','ylabel','PDF','color','colormap','serror','fsize',20);
        title(sprintf('%.0f seconds',delays(d)),'FontSize',10);
    end
end
clearvars('-except',initialVars{:});

%% Fit and plot distributions - All participants
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0,:);
% Delay
[wei,~] = fitdist(temp.response,'weibull','by',nominal(temp.delay));
[norm,~] = fitdist(temp.response,'normal','by',nominal(temp.delay));
[gamma,~] = fitdist(temp.response,'gamma','by',nominal(temp.delay));
figure; hold on;
for d = 1:4
    plot(pdf(norm{d},0:0.05:8));
end
legend({'2 seconds','3 seconds','4 seconds','5 seconds'});
ylabel('PDF');
set(gca,'XTick',[]);
xlabel('Time');
% Reward
[wei,~] = fitdist(temp.response,'weibull','by',nominal(temp.lagReward));
[norm,~] = fitdist(temp.response,'normal','by',nominal(temp.lagReward));
[gamma,~] = fitdist(temp.response,'gamma','by',nominal(temp.lagReward));
figure; hold on;
for d = 1:4
    plot(pdf(norm{d},0:0.05:8));
end
legend({'No reward','Small reward','Medium reward','Large reward'});
ylabel('PDF');
set(gca,'XTick',[]);
xlabel('Time');

clearvars('-except',initialVars{:});

%% Plot normality - Individual participants
plots = 'scaled'; % Choose hist, CDF, prob, all or scaled
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0,:);
    switch plots
        case 'hist'
            figure;
            for d = 1:4
                subplot(2,2,d);
                %plot(pdf(norm{d},0:0.05:8));
                histfit(temp.response(temp.delay == delays(d)));
                title(sprintf('%.0f seconds',delays(d)));
            end
            suptitle('Histograms');
        case 'CDF'
            figure;
            for d = 1:4
                subplot(2,2,d);
                cdfplot(temp.response(temp.delay == delays(d)));
                hold on;
                xx = min(temp.response(temp.delay == delays(d))):0.1:max(temp.response(temp.delay == delays(d)));
                p = normcdf(xx,nanmean(temp.response(temp.delay == delays(d))),nanstd(temp.response(temp.delay == delays(d))));
                plot(xx,p);
                title(sprintf('%.0f seconds',delays(d)));
                legend('Empirical','Theoretical','Location','NW')
            end
            suptitle('CDF');
        case 'prob'
            figure;
            for d = 1:4
                subplot(2,2,d);
                normplot(temp.response(temp.delay == delays(d)));
                title(sprintf('%.0f seconds',delays(d)));
            end
            suptitle('Normal probability plots');
        case 'all'
            figure;
            cdfplot(temp.response);
            hold on;
            xx = min(temp.response):0.1:max(temp.response);
            p = normcdf(xx,nanmean(temp.response),nanstd(temp.response));
            plot(xx,p);
            title(sprintf('Participant %.0f',x));
            legend('Empirical','Theoretical','Location','NW')
        case 'scaled'
             figure;
            cdfplot((temp.response)./(temp.delay./2));
            hold on;
            xx = min((temp.response)./(temp.delay./2)):0.1:max((temp.response)./(temp.delay./2));
            p = normcdf(xx,nanmean((temp.response)./(temp.delay./2)),nanstd((temp.response)./(temp.delay./2)));
            plot(xx,p);
            title(sprintf('Participant %.0f',x));
            legend('Empirical','Theoretical','Location','NW')
    end
end
clearvars('-except',initialVars{:});
%% Test normality - Individual participants
tests = 'all'; % Choose delay, all or scaled
for tidiness = 1
switch tests
    case 'delay'
        for x = participants
            temp = trialData(trialData.id == x & trialData.flag == 0,:);
            for d = 1:4
                [lilSig(x,d),lilP(x,d)] = lillietest(temp.response(temp.delay == delays(d)));
                [ksSig(x,d),ksP(x,d)] = kstest(temp.response(temp.delay == delays(d)));
                [jbSig(x,d),jbP(x,d)] = jbtest(temp.response(temp.delay == delays(d)));
            end
        end
    case 'all'
        for x = participants
            temp = trialData(trialData.id == x & trialData.flag == 0,:);
            [lilSig(x),lilP(x)] = lillietest(temp.response);
            [ksSig(x),ksP(x)] = kstest(temp.response);
            [jbSig(x),jbP(x)] = jbtest(temp.response);
        end
    case 'scaled'
        for x = participants
            temp = trialData(trialData.id == x & trialData.flag == 0,:);
                [lilSig(x),lilP(x)] = lillietest((temp.response)./(temp.delay./2));
                [ksSig(x),ksP(x)] = kstest((temp.response)./(temp.delay./2));
                [jbSig(x),jbP(x)] = jbtest((temp.response)./(temp.delay./2));
        end
        case 'accuracy'
        for x = participants
            temp = trialData(trialData.id == x & trialData.flag == 0,:);
                [lilSig(x),lilP(x)] = lillietest(temp.accuracy);
                [ksSig(x),ksP(x)] = kstest(temp.accuracy);
                [jbSig(x),jbP(x)] = jbtest(temp.accuracy);
        end
            case 'scaledAccuracy'
        for x = participants
            temp = trialData(trialData.id == x & trialData.flag == 0,:);
                [lilSig(x),lilP(x)] = lillietest(temp.normAccuracy);
                [ksSig(x),ksP(x)] = kstest(temp.normAccuracy);
                [jbSig(x),jbP(x)] = jbtest(temp.normAccuracy);
        end
end
end
disp(lilSig);
disp(ksSig);
disp(jbSig);
clearvars('-except',initialVars{:});

%% Autocorrelation
figure;
c = 1;
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0,:);
    subplot(5,5,c);
    autocorr(temp.accuracy);
    title(sprintf('Participant %.0f',x));
    c = c + 1;
end
clearvars('-except',initialVars{:});

%% Histograms - Individual participants
for tidiness = 1
    rewardStrings = {'No reward','Small reward','Medium reward','Large reward'};
    delayStrings = {'2 seconds','3 seconds','4 seconds','5 seconds'};
    for x = participants
        temp = trialData(trialData.id == x & trialData.flag == 0,:);
        A = temp.response;
        for d = 1:numel(delays)
            temp2 = temp(temp.delay == delays(d),:);
            D{d} = temp2.response;
            for a = 1:numel(amounts)
                temp3 = temp(temp.reward == amounts(a),:);
                R{a} = temp3.accuracy;
            end
        end
        figure;
        subplot(3,1,2);
        nhist(D,'smooth','legend',delayStrings,...
            'decimalplaces',1,'xlabel','Seconds','ylabel','PDF','color','colormap');%,'fsize',20);
        title('Response by delay');
        subplot(3,1,3);
        nhist(R,'smooth','legend',rewardStrings,...
            'precision',3,'xlabel','Seconds','ylabel','PDF','color','colormap','serror');%,'fsize',20);
        title('Accuracy by reward');
        suptitle(sprintf('Participant %.0f',x));
        subplot(3,1,1);
        nhist(A,'smooth',...
            'precision',3,'xlabel','Seconds','ylabel','PDF','color',[0 0.447 0.741]);%,'fsize',20);
        title('All responses');
        suptitle(sprintf('Participant %.0f',x));
    end
end
clearvars('-except',initialVars{:});

    %% Regression
    temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
    labels = {'id','delay','reward','lagReward','totalvolume','lagDelay','lagResponse'};
    predMatrix = [temp.id, temp.delay, temp.reward, temp.lagReward, temp.totalvolume,temp.lagDelay,temp.lagResponse];
    Y = temp.response;
    
    % Identify features
    opts = statset('display','iter');
    
    fun = @(x0,y0,x1,y1) norm(y1-x1*(x0\y0))^2;  % residual sum of squares
    [in,history] = sequentialfs(fun,predMatrix,Y, 'options',opts);
    inclVar = {labels{in}};
    
    % Get regression stats
    [~,~,stats] = glmfit(predMatrix(:,in),Y,'normal');
inclVar
stats.beta
stats.p

% Get multi-level regression stats
model = @(PHI,t) PHI(1) + PHI(2)*t(:,1) + PHI(3)*t(:,2) + PHI(4)*t(:,3);
beta0 = [1 1 1 1];
[beta,PSI,stats,B] = nlmefit(predMatrix(:,in),temp.response,categorical(temp.id),[],model,beta0,'REParamsSelect',[1]);
clearvars('-except',initialVars{:});

%% Analyse different models
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
model = @(PHI,t) PHI(1) + PHI(2)*t(:,1) + PHI(3)*t(:,2) + PHI(4)*t(:,3);
beta0 = [1 1 1 1];
predMatrix = 
[beta,PSI,stats,B] = nlmefit(predMatrix,temp.response,categorical(temp.reward),[],model,beta0,'REParamsSelect',[1]);

%% Regression 2
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);

mdl = stepwiselm(temp,'constant',...
    'ResponseVar','response',...
    'PredictorVars',{'delay','reward','lagReward','totalvolume','lagDelay','lagResponse'},...
    'CategoricalVars',{'delay','reward','lagReward','lagDelay'})
plotResiduals(mdl,'fitted');
plotSlice(mdl);
plotEffects(mdl);
clearvars('-except',initialVars{:});

%% Multi-level regression (mixed-effects)

temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);

model = @(PHI,t) PHI(1) + PHI(2)*t(:,1) + PHI(3)*t(:,2) + PHI(4)*t(:,3);
beta0 = [1 1 1 1];

[beta,PSI,stats,B] = nlmefit([temp.id temp.delay temp.lagReward],temp.response,categorical(temp.id),...
    [],model,beta0,'REParamsSelect',[1],'ErrorModel','Proportional');
plotResiduals(stats);

[beta,PSI,stats,B] = nlmefitsa([temp.id temp.delay temp.lagReward],temp.response,categorical(temp.id),...
    [],model,beta0,'REParamsSelect',[1]);
plotResiduals(stats);

stevens = 'k*(x^b)'; % 3 parameter power function
mdl = @(PHI,t) PHI(1) + (t(:,1) - (PHI(1)*t(:,2)))^PHI(3)*(t(:,3));
clearvars('-except',initialVars{:});

%% Multi-level regression (participant basis)
vars = {'reward','delay','lagReward','lagDelay','totalvolume','lagAccuracy'};
plotVar = 2;
for x = participants
    temp = trialData(trialData.id == x & trialData.flag == 0 & trialData.session == 2,:);
    for v = 1:numel(vars)
    predMatrix(:,v) = table2array(temp(:,vars{v}));
    end
    [beta{x},~,stats{x}] = glmfit(predMatrix,temp.response);
    clearvars predMatrix
end
c = 1;
for x = participants
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
figure;
c = 1;
for x = participants
    subplot(5,5,c);
    plot(stats{x}.resid);
    xlim([0 160]);
    title(sprintf('Participant %.0f',x));
    c = c + 1;
end
clearvars('-except',initialVars{:});

%% Distributed lag model
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
lags = [0 1 2 3];
lagMatrix = lagmatrix(temp.reward, lags);

[beta,dev,stats] = glmfit(lagMatrix,temp.response);
plot(stats.resid);

%% Cox regression
temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
figure;
lStyle = {'-','--','-.',':'};
lCol = {[0 0.447 0.741] [0.85 0.325 0.098] [0.443 0.82 0.6] [0.929 0.694 0.1250]};
for d = 1:numel(delays)
    for a = 1:numel(amounts)
    i = temp.delay == delays(d) & temp.lagReward == amounts(a);
    [b,logl,H,stats] = coxphfit(temp.id(i), temp.response(i));
    [b stats.p];
    stairs(H(:,1),exp(-H(:,2)),'LineWidth',2, 'LineStyle',lStyle{d}, 'Color',lCol{a});
    hold on;
    end
end
% legend('2 secs, no reward','2 secs, small reward','2 secs, medium reward',...
%     '2 secs, large reward','3 secs, no reward','3 secs, small reward','3 secs, medium reward',...
% '3 secs, large reward','4 secs, no reward','4 secs, small reward','4 secs, medium reward',...
% '4 secs, large reward','5 secs, no reward','5 secs, small reward','5 secs, medium reward','5 secs, large reward');
legend('No reward','Small reward','Medium reward',...
    'Large reward');
ylabel('Probability of no response');
xlabel('Seconds');
predMatrix = [temp.delay temp.lagReward temp.totalvolume];
[b,logl,H,stats] = coxphfit(predMatrix, temp.response);
[b stats.p]

%% Delay test for time series data
temp = trialData(ismember(trialData.id,participants) & trialData.flag == 0 & trialData.session == 2,:);
d = iddata(temp.accuracy,temp.reward,1);
delayest(d)

%% Means of means (normalised accuracy by delay by lagged reward)
figure;
limits = {[1.5 2.5],[2.5 3.5],[3.5 4.5],[4.5 5.5]};
for d = 1:numel(delays)
temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0,:);
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
    bar(ME,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[1 1 1], 'BarWidth',0.8);
    hold on;
    errorbar(1:4,ME,SEM,'Color',[0 0 0] ,'LineWidth',1,'LineStyle', 'none');
    set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
ylabel('Normalised accuracy');
ylim([-.2 .3]);
title(sprintf('%.0f seconds',delays(d)));
blue = [0 0.447 0.741];
og = [0.85 0.325 0.098];
end
clearvars('-except',initialVars{:});

%% Normalised accuracy as function of previous delay (temporal context effects)
for d = 1:numel(delays)
temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
    id = unique(trialData.id(ismember(trialData.id, participants)));
    for x = 1:numel(id)
            i = temp.id == id(x) & ismember(temp.delay,delays(d));
            M(x,d) = nanmean(temp.accuracy(i));
    end
end
    ME = nanmean(M);
    SD = nanstd(M);
    SEM = SD ./ sqrt(size(M,1));
    CI = (1.96 .* SEM);
    figure;
    bar(ME,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[1 1 1], 'BarWidth',0.8);
    hold on;
    errorbar(1:4,ME,SEM,'Color',[0 0 0] ,'LineWidth',1,'LineStyle', 'none');
    set(gca,'XTick',1:numel(amounts),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
ylabel('Normalised accuracy');

clearvars('-except',initialVars{:});

%% Generate table with means by condition
T = table;
c = 1;
REWARD = table;
ID = table;
for x = participants
    temp = trialData(trialData.id == x,:);
    for a = 1:numel(amounts)
        REWARD = cat(1,REWARD,table(amounts(a),'VariableNames',{'reward'}));
        ID = cat(1,ID,table(x,'VariableNames',{'id'}));
        temp2 = temp(temp.lagReward == amounts(a),:);
        ind = getTimeData(temp2.delay(~isnan(temp2.response))./2,...
            temp2.response(~isnan(temp2.response)));
        T = [T;ind];
    end
    c = c + 1;
end
T = [ID REWARD T];
T.Properties.VariableNames(1) = {'id'};
T.Properties.VariableNames(2) = {'reward'};

clearvars('-except',initialVars{:});

%% Find and plot sequence events
sequence = [0,0,0];

for d = 1:numel(delays)
    temp = trialData(ismember(trialData.id, participants) & trialData.flag == 0 & trialData.session == 2,:);
    i = strfind(temp.reward',sequence);
    temp = temp(i+length(sequence)-1,:);
    id = unique(trialData.id(ismember(trialData.id, participants)));
    for x = 1:numel(id)
        i = temp.id == id(x) & ismember(temp.lagDelay,delays(d));
        M(x,d) = nanmean(temp.normAccuracy(i));
    end
end
ME = nanmean(M);
SD = nanstd(M);
SEM = SD ./ sqrt(size(M,1));
CI = (1.96 .* SEM);
figure;
bar(ME,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[1 1 1], 'BarWidth',0.8);
hold on;
errorbar(1:4,ME,SEM,'Color',[0 0 0] ,'LineWidth',1,'LineStyle', 'none');
set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});%{'4 secs','6 secs','8 secs','10 secs'});
ylabel('Normalised accuracy');

clearvars('-except',initialVars{:});

%% Check CV for each delay
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
    CV(:,d) = STD.nanstd_response(STD.delay == delays(d)) ./ M.nanmean_response(M.delay == delays(d))
end

[p,table,stats] = anova1(CV);

clearvars('-except',initialVars{:});


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