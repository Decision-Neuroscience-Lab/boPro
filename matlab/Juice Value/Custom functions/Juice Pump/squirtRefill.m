function [dia, vol, rate] = squirtRefill(pump) 
% Withdraws liquid to refill until a key is pressed.

% Set to withdraw
cmd = '2 mode w';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

% Set diameter
cmd = '2 dia 38.40';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

% Set volume and rate
cmd = sprintf('2 volw %05.0f ml', 0);
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

cmd = sprintf('2 ratew %05.1f ml/m', 147);
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

% Query diameter, volume and rate
cmd = '2 dia?';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
dia = fscanf(pump, '%s');

cmd = '2 volw?';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
vol = fscanf(pump, '%s');

cmd = '2 ratew?';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
rate = fscanf(pump, '%s');

if any(strcmp('2E',{rate vol dia}))
    fscanf(pump);
    error('The pump has thrown an error. Pump buffer cleared.');
end

% Run pump
cmd = '2 run';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

KbWait([], 2);
    
% Stop pump
cmd = '2 stop';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

return