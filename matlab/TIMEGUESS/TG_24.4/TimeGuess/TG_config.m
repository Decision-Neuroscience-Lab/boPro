function [key, params] = TG_config

%% Basic parameters (screen and keyboard)
KbName('UnifyKeyNames');
leftkey = KbName('LeftArrow');
upkey = KbName('UpArrow');
downkey = KbName('DownArrow');
rightkey = KbName('RightArrow');

mshortkey = KbName('C');
shortkey = KbName('V');
samekey = KbName('B');
longkey = KbName('N');
mlongkey = KbName('M');
xshortkey = KbName('X');
xlongkey = KbName(',');

key = [mshortkey shortkey longkey mlongkey];

%% Parameters

params.oddball = [5 10];

params.blocks = 3;

params.anchortime = 1.5;

params.dots = 3; % 0 is numbers, 1 is dots, 2 is circles, 3 is lines

params.pair(1,:) = [1 6];
params.pair(2,:) = [2 8];
params.pair(3,:) = [4 10];

params.numrepeats = 10;
params.practice_repeats = 2;
