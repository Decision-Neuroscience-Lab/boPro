function sc = getstimval(sc)
% returns a new stimulus value

% get the current stimval
stimval = sc.stairs(sc.current).stimval;

% get the direction to decide if we're going to add or substract
direction = sc.stairs(sc.current).direction;

% calculate the number of reversals
numreversals = size(sc.stairs(sc.current).reversal,1);

% if we're on the first trial, just use the initial values
if sc.stairs(sc.current).trial > 1,
    
    switch lower(sc.stairs(sc.current).steptype),
    
        case 'fixed',
             
            % we're not on the last item in the stepsize vector
            if numreversals < numel(sc.fixedstepsizes),
                
                % the index in the stepsize vector is equal to the number
                % of reversals we have encountered so far (+1 for zero index)
                stepindex = numreversals + 1;
                
            else
                
                % we're at the last element in the stepsize vector
                stepindex = numel(sc.fixedstepsizes);
                
            end
            
            % extract the stepsize
            stepsize = sc.fixedstepsizes(stepindex);
            
            % calculate the new stimval
            stimval = stimval + (direction * stepsize);
            
        case 'random',
                     
            % choose a random stepsize
            stepindex = ceil(numel(sc.fixedstepsizes)*rand(1,1));
            
            
            % stepindex = randi(numel(sc.fixedstepsizes),1);
            
            % extract the stepsize
            stepsize = sc.fixedstepsizes(stepindex);
            
            % calculate the new stimval
            stimval = stimval + (direction * stepsize);
  
    end % end switch
    
    % code contributed in part by Jeffrey Bower
    % checks if the stimulus value is out of bounds
    
    % stimval is smaller than the minumum stimval
    if (stimval < sc.stairs(sc.current).minstimval),
    
        % set the stimval to the min stimval
        stimval = sc.stairs(sc.current).minstimval;
        
        % increase the boundary hit counter
        sc.stairs(sc.current).hitboundaries = sc.stairs(sc.current).hitboundaries + 1;
    
    % stimval is larger than the maximum stimval;
    elseif (stimval > sc.stairs(sc.current).maxstimval),
    
        % set the stimval to the max stimval
        stimval = sc.stairs(sc.current).maxstimval;
        
        % increase the boundary hit counter
        sc.stairs(sc.current).hitboundaries = sc.stairs(sc.current).hitboundaries + 1;
    end
    
end

% set it back to the new (or old) value
sc.stairs(sc.current).stimval = stimval;
