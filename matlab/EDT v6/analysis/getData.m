
participants = [1:19];
dataMatrix = [];

for x = participants
    if x == 4 % Go to next participant as file is missing
        continue;
    end
    oldcd = cd('/Users/Bowen/Documents/MATLAB/EDT v6/data');
    name = sprintf('%.0f_3_*', x);
    loadname = dir(name);
    load(loadname.name,'data');
    cd(oldcd);
  
    % Format variables from data
    id(1:size(data.trialLog,2),1) = x;
    trial = [1:size(data.trialLog,2)]';
    dataMatrixIndividual = cat(2, [id],[trial],[data.trialLog.fA]',[data.trialLog.fD]',[data.trialLog.A]',[data.trialLog.D]',[data.trialLog.choice]',[data.trialLog.totalvolume]',[data.trialLog.choiceBias]');
    
    % Name variables and create new ones
    ssA = dataMatrixIndividual(:,3);
    ssD = dataMatrixIndividual(:,4);
    llA = dataMatrixIndividual(:,5);
    llD = dataMatrixIndividual(:,6);
    choice = dataMatrixIndividual(:,7);
    bias = dataMatrixIndividual(:,9);
    
    optimal = choice == bias;
    sooner = choice == 1;
    later = choice == 2;
    missed = choice == 3;
    predSooner = bias == 1;
    predLater = bias == 2;
    
    for t = 1:size(dataMatrixIndividual,1)
        if sooner(t)
            cA(t,1) = ssA(t);
            cD(t,1) = ssD(t);
        elseif later(t)
            cA(t,1) = llA(t);
            cD(t,1) = llD(t);
        elseif missed(t)
            cA(t,1) = 0;
            cD(t,1) = llD(t);
        end
        if predSooner(t)
            pA(t,1) = ssA(t);
            pD(t,1) = ssD(t);
        elseif predLater(t)
            pA(t,1) = llA(t);
            pD(t,1) = llD(t);
        end
    end
    
    dataMatrixIndividual = cat(2,dataMatrixIndividual,[cA,cD,pA,pD,optimal]);
    
    % Get reaction time
    rt = [data.trialLog.rt]';
    dataMatrixIndividual = cat(2,dataMatrixIndividual,rt);
        
    dataMatrix = cat(1,dataMatrix,dataMatrixIndividual);
    clearvars -except x participants dataMatrix
    
end

% Load calib file for other tests
dataMatrixCalibration = [];
for x = participants
    
    oldcd = cd('/Users/Bowen/Documents/MATLAB/EDT v6/data');
    name = sprintf('%.0f_1_*', x);
    loadname = dir(name);
    load(loadname.name,'data');
    cd(oldcd);
    
    % Build data matrix for calibration
    id(1:size(data.trialLog,2),1) = x;
    trial = [1:size(data.trialLog,2)]';
    dataMatrixCalibIndividual = cat(2, [id],[trial],[data.trialLog.fA]',[data.trialLog.fD]',[data.trialLog.A]',[data.trialLog.D]',[data.trialLog.choice]',[data.trialLog.totalvolume]', [data.trialLog.rt]');
    dataMatrixCalibration = cat(1,dataMatrixCalibration,dataMatrixCalibIndividual);
    clearvars -except x participants dataMatrix dataMatrixCalibration
    
end



dCal = [ones(size(dataMatrixCalibration,1),1), dataMatrixCalibration; ones(size(dataMatrix,1),1) + 1, dataMatrix(:,1:9)];
dCal(dCal(:,2) == 4,:) = [];

return