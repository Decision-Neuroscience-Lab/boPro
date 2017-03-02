function [params] = RETIME_config
%% Global parameters
params.dataDir = '/Users/Bowen/Documents/MATLAB/RETIME/data';
params.testing = 0;
params.betTime = 3;
params.postBetTime = 0.5;
params.choiceTime = 3;
params.postChoiceTime = 0.5;

params.colours = {[0 113.985 188.955]; [216.75 82.875 24.99]; [0.443 0.82 0.6]; [127.5 127.5 127.5]}; % Two bet colours, choice colour and neutral colour

KbName('UnifyKeyNames');
params.leftkey = KbName('LeftArrow');
params.rightkey = KbName('RightArrow');
params.downkey = KbName('DownArrow');
params.escapekey = KbName('ESCAPE');

%% Initialise PTB and Screen parameters
AssertOpenGL; % Check graphics library is compatible with this version of Psychtoolbox
params.PTB.myScreen = max(Screen('Screens')); % Get max screen number (if there is an external monitor, use that)
Screen('Preference', 'SkipSyncTests', 0); % Set test preferences (0 is normal, 1 is short, 2 is skip completely)
[params.window,params.PTB.dimensions] = Screen(params.PTB.myScreen,'OpenWindow',[],[],[],[],[],8); % Open a new screen and set multisampling to 8 for anti-aliasing
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

%% Stimuli
params.anchors = [0.5, 1, 1.5, 2, 3];
wf = 0.05; % Estimated minimum weber fraction
numSamples = 6;
numTests = 2;
params.numTrials = numel(params.anchors) * numSamples * numTests * 2;

trialTime = (params.betTime + params.postBetTime + params.choiceTime + params.postChoiceTime + mean(params.anchors));
estimatedTime =  (trialTime * numel(params.anchors) * numSamples * 2 * 2 * numTests) / 60;

% Outcomes
sequence = deBruijn(2, 6); % Build deBruijn sequence
sequence = cat(1, sequence, sequence(1:(params.numTrials - numel(sequence))));
stimuli = [];
for a = 1:numel(params.anchors)
    standard = params.anchors(a);
    for s = 0:numSamples
        sample = wf*s + standard;
        for t = 1:numTests
            if mod(t,2)
                standardFirst = 1;
            else
                standardFirst = 0;
            end
            for o = 1:2
                if mod(o,2)
                    outcome = 1;
                else
                    outcome = 2;
                end
                stimuli = cat(1,stimuli,[standard sample standardFirst outcome]);
            end
        end
    end
end

for c = 1:size(stimuli,1)
    while stimuli(c,4) ~= sequence(c)
        stimuli(c:end,:) = shuffleDim(stimuli(c:end,:),1);
    end
end

stimuli = cat(2,stimuli,outcome);

params.numTrials = length(stimuli);
    

return