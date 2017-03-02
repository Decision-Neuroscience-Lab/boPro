participants = [1:17,19:26];
trialData = [];
practiceData = [];
thirst = [];

for x = participants
    oldcd = cd('/Users/Bowen/Documents/MATLAB/PIP v3/data');
    
    try % If there was a restart in one of the files load the second file
        name = sprintf('%.0f_2_*', x);
        loadname = dir(name);
        load(loadname.name,'data');
        fprintf('Loaded restarted data for participant %.0f.\n',x);
    catch
        % Load first try
        name = sprintf('%.0f_1_*', x);
        loadname = dir(name);
        load(loadname.name,'data');
    end
    cd(oldcd);
    
  % Practice (no reward)
    id(1:size(data.firstPractice,2)) = x;
    session(1:size(data.firstPractice,2)) = 1;
    trial = 1:size(data.firstPractice,2);
    temp1 = cat(2,id', session', trial', [data.firstPractice.D]', [data.firstPractice.bisectRt]');
    session(1:size(data.secondPractice,2)) = 3;
    trial = 1:size(data.secondPractice,2);
    temp2 = cat(2,id', session', trial', [data.secondPractice.D]', [data.secondPractice.bisectRt]');
    practiceData = cat(1,practiceData,temp1,temp2);
    clearvars id session trial temp1 temp2
    
    % Main task
    id(1:size(data.trialLog,2)) = x;
    session(1:size(data.trialLog,2)) = 2;
    trial = 1:size(data.trialLog,2);
    temp4 = cat(2, id', session', trial',[data.trialLog.D]',[data.trialLog.bisectRt]',[data.trialLog.A]',[data.trialLog.totalvolume]',[data.trialLog.thirst]',[data.trialLog.pleasantness]');
    % Append initial thirst rating
  %  temp4(1,8) = data.startThirst;
    
    trialData = cat(1,trialData,temp4);
    th = [data.trialLog.thirst];
    th(isnan(th)) = [];
    firstthirst = data.startThirst;
    endThirst = data.endThirst;
    temp45 = [firstthirst, th, endThirst];
    thirst(x,:) = [firstthirst, th, endThirst];
    practice(x) = data.rewardPractice;
    
     pl = [data.trialLog.thirst];
    pl(isnan(pl)) = [];
    pleasantness(x,:) = pl;
    
    
    clearvars -except x participants practiceData trialData data practice thirst pleasantness
    
end

fill = NaN(size(practiceData,1),1); % Make extra columns to fit trialData
practiceData = cat(2,practiceData,repmat(fill,1,size(trialData,2)-size(practiceData,2)));

trialData = cat(1,practiceData,trialData); % Adjoin trial and practice
trialData(isnan(trialData(:,6)),6) = 0; % Make practice 'zero' reward
trialData(trialData(:,6) == 0.01,6) = 0; % Make 0.01 'zero' reward
trialData(trialData(:,6) == 0.05,6) = 0; % Make 0.05 'zero' reward
trialData = sortrows(trialData,[1,2]);
for x = participants
trialData(trialData(:,1)==x,3) = 1:size(trialData(trialData(:,1)==x),1); % Change to global trial number
end

trialData = array2table(trialData,'VariableNames',{'id','session','trial','delay','response','reward','totalvolume','thirst','pleasantness'});
trialData.Properties.VariableUnits = {'' '' '' 'Seconds' 'Seconds' 'mL' 'mL' '' ''};

clearvars -except x participants trialData thirst
return