function [AUC, f] = zaub_auc(reference,subject,min_delay,max_delay)

% Normalise vectors to last element
x = reference * min_delay; % Objective time
y = subject * min_delay; % Subjective time

% Calculate AUC
AUC = 0;
for i = 1:numel(y) - 1;
    AUC = AUC + (x(i+1)-x(i)) * y(i); % Rectangle for each interval
    % Triangle for each interval (for monotinic and non-monotonic
    % increases in y)
    if y(i+1) > y(i)
        AUC = AUC + (x(i+1)-x(i)) * (y(i+1)-y(i)) * 0.5;
    else
        AUC = AUC + (x(i+1)-x(i)) * (y(i)-y(i+1)) * 0.5;
    end
end

% Calculate AUC as a proportion of objective time perception curve
AUC = AUC/(max_delay^2/2);