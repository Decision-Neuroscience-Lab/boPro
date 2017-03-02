dataDir = 'Q:\DATA\BB\raw\behavioural\';
participants = [1:14];
nParticipants = numel(participants);  

load('Q:\CODE\PROJECTS\BB\Analysis\fitParameters.mat');
par = x;

likelihood = [];
counter = 0;

for p = participants
    
    logFile = [dataDir 'BLINKBANDIT_DATA_p' num2str(p) '.mat'];
    load(logFile, 'trialLog');
    
    iti = [iti [trialLog.iti]];
    rt = [rt [trialLog.rt]];
    
    
end


for p = participants
      
    counter = counter + 1;
    logFile = [dataDir 'BLINKBANDIT_DATA_p' num2str(p) '.mat'];
    load(logFile, 'trialLog');
%     likelihood(counter) = DanKalman(par,trialLog, counter);
    [~, beliefs{p}] = DanKalman(par,trialLog,counter);
    

    logFile = [dataDir 'BLINKBANDIT_DATA_p' num2str(p) '.mat'];
    belief = beliefs{p};
    rt(p) = nanmean([trialLog.rt]);
    
    maxPayoff = max(belief);
    for i = 1:numel(maxPayoff)
        whichMax = find(belief(:,i) == maxPayoff(i));
        try
            lastChoice = trialLog(i-1).choice;
        catch
            lastChoice = [];
        end
        
        
        trialChoice = trialLog(i).choice;
        if any(trialChoice == whichMax)
            choseMax(p,i) = 1;
        else
            choseMax(p,i) = 0;
        end
        
        if trialChoice == lastChoice
            same(p,i) = 1;
        else
            same(p,i) = 0;
        end
        
    end
    
    
    
    
end

expProp = mean(choseMax') * 100;