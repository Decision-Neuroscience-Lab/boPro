function [params] = TIRE_config(window, width, height)
% numrepeats must > 2. Forced trials are appended so that each combination
% has a forced selection for SS and LL (therefore need to be more than 2
% repeats of each combo, otherwise there will be more forced trials than free ones).

%% Global parameters
params.dataDir = '/Users/Bowen/Documents/MATLAB/TIRE/data';
params.testing = 0;
params.betTime = 3;
params.choiceTime = 3;
params.numTrials = 100; % Must be even

KbName('UnifyKeyNames');
params.leftkey = KbName('LeftArrow');
params.rightkey = KbName('RightArrow');
params.downkey = KbName('DownArrow');
params.escapekey = KbName('ESCAPE');

%% Screen parameters
params.window = window;
params.width = width;
params.height = height;

%% Stimuli
% Outcomes
sequence = deBruijn(2, 6); % Build deBruijn sequence
params.outcome = sequence;
params.numTrials = length(sequence);

% Durations
wf = 0.12; % Set Weber Fraction to compute differences in stimulus duration
anchorDurations = [600 800 1000 1200 1400]; % Anchor durations (in msecs)
numComparisons = 4;
for x = 1:numComparisons
comparisonAdjustments = [wf*(x*(1/2))];
end

for x = 1:numel(anchorDurations);
    sample = anchorDurations(x);
    comparison = anchorDurations(x).*comparisonAdjustments;
end
    

return