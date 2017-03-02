function [dia, vol, rate, err] = pumpInf(pump, v) 
% Takes volume (v) from 1-140. If v is 0, pump will
% stop. This version will adapt the rate to the volume, delivering
% volume (max 9.8mL) in a fixed interval (2 seconds). Precision is 3 decimal points of a mL.

flushinput(pump); % Remove data from input buffer

v = v / 2; % Because there are two syringes
r = v * 30; % 1mL/s is 60mL/min (pump units). For each mL of volume, we should have
% a rate of 60mL/min. We have already halved the volume because we are
% using two syringes, but we need to halve the rate again if we want a
% longer delivery (2s). For 2mL/s (e.g. 120mL/min) we simply double the
% modifier. The maximum value the pump can take for rate is 147
% (147mL/min), thus the maximum volume we can deliver in a second is 2.45mL per syringe (4.9mL).

% Set to infuse
cmd = '2 mode i';
query(pump, cmd, '%s\r\n');

if v ~= 0
% Set diameter
cmd = '2 dia 38.40';
query(pump, cmd, '%s\r\n');

% Set volume and rate
cmd = sprintf('2 voli %05.3f ml', v);
query(pump, cmd, '%s\r\n');

cmd = sprintf('2 ratei %05.1f ml/m', r);
query(pump, cmd, '%s\r\n');

% Query diameter, volume and rate
cmd = '2 dia?';
query(pump, cmd, '%s\r\n');
dia = fscanf(pump, '%s'); % Record response

cmd = '2 voli?';
query(pump, cmd, '%s\r\n');
vol = fscanf(pump, '%s'); % Record response

cmd = '2 ratei?';
query(pump, cmd, '%s\r\n');
rate = fscanf(pump, '%s'); % Record response

cmd = '2 error?';
query(pump, cmd, '%s\r\n');
err = fscanf(pump, '%s'); % Record response

if strcmp(err,'4')
    flushinput(pump); % Remove data from input buffer
    warning('The pump has thrown an error (serial overrun). Pump buffer cleared.');
end

% Run pump
cmd = '2 run';
query(pump, cmd, '%s\r\n');

else
% Stop pump
cmd = '2 stop';
query(pump, cmd, '%s\r\n');
end
return