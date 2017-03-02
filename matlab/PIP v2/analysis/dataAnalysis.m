participants = [1:9,11];
set(0,'DefaultAxesColorOrder', [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);

%% Concatenate practice and main task, identify amounts and delays and set NaN amounts to zero
trialData = cat(1,practiceData,trialData);
trialData(isnan(trialData(:,6)),6) = 0;
trialData(trialData(:,6) == 0.01,6) = 0;
amounts = unique(trialData(:,6));
delays = unique(trialData(:,4));

% Get only first half of experiment
% trialData = trialData(trialData(:,3) <= 100,:);

%% MUST FIX OUTLIER IDENTIFICATION - PLOT IS NOT REPRESENTATIVE OF EXCLUDED DATA
%% Removed missed and identify outliers using an arbitrary threshold and add exclusion variable to trialData
% Add exclusion variables to trialData
trialData(:,8) = zeros(size(trialData,1),1);
trialData(trialData(:,5) == -1,8) = 1; % Mark missed responses as excluded
TH = 2.5;
ploton = 0;
for x = participants
    temp = trialData(trialData(:,1) == x & trialData(:,8) == 0,:);
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
        trialData(i & trialData(:,8) == 0,9) = temp2(:,5) < (M(x,d) - TH.*SD(x,d)) | temp2(:,5) > (M(x,d) + TH.*SD(x,d)); % Create exclusion logical
        fprintf('%.0f trials excluded for participant %.0f in delay %.0f.\n',sum(temp2(:,5) < (M(x,d) - TH.*SD(x,d)) | temp2(:,5) > (M(x,d) + TH.*SD(x,d))),x,delays(d));
    end
    clearvars -except trialData amounts delays participants TH x exclude delays M SD ploton
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
        semBin = nanstd(bins) / (sqrt(numel(bins)));
    else
        accuracy(end+1:end+(numBins-mod(numel(accuracy),numBins))) = NaN; % Add NaN until even
        bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(bins)));
    end
    subplot(3,4,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth'});
    title(sprintf('Participant %.0f',x));
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    set(h, 'Color', [0 0 0]);
    
    c = c + 1;
    clearvars temp semBin meanBin bins accuracy
end
suptitle('Binned accuracy');

%% All participants binned absolute accuracy
separateFactor = 0;
REWARD = 0;
DELAY = 0;
for tidiness = 1
    temp = trialData(ismember(trialData(:,1),participants) & trialData(:,8) == 0,:); % Select participant without outliers
    
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    accuracy = temp(:,5) - (temp(:,4)./2);
    noreward = [];
    
    %Index, create and map each reward condition separately
        i = temp(:,6) == 0;
        noreward = accuracy; % Create 'no reward' responses
        noreward(~i) = NaN; % Remove normal responses
        accuracy(i) = NaN; % Remove 'no reward' responses
    
    
    % Index all different factors
    if separateFactor == 1
        % Choose factor below
        if REWARD == 1
            for  a = 1:numel(amounts)
                FACTOR{:,a} = accuracy(temp(:,6) == amounts(a));
            end
        elseif DELAY == 1;
            for d = 1:numel(delays)
                FACTOR{:,d} = accuracy(temp(:,4) == delays(d));
            end
        end
        
        numBins = 5;
        for factor = 1:numel(FACTOR)
            if mod(numel(FACTOR{factor}), numBins) == 0
                bins = reshape(FACTOR{factor},numel(FACTOR{factor})/numBins,numBins);
                meanBin(factor,:) = nanmean(bins);
                semBin(factor,:) = nanstd(bins) / (sqrt(numel(bins)));
            else
                FACTOR{factor}(end+1:end+(numBins-mod(numel(FACTOR{factor}),numBins))) = NaN; % Add NaN until even
                bins = reshape(FACTOR{factor},numel(FACTOR{factor})/numBins,numBins);
                meanBin(factor,:) = nanmean(bins);
                semBin(factor,:) = nanstd(bins) / (sqrt(numel(bins)));
            end
        end
        
        figure;
        hBar = bar(meanBin');
        colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250];
        for c = 1:numel(hBar)
            set(hBar(c),'FaceColor',colors(c,:),'EdgeColor',[1 1 1]);
        end
        set(gca,'XTick',1:numBins);
        set(gca,'XTickLabel',{'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eightth','Ninth','Tenth'});
        ylabel('Deviation (seconds)');
        hold on
        
        barWidth = 0.09;
        dist = [-3.1*barWidth -1*barWidth 1*barWidth 3.1*barWidth];
        for d = 1:size(meanBin,2)
            for f = 1:size(meanBin,1)
                h = errorbar(d + dist(f), meanBin(f,d),semBin(f,d));
                set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
            end
        end
        set(gcf, 'Color',[1 1 1]);
        if REWARD == 1
                    title('Mean accuracy by reward');
            legend({'No reward','Small reward','Medium reward','Large reward'});
        elseif DELAY == 1
                    title('Mean accuracy by delay');
            legend({'4 seconds','6 seconds','8 seconds','10 seconds'});
        end
        
    else
        
        numBins = 10;
        if mod(numel(accuracy), numBins) == 0
            bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
            bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
            meanBin = nanmean(bins);
            meanBin0 = nanmean(bins0);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
            semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
        else
            accuracy(end+1:end+(numBins-mod(numel(accuracy),numBins))) = NaN; % Add NaN until even
            noreward(end+1:end+(numBins-mod(numel(noreward),numBins))) = NaN; % Add NaN until even
            bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
            bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
            meanBin = nanmean(bins);
            meanBin0 = nanmean(bins0);
            semBin = nanstd(bins) / (sqrt(numel(bins)));
            semBin0 = nanstd(bins0) / (sqrt(numel(bins0)));
        end
        
        figure;
        hBar = bar(meanBin);
        set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
        set(gca,'XTick',1:numBins);
        set(gca,'XTickLabel',{'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eightth','Ninth','Tenth'});
        title('Mean accuracy');
        ylabel('Deviation (seconds)');
        hold on
        h = errorbar(meanBin,semBin);
        set(h,'linestyle','none');
        set(h, 'Color', [0 0 0]);
        set(gcf, 'Color',[1 1 1]);
        xlim([0 11]);
        
        % Plot 'no reward'
        gBar = plot(meanBin0);
        set(gBar,'Color',[0 0.447 0.741], 'Marker','o');
        g = errorbar(meanBin0,semBin0);
        set(g,'linestyle','none');
        set(g, 'Color', [0 0.447 0.741]);
        if ~isempty(noreward)
            legend([hBar gBar],'Reward','No Reward');
        end
        
    end
    clearvars temp semBin semBin0 meanBin meanBin0 bins bins0 accuracy noreward
end
%% Individual participants binned absolute accuracy
for x = participants
    temp = trialData(ismember(trialData(:,1),x) & trialData(:,8) == 0,:); % Select participant without outliers
    
    temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
    accuracy = temp(:,5) - (temp(:,4)./2);
    noreward = [];
    
    numBins = 10;
    if mod(numel(accuracy), numBins) == 0
        bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin = nanmean(bins);
        meanBin0 = nanmean(bins0);
        semBin = nanstd(bins) / (sqrt(numel(accuracy)));
        semBin0 = nanstd(bins0) / (sqrt(numel(noreward)));
    else
        accuracy(end+1:end+(numBins-mod(numel(accuracy),numBins))) = NaN; % Add NaN until even
        noreward(end+1:end+(numBins-mod(numel(noreward),numBins))) = NaN; % Add NaN until even
        bins = reshape(accuracy,numel(accuracy)/numBins,numBins);
        bins0 = reshape(noreward,numel(noreward)/numBins,numBins);
        meanBin = nanmean(bins);
        meanBin0 = nanmean(bins0);
        semBin = nanstd(bins) / (sqrt(numel(accuracy)));
        semBin0 = nanstd(bins0) / (sqrt(numel(noreward)));
    end
    
    figure;
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth','Fifth','Sixth','Seventh','Eightth','Ninth','Tenth'});
    title('Mean accuracy');
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    set(h, 'Color', [0 0 0]);
    
    % Plot 'no reward'
    gBar = plot(meanBin0);
    set(gBar,'Color',[0 0.447 0.741]);
    g = errorbar(meanBin0,semBin0);
    set(g,'linestyle','none');
    set(g, 'Color', [0 0.447 0.741]);
    if ~isempty(noreward)
        legend([hBar gBar],'Reward','No Reward');
    end
    clearvars temp semBin semBin0 meanBin meanBin0 bins bins0 accuracy noreward
end
%% Check individual accuracy over experiment
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
    set(gcf, 'Color', [1 1 1]);
    
    
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
    clearvars -except trialData participants x amounts delays
end

%% Check all accuracy over experiment
for tidiness = 1;
    zScore = [];
    trialNumber = [];
    session = [];
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
        accuracy = zeros(size(temp(:,4),1),1);
        for d = 1:numel(delays)
            i = temp(:,4) == delays(d);
            accuracy(i) = zscore(temp(i,5) - temp(i,4)./2);
        end
        zScore = cat(1,zScore, accuracy);
        trialNumber = cat(2,trialNumber, 1:size(accuracy,1));
        session = cat(1,session,temp(:,2));
        clearvars -except trialData participants zScore delays amounts trialNumber session
    end
    
    for t = 1:max(trialNumber)
        i = trialNumber == t;
        M(t) = mean(zScore(i));
    end
    
    %figure;
    plot(1:max(trialNumber),M);
    hold on
    plot(1:max(trialNumber), zeros(1,max(trialNumber)), 'LineStyle','--');
    xlim([0 max(trialNumber)]);
    ylim([-5 5]);
    ylabel('Devation (secs)');
    xlabel('Trial number');
    title('All participants');
    set(gcf, 'Color', [1 1 1]);
    
    for s = [1, 2, 3]
        i = session == s;
        subTrials = trialNumber(i);
        subScore = zScore(i);
        for t = 1:max(subTrials)
            j = subTrials == t;
            score(t) = mean(subScore(j));
        end
        plot(1:max(subTrials),score);
        clearvars -except trialData participants x amounts delays s zScore trialNumber session subScore subTrials score
    end
    
    clearvars -except trialData practiceData thirst participants c amounts delays
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
    temp = trialData(trialData(:,1) == x & trialData(:,8) == 0,:); % Select participant without outliers
    
    temp(isnan(temp(:,6)),6) = 0;
    
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            i = temp(:,4) == delays(d) & temp(:,6) == amounts(a);
            M(d,a) = mean(temp(i,5));
            SD(d,a) = std(temp(i,5));
            SEM(d,a) = SD(d,a) ./ sqrt(numel(temp(i,5)));
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
    set(gcf, 'Color', [1 1 1]);
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
    
    clearvars -except trialData participants x amounts delays
end

%% Standardise responses and perform ANOVA
for tidiness = 1
    response = [];
    allR = [];
    allD = [];
    allId = [];
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        temp(isnan(temp(:,6)),6) = 0;
        
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
        
         accuracy = zscore(temp(:,5) - temp(:,4)./2);
        % accuracy = temp(:,5) - temp(:,4)./2;
        % accuracy = temp(:,5);
        
        response = cat(1,response, accuracy);
        allR = cat(1,allR, reward);
        allD = cat(1,allD, delay);
        allId = cat(1,allId,id);
        
        %[P,T,STATS,TERMS] = anovan(accuracy,{reward, delay}, 'model', 'full', 'varnames', char('Reward', 'Delay'));
        
        clearvars -except trialData participants x response allR allD allId amounts delays
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
    
end

%% Fit psychophysical functions to individual participants
c = 1;
for x = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp(:,4) = temp(:,4)./2; % Divide objT by 2
    temp(isnan(temp(:,6)),6) = 0;
    
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
    set(gcf, 'Color', [1 1 1]);
    title(sprintf('Psychophysical function for participant %.0f',x));
    
    c = c + 1;
    clearvars -except trialData practiceData thirst participants c amounts delays
end

%% Fit psychophysical functions to all normalised data, with histogram as third dimension
zScore = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        
        accuracy = zscore(temp(:,5) - temp(:,4)./2);
        zScore = cat(1,zScore, accuracy);
        clearvars -except trialData participants zScore delays amounts
    end
    
    temp = trialData(ismember(trialData(:,1),participants) & trialData(:,8) == 0,:);
    temp(:,4) = temp(:,4)./2; % Divide objT by 2
    temp(isnan(temp(:,6)),6) = 0;
    
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
            case delays(1)./2
                zScore(t) = zScore(t) + 2;
            case delays(2)./2
                zScore(t) = zScore(t) + 3;
            case delays(3)./2
                zScore(t) = zScore(t) + 4;
            case delays(4)./2
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
    
    hist3(gca,[temp(:,4),temp(:,5)],[4 25], 'FaceAlpha', 0.2, 'EdgeAlpha',0.2, 'FaceColor',[0.9 0.9 0.9]);
    set(gca,'CameraPosition', [-0.6831 -22.3766 255.8894]);
    set(gcf, 'Color', [1 1 1]);
    ylim([0 10]);
    xlim([0 10]);
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    title('Psychophysical function for all participants');
    
    clearvars -except trialData practiceData thirst participants amounts delays
end
%% Compare mean accuracy and SD of responses across conditions
R = [];
zR = [];
for tidiness = 1
    for x = participants
        temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
        temp = sortrows(temp,[1 2]); % Make sure data is in participant order
        
        response = temp(:,5);
        zResponse = zscore(temp(:,5));
        
        R = cat(1,R, response);
        zR = cat(1,zR, zResponse);
        
        clearvars -except trialData participants R zR amounts delays trialNumber
    end
    
    temp = trialData(ismember(trialData(:,1), participants) & trialData(:,8) == 0,:);
    temp = sortrows(temp,[1 2]); % Make sure data is in participant order, followed by chronological order
    
    temp(isnan(temp(:,6)),6) = 0;
    
    % Add counter for total trials (for trial selection)
    for x = participants
        i = temp(:,1) == x;
        temp(i,9) = [1:sum(i)]';
    end
    
    % Choose trial subset and modify relevant arrays
    subSet = temp(:,9) >= floor(max(temp(:,9))./2);
    temp = temp(subSet,:);
    R = R(subSet,:);
    zR = zR(subSet,:);
    
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
   % subplot(2,1,1);
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
    
    set(gca,'FontSize',20)
    set(findall(gcf,'type','text'),'FontSize',20)
    
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
    set(gcf, 'Color', [1 1 1]);
    legend('No reward','Small reward','Medium reward','Large reward','Location','NorthWest');
    hold on
    
    dist = [-3.1*0.0875 -1*0.0875 1*0.0875 3.1*0.0875];
    for d = 1:numel(delays)
        for a = 1:numel(amounts)
            h = errorbar(d + dist(a), SD(d,a),SEM(d,a));
            set(h,'LineStyle','None', 'Color', [0.494 0.184 0.556]);
        end
    end
    
    clearvars -except trialData participants x amounts delays
end

%% Fit psychophysical functions to individual participants, with histogram as third dimension
c = 1;
for x = participants
    temp = trialData(trialData(:,1)==x & trialData(:,8) == 0,:); % Select participant without outliers
    temp(:,4) = temp(:,4)./2; % Divide objT by 2
    temp(isnan(temp(:,6)),6) = 0;
    
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
    plot(xx,y, 'Color', [0.929 0.694 0.1250], 'LineStyle', '--', 'LineWidth',1);
    rewardFit = flipud(rewardFit);
    cc = 1;
    for z = 1:4
        y = rewardFit(z,1).*xx.^rewardFit(z,2);
        h = plot(xx,y,'Color', colors(cc,:), 'LineWidth',3);
        cc = cc + 1;
    end
    
    hist3(gca,[temp(:,4),temp(:,5)], 'FaceAlpha', 0.2, 'EdgeAlpha',0.2, 'FaceColor',[0.9 0.9 0.9]);
    set(gca,'CameraPosition', [-0.6831 -22.3766 255.8894]);
    
    xlabel('Objective time (secs)');
    ylabel('Subjective time (secs)');
    zlabel('Response frequency');
    set(gcf, 'Color', [1 1 1]);
    title(sprintf('Psychophysical function for participant %.0f',x));
    
    c = c + 1;
    clearvars -except trialData practiceData thirst participants c amounts delays
end