function [params] = generateStimuli(params)
 %% Generate stimuli for practice
 
        params.practiceStim1 = shuffleDim(repmat(params.D, 1, params.numrepeats),2);
        params.practiceStim2 = shuffleDim(repmat(params.D, 1, params.numrepeats),2);

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
        
        params.stimuli = shuffleDim(repmat(conditions,params.numrepeats,1),1);
        params.numTrials = size(params.stimuli,1);

return

