participants = [1:19];
set(0,'DefaultAxesColorOrder', [0 0.447 0.741; 0.85 0.325 0.098;  0.443 0.82 0.6]);

%% Indifference points
c = 1;
for x = participants
    [~, ~, ipPsi(c,1:3), ipSE(c,1:3), ipPsiAverage(c,1:3), ipQuest(c,1:3)] = checkIP(x);
    c = c + 1;
end

%% Test Optimality
c = 1;
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    % Check optimality (TIMERR with ITI)
    [~, empRewardDensity(c), propMatchTest(c,1), simRewardDensity(c)] = checkOptimality(11.5, 3, 'ert',x);
    testOptimality(c,1) = empRewardDensity(c)/simRewardDensity(c);
    % Check optimality (TIMERR with no ITI)
    [~, empRewardDensity(c), propMatchTest(c,2), simRewardDensity(c)] = checkOptimality(0, 3, 'ert',x);
    testOptimality(c,2) = empRewardDensity(c)/simRewardDensity(c);
    c = c + 1;
end

%% Calibration Optimality
c = 1;
for x = participants
    % Check optimality (TIMERR with ITI)
    [~, empRewardDensity(c), propMatchCalib(c,1), simRewardDensity(c)] = checkOptimality(11.5, 1, 'ert',x);
    calibOptimality(c,1) = empRewardDensity(c)/simRewardDensity(c);
    % Check optimality (TIMERR with no ITI)
    [~, empRewardDensity(c), propMatchCalib(c,2), simRewardDensity(c)] = checkOptimality(0, 1, 'ert',x);
    calibOptimality(c,2) = empRewardDensity(c)/simRewardDensity(c);
    c = c + 1;
end

%% Binned bias
c = 1;
figure;
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    % Subplot
    numBins = 4;
    biasTrial = +temp(:,14); % Convert to numerical
    if mod(numel(biasTrial), numBins) == 0
        bins = reshape(biasTrial,numel(biasTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(biasTrial)));
    else
        biasTrial(end+1:end+(numBins-mod(numel(biasTrial),numBins))) = NaN; % Add NaN until even
        bins = reshape(biasTrial,numel(biasTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(biasTrial)));
    end
    subplot(5,4,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'YTick',0:0.5:2);
    set(gca,'YTickLabel',{'Non-biased','0.5','Biased'});
    ylim([0,1]);
    xlim([0,5]);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth'});
    title(sprintf('Participant %.0f',x));
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    
    c = c + 1;
    clearvars temp semBin meanBin bins biasTrial
end
suptitle('Mean Bias');

%% Overall bias
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    biasTrial(x) = mean(temp(:,14)); % Mean
    semTrial(x) = nanstd(temp(:,14)) / (sqrt(numel(temp(:,14)))); % SEM
    
    clearvars temp missed
end
figure;
hBar = bar(biasTrial);
set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
ylabel('Percentage');
xlabel('Participant');
hold on
h = errorbar(biasTrial,semTrial);
set(h,'linestyle','none');
title('Percentage Biased');

%% Bias split by prediction
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    i = temp(:,9)==1 & temp(:,6)==d;
    j = temp(:,9)==2 & temp(:,6)==d;
    predictedSS(x) = mean(temp(i,7) == 1);
    predictedLL(x) = mean(temp(j,7) == 2);
    
    clearvars temp missed i j y
end

