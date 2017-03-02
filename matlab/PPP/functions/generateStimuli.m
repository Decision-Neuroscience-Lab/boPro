function [params] = generateStimuli(params)
%% Generate stimuli for practice

params.practiceStim1 = [];
params.practiceStim2 = [];

for r = 1:2
    params.practiceStim1 = cat(2,params.practiceStim1,params.D(deBruijn(4,2)));
    params.practiceStim2 = cat(2,params.practiceStim2,params.D(deBruijn(4,2)));
end

%% Generate stimuli for main EDT task

% Create pseudorandomly
%         conditions = []; % Create empty list
%         for a = 1:numel(params.A);
%             A = params.A(a);
%             for d = 1:numel(params.D)
%                 D = params.D(d);
%                 conditions = cat(1,conditions,[A, D]);
%             end
%         end
%         params.stimuli = shuffleDim(repmat(conditions,params.numRepeats,1),1);
%         params.numTrials = size(params.stimuli,1);

% Create via deBruijn sequence (on reward amount)
order = deBruijn(4,3);
rewards = params.A(repmat(order,[2,1]));
delays = nan(1,size(rewards,2));
for a = unique(rewards)
    i = rewards == a;
    delays(i) = shuffleDim(repmat(params.D,[1,params.numRepeats]));
end

params.stimuli = [rewards' delays'];
params.numTrials = size(params.stimuli,1);

% plot(tsmovavg(params.stimuli(:,1)', 's', 5)); % Use this +
% findpeaks() for PP analysis

return

