 function [X] = BlinkyWalk(par)
%random walk - one dimensional with decaying gaussian

pointMin = min(par.pointBounds);
pointMax = max(par.pointBounds);
X = zeros(par.nBandits, par.nTrials); % container variable

% random walk parameters
lambda = par.lambda; %decay parameter
theta = par.theta; %decay centre
sigmaD = par.sigmaD; %standard deviation of gaussian noise

% initialise starting points

startingPoints = rand([1,par.nBandits]) * 100;
X(:,1) = startingPoints';

% random walk
for step = 2:par.nTrials

    stepDone = 0;

    while ~stepDone

        lastStep = X(:, step - 1); %get last steps for all bandits

        stepNoise = sigmaD.*randn(par.nBandits,1); %independently get noise for all bandits
        thisStep = (lambda .* lastStep) + ( ( 1 - lambda ) .* theta ) + stepNoise; %calculate next step for all bandits

        if all(thisStep > pointMin & thisStep < pointMax)   %make sure all values are within permissable range
            X(:, step) = thisStep;
            stepDone = 1;
        end
    end
end


end