figure;
subplot(2,1,1);
hBar = bar(predictedSS);
set(hBar(1),'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1],'BarWidth',1);
set(gca,'XTick',1:max(participants));
ylabel('Proportion biased');
title('Predicted SS');
subplot(2,1,2);
hBar = bar(predictedLL);
set(hBar(1),'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1],'BarWidth',1);
set(gca,'XTick',1:max(participants));
ylabel('Proportion biased');
title('Predicted LL');
clearvars predictedSS predictedLL

%% Bias split by prediction and delay
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    y = 1;
    for d = [6 8 10]
        i = temp(:,9)==1 & temp(:,6)==d;
        j = temp(:,9)==2 & temp(:,6)==d;
        predictedSS(x,y) = mean(temp(i,7) == 1);
        predictedLL(x,y) = mean(temp(j,7) == 2);
        y = y + 1;
    end
    
    clearvars temp missed i j y
end

figure;
subplot(2,1,1);
hBar = bar(predictedSS);
set(hBar(1),'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1],'BarWidth',1);
set(hBar(2),'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1],'BarWidth',1);
set(hBar(3),'FaceColor',[0.443 0.82 0.6],'EdgeColor',[1 1 1],'BarWidth',1);
set(gca,'XTick',1:max(participants));
ylabel('Proportion biased');
legend('6 seconds','8 seconds','10 seconds');
title('Predicted SS');
subplot(2,1,2);
hBar = bar(predictedLL);
set(hBar(1),'FaceColor',[0 0.447 0.741],'EdgeColor',[1 1 1],'BarWidth',1);
set(hBar(2),'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1],'BarWidth',1);
set(hBar(3),'FaceColor',[0.443 0.82 0.6],'EdgeColor',[1 1 1],'BarWidth',1);
set(gca,'XTick',1:max(participants));
ylabel('Proportion biased');
title('Predicted LL');
clearvars predictedSS predictedLL

%% Binned choice
c = 1;
figure;
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    % Subplot
    numBins = 4;
    choiceTrial = temp(:,7)-1; % Convert to numerical
    if mod(numel(choiceTrial), numBins) == 0
        bins = reshape(choiceTrial,numel(choiceTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(choiceTrial)));
    else
        choiceTrial(end+1:end+(numBins-mod(numel(choiceTrial),numBins))) = NaN; % Add NaN until even
        bins = reshape(choiceTrial,numel(choiceTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(choiceTrial)));
    end
    subplot(5,4,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'YTick',0:0.5:2);
    set(gca,'YTickLabel',{'SS','0.5','LL'});
    ylim([0,1]);
    xlim([0,5]);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth'});
    title(sprintf('Participant %.0f',x));
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    
    c = c + 1;
    clearvars temp semBin meanBin bins choiceTrial
end
suptitle('Mean Choice');

%% Binned RT (for calibration)
c = 1;
figure;
for x = participants
    
    temp = dataMatrixCalibration(dataMatrixCalibration(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    % Subplot
    numBins = 4;
    rtTrial = temp(:,9); % Convert to numerical
    if mod(numel(rtTrial), numBins) == 0
        bins = reshape(rtTrial,numel(rtTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(rtTrial)));
    else
        rtTrial(end+1:end+(numBins-mod(numel(rtTrial),numBins))) = NaN; % Add NaN until even
        bins = reshape(rtTrial,numel(rtTrial)/numBins,numBins);
        meanBin = nanmean(bins);
        semBin = nanstd(bins) / (sqrt(numel(rtTrial)));
    end
    subplot(5,4,c);
    hBar = bar(meanBin);
    set(hBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    set(gca,'XTick',1:numBins);
    set(gca,'XTickLabel',{'First','Second','Third','Fourth'});
    title(sprintf('Participant %.0f',x));
    hold on
    h = errorbar(meanBin,semBin);
    set(h,'linestyle','none');
    
    c = c + 1;
    clearvars temp semBin meanBin bins rtTrial
end
suptitle('Mean RT');

%% RT plots (for calibration) - for each participant plots trial vs rt (choice group) and ssA vs rt (delay group)
c = 1;
for x = participants
    
    temp = dataMatrixCalibration(dataMatrixCalibration(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    %     RT = log(temp(:,9)); % Log transform reaction time
    RT = temp(:,9);
    
    for t = 1:size(temp,1) % Create grouping strings
        if temp(t,7) == 1
            group{t,1} = 'SS';
        else
            group{t,1} = 'LL';
        end
        if temp(t,6) == 6
            group{t,2} = '6 secs';
        elseif temp(t,6) == 8
            group{t,2} = '8 secs';
        else
            group{t,2} = '10 secs';
        end
    end
    
    figure;
    cB = 1;
    vLabels = {'Trial vs RT','Amount vs RT'};
    for v = [2,3];
        subplot(2,1,cB);
        g = gscatter(temp(:,v),RT, {group{:,cB}}',[0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6]);
        title(sprintf('%s',vLabels{cB}));
        cB = cB + 1;
    end
    suptitle(sprintf('Participant %.0f',x));
    
    c = c + 1;
    clearvars temp group
end

%% RT plots (for test component) - plots trial vs rt (choice group)
c = 1;
figure;
for x = participants
    if x == 4
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    % RT = log(temp(:,15)); % Log transform reaction time
    RT = temp(:,15);
    
    for t = 1:size(temp,1) % Create grouping strings
        if temp(t,14) == 1
            group{t,1} = 'Biased';
        else
            group{t,1} = 'Non-biased';
        end
    end
    
    group = categorical(group);
    
    subplot(5,4,c);
    g = gscatter(temp(:,2), RT, group,[0 0.447 0.741; 0.85 0.325 0.098]);
    title(sprintf('Participant %.0f',x));
    xlim([0 54]);
    
    c = c + 1;
    clearvars temp group
end
suptitle('Trial vs RT');
%% Choice vs trial with accumulated juice
c = 1;
figure;
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    for t = 1:size(temp,1) % Create grouping string
        if temp(t,14) == 1
            group{t,1} = 'Biased';
        else
            group{t,1} = 'Non-biased';
        end
    end
    
    subplot(5,4,c);
    [h,l1,l2] = plotyy(temp(:,2), temp(:,7), temp(:,2), temp(:,8));
    set(l1,'linestyle','none');
    ylabel(h(2),'Total juice');
    xlabel('Trial');
    title(sprintf('Participant %.0f',x));
    xlim(h(2),[0,54]);
    ylim(h(2),[0,300]);
    hold on
    g = gscatter(temp(:,2),temp(:,7),group,[0 0.447 0.741; 0.85 0.325 0.098]);
    legend(g,'Location','SouthEast');
    xlim([0,54]);
    
    c = c + 1;
    clearvars group temp
end
suptitle('Trial vs Choice');
%% TD fits
c = 1;
for x = participants
    if x == 4 % Go to next participant if file is missing
        continue;
    end
    
    [E, ~, ~] = fitTD(ssA, ssD, llA, llD, choice, 'exponential');
    tdFits(c).beta = E(1);
    tdFits(c).k = E(2);
    c = c + 1;
end

%% Regression (stepwise, for calibration)
c = 1;
for x = participants
    temp = dataMatrixCalibration(dataMatrixCalibration(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    labels = {'trial','ssA','ssD','llA','llD','juice','rt'};
    predMatrix = [temp(:,2:6), temp(:,8:end)];
    Y = temp(:,7) - 1;
    
    % Identify features
    opts = statset('display','iter');
    
    fun = @(x0,y0,x1,y1) norm(y1-x1*(x0\y0))^2;  % residual sum of squares
    [in,history] = sequentialfs(fun,predMatrix,Y,'cv',5, 'options',opts);
    inclVar{c} = {labels{in}};
    
    % Get regression stats
    [~,~,stats(c)] = glmfit(predMatrix(:,in),Y,'binomial');
    
    clearvars temp
    c = c + 1;
end

%% Regression (include all, for calibration)
c = 1;
for x = participants
    temp = dataMatrixCalibration(dataMatrixCalibration(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    inclVar{c} = {'trial','ssA','llD','juice'};
    predMatrix = [temp(:,2), temp(:,3), temp(:,6), temp(:,8)];
    Y = temp(:,7) - 1;
    
    % Get regression stats
    [~,~,stats(c)] = glmfit(predMatrix,Y,'binomial');
    
    clearvars temp
    c = c + 1;
end

%% Juice Regression Plot (for test component)
c = 1;
for x = participants
    
    if x == 4
        continue;
    end
    
    temp = dataMatrix(dataMatrix(:,1) == x,:);
    
    % Remove missing and recode
    missed = temp(:,7) == 3;
    temp(missed,:) = [];
    fprintf('%.0f trials missed for participant %.0f.\n', sum(missed), x);
    
    predMatrix = temp(:,8);
    Y = temp(:,7) - 1;
    
    % Get regression stats
    [~,~,stats] = glmfit(predMatrix,Y,'binomial');
    betas(x) = stats.beta(2,1);
    se(x) = stats.se(2,1);
    p(x) = stats.p(2,1);
    residuals{x} = stats.resid;
    
    clearvars temp
    c = c + 1;
end

% Plot juice betas with SE and P
figure;
[dBar] = bar(betas);
set(dBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
hold on
[hBar] = errorbar(betas,se);
set(hBar,'LineStyle','none');
for t = 1:numel(p)
    if t == 4
        continue;
    end
    if p(t) < 0.05
        text(t - 0.1,0,'*','fontSize',25);
    end
end
ylim([-0.1 0.1]);
title('Juice beta coefficients');
xlabel('Participant');

% Plot residuals
c = 1;
figure;
for x = participants
    if x == 4
        continue;
    end
    subplot(5,4,x);
    plot(1:length(residuals{x}),residuals{x});
    title(sprintf('Residuals for Participant %.0f',x));
    c = c + 1;
end
suptitle('Juice volume residuals');

%% Plot regression results
c = 1;
figure;
for x = participants
    % Plot coefficients with standard error
    betas = stats(c).beta;
    se = stats(c).se;
    p = stats(c).p;
    subplot(5,4,c);
    [dBar] = bar(betas);
    set(dBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
    hold on
    [hBar] = errorbar(betas,se);
    set(hBar,'LineStyle','none');
    for t = 1:numel(p)
        if p(t) < 0.05
            text(t - 0.2,0,'*','fontSize',25);
        end
    end
    title(sprintf('Regression model for Participant %.0f',x));
    set(gca,'XTick',1:numel(betas));
    set(gca,'XTickLabel',['Constant', inclVar{c}]);
    
    c = c + 1;
end
suptitle('Regression coefficients');

% Plot residuals
c = 1;
figure;
for x = participants
    subplot(5,4,c);
    plot(1:numel(stats(c).resid),stats(c).resid);
    title(sprintf('Residuals for Participant %.0f',x));
    c = c + 1;
end
suptitle('Regression residuals');
