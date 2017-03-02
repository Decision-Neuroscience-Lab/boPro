%% PPP physiological data analyses
% Bowen J Fung, 2016

%% Load in behavioural data
%oldcd = cd('/Volumes/333-fbe/DATA/TIMEJUICE/PPP/physiological');
oldcd = cd('/Users/Bowen/Documents/MATLAB/PPP/data');

load('heartData.mat');
load('blinkData.mat');
load('skinData.mat');
cd(oldcd);

Aspartame = [9:16,26:35,44:52];
Glucose = [1:8,17:25,36:43];
participants = 1:52;


% Participants removed from behavioural data: [10,34,49]
% Participant 18 had CM problem, removed from all physiological analysis

%% Analyse physiological signals
for tidiness = 1
    % HR
    HRparticipants = [1:9,11:17,19:33,35:52];
    for x = 1:52
        fprintf('Running participant %.0f.\n',x);
        try
            heartData(x) = getHR(x);
        catch
            fprintf('Problem with HR for participant %.0f.\n',x);
            HRprob(x) = 1;
            continue;
        end
    end
    fprintf('Done.\n');
    
    % GSR
    % GSR issues: participants 1:8, 16 missing data, participants 11 and 26
    % weird, 34 excluded
    GSRparticipants = [9,12:15,17,19:25,27:33,35:52];
    for x = 1:52
        fprintf('Running participant %.0f.\n',x);
        try
            skinData(x) = getGSR(x,0);
            response(x,:) = skinData(x).response;
            for r = 1:4
                reward{r}(x,:) = skinData(x).reward{r};
            end
        catch
            fprintf('No GSR for participant %.0f.\n',x);
            GSRprob(x) = 1; % Problem for 21, 22
            continue;
        end
    end
    fprintf('Done.\n');
    
    % EBR
    EBRparticipants = [1:9,11:17,19:33,35:52];
    for x = 1:52
        fprintf('Running participant %.0f.\n',x);
        try
            blinkData(x) = getEBR(x);
        catch
            fprintf('Problem with EBR for participant %.0f.\n',x);
            EBRprob(x) = 1;
            continue;
        end
    end
    fprintf('Done.\n');
end

