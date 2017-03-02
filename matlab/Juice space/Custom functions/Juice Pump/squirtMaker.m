function [dia, vol, rate] = squirtMaker(pump, v) 
% Takes volume (v) from 1-140, rate (r) from 1-147. If v is 0, pump will
% stop. This version will adapt the rate to the volume, delivering
% volume (max 10) in a fixed interval (2 seconds). Precision is 3 decimal points of a mL.


v = v / 2;
r = v * 30; % e.g. For 2mL over 2 seconds we set the rate to 30mL/min = 0.5mL/s * 2 for two seconds and * 2 again because we have two syringes (larger dose). 

% Set to infuse
cmd = '2 mode i';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

if v ~= 0
% Set diameter
cmd = '2 dia 38.40';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

% Set volume and rate
cmd = sprintf('2 voli %05.3f ml', v);
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

cmd = sprintf('2 ratei %05.1f ml/m', r);
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response

% Query diameter, volume and rate
cmd = '2 dia?';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
dia = fscanf(pump, '%s');

cmd = '2 voli?';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
vol = fscanf(pump, '%s');

cmd = '2 ratei?';
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

else
% Stop pump
cmd = '2 stop';
fprintf(pump, '%s\r\n', cmd);
fscanf(pump); % discard garbage response
end
return