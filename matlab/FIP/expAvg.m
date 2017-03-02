function [out] = expAvg(vector,periods)

[vectorVars, observ] = size(vector);

k = 2 / (periods + 1);

% Calculate the simple moving average for the first 'exp mov avg'
% value.
out = nan(vectorVars, observ);
out(:, periods) = sum(vector(:, 1:periods), 2)/periods;

% K*vector; 1-k
kvector = vector(:, periods:observ) * k;
oneK = 1-k;

% First period calculation
out(:, periods) = kvector(:, 1) + (out(:, periods) * oneK);

% Remaining periods calculation
for idx = periods+1:observ
    out(:, idx) = kvector(:, idx-periods+1) + (out(:, idx-1) * oneK);
end
return