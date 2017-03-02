participants = [1:10];
models = {'ert','ofs','timerr','opportunityBonus'};

for x = participants
    [~, empRewardDensity(x), ~, simRewardDensity(x)] = simulateTD(11.5,'timerr',x);
    
    [~, ~, ipPsi(x,1:3), ipPsiAverage(x,1:3), ipQuest(x,1:3)] = checkIP(x);
    
    if x ~= 4
        propBias(x) = checkBias(x);
    end
    
    optimality(x,1) = empRewardDensity(x)/simRewardDensity(x);
end

% Get total volume
for x = participants
    oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
    name = sprintf('%.0f_1_*', x); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);
    score(x,1) = data.trialLog(end).totalvolume;
end

%% Fit TD models to individual participants
participants = [1:10];
for x = participants
    oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
    name = sprintf('%.0f_1_*', x); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);

    % Format variables from data
    empChoice = [data.trialLog.choice]';
    ssA = [data.trialLog.fA]';
    ssD = [data.trialLog.fD]';
    llA = [data.trialLog.A]';
    llD = [data.trialLog.D]';
    
    [H(x,1:2), Hfval(x), exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, 'hyperbolic');
    [E(x,1:2), Efval(x), exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, 'exponential');
    [R(x,1:2), Rfval(x), exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, 'random');
    
    pseudoR = @(L,R) (R-L)/R;
    Hfit(x) = pseudoR(Hfval(x),Rfval(x));
    Efit(x) = pseudoR(Efval(x),Rfval(x));
end

