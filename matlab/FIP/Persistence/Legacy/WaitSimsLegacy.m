%% Find optimal waiting times and simulate persistence data
clear
% Setup parameters
params.smallReward = 0.01; % Reward size (dollars)
params.largeReward = 0.15;
params.upperlimit = 20; % Upper bound
params.ITI = 2; % Intertrial interval
params.experimentLength = 600; % Length of experiment in seconds

params.numTauEstimations = 100000; % Number of random draws from distribution to estimate mean reward delivery time

% Uniform distribution
params.a = 0;
params.b = 12;

% Pareto distribution
params.k = 8;
params.sigma = 3.4;
params.theta = 0; % Lower bound

%% First find maximum reward rate for waitPolicy(t)
trialLength = params.upperlimit;
expectedReturn = NaN(1,trialLength);
expectedCost = NaN(1,trialLength);
rT = NaN(2,trialLength);
x = 1;
for t = 0.01:0.01:trialLength
    [expectedReturn(1,x), expectedCost(1,x), rT(1,x)] = waitPolicy(params,t,'uniform');
    [expectedReturn(2,x), expectedCost(2,x), rT(2,x)] = waitPolicy(params,t,'pareto');
    fprintf('Evaluating policy %.1f%%...\n\n',(t./trialLength)*100);
    x = x + 1;
end
[rStar(1),T(1)] = max(rT(1,:)); % Decompose into reward and stopping time
[rStar(2),T(2)] = max(rT(2,:));
fprintf('Maximum total expected return is\nUniform: $%.0f at %.0f seconds.\nPareto: $%.0f at %.0f seconds.\n',...
    rStar(1)*params.experimentLength,T(1)./100,rStar(2)*params.experimentLength,T(2)./100);

%% Plot optimal quitting time for both policies
figure;
% Plot expected return
subplot(2,2,1);
plot(1:size(expectedReturn,2),expectedReturn(1,:));
hold on;
plot(1:size(expectedReturn,2),expectedReturn(2,:));
title('Expected return per trial');
ylabel('Dollars');
% Plot expected cost
subplot(2,2,2);
plot(1:size(expectedCost,2),expectedCost(1,:)); hold on;
plot(1:size(expectedCost,2),expectedCost(2,:));
title('Expected cost per trial');
ylabel('Seconds');
% Plot total reward rate
subplot(2,2,[3,4]);
h = plot(1:size(rT,2),rT(1,:).*params.experimentLength); hold on;
line([T(1) T(1)],get(gca,'YLim'),'Color',[1 0 0],'LineStyle',:)
h2 = plot(1:size(rT,2),rT(2,:).*params.experimentLength); hold on;
line([T(2) T(2)],get(gca,'YLim'),'Color',[1 0 0],'LineStyle',:)
xlabel('Elapsed time'); ylabel('Expected return ($)');
title('Expected total monetary return for waitPolicy(t)');
legend([h,h2],'Uniform distribution','Pareto distribution');

%% Calculate subjective value and action for each time point



for t = 1:1:trialLength
    [gT(1,t)] = valuePolicy(params,t,rStar(1),T(1)./60,'uniform');
    [gT(2,t)] = valuePolicy(params,t,rStar(2),T(2)./60,'pareto');
end

figure;
plot(1:size(gT,2),gT(1,:)); hold on;
plot(1:size(gT,2),gT(2,:));
axis([-inf,inf,0,inf]);

%% Plot subjective value
subplot(2,1,1);
plot(1:size(gT,2),gT);
title('Subjective Value');

% Plot action
[N,edges] = histcounts(action{1},900);
[f,x,flo,fup] = ecdf(N,'function','survivor');
subplot(3,2,[5 6]);
stairs(x,f);
hold on;
stairs(x,flo,'r:'); stairs(x,fup,'r:');
title('Survivor Function');
hold off;
AUC = trapz(x,flo);