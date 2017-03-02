%% Find optimal waiting times and simulate persistence data
clear
% Setup parameters
params.smallReward = 0.01; % Reward size (dollars)
params.largeReward = 0.15;
params.upperlimit = 20; % Upper bound for testing policy
params.ITI = 2; % Intertrial interval
params.experimentLength = 600; % Length of experiment in seconds
params.numParticipants = 25; % Number of participants - (number of betas drawn from dist)
params.numTrials = 70; % Number of simulated trials
params.sampleRate = 10; % Sample rate per second
params.numTauEstimations = 100000; % Number of random draws from distribution to estimate mean reward delivery time
params.beta = truncate(makedist('Normal',1,0.5),0,40); % Softmax temperature parameter distribution (inverse)
params.uncertain = 1; % Temporal uncertainty switch
params.cv = 0.16; % Coefficient of variation for temporal uncertainty
%% Create distributions (does not handle asymptotes well - please truncate)
% For uniform
params.a = 8;
params.b = 2;
D = makedist('Normal',params.a,params.b);
% For Pareto
params.k = 8;
params.sigma = 3.4;
params.theta = 0; % Lower bound
D2 = makedist('Generalized Pareto',params.k,params.sigma,params.theta);
D2 = truncate(D2,0,90);
% Exponential
params.mu = 1;
D3 = makedist('Exponential',params.mu);
D3 = truncate(D3,0,params.upperlimit);
% Check distributions
%figure;plot(1:20,pdf(D3,1:20));
% Create distribution list
distNames = {D D2 D3};
numD = numel(distNames);
%% First find maximum reward rate for waitPolicy(t)
trialLength = params.upperlimit;
expectedReturn = NaN(numD,trialLength*params.sampleRate);
expectedCost = NaN(numD,trialLength*params.sampleRate);
rT = NaN(numD,trialLength*params.sampleRate);
rStar = NaN(numD,1);
T = NaN(numD,1);
h = WAITBAR(0,'Initializing...');
c = 1;
for d = 1:numD
    x = 1;
    for t = (1/params.sampleRate):(1/params.sampleRate):trialLength;
        [expectedReturn(d,x), expectedCost(d,x), rT(d,x)] = waitPolicy(params,t,distNames{d});
        mes = sprintf('Evaluating policy for distribution %.0f of %.0f.',d,numD);
        WAITBAR(c./(numD*trialLength*params.sampleRate), h, mes);
        x = x + 1;
        c = c + 1;
    end
end
close(h);
for d = 1:numD
    i = expectedReturn(d,:) >= 0.149; % Set threshold for maximum
    expectedReturn(d,i) = NaN;
    expectedCost(d,i) = NaN;
    rT(d,i) = NaN;
    [rStar(d),T(d)] = nanmax(rT(d,:)); % Decompose into reward and stopping time
    %[rStar(d),T(d)] = findpeaks(rT(d,:),'Npeaks',1); % Decompose into reward and stopping time
    
    fprintf('Maximum total expected return for %s distribution is $%.2f at %.2f seconds.\n',...
        distNames{d}.DistributionName,rStar(d)*params.experimentLength,T(d)./params.sampleRate);
end
%% Plot optimal quitting time
figure;
for d = 1:numD
    % Plot expected return
    subplot(2,2,1);
    plot(1:size(expectedReturn,2),expectedReturn(d,:));
    title('Expected return per trial');
    ylabel('Dollars');
    hold on;
end
for d = 1:numD
    % Plot expected cost
    subplot(2,2,2);
    plot(1:size(expectedCost,2),expectedCost(d,:));
    title('Expected cost per trial');
    ylabel('Seconds');
    hold on;
end
l = cell(numD,1);
for d = 1:numD
    % Plot total reward rate
    subplot(2,2,[3,4]);
    h(d) = plot(1:size(rT,2),rT(d,:).*params.experimentLength);
    set(h(d),'userdata',distNames{d}.DistributionName);
    xlabel('Elapsed time'); ylabel('Expected return ($)');
    title('Expected total monetary return for waitPolicy(t)');
    hold on;
    l{d} = sprintf('%s',distNames{d}.DistributionName);
end
c = get(groot,'defaultAxesColorOrder');
for d = 1:numD
    line([T(d) T(d)],get(gca,'YLim'),'Color',c(d,:),'LineStyle',:); hold on;% Indicate maximum
end
legend(h(1:numD),l);
%% Calculate subjective value and action for each time point
action = cell(1,numD);
gT = cell(1,numD);
h = WAITBAR(0,'Initializing waitbar...');
c = 1;
for d = 1:numD
    for n = 1:params.numTrials
        beta = -1;
        while beta < 0
            beta = random(params.beta);
        end
        for t = 1:1:trialLength
            if params.uncertain == 1
                ut = normrnd(t,t*params.cv);
                [action{d}(n,t), gT{d}(n,t)] = valuePolicy(params,ut,rStar(d),T(d)./params.sampleRate,distNames{d},beta);
            else
                [action{d}(n,t), gT{d}(n,t)] = valuePolicy(params,t,rStar(d),T(d)./params.sampleRate,distNames{d},beta);
            end
            c = c + 1;
        end
        mes = sprintf('Deriving actions for distribution %.0f of %.0f',d,numD);
        WAITBAR(c./(numD*params.numTrials*trialLength), h, mes);
    end
