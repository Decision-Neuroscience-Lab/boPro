function [data, time, interval, discarded] = timedecData

dataDir = 'Q:\DATA\TIMEDEC\data\behavioural\';
participants = [1:57,59:91,95:145];
data = [];
time = [];
interval = [];
for x = participants
    discarded(x) = 0;
    disp(x)
    stringfordir = sprintf('%.0f_*', x);
    cd(dataDir);
    loadname = dir(stringfordir);
    load(loadname.name);
    
    % Get temporal discounting data
    k = TD.delay1.fast(TD(1).delay1.lasttrial).k50;
    s = TD.delay1.fast(TD(1).delay1.lasttrial).s50;
    
    try
    k2 = TD.delay2.fast(TD(1).delay2.lasttrial).k50;
    s2 = TD.delay2.fast(TD(1).delay2.lasttrial).s50;
    catch
        disp('No second discounting session');
         k2 = NaN;
         s2 = NaN;
    end
   
    
    % Get duration data
    id = x;
            cond = TD.condition(1);
    % Conditions are 1 = above, 2 = below, over (longer), 3 = below, under
    % (shorter), 4 = praise, 0 = control
    trial = (1:(size(TD.time1,1)))';
    sample = TD.time1(:,1);
    timeOn = TD.time1(:,4);
    timeOff = TD.time1(:,5);
    
    %% Remove missed
    toDelete = timeOn == 0;
    discarded(x) = sum(toDelete) + discarded(x);
    sample(toDelete,:) = [];
    timeOn(toDelete,:) = [];
    timeOff(toDelete,:) = [];
    trial(toDelete,:) = [];
    
    idTime(1:length(trial),1) = x;
    
    % Fundamental stats
    reproduction = timeOff-timeOn;
    diff = reproduction - sample;
    absDiff = abs(reproduction-sample);
    relDiff = diff ./ sample;
    relReproduction = reproduction ./ sample;
    SR = sample ./ reproduction;
    absError = absDiff./sample;
    [reproductionData] = durationReproductionStats(sample,reproduction);
    
    % Individual intervals
    intervals = exp(.7+.4.*[0 1 2 3 4 5]);
    for int = 1:numel(intervals)
        d = sample == intervals(int);
        temp1 = sample(d);
        temp2 = reproduction(d);
        [individual{int}] = durationReproductionStats(temp1,temp2);
        idInterval(int,1) = x;
        sampleInterval(int,1) = intervals(int);
        cv(int,1) = individual{int}(:,2);
    end

    
    % Curve fitting for individual intervals (variation)
    weber = 'a.*log(x)+c';
    stevens =  'k*(x^b)';
    fitTypes = {weber, stevens};
    [xData, yData] = prepareCurveData(sampleInterval, cv);
    for f = 1:numel(fitTypes)
        ft = fittype(fitTypes{f});
        [FO{f}, G{f}] = fit(xData, yData, ft);
    end
    weberVar = FO{1}.a;
    weberVarR= G{1}.rsquare;
    stevensVar = FO{2}.b;
    stevensVarR = G{2}.rsquare;
    
    %% Curve fitting
    weber = 'a.*log(x)+c';
    stevens =  'k*(x^b)';
    fitTypes = {weber, stevens};
    [xData, yData] = prepareCurveData(sample, reproduction);
    for f = 1:numel(fitTypes)
        ft = fittype(fitTypes{f});
        [FO{f}, G{f}] = fit(xData, yData, ft);
    end
    weber1 = FO{1}.a;
    weber2 = FO{1}.c;
    weberR= G{1}.rsquare;
    stevens1 = FO{2}.k;
    stevens2 = FO{2}.b;
    stevensR = G{2}.rsquare;
    
    data = cat(1,data,[id,cond,k,s,k2,s2,weber1,weber2,weberR,stevens1,stevens2,stevensR,reproductionData,weberVar,weberVarR,stevensVar,stevensVarR]); % Build into data file
    time = cat(1,time,[idTime,trial,sample,reproduction,diff,absDiff,relReproduction,SR,relDiff,absError]); % Build into data file (time series)
    temp3 = cat(1,individual{1},individual{2},individual{3},individual{4},individual{5},individual{6});
    interval = cat(1,interval,[idInterval,sampleInterval,temp3]);
    
    clearvars -except dataDir participants data discarded time interval
end
end