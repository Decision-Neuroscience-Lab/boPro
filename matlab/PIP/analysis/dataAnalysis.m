participants = [1:5];
set(0,'DefaultAxesColorOrder', [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);

%% Concatenate practice and main task
trialData = cat(1,practiceData,trialData);

%% MUST FIX OUTLIER IDENTIFICATION - PLOT IS NOT REPRESENTATIVE OF EXCLUDED DATA
%% Removed missed and identify outliers using an arbitrary threshold and add exclusion variable to trialData
% Add exclusion variables to trialData
trialData(:,8) = zeros(size(trialData,1),1);
trialData(trialData(:,5) == -1,8) = 1; % Mark missed responses as excluded
TH = 2.5;
ploton = 0;
for x = participants
    temp = trialData(trialData(:,1) == x,:);
    delays = unique(trialData(:,4));
    for d = 1:numel(delays)
        temp2 = temp(temp(:,4) == delays(d),:);
        i = trialData(:,1) == x & trialData(:,4) == delays(d);
        
        % Get mean and std for each delay
        M(x,d) = mean(temp2(:,5));
        SD(x,d) = std(temp2(:,5));
        
        [N,X] = hist(temp2(:,5),10);
        try
            f1 = fit(X', N', 'gauss1', 'Exclude', X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d))); % Fit to included data
        catch
            continue;
        end
        if ploton
            figure;
            subplot(2,2,d);
            h = plot(f1,X,N,X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d)));
            if size(h,1) == 3
                set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o'); set(h(2), 'Color', [0.443 0.82 0.6], 'Marker', '*'); set(h(3), 'Color', [0.85 0.325 0.098]);
                legend('Data','Excluded data','Fitted normal distribution');
            else
                set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o'); set(h(2), 'Color', [0.85 0.325 0.098]);
                legend('Data','Fitted normal distribution');
            end
            hold on
            plot(repmat(delays(d)./2, 1, max(N) + 1), 0:max(N), 'LineStyle', '--', 'Color', [0.85 0.325 0.098]);
            ylabel('Response frequency');
            xlabel('Response (secs)');
            title(sprintf('Participant %.0f, %.0f seconds', x, delays(d)));
        end
        trialData(i,9) = temp2(:,5) < (M(x,d) - TH.*SD(x,d)) | temp2(:,5) > (M(x,d) + TH.*SD(x,d)); % Create exclusion logical
        fprintf('%.0f trials excluded for participant %.0f in delay %.0f.\n',sum(temp2(:,5) < (M(x,d) - TH.*SD(x,d)) | temp2(:,5) > (M(x,d) + TH.*SD(x,d))),x,delays(d));
    end
    clearvars -except trialData participants TH x exclude delays M SD ploton
end

trialData(:,8) = trialData(:,8) + trialData(:,9); % Add missed to excluded
trialData(:,9) = [];


