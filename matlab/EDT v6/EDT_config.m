function [params] = EDT_config(window, width, height)
% numrepeats must > 2. Forced trials are appended so that each combination
% has a forced selection for SS and LL (therefore need to be more than 2
% repeats of each combo, otherwise there will be more forced trials than free ones).

%% Global parameters
params.dataDir = '/Users/dnl/Documents/MATLAB/EDT v6/data';
params.testing = 0;
params.text = 1;
params.transform = 1;
params.adaptiveSC = 1;
params.choicetime = 6;
params.drinktime = 5;
params.totalvolume = [];


KbName('UnifyKeyNames');
params.leftkey = KbName('LeftArrow');
params.rightkey = KbName('RightArrow');
params.downkey = KbName('DownArrow');
params.escapekey = KbName('ESCAPE');

%% Variable parameters
params.D = [6 8 10];
params.A = [1 2 4];
params.fD = 2;

params.numrepeats = 3;

params.ratio = 1:2; % Ratio of SS:LL biased options in EDT task

% Display transformed values (based on pleasantness ratings)
params.powerA = 0.33;
params.powerB = 0.59;
params.ml2plsnt = @(a, b, volume) a.*volume.^(b);


%% Read in textures and name colours
oldcd = cd('/Users/dnl/Documents/MATLAB/EDT v6/symbols');
ss{4} = imread('TimeJuice Symbols.007.jpg');
ll{16} = imread('TimeJuice Symbols.004.jpg');
star = imread('Untitled.jpg');
dollar = imread('dollar.jpg');

params.ssTextures = ss;
params.llTextures = ll;
params.starTexture = star;
params.dollarTexture = dollar;

cd(oldcd);

%% Positions
params.window = window;
params.width = width;
params.height = height;

rect = 190;
params.leftup = [width*(1/3) (height/2)-(rect/2)-20];
params.leftdown = [width*(1/3)+rect (height/2)+(rect/2)];
params.leftpos = [params.leftup, params.leftdown];
params.rightup = [width*(2/3)-rect (height/2)-(rect/2)-20];
params.rightdown = [width*(2/3), (height/2)+(rect/2)];
params.rightpos = [params.rightup, params.rightdown];
params.pos = {params.leftpos, params.rightpos};

return