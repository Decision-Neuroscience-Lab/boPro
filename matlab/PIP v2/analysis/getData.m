
participants = [1:11];
trialData = [];
practiceData = [];
thirst = [];

for x = participants
    oldcd = cd('/Users/Bowen/Documents/MATLAB/PIP v2/data');
    name = sprintf('%.0f_1_*', x);
    loadname = dir(name);
    load(loadname.name,'data');
    cd(oldcd);
    
    if x < 6
        % Thirst ratings
        thirst = cat(1,thirst,[data.startThirst, data.midThirst, data.endThirst]);
        
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
        temp4 = cat(2, id', session', trial',[data.trialLog.D]',[data.trialLog.bisectRt]',[data.trialLog.A]',[data.trialLog.totalvolume]');
        
        trialData = cat(1,trialData,temp4);
        
    else
        % Thirst ratings
        thirst = cat(1,thirst,[data.startThirst, data.midThirst, data.endThirst]);

        % Main task
        id(1:size(data.trialLog,2)) = x;
        session(1:size(data.trialLog,2)) = 2;
        trial = 1:size(data.trialLog,2);
        temp4 = cat(2, id', session', trial',[data.trialLog.D]',[data.trialLog.bisectRt]',[data.trialLog.A]',[data.trialLog.totalvolume]');
        
        trialData = cat(1,trialData,temp4);
    end
    
    clearvars -except x participants thirst practiceData trialData
    
end

fill = NaN(size(practiceData,1),1);
practiceData = cat(2,practiceData,fill,fill);

clearvars -except x participants thirst practiceData trialData
return