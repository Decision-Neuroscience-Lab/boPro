%% Extract discounting data and collapse k value

dataDir = '/Users/Bowen/Documents/MATLAB/TIMEDEC/behavioural data';
participants = [1:145];

for x = participants
    data = [];
    try
        % fprintf('Loading participant %.0f...\n',x);
        stringfordir = sprintf('%.0f_*', x);
        oldcd = cd(dataDir);
        loadname = dir(stringfordir);
        load(loadname.name);
        saveName = sprintf('/Users/Bowen/Documents/MATLAB/TIMEDEC/2015/Bayesian Estimation/data/%.0f.txt', x);
        cd(oldcd);
        
        % TD1
        numTrials = size([TD.delay1.response.choice],2);
        DA = zeros(numTrials,1);
        DB = [TD.delay1.options.delay]';
        A = [TD.delay1.options.vn]';
        B = [TD.delay1.options.vd]';
        R = [TD.delay1.response.choice]'; % 0 is SS, 1 is LL, -1 is no response
        
        data = cat(1,data,[A(1:numTrials),DA(1:numTrials),B(1:numTrials),DB(1:numTrials),R(1:numTrials)]);
        
        try
            clearvars numTrials
            % TD2
            numTrials = size([TD.delay2.response.choice],2);
            DA = zeros(numTrials,1);
            DB = [TD.delay2.options.delay]';
            A = [TD.delay2.options.vn]';
            B = [TD.delay2.options.vd]';
            R = [TD.delay2.response.choice]'; % 0 is SS, 1 is LL, -1 is no response
            
            data = cat(1,data,[A(1:numTrials),DA(1:numTrials),B(1:numTrials),DB(1:numTrials),R(1:numTrials)]);
        catch
            fprintf('No second discounting session for participant %.0f.\n',x);
        end
        
        data = array2table(data,'VariableNames',{'A','DA','B','DB','R'});
        
        % Remove missing
        data(data.R == -1,:) = [];
        
        writetable(data,saveName,'Delimiter','\t');
        
        clearvars -except dataDir participants x
    catch
        fprintf('Problem with participant %.0f.\n',x);
        continue;
    end
end
fprintf('Done.\n');
