function [minParams, ip] = logitFit(x,y, ploton)
minFun = @(par) CostFunction(par,x,y);

x0 = rand(1,2); % Initial values for parameter search

lowerBound = [-inf 0];
upperBound = [0 inf];
[minParams, fval, exitflag, output] = fmincon(minFun,x0,[],[],[],[],lowerBound,upperBound); % NOTE THAT THIS IS CURRENTLY CONSTRAINED FOR A FLIPPED FIT (THE FIRST PARAMETER IS NEGATIVE!)
% [minParams, fval, exitflag, output] = fminunc(minFun,x0);

% Derive indifference point with inverted logistic function
ip = ((-log((1-0.5)./0.5)) ./ minParams(1)) + minParams(2); 

if ploton == 1
% Plot fitted function
xx = linspace(min(x),max(x)); % Generate additional x-axis points to smooth curve
modelY = 1./(1+exp(-minParams(1).*(xx - minParams(2)))); % Generate data with new model
figure;
hold on;
plot(xx, modelY, 'b-'); % Plot model
plot(x, y, 'ro'); % Plot data
plot(ip, 0.5, 'kh'); % Plot indifference point
end

function [cost] = CostFunction(par,x,y)
p = 1./(1+exp(-par(1).*(x - par(2)))); % Logit function
cost = sum( (y - p) .^ 2);
end
end