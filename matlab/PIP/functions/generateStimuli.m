function [params] = generateStimuli(params)

%% Generate stimuli for practice
 
        params.practiceStim = Shuffle(repmat(params.D, 1, params.practicenumrepeats));
        
%% Generate stimuli for main EDT task
       
        % Create via deBruijn sequence
        conditions = []; % Create empty list
   
        for a = 1:numel(params.A);
            A = params.A(a);
            for d = 1:numel(params.D)
                D = params.D(d);
                conditions = cat(1,conditions,[A, D]);
            end
        end
        sequence = deBruijn(length(conditions),2);
        stimuli = conditions(sequence,:);
        extrastim = Shuffle(repmat(conditions,(((length(conditions) * params.numrepeats)-size(stimuli,1)) / size(conditions,1)),1));
        params.stimuli = cat(1,extrastim,stimuli);
        params.numTrials = size(params.stimuli,1);

return

