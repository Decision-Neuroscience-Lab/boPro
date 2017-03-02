%% TD for QT
% Bowen J Fung, 2015

%% Create value space
timeBin = 1;
upperLimit = 90;
smallReward = 0.01;
largeReward = 0.15;
blockTime = 5 * 60;

% Uniform distribution
a = 0;
b = 12;
D1 = makedist('Uniform',a,b);

% Pareto dsitribution
k = 8;
sigma = 3.4;
theta = 0; % Lower bound
D2 = makedist('Generalized Pareto',k,sigma,theta);
D2 = truncate(D2,0,90); % Truncate at 90

D = {D1, D2}; % Distribution wrapper

%% Treat trials as independent, create state space for single trial
% Define number of states
x = 2;
numStates = 0;
for i = 1:(upperLimit / timeBin)
    numStates = numStates + x;
    x = x*2;
end
S = 1:numStates;

% Iterate through trials

S = 1:2^(blockTime ./ timeBin)

for i = (blockTime ./ timeBin) * 3
    S(i) = i; % State number
    P(i) = % Transition probability
    R(i) =  % Reward
    
end
    