%% Binned absolute accuracy
c = 1;
figure;
for x = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    accuracy = temp(:,5) - (temp(:,4)./2);
    accuracy = abs(accuracy);
    
    % Subplot
    numBins = 4;
    if mod(numel(accuracy), numBins) == 0
        bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(accuracy)));
    else
        accuracy(end+1:end+(numBins-mod(numel(accuracy),numBins))) = NaN; % Add NaN until even
        bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(accuracy)));
    end
    subplot(2,3,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth'});
    title(sprintf('Participant %.0f',x));
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    
    c = c + 1;
    clearvars temp semBin meanBin bins accuracy
end
suptitle('Binned accuracy');

%% Check accuracy over experiment
for x  = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    accuracy = temp(:,5) - (temp(:,4)./2);
    figure;
    plot(accuracy);
    hold on
    plot(1:size(accuracy,1), zeros(1,size(accuracy,1)), 'LineStyle','--');
    xlim([0 size(accuracy,1)]);
    ylim([-5 5]);
    ylabel('Devation (secs)');
    xlabel('Trial number');
    title(sprintf('Participant %.0f',x));
    
    allTrials = 1:size(temp(:,2));
    
    [r, p] = corr(accuracy, temp(:,6), 'rows', 'complete');
    [r1, p1] = corr(accuracy, cat(1,0, temp(1:end-1,6)), 'rows', 'complete');
    [r2, p2] = corr(abs(accuracy), temp(:,7), 'rows', 'complete');
    fprintf('Correlation of accuracy and reward.\nParticipant %.0f\nr:%.3f\np:%.3f\n',x,r,p);
    fprintf('Correlation of accuracy and reward with lag.\nParticipant %.0f\nr:%.3f\np:%.3f\n',x,r1,p1);
    fprintf('Correlation of accuracy and cumulative reward.\nParticipant %.0f\nr:%.3f\np:%.3f\n',x,r2,p2);
    
    for s = [1, 2, 3]
        temp2 = temp(temp(:,2) == s,:);
        subTrials = allTrials(temp(:,2) == s);
        accuracy = temp2(:,5) - (temp2(:,4)./2);
        plot(subTrials,accuracy);
    end
    clearvars -except trialData participants x
end

%% Plot thirst and compare responses with total juice consumed

%% Generate time perception measures
for x = participants
    diff = reproduction - sample;
    absDiff = abs(reproduction-sample);
    relDiff = diff ./ sample;
    relReproduction = reproduction ./ sample;
    SR = sample ./ reproduction;
    absError = absDiff./sample;
    % Reproduction
    meanReproduction = mean(reproduction);
    stdReproduction = std(reproduction);
    cvReproduction = stdReproduction./meanReproduction;
    % Deviation
    meanDiff = mean(diff);
    stdDiff = std(diff);
    cvDiff = stdDiff./meanDiff;
    % Absolute deviation
    meanAbsDiff = mean(absDiff);
    stdAbsDiff = std(absDiff);
    cvAbsDiff = stdAbsDiff./meanAbsDiff;
    % Relative reproduction
    meanRelReproduction = mean(relReproduction);
    stdRelReproduction = std(relReproduction);
    cvRelReproduction = stdRelReproduction./meanRelReproduction;
    % SR
    meanSR = mean(SR);
    stdSR = std(SR);
    cvSR = stdSR./meanSR;
    % Relative deviation
    meanRelDiff = mean(relDiff);
    stdRelDiff = std(relDiff);
    cvRelDiff = stdRelDiff./meanRelDiff;
    % absError
    meanAbsError = mean(absError);
    stdAbsError = std(absDiff);
    cvAbsError = stdAbsError./meanAbsError;
end

%% Compare mean responses and SD of responses across conditions
for x = participants
    figure;
    temp = trialData(trialData(:,1)== x & trialData(:,8) == 0,4:6); % Select participant without outliers
    
    temp(isnan(temp(:,3)),3) = 0;
    
    delays = unique(temp(:,1));
    amounts = unique(temp(:,3));
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp(:,1) == delays(d) & temp(:,3) == amounts(a);
            M(d,a) = mean(temp(i,2));
            SD(d,a) = std(temp(i,2));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(temp(i,2)));
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
    
    clearvars -except trialData participants x
end

%% Standardise responses and perform ANOVA
response = [];
allR = [];
allD = [];
allId = [];
for x = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp(isnan(temp(:,6)),6) = 0;
    amounts = unique(temp(:,6));
    delays = unique(temp(:,4));
    
    for t = 1:size(temp,1) % Create grouping strings
        switch temp(t,6)
            case amounts(1)
                reward{t,1} = 'Zero reward';
            case amounts(2)
                reward{t,1} = 'Small reward';
            case amounts(3)
                reward{t,1} = 'Medium reward';
            case amounts(4)
                reward{t,1} = 'Large reward';
        end
        switch temp(t,4)
            case delays(1)
                delay{t,1} = '4 seconds';
            case delays(2)
                delay{t,1} = '6 seconds';
            case delays(3)
                delay{t,1} = '8 seconds';
            case delays(4)
                delay{t,1} = '10 seconds';
        end
        id(t,1) = x;
    end
    reward = categorical(reward);
    delay = categorical(delay);
    id = categorical(id);
    
    % Concatenate with other participants - choose normalised scores,
    % accuracy or raw RT
    
    % accuracy = zscore(temp(:,5) - temp(:,4)./2);
    % accuracy = temp(:,5) - temp(:,4)./2;
    accuracy = temp(:,5);
    
    response = cat(1,response, accuracy);
    allR = cat(1,allR, reward);
    allD = cat(1,allD, delay);
    allId = cat(1,allId,id);
    
    %[P,T,STATS,TERMS] = anovan(accuracy,{reward, delay}, 'model', 'full', 'varnames', char('Reward', 'Delay'));
    
    clearvars -except trialData participants x response allR allD allId
end
% Test all participants
[P,T,STATS,TERMS] = anovan(response, {allR, allD, allId}, 'model', 'full', 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));

% Test all participants without 'Zero reward' group
z = allR ~= 'Zero reward';
[P,T,STATS,TERMS] = anovan(response(z), {allR(z), allD(z), allId(z)}, 'model', 'full', 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));

% Test all participants with reward as continuous variable instead of
% categorical
conreward = trialData(trialData(:,8) == 0,6);
conreward(isnan(conreward)) = 0;
[P,T,STATS,TERMS] = anovan(response(z), {conreward(z), allD(z), allId(z)}, 'model', 'full', 'continuous', [1], 'random', [3], 'varnames', char('Reward', 'Delay', 'id'));

