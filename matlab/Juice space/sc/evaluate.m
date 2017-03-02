function sc = evaluate(trial, sc)
% evaluates the response

% set the direction to 'no change' as a default
sc.stairs(sc.current).direction = 0;

switch trial.resp,
    
    % incorrect answer
    case 0,
        
        % increase the number of correct answers index
        sc.stairs(sc.current).wrong = sc.stairs(sc.current).wrong + 1;
        
        if sc.stairs(sc.current).up == 1 || mod(sc.stairs(sc.current).wrong, ...
                sc.stairs(sc.current).up) == 0,
            
            % we've got a reversal so save it!
            if sc.stairs(sc.current).right >= sc.stairs(sc.current).down, 
                sc = reversal(sc); end
            
            % reset the counter
            sc.stairs(sc.current).right = 0;
            
            % set the step direction to up
            sc.stairs(sc.current).direction = 1;
        end
        
    % correct answer
    case 1,
        
        % increase the number of correct answers index
        sc.stairs(sc.current).right = sc.stairs(sc.current).right + 1;
        
        if sc.stairs(sc.current).down == 1 || mod(sc.stairs(sc.current).right, ...
                sc.stairs(sc.current).down) == 0,
            
            % we've got a reversal so save it!
            if sc.stairs(sc.current).wrong >= sc.stairs(sc.current).up,
                sc = reversal(sc); end
            
            % reset the counter
            sc.stairs(sc.current).wrong = 0;
            
            % set the step direction to down
            sc.stairs(sc.current).direction = -1;
            
        end
        
end

% update the staircase (this was first placed in the main loop)
sc = update(sc, trial);

function sc = reversal(sc)
% saves a reversal in the correct location

% create the data format we need
data = [ sc.stairs(sc.current).trial sc.stairs(sc.current).stimval ];

% save it to the reversal matrix
sc.stairs(sc.current).reversal = [ sc.stairs(sc.current).reversal; data ];

