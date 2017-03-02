%% Load data
set(0,'DefaultFigureColor',[1 1 1]);
load('/Users/Bowen/Documents/MATLAB/EDT v6/dataMatrix');

% Clean (missing and bad fits)
for p = [2,17]
    dataMatrix(dataMatrix(:,1) == p,:) = []; % Delete
end
 remP = unique(dataMatrix(:,1),'stable');
 numP = numel(remP);
for p = 1:numP
    dataMatrix(dataMatrix(:,1) == remP(p),1) = p;
end

% Set hyperbolic or exponential
model = 'hyperbolic';

%% Estimate parameters from pilot
for p = 1:numP % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    [estPars(p,1:2), ~, ~] = fitTD(subset.ssA, subset.ssD, subset.llA, subset.llD, subset.choice, model); % Estimate parameters
end

% Plot estimates
figure;
hBar = bar(estPars(:,1));
set(hBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated temperature');
tempFig = gca; hold on;
figure;
dBar = bar(estPars(:,2));
set(dBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated k');
kFig = gca; hold on;

%% Simulate choices using gleaned parameters and compare to data
for p = 1:numP % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    simData{p} = simTD(estPars(p,:),[subset.ssA, subset.llA], [subset.ssD, subset.llD],height(subset),model); % Simulate parameters
    hitRate(p,1) = mean(simData{p}(:,5) == subset.choice);
end
disp(hitRate);
%% Recover estimated parameters from simulated choices
for p = 1:numP % Participant loop
    [estPars2(p,1:2), ~, ~] = fitTD(simData{p}(:,1), simData{p}(:,2), simData{p}(:,3), simData{p}(:,4), simData{p}(:,5), model); % Estimate parameters
end

% Plot over first estimated parameters
hBar = bar(tempFig,estPars2(:,1));
set(hBar,'FaceColor','none','EdgeColor',[1 0 0]);
dBar = bar(kFig,estPars2(:,2));
set(dBar,'FaceColor','none','EdgeColor',[1 0 0]);
%% Simulate new data using new (arbitrary) parameters and recover these parameters
LL = 16; % Fixed large amount
delays = [5, 15, 30, 60];
numParticipants = 40;
numTrials = 3;
simData2 = cell(numParticipants,1);

for p = 1:numParticipants
    genPars(p,2) = random('gamma',0.1,2.5);
    genPars(p,1) = -1;
    while genPars(p,1) < 0
        genPars(p,1) = random('normal',0.5,0.2);
    end
end

for p = 1:numParticipants
    for d = delays
        for t = 1:numTrials
            if t == 1
                sim = simTD(genPars(p,:), [8,LL], [0, d], 1, model); % Simulate data
            elseif simData2{p}(t-1,5) == 1
                sim = simTD(genPars(p,:), [simData2{p}(t-1,1)/2, LL], [0, d], 1, model); % Simulate data
            elseif simData2{p}(t-1,5) == 2
                sim = simTD(genPars(p,:), [simData2{p}(t-1,1)*2, LL], [0, d], 1 ,model); % Simulate data
            end
            simData2{p} = cat(1,simData2{p},sim);
        end
    end
    [estPars3(p,1:2), ~, ~] = fitTD(simData2{p}(:,1), simData2{p}(:,2), simData2{p}(:,3), simData2{p}(:,4), simData2{p}(:,5), model); % Estimate parameters
    plotPars{1}(p) = estPars3(p,1);
    plotPars{2}(p) = estPars3(p,2);
end

% figure;
% nhist(plotPars,'smooth','pdf','legend',{'Beta','K'},...
%     'xlabel','Value','ylabel','Probability density function','color','colormap','fsize',15);

figure;
hBar = bar(estPars3(:,1));
set(hBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated temperature');
hold on;
hBar = bar(genPars(:,1));
set(hBar,'FaceColor','none','EdgeColor',[1 0 0]);
figure;
dBar = bar(estPars3(:,2));
set(dBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated k');
hold on;
dBar = bar(genPars(:,2));
set(dBar,'FaceColor','none','EdgeColor',[1 0 0]);

%% Generate a loglikelihood landscape for combinations of parameters
beta = [0:0.1:10];
k = [0:0.1:2];
for p = 1:numP % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    for b = 1:numel(beta)
        for o = 1:numel(k)
            ll(p,b,o) = likelihoodTD([beta(b),k(o)], subset.ssA, subset.ssD, subset.llA, subset.llD, subset.choice, model);
            fprintf('Participant %.0f, %.0f%%...\n\n',p,(b./numel(beta))*100);
        end
    end
end

% Plot landscape for each participant
for p = 1:numP
h = figure;
surf(squeeze(ll(p,:,:)));
set(gcf,'Position',[100, 100, 1500, 1000]);
xlabel('beta'); ylabel('k'); zlabel('-loglikelihood');
pause;
close(h);
end