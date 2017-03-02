function [x,fval,exitflag,output] = BBMin
%%
dataDir = 'Q:\DATA\BB\raw\behavioural\';
participants = [100];
nParticipants = numel(participants);

%% standard version
minFun = @(par) ParticipantLoop(par, participants, dataDir);
initial_values = [50, 10,zeros(1,nParticipants) + 0.1];
lowerBounds = [0, 0, zeros(1,nParticipants)];
upperBounds = [100, 100, ones(1,nParticipants)];
options = optimset('Algorithm', 'interior-point', 'Display', 'iter');
[x,fval,exitflag, output] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[], options);

%% exploration bonus version 1
% minFun = @(par) ParticipantLoop(par, participants, dataDir);
% initial_values = [50, 50, 0.5, zeros(1,nParticipants) + 0.01];
% lowerBounds = [0, 0, 0, zeros(1,nParticipants)];
% upperBounds = [100, 100, 1, ones(1,nParticipants)];
% options = optimset('Algorithm', 'interior-point', 'Display', 'iter');
% [x,fval,exitflag, output] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[], options);


%% exploration bonus version 2
% minFun = @(par) ParticipantLoop(par, participants, dataDir);
% initial_values = [50, 50, 0.5, zeros(1,nParticipants) + 0.5];
% lowerBounds = [0, 0, 0, zeros(1,nParticipants)];
% upperBounds = [100, 100, 100, ones(1,nParticipants)];
% options = optimset('Algorithm', 'interior-point', 'Display', 'iter');
% [x,fval,exitflag, output] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[], options);

%% tradeoff version
% minFun = @(par) ParticipantLoop(par, participants, dataDir);
% % initial_values = [63, 10, 0.13, zeros(1,nParticipants) + 0.1];
% initial_values =[63,2.75734729095628,0.05,0.887336741874298,0.635752818599524,0.999996966670173,0.775218847981077,0.857069077618014,0.841579690943846,0.814601228356136,0.618857765669214,0.711180662092647,0.717055759118640,0.812237716188416,0.843858902524966,0.896414491217698,0.840780078724787];
% lowerBounds = [0, 0, 0, zeros(1,nParticipants)];
% upperBounds = [100, 100, 1, ones(1,nParticipants)];
% options = optimset('Algorithm', 'interior-point', 'Display', 'iter');
% [x,fval,exitflag, output] = fmincon(minFun,initial_values,[],[],[],[],lowerBounds,upperBounds,[], options);

%%
    function [logLikelihood] = ParticipantLoop(par, participants, dataDir)
        
        likelihood = [];
        counter = 0;
        for p = participants
            
            counter = counter + 1;
            logFile = [dataDir 'BLINKBANDIT_DATA_p' num2str(p) '.mat'];
            load(logFile, 'trialLog');
            trialLog = trialLog(1:260);
            likelihood(counter) = DanKalman(par,trialLog, counter);
            
        end
        
        logLikelihood = -sum(log(likelihood));
    end

end
