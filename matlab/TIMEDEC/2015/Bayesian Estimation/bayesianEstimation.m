function bayesianEstimation
%% Preamble
	toolboxPath = '/Users/Bowen/Documents/MATLAB/misc scripts/delay-discounting-analysis-master/ddToolbox';
	addpath(genpath(toolboxPath))
	projectPath = '/Users/Bowen/Documents/MATLAB/TIMEDEC/2015/Bayesian Estimation';
	cd(projectPath)
% set some graphics preferences
setPlotTheme;

%% Create data object
dataPath = sprintf('%s/data',projectPath);
nameList = dir(fullfile(dataPath,'*.txt'));
% Weird looking participants (high epsilons): 7, 41, 69, 72, 88, 99(?), 107,
% 111, 131, 141 

fnames = sort_nat({nameList.name});
saveName = 'groupData.txt';

% Create the group-level data object
myData = dataClass(saveName);
myData.loadDataFiles(fnames);

%myData.quickAnalysis(); % Simple visualization of data

%% Analyse the data with the hierarchical model

% First we create a model object, which we will call hModel. This is an
% instance of the class 'modelHierarchical'
hModel = modelHierarchical(toolboxPath);

% Here we should change default parameters
hModel.setMCMCtotalSamples(5000); % default is 10^5

hModel.conductInference(myData);

% Plot all the results
% hModel.plot(myData)

%% Check discount rates
plotFlag= true;
figure;
subplot(1,2,1);
logK10 = hModel.conditionalDiscountRates(10, plotFlag);
subplot(1,2,2);
logK100 = hModel.conditionalDiscountRates(100, plotFlag);

%writetable(logK10,'/Users/Bowen/Documents/R/TIMEDEC/bayesianLogK10.csv');
%% Example research conclusions...

% Calculate Bayes Factor, and plot 95% CI on the posterior
hModel.HTgroupSlopeLessThanZero(myData)

% Modal values of m_p for all participants
% Export these point estimates into a text file and analyse with JASP
magEffect = array2table(hModel.analyses.univariate.m.mode')
writetable(magEffect,'/Users/Bowen/Documents/R/TIMEDEC/magEffect.csv');

return