%% Fit to all participants
participants = [1:10];
empChoice = [];
ssA = [];
ssD = [];
llA = [];
llD = [];
for x = participants
    oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
    name = sprintf('%.0f_1_*', x); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);
    
    
    % Format variables from data
    empChoice = cat(1,empChoice,[data.trialLog.choice]');
    ssA = cat(1,ssA,[data.trialLog.fA]');
    ssD = cat(1,ssD,[data.trialLog.fD]');
    llA = cat(1,llA,[data.trialLog.A]');
    llD = cat(1,llD,[data.trialLog.D]');
end

[H, Hfval, exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, 'hyperbolic');
[E, Efval, exitflag] = fitTD(ssA, ssD, llA, llD, empChoice, 'exponential');


%% Fit foraging models to individual participants
participants = [1:10];
for x = participants
    if x ~= 4
    oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
    name = sprintf('%.0f_3_*', x); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);
    
    % Format variables from data
    empChoice = [data.trialLog.choice]';
    ssA = [data.trialLog.fA]';
    ssD = [data.trialLog.fD]';
    llA = [data.trialLog.A]';
    llD = [data.trialLog.D]';
    
    iti = data.params.drinktime + data.params.choicetime + 0.5;
    iti = 11.5;
    [E(x), Efval(x), exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'ert');
    [O(x), Ofval(x), exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'opportunityCost');
    [S(x), Sfval(x), exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'simpleTimerr');
    [R(x), Rfval(x), exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'random');
    
    pseudoR = @(L,R) (R-L)/R;
    Efit(x) = pseudoR(Efval(x),Rfval(x));
    Ofit(x) = pseudoR(Ofval(x),Rfval(x));
    Sfit(x) = pseudoR(Sfval(x),Rfval(x));
    end
end

%% Fit to all participants
participants = [1:10];
empChoice = [];
ssA = [];
ssD = [];
llA = [];
llD = [];
for x = participants
    oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
    name = sprintf('%.0f_1_*', x); % 1 is session number for calibration
    loadname = dir(name);
    load(loadname.name);
    cd(oldcd);
    
  iti = data.params.drinktime + data.params.choicetime + 0.5;
    iti  = 0;
    % Format variables from data
    empChoice = cat(1,empChoice,[data.trialLog.choice]');
    ssA = cat(1,ssA,[data.trialLog.fA]');
    ssD = cat(1,ssD,[data.trialLog.fD]');
    llA = cat(1,llA,[data.trialLog.A]');
    llD = cat(1,llD,[data.trialLog.D]');
end

[E, Efval, exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'ert');
[O, Ofval, exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'opportunityCost');
[S, Sfval, exitflag] = fitSimple(ssA, ssD, llA, llD, empChoice, iti, 'simpleTimerr');

%% Checking optimality for each
participants = 1:10;
dataMatrix = [];
for x = participants
    if x ~= 4
        oldcd = cd('Q:\CODE\PROJECTS\TIMEJUICE\EDT v6\data');
        name = sprintf('%.0f_3_*', x); % 1 is session number for calibration
        loadname = dir(name);
        load(loadname.name);
        cd(oldcd);
        
        % Format variables from data
        id(1:size(data.trialLog,2),1) = x;
        trial = [1:size(data.trialLog,2)]';
        ind = [];
        ind = cat(2, [id],[trial],[data.trialLog.fA]',[data.trialLog.fD]',[data.trialLog.A]',[data.trialLog.D]',[data.trialLog.choice]',[data.trialLog.totalvolume]',[data.trialLog.choiceBias]');
        
        for t = 1:size(data.trialLog,2)
        amounts(t,1) = data.trialLog(t).amount(1);
        amounts(t,2) = data.trialLog(t).amount(2);
        amounts(t,3) = data.trialLog(t).amount(3);
        predReward(t,1) = amounts(t, ind((t),9));
        reward(t,1) = amounts(t,ind((t),7));
        if t ~= 1
        predJuice(t,1) = predJuice(t-1,1) + amounts(t,ind((t),9));
        else
            predJuice(t,1) = ind(t,8);
        end
        end
        
        ind = cat(2,ind,[reward,predReward,predJuice]);
             
        % Remove missing
        i = ind(:,7) == 3;
        ind(i,:) = [];
        
        juice = ind(:,8);
        predJuice = ind(:,12);
        
        % Plots
        figure;
        hold on;
        plot(1:size(ind,1),juice,'r-') % Plot total juice
        plot(1:size(ind,1),predJuice, 'g-') % Plot predicted juice
        plot(1:size(ind,1), predJuice-juice,'b-') % Plot difference
        title(sprintf('Participant %0.f, total juice vs expected juice',x));
        
% Check whether choices biased
bias = ind(:,9);
choice = ind(:,7);
optimal = choice == bias;

full = size(optimal,1);
    quad(1) = mean(optimal(1:floor(full/4)));
    quad(2) = mean(optimal(floor(full/4):floor(full/2)));
    quad(3) = mean(optimal(floor(full/2):floor(full*(3/4))));
    quad(4) = mean(optimal(floor(full*(3/4)):full));
figure;
bar(quad);
title(sprintf('Participant %0.f optimal for each quarter',x));

        % Regression
        predMatrix = [ind(:,3:6),ind(:,7)];
        [b(:,x),dev,stats] = glmfit(predMatrix,choice-1,'binomial');
        [c(:,x),dev,stats] = glmfit(predMatrix,optimal,'binomial');
        
        dataMatrix = cat(1,dataMatrix,ind);
    end
    clearvars -except dataMatrix nonOpt
end

i = dataMatrix(:,7) == dataMatrix(:,9);
nonOptimal = dataMatrix(~i,:);
predMatrix = [dataMatrix(:,3), dataMatrix(:,5:7)]%, dataMatrix(:,8)];
[b,dev,stats] = glmfit(predMatrix,i,'binomial');
[b,dev,stats] = glmfit(predMatrix,dataMatrix(:,7)-1,'binomial');

% Box plot variables, vs non-optimal
for t = 1:size(dataMatrix,1)
    if dataMatrix(t,7) == dataMatrix(t,9)
        group{t,1} = 'Biased';
    else
        group{t,1} = 'Non-biased';
    end
end
variables = [3,5:8];
text = char('ssA', 'llA', 'llD', 'choice', 'juice');
c = 1;
for v = variables
figure;
boxplot(dataMatrix(:,v),group);
title(text(c,:));
c = c + 1;
end