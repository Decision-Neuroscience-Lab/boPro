function visualise(sc)
% Visualises the staircase path.

% YES! it's a growing vector, I know that. 
thresholds = [];

% initialise a new figure with a white background
fig = figure('color', 'w');

% first plot just shows the raw data from each staircase and the thresholds
% that were calculated. Should probably find a nicer way to do this. 

subplot(1,2,1); hold on; box on; set(gca, 'FontSize', 8);

% just using the values used in the simulation
ylim([0 100]);

% loop through all staircases
for i=1:sc.num,
    
    % plot the normal values in blue
    p(1) = plot(sc.stairs(i).data(:,1), sc.stairs(i).data(:,2), ...
        '-ko', 'MarkerSize', 3, 'MarkerFaceColor', 'k');
    
    % plot the "incorrect" values in red
    f = sc.stairs(i).data(:,3) == 0;
    p(2) = plot(sc.stairs(i).data(f,1), sc.stairs(i).data(f,2), ...
        'ro', 'MarkerSize', 3, 'MarkerFaceColor', 'r');
    
    % plot the reversals
    % p(3) = gridxy(sc.stairs(i).reversal(:,1), [], 'LineStyle', ':', 'Color', [0.8 0.8 0.8]);
    
    % gather the individual thresholds
    thresholds = [ thresholds; sc.stairs(i).threshold ];
    
end

% draw the final threshold and individual thresholds
p(4) = gridxy([], sc.threshold, 'color', 'r', 'linewidth', 1.5);
p(5) = gridxy([], thresholds, 'color', 'r', 'LineStyle', ':');

% labels and title
xlabel('Trial number', 'fontsize', 14);
ylabel('Stimulus values', 'fontsize', 14);
title('Raw data', 'fontsize', 14)

% legend
legend([p(1) p(2) p(3) p(4) p(5)], 'Correct answer', 'Incorrect answer', ... 
    'Reversal', 'Mean threshold', 'Individual threshold', 'Location', 'SouthEast');

% second plot is a bit overkill, but shows the proportion it targets on the
% psychometric function, given the values of the gaussian distribution used
% in the data generation (in this case sc.sim.mu and sc.sim.sg). 

subplot(1,2,2); hold on; box on; set(gca, 'FontSize', 8);

% only drawing the range used in the example
x = 1:100;

% create the cumulative normal
y = normcdf(x, sc.sim.mu, sc.sim.sg);

% plot it
p(1) = plot(x,y, 'k', 'Linewidth', 1);

% plot the threshold on this one as well
p(2) = gridxy(sc.threshold, [], 'color', 'r', 'linewidth', 1.5);

% extract the number of conditions
p(3) = gridxy(thresholds, [], 'color', 'r', 'LineStyle', ':');

% plot a horizontal line for the proportion
p(4) = gridxy([], normcdf(sc.threshold, sc.sim.mu,sc.sim.sg), 'LineStyle', '--');

% labels and title
xlabel('Stimulus values', 'fontsize', 14);
ylabel('Proportion correct', 'fontsize', 14);
title('Simulation', 'fontsize', 14);

% legend
legend([p(1) p(2) p(3) p(4)], 'Simulated Gaussian', 'Mean threshold', ...
    'Individual threshold', 'Proportion correct', 'Location', 'SouthWest');

set(fig,'Units','pixels')
set(fig,'Position',[200,200,800,400])