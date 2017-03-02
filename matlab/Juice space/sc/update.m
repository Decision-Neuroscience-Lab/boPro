function sc = update(sc, t)
% updates the staircase with new data

% create a new line for the data saving process
newdata = [t.number t.stimval t.resp];

% save the data from this trial to the struct
sc.stairs(sc.current).data = [sc.stairs(sc.current).data; newdata];

% check if we have reached the limit for this staircase based on the number
% of trials and reversals or when it has hit the maximum about of boundary 
% hits-- if we have, remove that staircase from list
terminate = sc.stairs(sc.current).trial >= sc.maxtrials || ...
            size(sc.stairs(sc.current).reversal,1) >= sc.maxreversals || ...
            sc.stairs(sc.current).hitboundaries >= sc.maxboundaries;

% if this is indeed the end, remove it
if terminate, sc = remove(sc); end

% a simple check to check if we should quit - no more active staircases
sc.done = ~numel(sc.active);

% calculate some stats if we're done
if sc.done, sc = stats(sc); end


function sc = remove(sc)
% a little function that removes an active staircase from the active
% staircase vector once we're done. Just added to keep me sane.

% get the current index
index = sc.stairs(sc.current).index;

% delete that one from the list
sc.active(sc.active == index) = [];