%% Output physiological data to R
for tidiness = 1
    physiological = nan([52,4]);
    for p = 1:52
        if ~isempty(heartData(p).heartRate)
            physiological(p,1) = heartData(p).heartRate(1);
        end
        if ~isempty(heartData(p).hrv)
            physiological(p,2) = heartData(p).hrv(1);
        end
        if ~isempty(skinData(p).meanSCL)
            physiological(p,3) = skinData(p).meanSCL(1);
        end
        if ~isempty(blinkData(p).blinkRate)
            physiological(p,4) = blinkData(p).blinkRate(1);
        end
    end
    
    physMeans = array2table(physiological,'VariableNames',{'hr','hrv','scl','ebr'});
    writetable(physMeans,'/Users/Bowen/Documents/R/PPP/physMeans');
    
    % Aggregate by session
    for s = 1:4
        for p = 1:52
            if ~isempty(heartData(p).heartRate)
                HR(p,s) = heartData(p).heartRate(s);
            end
            if ~isempty(heartData(p).hrv)
                HRV(p,s) = heartData(p).hrv(s);
            end
            if ~isempty(skinData(p).meanSCL)
                SCL(p,s) = skinData(p).meanSCL(s);
            end
            if ~isempty(blinkData(p).blinkRate)
                EBR(p,s) = blinkData(p).blinkRate(s);
            end
        end
    end
    
    HR = reshape(HR,[52*4,1]);
    HRV = reshape(HRV,[52*4,1]);
    SCL = reshape(SCL,[52*4,1]);
    EBR = reshape(EBR,[52*4,1]);
    
    participants = 1:52;
    id = repmat([participants]',[4,1]);
    session = sort(repmat([1:4]',[participants(end),1])); % 1 is all phases, 2 baseline1, 3 main task, 4 baseline2
    
    physiological = [id, session, HR(:), HRV(:), EBR(:), SCL(:)];
    physiological(physiological == 0) = NaN;
    
    physiological = array2table(physiological, 'VariableNames', ...
        {'id','session','HR','HRV','EBR','SCL'});
    
    save('/Users/Bowen/Documents/MATLAB/PPP/data/physiologicalData.mat','physiological');
    
    writetable(physiological,'/Users/Bowen/Documents/R/PPP/physiological');
end

%% Check individual participants
for tidiness = 1
    % HR
    figure;
    for p = [1:9,11:17,19:33,35:46];
        disp(p);
        plot(heartData(p).timeSeries(1,:));
        ylim([60 100]);
        pause;
        close
    end
    
    % GSR
    % Participants for exclusion: 1:8, 11, 16, 26,
    % Possibly weird participants: 18
    for x = [9,10,12:15,17:25,27:52]
        try
            figure;
            plot(skinData(x).responseTime,skinData(x).response);
            text = sprintf('Participant %.0f',x);
            title(text);
            pause
            close
        catch
            continue
        end
    end
    
    % EBR
    figure;
    for p = 1:52;
        disp(p);
        plot(blinkData(p).timeSeries(1,:));
        ylim([0 70]);
        pause;
        close
    end
end

%% HR
% HR reward
figure;
allBeats = cat(1,heartData.rewardHeartTimes);
nhist(cat(2,allBeats{:}),'smooth','pdf','noerror');
title('Probability density function of heartbeats after reward presentation','FontSize',20);
set(gca,'FontName','Helvetica');
xlabel('Time (ms)','FontSize',20); ylabel('Probability density function','FontSize',20);
xlim([0, 4000]);

%% EBR
figure;
allBlinks = cat(1,blinkData.rewardBlinkTimes);
for r = 1:4
    %subplot(2,2,r);
    % hist(cat(2,allBlinks{:,r}),100);
    nhist(cat(2,allBlinks{:,r}),'smooth', 'pdf'); hold on;
    %xlim([0 2000]);
    %ylim([20 80]);
    
end
nhist(cat(2,allBlinks{:}),'smooth','pdf','noerror');
title('Probability density function of eyeblinks after reward presentation','FontSize',20);
set(gca,'FontName','Helvetica');
xlabel('Time (ms)','FontSize',20); ylabel('Probability density function','FontSize',20);
xlim([0, 5500]);


%% GSR
% Standardize values
for p = 1:52
    if ~isempty(skinData(p).meanSCL)
        SCL(p,:) = skinData(p).meanSCL;
    else
        SCL(p,1:4) = NaN;
    end
end

for x = 1:52
    normSCL(x,:) = zscore(SCL(x,2:4)); % just take 3 task phases (ignore whole task)
    normSCL(x,:) = SCL(x,2:4); % Range corrected
    normSCL(x,:) = zscore(SCL(x,2:4)); % Prop of maximum
end

for x = 1:52
    normResponse(x,:) = zscore(response(x,:));
    for r = 1:4
        normReward{r}(x,:) = zscore(reward{r}(x,:));
    end
end

% GSR response
GSRresponse = [];
for p = [9,10,12:15,17,19:25,27:52]
    if ~isempty(skinData(p).response)
        GSRresponse(p,1:6656) = skinData(p).response;
    else
        GSRresponse(p,1:6656) = nan([1,6656]);
    end
end
aspSCL = nanmean(GSRresponse(Aspartame,:));
gluSCL = nanmean(GSRresponse(Glucose,:));

figure;
plot(skinData(15).responseTime,aspSCL); hold on
plot(skinData(15).responseTime,gluSCL);
legend({'Aspartame','Maltodextrin'},'FontSize',20)
set(gca,'FontName','Helvetica');
xlabel('Time (ms)','FontSize',20); ylabel('Amplitude (?S)','FontSize',20);
title('Group differences in response-locked SCL','FontSize',20);

% GSR reward
reward = [];
for r = 1:4
    for p = [9,10,12:15,17,19:25,27:52]
        if ~isempty(skinData(p).response)
            reward{r}(p,1:6656) = skinData(p).reward{r};
        else
            reward{r}(p,1:6656) = nan([1,6656]);
        end
    end
    reward{r}(reward{r} == 0) = NaN;
end
figure;
for r = 1:4
    plot(skinData(15).rewardTime{r},nanmean(reward{r})); hold on;
end
legend({'No reward','Small','Medium','Large'},'FontSize',20);
title('Grand average reward-locked SCL','FontSize',20);
set(gca,'FontName','Helvetica');
xlabel('Time (ms)','FontSize',20); ylabel('Amplitude (?S)','FontSize',20);
xlim([0, 8500]);

% Split by treatment
for r = 1:4
    gluRew{r} = reward{r}(Glucose,:);
    aspRew{r} = reward{r}(Aspartame,:);
end
figure;
for r = 1:4
    plot(skinData(15).rewardTime{r},nanmean(gluRew{r})); hold on;
end
figure;
for r = 1:4
    plot(skinData(15).rewardTime{r},nanmean(aspRew{r})); hold on;
end
legend({'No reward','Small','Medium','Large'},'FontSize',20);
title('Grand average reward-locked SCL','FontSize',20);
set(gca,'FontName','Helvetica');
xlabel('Time (ms)','FontSize',20); ylabel('Amplitude (?S)','FontSize',20);
xlim([0, 8500]);

% Reward vs no reward
figure;
allRew = [];
for r = 2:4
    allRew = cat(1,allRew,reward{r});
end
noRewSE = nanstd(reward{1});
allRewSE = nanstd(allRew);
shadedErrorBar(skinData(15).rewardTime{1},nanmean(reward{1}),noRewSE,'-b',1); hold on
shadedErrorBar(skinData(15).rewardTime{1},nanmean(allRew),allRewSE,'-r',1);

plot(skinData(15).rewardTime{1},nanmean(reward{1})); hold on;
plot(skinData(15).rewardTime{1},nanmean(allRew));
