function [params] = generateStimuli(params)
% Generates stimuli for all components of the EDT. For calibration it
% generates a MOCS type scheme. For bisection, it generates a repeated,
% randomised list of delays. For the final task, it generates choice
% options from the calibrated indifferences points, in such a way that
% there are the values for each LL option are stable, by changing the value
% of the SS amount for each opttion.

switch params.session
    case 1
        %% Generate stimuli for bisection
        sequence = deBruijn(numel(params.D),3); % Create deBruijn counterbalance sequence
        stimuli = params.D(sequence)';
        
    case 2
        %% Generate stimuli for main EDT task
        
        stimuli = []; % Create empty list in correct format
        fD = params.fD;
        
        for d = 1:numel(params.D)
            D = params.D(d);
            for a = 1:numel(params.A);
                A = params.A(a);
                for r = 1:max(params.ratio)
                    switch r
                        case 1 % To bias toward LL
                            z = (fD / D) * A;
                            y = (fD / D) * 2 * A;
                            fA = round(z + (y-z).*rand(1,1));
                        case 2  % For all other cases, bias toward SS
                            z = A;
                            y = (A / D) * fD;
                            fA = round(z + (y-z).*rand(1,1));
                        case 3
                            z = A;
                            y = (A / D) * fD;
                            fA = round(z + (y-z).*rand(1,1));
                        case 4
                            z = A;
                            y = (A / D) * fD;
                            fA = round(z + (y-z).*rand(1,1));   
                    end
                    stimuli = cat(1,stimuli,[fA, fD, A, D]);
                end
            end
        end
        
        sequence = deBruijn(numel(params.D), 2); % Create de Bruijn Sequence
        delays = params.D(sequence)'; % Create delay stimuli
        delays = repmat(delays,3,1); % Repeat to fit
        
        stimuli(:,3) = delays;
        stimuli(:,1) = fA;
        stimuli(:,4) = fD;
        stimuli(:,2) = 0.3; % Set at min for practice
        
        % Generate practice stimuli (to familiarise to amounts)
        params.practice = shuffleDim(linspace(min(stimuli(:,2)),max(stimuli(:,1)),5));
        
end % End session switch

params.stimuli = stimuli;
params.numTrials = size(stimuli,1);

return

