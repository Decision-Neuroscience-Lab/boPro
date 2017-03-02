%% Extract discounting data and collapse k value

dataDir = '/Users/Bowen/Documents/MATLAB/TIMEDEC/behavioural data';
participants = [1:57,59:91,95:145];
data = [];

for x = participants
    fprintf('Loading participant %.0f...\n',x);
    stringfordir = sprintf('%.0f_*', x);
    oldcd = cd(dataDir);
    loadname = dir(stringfordir);
    load(loadname.name);
    cd(oldcd);
    
    % TD1
    numTrials = TD.delay1.lasttrial;
    id = repmat(x,numTrials,1);
    trial = [1:numTrials]';
    llTop = [TD.delay1.options.lltop]';
    delay = [TD.delay1.options.delay]';
    ssA = [TD.delay1.options.vn]';
    llA = [TD.delay1.options.vd]';
    response = [TD.delay1.response.choice]'; % 0 is SS, 1 is LL, -1 is no response
    llRight = [TD.delay1.response.llright]';
    rt = [TD.delay1.response.rt]';
    
    data = cat(1,data,[id,trial,llTop(1:numTrials),delay(1:numTrials),ssA,llA,llRight(1:numTrials),response,rt]);
    
    try
        clearvars numTrials
        % TD2
        numTrials = TD.delay2.lasttrial;
        id = repmat(x,numTrials,1);
        trial = [1:numTrials]';
        llTop = [TD.delay2.options.lltop]';
        delay = [TD.delay2.options.delay]';
        ssA = [TD.delay2.options.vn]';
        llA = [TD.delay2.options.vd]';
        response = [TD.delay2.response.choice]'; % 0 is SS, 1 is LL, -1 is no response
        llRight = [TD.delay2.response.llright]';
        rt = [TD.delay2.response.rt]';
        
        data = cat(1,data,[id,trial,llTop(1:numTrials),delay(1:numTrials),ssA,llA,llRight(1:numTrials),response,rt]);
    catch
        fprintf('No second discounting session for participant %.0f.\n',x);
    end
    
    clearvars -except dataDir participants data
end
fprintf('Done.\n');

trialData = array2table(data,'VariableNames',{'id','trial','llTop','delay','ssA','llA','llRight','response','rt'});
writetable(trialData,'discountingData');

%% Do quick check on missed responses
for x = participants
    temp = trialData(trialData.id == x,:);
    missed(x) = sum(temp.response == -1);
end
findID = find(missed > 10); % Identify participants who weren't paying attention
% Remove participants
participants(ismember(participants, findID)) = [];

%% Do quick check on choices toward negative numbers
for x = participants
    temp = trialData(trialData.id == x,:);
    neg(x) = sum(temp.llA < 0 & temp.response == 1);
end
findID = find(neg > 1); % Identify participants who weren't paying attention
% Remove participants
participants(ismember(participants, findID)) = [];

%% Delete remaining missed responses
trialData(trialData.response == -1,:) = [];

%% Fit functions to data
numberOfTests = 20;
model = {'hyperbolic','exponential','qh','random'};
for m = 1:4
    for x = participants
        
        bestFval = inf;
        
        temp = trialData(trialData.id == x,:);
        for t = 1:numberOfTests
            fprintf('Fitting participant %.0f, iteration %.0f.\n',x,t);
            try
                [minPar, fval, exitflag] = fitTD(temp.ssA, zeros(size(temp.ssA,1),1), temp.llA, temp.delay, temp.response + 1, model{m});
                if fval < bestFval
                    
                    bestFval = fval;
                    
                    fit(x,m) = bestFval;
                    
%                     k(x) = minPar(2);
%                     s(x) = minPar(1);
%                     
%                     if size(minPar,2) > 2
%                         beta(x) = minPar(3);
%                     end
                end
            catch
                fprintf('Could not fit.\n');
                continue
            end
        end
        fprintf('Done.\n\n\n');
    end
end