function [dia, vol, rate] = pumpInf(pump, v) 
% Takes volume (v) from 1-140. If v is 0, pump will
% stop. This version will adapt the rate to the volume, delivering
% volume (max 9.8mL) in a fixed interval (2 seconds). Precision is 3 decimal points of a mL.


v = v / 2; % Because there are two syringes
r = v * 30; % 1mL/s is 60mL/min (pump units). For each mL of volume, we should have
% a rate of 60mL/min. We have already halved the volume because we are
% using two syringes, but we need to halve the rate again if we want a
% longer delivery (2s). For 2mL/s (e.g. 120mL/min) we simply double the
% modifier. The maximum value the pump can take for rate is 147
% (147mL/min), thus the maximum volume we can deliver in a second is 2.45mL per syringe (4.9mL).

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