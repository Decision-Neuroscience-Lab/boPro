function demo
% Demonstrates the use of the staircase algorithm
% (c)2009 Arthur Lugtigheid (lugtigheid@gmail.com)
% Last edit: 16 December 2009 - Version 2.0.3-beta
%
% This is the third beta version ready for testing. I welcome any comment
% or critique. Please let me know if you find any bugs or have an idea for
% additional functionality. There are some additions upcoming, but would
% rather test the basic functionality first.
%
% Some of the staircase logic is loosely based on work in our lab by Dr. 
% Andrew Welchman and Matthew Dexter of the University of Birmingham.

% clear everything - clean slate
clc; clear all;

% Set up some general stuff to determine when it should end: when it
% reaches the maximum number of trials, or maximum number of reversals, the
% termination rule is activated and the staircase ends. In the example
% below, the first 6 reversals are ignored thus basing the analysis on the
% last 10 reversals. 

sc.maxtrials = 100;                 % the maximum number of trials
sc.maxreversals = 16;               % the maximum number of reversals
sc.ignorereversals = 6;             % number of reversals to ignore

% Define the range in which the stimulus values are allowed to vary
% (minstimval being the lower boundary and maxstimval being the upper
% boundary). You can set the maximum amount that a staircase is allowed to
% hit one of the boundaries by setting sc.maxboundaries - it will terminate
% once the 'boundary hit counter' has reached this number.

sc.minstimval = 0;              % minimum stimulus value
sc.maxstimval = 100;            % maximum stimulus value
sc.maxboundaries = 3;           % number of times sc can hit boundary

% Set up the behaviour of the staircase algorithm in terms of steps. It's
% quite common to use fixed stepsizes as shown below, where the stepsize
% decreases after each reversal. Another - new - option is to use random 
% stepsizes. This chooses a random stepsize from the fixed stepsizes vector. 
% The idea behind that is that this samples around threshold more broadly, 
% enabling you to fit a psychometric function to your staircase data,
% provided, of course, that you have enough data to do so.

sc.steptype = 'fixed';              % other option is 'random'
sc.fixedstepsizes = [10 5 2.5 1];   % specifies the stepsize vector

% TODO: fix the scaled stepsize mechanism - anything to do with the scaling
% mechanism is currently (Jan 2010) a work in progress.

sc.scalefactor = 5;                 % scale factor in percentages (N/A)

% The code below defines the type of staircase. If your staircase is a 1
% down / 3 up staircase, the proper way to set it up is as in this example.
% This should (theoretically) converge to about 0.8 proportion - if you
% want the 50% interval, you should use a 1 down / 1 up staircase. 

sc.up = 1;                          % # of incorrect answers to go one step up
sc.down = 3;                        % # of correct answers to go one step down

% Set up the values used to simulate responses

% PLEASE NOTE: due to the fact that we're using a 1-up/3-down staircase,
% this will not target the threshold at 60, but rather the 0.8 proportion
% (i.e. the area under the underlying gaussian) on the psychometric curve.
% Also see above description.

sc.sim.mu = 50;                     % simulated threshold (mu)
sc.sim.sg = 15;                     % simulated sensitivity (sigma)

% Changing the simulated threshold will shift the threshold - changing the
% sensitivity will change the slope of the psychometric function, thereby
% adding or reducing 'noise' in the responses. 

%% set up the staircases

% The individual staircases are set up in an embedded structure called 
% sc.stairs, and each one has an index. At the very least, it's necessary 
% to initialise it with the initial stimulus value as shown below, but it 
% should be possible to individually set up multiple variables in the future. 
% Furthermore, it should be noted that the algoritm interleaves these
% staircases randomly. This particular demo interleaves 4 staircases. 

sc.stairs(1).initial = 0;           % first staircase
sc.stairs(2).initial = 25;          % second staircase
sc.stairs(3).initial = 75;          % third staircase
sc.stairs(4).initial = 100;         % fourth staircase

% Please note that the visualise script uses above values, so if you change
% these values you need to change them in the visualisation script as well.

% You can set some extra's; for instance if we want the fourth staircase 
% to be a staircase that targets the 0.2 proportion so that we can take 
% the mean of the 0.2 and the 0.8; These values can be set anywhere before
% calling the init function (which sets the values):

% sc.stairs(4).up = 3; 
% sc.stairs(4).down = 1;

% or maybe we want the step type of staircase 3 set to random:
sc.stairs(3).steptype = 'random';

% you can also link staircases by providing a condition id (if you don't 
% specify this, it will just assume that all conditions are '1'). This 
% doesn't do much now, but it will allow you to segregate your data later:
sc.stairs(2).condition = 2;
sc.stairs(4).condition = 2;

% you can also add other (useful) variables to the struct that you might 
% want to use later in your analysis by specifying them as follows:

% global stair variable:         sc.<variable name>
% stair specific variable:       sc.stairs(index).<variable name>

% initialise the staircases (TODO: validate)
sc = init(sc);

%% run the staircase algorithm until we're done

while ~sc.done,
    
    % gets the next trial; some of the trial parameters are stored in a
    % 'trial' struct, like the stimulus value (trial.stimval) and the 
    % trial number (trial.number)
    [trial,sc] = newtrial(sc);
    
    % simulates a response -- you would normally write a function that will
    % actually run your stimulus and return a response from the subject.
    trial.resp = simulate(sc);
    
    % evaluates the response and updates the staircase struct.
    sc = evaluate(trial, sc);
    
end

%% Do some additional analysis

% put the main variable in the workspace (for debugging)
assignin('base', 'sc', sc);

% visualise the results
visualise(sc);
