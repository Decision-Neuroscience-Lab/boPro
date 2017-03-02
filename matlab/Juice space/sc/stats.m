function sc = stats(sc)
% does some additional calculations and outputs them to the command window
% code in part contributed by Jeffrew Bower

fprintf('\n');
fprintf('%s:\n\n', 'SUMMARY DATA');
fprintf('%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n', 'ID', 'Thresh.', 'Std.', 'Trials', 'Cond.', 'Steptype')


% get the last portion of the reverals for all staircases, 
% ignoring the first # reversals (specified in the config)
for n=1:sc.num, 

    % when there are no reversals... (it's possible)
    if(isempty(sc.stairs(n).reversal))
        
        % just use the last stimval (is there a better method for this?)
        t(n) = sc.stairs(n).stimval;
        
        % SD is kinda stupid here, isn't it?
        s(n) = 0;
        
    else
        
        % you may also not want to ignore any reversals
        if ~sc.ignorereversals, rev = sc.stairs(n).reversal(sc.ignorereversals:end,2);
            
        % get the last portion of the reversals, ignoring a certain number
        else rev = sc.stairs(n).reversal(sc.ignorereversals:end,2); end
    
        % get the threshold (t) and the standard deviation (s)
        t(n) = mean(rev); s(n) = std(rev);
        
    end
    
    
    % save them in the structure
    sc.stairs(n).threshold = t(n);
    sc.stairs(n).std = s(n);
   
    % output the data
    fprintf('%-2.f\t\t%-6.2f\t\t%-6.2f\t\t%-6.0f\t\t%-2.0f\t\t\t%s\n', ...
        sc.stairs(n).index, sc.stairs(n).threshold, ...
        sc.stairs(n).std, sc.stairs(n).trial, ...
        sc.stairs(n).condition, sc.stairs(n).steptype);
    
end

% save the final threshold and standard deviation
sc.threshold = mean(t); sc.std = mean(s);

%fprintf('%s\n', '------------------------------------------------------');
fprintf('%s\t\t%-6.2f\t\t%-6.2f\t\t%-6.0f\n', 'M', sc.threshold, sc.std, sc.trial)
fprintf('\n');