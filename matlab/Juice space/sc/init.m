function sc = init(sc)
% initialises the staircases

% global trialcounter
sc.trial = 0;

% get the number of staircases we want to initialise
sc.num = numel(sc.stairs);

% create a vector with the active staircases
sc.active = 1:sc.num;

% we're not done, we're only just starting!
sc.done = 0;

% cycle through the staircases to initialise them
for n=1:sc.num,

    % set up some values for all staircases
    
    sc.stairs(n).trial = 0;             % staircase specific trial number
    sc.stairs(n).data = [];             % contains raw data
    sc.stairs(n).index = n;             % index of the staircase
    sc.stairs(n).wrong = 0;             % number of correct answers
    sc.stairs(n).right = 0;             % number of incorrect answers
    sc.stairs(n).direction = 0;         % the direction of the staircase
    sc.stairs(n).reversal = [];         % contains reversal data
    sc.stairs(n).maxboundaries = 3;     % maximum it can hit the boundaries
    sc.stairs(n).hitboundaries = 0;     % counter for how often it hit the boundaries
    
    % Set some staircase specific variables:  
    
    % set the up/down seperately for each staircase if it was specified
    if ~isfield(sc.stairs(n), 'up') || isempty(sc.stairs(n).up), sc.stairs(n).up = sc.up;end
    if ~isfield(sc.stairs(n), 'down') || isempty(sc.stairs(n).down), sc.stairs(n).down = sc.down; end
    
    % set the steptype seperately for each staircase if specified
    if ~isfield(sc.stairs(n), 'steptype') || isempty(sc.stairs(n).steptype), sc.stairs(n).steptype = sc.steptype; end

    % set the condition seperately for each staircase if specified
    if ~isfield(sc.stairs(n), 'condition') || isempty(sc.stairs(n).condition), sc.stairs(n).condition = 1; end

    % set the minimum and maximum stimvals and the number of times a
    % staircase is allowed to reach that boundary before terminating
    if ~isfield(sc.stairs(n), 'maxboundaries') || isempty(sc.stairs(n).maxboundaries), sc.stairs(n).maxboundaries = sc.maxboundaries; end
    if ~isfield(sc.stairs(n), 'minstimval') || isempty(sc.stairs(n).minstimval), sc.stairs(n).minstimval = sc.minstimval; end
    if ~isfield(sc.stairs(n), 'maxstimval') || isempty(sc.stairs(n).maxstimval), sc.stairs(n).maxstimval = sc.maxstimval; end

    % set the initial stimulus value
    sc.stairs(n).stimval = sc.stairs(n).initial;

end