function [trial, sc] = newtrial(sc)
% selects a random staircase and gets new trial parameters

% select a random staircase from the active staircases - returns index of
% sc rather than the index used in the active staircase vector
sc.current = sc.active(ceil(numel(sc.active) * rand(1,1)));

% increment the trial counter for the current staircase
sc.stairs(sc.current).trial = sc.stairs(sc.current).trial + 1;

% increment the total trial count
sc.trial = sc.trial + 1;

% sets a stimulus value
sc = getstimval(sc);

% set the values in the trial struct
trial.stimval = sc.stairs(sc.current).stimval;
trial.number = sc.stairs(sc.current).trial;