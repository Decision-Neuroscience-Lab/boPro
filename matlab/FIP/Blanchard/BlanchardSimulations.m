%% Load data
set(0,'DefaultFigureColor',[1 1 1]);

load('/Users/Bowen/Documents/MATLAB/EDT v6/dataMatrix');
dataMatrix(dataMatrix(:,1) > 4, 1) = dataMatrix(dataMatrix(:,1) > 4, 1) - 1; % (Because we are missing participant 4)
% dataMatrix(dataMatrix(:,2) > 4, 2) = dataMatrix(dataMatrix(:,2) > 4, 2) - 1; % (Because we are missing participant 4)
% dataMatrix(:,1) = [];

%% Estimate parameters from pilot
for p = 1:18 % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    [estPars(p,1:2), ~, ~] = fitITI(subset.ssA, subset.ssD, subset.llA, subset.llD, subset.choice); % Estimate parameters
end
% Plot estimates
figure;
hBar = bar(estPars(:,1));
set(hBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated temperature');
figure;
dBar = bar(estPars(:,2));
set(dBar,'FaceColor',[.3 .3 .3],'EdgeColor',[1 1 1]);
xlabel('Participants');
ylabel('Estimated omega');

%% Simulate choices using gleaned parameters and compare to data
for p = 1:18 % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    simData{p} = simITI(estPars(p,:),[subset.ssA, subset.llA], [subset.ssD, subset.llD],height(subset)); % Simulate parameters
    hitRate(p,1) = mean(simData{p}(:,5) == subset.choice);
end

%% Recover estimated parameters from simulated choices
for p = 1:18 % Participant loop
    [estPars2(p,1:2), ~, ~] = fitITI(simData{p}(:,1), simData{p}(:,2), simData{p}(:,3), simData{p}(:,4), simData{p}(:,5)); % Estimate parameters
end

%% Simulate new data using new (arbitrary) parameters and recover these parameters
beta = 9;
omega = 6;
amounts = [0:0.2:5];
delays = [5, 15, 30, 60];
numParticipants = 40;
numTrials = 3;
% Generate some choice options
AA = nan(numTrials,2);
DD = nan(numTrials,2);
for t = 1:numTrials
    AA(t,1:2) = [amounts(randi(numel(amounts)./2)),amounts(randi([numel(amounts)./2, numel(amounts)]))]; % Randomly choose approximately SS
    DD(t,1:2) = [delays(randi(numel(delays)./2)), delays(randi([numel(delays)./2, numel(delays)]))]; % Randomly choose approximately LL
end

for p = 1:numParticipants
    simData2{p} = simITI([beta, omega], AA, DD, numTrials); % Simulate data
    [estPars3(p,1:2), ~, ~] = fitITI(simData2{p}(:,1), simData2{p}(:,2), simData2{p}(:,3), simData2{p}(:,4), simData2{p}(:,5)); % Estimate parameters
    plotPars{1}(p) = estPars3(p,1);
    plotPars{2}(p) = estPars3(p,2);
end

figure;
nhist(plotPars,'smooth','pdf','legend',{'Beta','Omega'},...
    'xlabel','Value','ylabel','Probability density function','color','colormap','fsize',15);

%% Generate a loglikelihood landscape for combinations of parameters
beta = [0:100];
omega = [0:100];
for p = 1:18 % Participant loop
    subset = array2table(dataMatrix(dataMatrix(:,1) == p,3:7),...
        'VariableNames',{'ssA','ssD','llA','llD','choice'}); % Select data
    for b = 1:numel(beta)
        for o = 1:numel(omega)
            ll(p,b,o) = likelihoodITI([beta(b),omega(o)], subset.ssA, subset.ssD, subset.llA, subset.llD, subset.choice);
            fprintf('Participant %.0f, %.0f%%...\n\n',p,(b./numel(beta))*100);
        end
    end
end

% Plot landscape for each participant
for p = 1:18
h = figure;
surf(squeeze(ll(p,:,:)));
set(gcf,'Position',[100, 100, 1500, 1000]);
xlabel('beta'); ylabel('omega'); zlabel('-loglikelihood');
pause;
close(h);
end