% Paired t-tests between reward conditions
temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
temp(isnan(temp(:,6)),6) = 0;
tests = combnk([unique(temp(:,6))],2);
for r = 1:size(tests,1)
    i = temp(:,6) == tests(r,1);
    j = temp(:,6) == tests(r,2);
    [h(r),p(r)] = ttest2(response(i), response(j));
end
sig = tests(logical(h),:);
    
% clearvars -except trialData participants x

%% Fit psychophysical functions to individual participants
c = 1;
for x = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp(:,4) = temp(:,4)./2; % Divide objT by 2
    temp(isnan(temp(:,6)),6) = 0;
    amounts = unique(temp(:,6)); % Check amounts
    
    for t = 1:size(temp,1) % Create grouping strings
        switch temp(t,6)
            case amounts(1)
                group{t,1} = 'Zero reward';
            case amounts(2)
                group{t,1} = 'Small reward';
            case amounts(3)
                group{t,1} = 'Medium reward';
            case amounts(4)
                group{t,1} = 'Large reward';
        end
    end
    
    group = categorical(group);
    
    % Fit function to all data
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp(:,4), temp(:,5));
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    allFit(1,1:3) = [FO.k, FO.b, G.adjrsquare];
    
    % Fit function to each reward group
    for r = 1:4
        stevens =  'k*(x^b)'; % 3 parameter power function
        [xData, yData] = prepareCurveData(temp(temp(:,6) == amounts(r),4), temp(temp(:,6) == amounts(r),5));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    % subplot(5,4,c);
    g = gscatter(temp(:,4),temp(:,5), group, [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    scatter(temp(temp(:,8)==1,1),temp(temp(:,8)==1,2),'k*');
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
    clearvars -except trialData practiceData thirst participants c
end

%% Fit psychophysical functions to all normalised data
zScore = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        
        accuracy = zscore(temp(:,5) - temp(:,4)./2);
        zScore = cat(1,zScore, accuracy);
        clearvars -except trialData participants zScore
    end
    
    temp = trialData(trialData(:,8) == 0,:);
    temp(:,4) = temp(:,4)./2; % Divide objT by 2
    temp(isnan(temp(:,6)),6) = 0;
    amounts = unique(temp(:,6)); % Check amounts
    delays = unique(temp(:,4)); % Check delays
    
    for t = 1:size(temp,1) % Create grouping strings
        switch temp(t,6)
            case amounts(1)
                group{t,1} = 'Zero reward';
            case amounts(2)
                group{t,1} = 'Small reward';
            case amounts(3)
                group{t,1} = 'Medium reward';
            case amounts(4)
                group{t,1} = 'Large reward';
        end
        switch temp(t,4)
            case delays(1)
                zScore(t) = zScore(t) + 2;
            case delays(2)
                zScore(t) = zScore(t) + 3;
            case delays(3)
                zScore(t) = zScore(t) + 4;
            case delays(4)
                zScore(t) = zScore(t) + 5;
        end
    end
    
    group = categorical(group);
    
    % Fit function to all data
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp(:,4), zScore);
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    allFit(1,1:3) = [FO.k, FO.b, G.adjrsquare];
    
    % Fit function to each reward group
    for r = 1:4
        stevens =  'k*(x^b)'; % 3 parameter power function
        [xData, yData] = prepareCurveData(temp(temp(:,6) == amounts(r),4), zScore(temp(:,6) == amounts(r)));
        ft = fittype(stevens);
        [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
        rewardFit(r,1:3) = [FO.k, FO.b, G.adjrsquare];
    end
    
    figure;
    g = gscatter(temp(:,4),zScore, group, [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556]);
    hold on
    scatter(temp(temp(:,8)==1,1),temp(temp(:,8)==1,2),'k*');
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
    title('Psychophysical function for all participants');
    
    clearvars -except trialData practiceData thirst participants
end
%% Compare mean accuracy and SD of responses across conditions
R = [];
zR = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        temp = sortrows(temp,[1]); % Make sure data is in participant order
        
        response = temp(:,5);
        zResponse = zscore(temp(:,5));
        
        R = cat(1,R, response);
        zR = cat(1,zR, zResponse);
        
        clearvars -except trialData participants R zR
    end
    
    temp = trialData(trialData(:,8) == 0,:);
    temp = sortrows(temp,[1]); % Make sure data is in participant order
    
    temp(isnan(temp(:,6)),6) = 0;
    
    delays = unique(temp(:,4));
    amounts = unique(temp(:,6));
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp(:,4) == delays(d) & temp(:,6) == amounts(a);
            M(d,a) = mean(R(i,1));
            SD(d,a) = std(R(i,1));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(R(i,1)));
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
    ylabel('Mean zScore');
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    
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
    
    clearvars -except trialData participants x
end