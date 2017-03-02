function [params] = QT_config
%% Global parameters
params.dataDir = '/Users/Bowen/Documents/MATLAB/QT/data';

params.smallReward = 0.01; % Reward size (dollars)
params.largeReward = 0.15;
params.iti = 2; % Intertrial interval
params.blockTime = 300; % Length of block in seconds (5 mins)
params.numBlocks = 10;
params.startBlock = 1; % Where to start (if reloading)
params.quartileSampling = 1; % Sample from random quartiles
% (reduces within-condition variability of timing statistics)
params.analyseUpper = 20; % Upper limit (secs) for waiting Policy

KbName('UnifyKeyNames');
params.leftkey = KbName('LeftArrow');
params.rightkey = KbName('RightArrow');
params.downkey = KbName('DownArrow');
params.escapekey = KbName('ESCAPE');
params.spacekey = KbName('space');
params.returnkey = KbName('Return');
RestrictKeysForKbCheck([params.leftkey,params.rightkey,...
    params.downkey,params.escapekey,params.spacekey,params.returnkey]);

%% Create distributions
% Pareto 1
% k = 0.6;
% sigma = 3.4;
% theta = 0; % Lower bound
% D1 = makedist('Generalized Pareto',k,sigma,theta);
% D1 = truncate(D1,0,90); % Truncate at 90

% Uniform
a = 0;
b = 12;
D1 = makedist('Uniform',a,b);

% % Log-normal
% mu = 2;
% sigma = 0.2;
% D1 = makedist('Lognormal',mu,sigma);
% D1 = truncate(D1,0,90); % Truncate at 90

% Bimodal
% q = [.2 .8];
% m = [4 12];
% s = [1 1];
% distrib = struct('mu', m, 'sigma', s, 'weight', q);
% nb = 200;
% X = randn(nb,length(q)).*repmat(s,nb,1)+repmat(m,nb,1);
% rsel = rand(nb,1);
% idx1 = (repmat(rsel,1,length(q))>repmat(cumsum(q),nb,1));
% idx2 = (repmat(rsel,1,length(q))<repmat(cumsum(q),nb,1));
% idx1(:,2:end) = idx1(:,1:end-1).*idx2(:,2:end);
% idx1(:,1) = idx2(:,1);
% X = sum(X.*idx1,2);
% [y,x]=ksdensity(X);figure;plot(x,y,'linewidth',2);

% Pareto
k = 8;
sigma = 3.4;
theta = 0; % Lower bound
D2 = makedist('Generalized Pareto',k,sigma,theta);
D2 = truncate(D2,0,90); % Truncate at 90

params.D = {D1, D2}; % Distribution wrapper

% figure;
% xx = 0:0.0001:15;
% plot(xx,pdf(D1,xx))
% plot(xx,pdf(D1,xx),'LineWidth',3,'Color',[217 83 25]./255)
% xlabel('Time (secs)')
% ylabel('Probability')

% Create quartile randomisation
if params.quartileSampling == 1
%     params.qtList = NaN(1,round(params.blockTime/params.iti));
%     for q = 1:4:round(params.blockTime/params.iti) % blockTime / iti is maximum possible number of trials given no waiting
%         params.qtList(1,q:q+3) = randsample(1:4,4); % Sample randomly without replacement
%     end
    params.qtList = [];
    for q = 1:round((params.blockTime/params.iti)/16) + 1
        params.qtList = cat(1,params.qtList,deBruijn(4,2)); % Balance first-order transition statistics
    end
end

%% Display parameters
blue = [0 113 189];
orange = [217 83 25];
teal = [113,203,153];
magenta = [203 81 171];
params.colours = {blue,orange,teal,[246.993,185.997,106.0035]};
%params.colours = {[214.9905,87.006,75.99],[83.0025,134.0025,143.9985],[246.993,185.997,106.0035]}; % Dusk
%cellfun(@(x) x*255,params.colours,'un',0)
params.thirstText = 'On a scale of ''1'' to ''10'', where ''1'' indicates ''no thirst'', and ''10'' indicates ''the most severe thirst you have experienced'', how thirsty are you?\n\n\n\n\n\n[Use the left and right arrow to select a point, and the down arrow to make a selection]';

%% Initialise PTB and Screen parameters
AssertOpenGL; % Check graphics library is compatible with this version of Psychtoolbox
params.PTB.myScreen = max(Screen('Screens')); % Get max screen number (if there is an external monitor, use that)
Screen('Preference', 'SkipSyncTests', 0); % Set test preferences (0 is normal, 1 is short, 2 is skip completely)
[params.window,params.PTB.dimensions] = Screen(params.PTB.myScreen,'OpenWindow',[],[],[],[],[],8); % Open a new screen and set multisampling to 8 for anti-aliasing
% Hey Bowen - use 3rd argument above to set background colour so you don't have to do it every time you draw
[params.width, params.height] = RectSize(params.PTB.dimensions); % Get screen dimensions
params.x0 = params.width/2;
params.y0 = params.height/2;
params.PTB.FlipInterval = Screen('GetFlipInterval',params.window); % Get Flip Interval
params.PTB.slack = params.PTB.FlipInterval/2;
params.PTB.MonitorFrequency = round(1/params.PTB.FlipInterval);
if params.PTB.myScreen < 1 % Hide mouse and turn off keyboard if there is no external monitor
HideCursor;
ListenChar(2);
end
Screen(params.window,'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Set the blend function
% Screen('TextFont', params.window, 'Helvetica'); % Set font
Screen('TextSize', params.window, 30);

return