end
close(h);
%% Plot subjective value, action rate and survivor functions
figure;
% Plot subjective value
subplot(3,1,1);
for d = 1:numD
    h(d) = plot(1:size(gT{d},2),nanmean(gT{d}(d,:),1));
    set(h(d),'userdata',distNames{d}.DistributionName);
    axis([0,20,0,0.15]);
    hold on;
    l{d} = sprintf('%s',distNames{d}.DistributionName);
end
legend(l);
title('Subjective value');
% Plot action
subplot(3,1,2);
for d = 1:numD
    h(d) = plot(1:size(action{d},2),nanmean(action{d},1)); hold on;
    xlim([0 20]);
end
title('Action')
ylabel('Stop rate');
% Plot survivor function
time = cell(numD);
for d = 1:numD
    for n = 1:params.numTrials
        if ~isempty(find(action{d}(n,:),1))
            time{d}(n,1) = find(action{d}(n,:),1);
            time{d}(n,2) = 0;
        else
            time{d}(n,1) = 0;
            time{d}(n,2) = 1;
        end
    end
end
subplot(3,1,3);
AUC = NaN(3,1);
for d = 1:numD
    [f,x,flo,fup] = ecdf(time{d}(:,1),'function','survivor');
    h(d) = stairs(x,f); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d) = trapz(x,f);
    l{d} = sprintf('AUC: %.3f',AUC(d));
end
legend(h(1:numD),l);
title('Survivor Function');
xlabel('Elapsed time'); ylabel('Probability of stopping');

% Calculate empirical vs optimal
for d = 1:numD
    fprintf('%s deviation from optimality: %.2f.\n',distNames{d}.DistributionName,AUC(d) - (T(d)./params.sampleRate));
end

%% Calculate subjective value and action for each time point and plot WITH JUICE EFFECT
params.effectSize = [0, -1]; % Juice effect size (in seconds)
numE = numel(params.effectSize); % Scale of effect size
action = cell(1,numE);
ACTION = cell(1,numE);
gT = cell(1,numE);
GT = cell(1,numE);
h = WAITBAR(0,'Initializing waitbar...');
c = 1;
for d = 1:numE
    for  p = 1:params.numParticipants
        beta(d,p) = -1;
        while beta(d,p) < 0
            beta(d,p) = random(params.beta);
        end
        for n = 1:params.numTrials
            for t = 1:1:trialLength
                if params.uncertain == 1
                    ut = normrnd(t,t*params.cv);
                    [action{d}(n,t), gT{d}(n,t)] = valuePolicy(params,ut + (params.effectSize(d)),rStar,T./params.sampleRate,distNames{1},beta(d,p));
                else
                    [action{d}(n,t), gT{d}(n,t)] = valuePolicy(params,t + (params.effectSize(d)),rStar,T./params.sampleRate,distNames{1},beta(d,p));
                end
                c = c + 1;
            end
            mes = sprintf('Deriving actions for effect size %.0f of %.0f',d,numE);
            WAITBAR(c./(numE*params.numParticipants*params.numTrials*trialLength), h, mes);
        end
        ACTION{d} = cat(1,ACTION{d},action{d});
        GT{d} = cat(1,GT{d},gT{d});
    end
end
close(h);

figure;
% Plot subjective value
subplot(3,1,1);
for d = 1:numE
    h(d) = plot(1:size(GT{d},2),nanmean(GT{d},1));
    axis([0,20,0,0.15]);
    hold on;
    l{d} = sprintf('+ %.1f secs',params.effectSize(d));
end
legend(l);
title('Subjective value');
% Plot action
subplot(3,1,2);
for d = 1:numE
    h(d) = plot(1:size(ACTION{d},2),nanmean(ACTION{d},1)); hold on;
    xlim([0 20]);
end
title('Action')
ylabel('Stop rate');
% Plot survivor function
time = cell(numE,1);
for d = 1:numE
    for n = 1:size(ACTION{d},1)
        if ~isempty(find(ACTION{d}(n,:),1))
            time{d}(n,1) = find(ACTION{d}(n,:),1);
            time{d}(n,2) = 0;
        else
            time{d}(n,1) = 0;
            time{d}(n,2) = 1;
        end
    end
end
subplot(3,1,3);
AUC = NaN(numE,1);
for d = 1:numE
    [f,x,flo,fup] = ecdf(time{d}(:,1),'function','survivor');
    h(d) = stairs(x,f); hold on;
    stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
    AUC(d) = trapz(x,f);
    l{d} = sprintf('AUC: %.3f',AUC(d));
end
legend(h(1:numE),l);
title('Survivor Function');
xlabel('Elapsed time'); ylabel('Probability of stopping');

% Calculate empirical vs optimal
for d = 1:numE
    fprintf('Effect %.0f deviation from optimality: %.2f.\n',d,AUC(d) - (T./params.sampleRate));
end

% Calculate AUC for each participants separately
AUC = NaN(params.numParticipants,numE);
for d = 1:numE
    c = 1;
    for p = 1:params.numTrials:params.numTrials*params.numParticipants
        TIME = time{d}(p:p+params.numTrials-1,1);
    [f,x,flo,fup] = ecdf(TIME,'function','survivor');
%     h(d) = stairs(x,f); hold on;
%     stairs(x,flo,'k:'); stairs(x,fup,'k:'); % Plot confidence bounds
if trapz(x,f) ~= 0
    AUC(c,d) = trapz(x,f);
else
    AUC(c,d) = x(1);
end
    c = c + 1;
    clearvars TIME
    end
end
[h,p] = ttest2(AUC(:,1),AUC(:,2));
disp([h p]);
