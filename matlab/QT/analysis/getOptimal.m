function [optimTime, rStar, expectedReturn, expectedCost, rT, T] = getOptimal(params)
%% First find time of maximum reward rate (in waitPolicy(t))
params.sampleRate = 10; % Sample rate (Hz)
numD = numel(params.D);
trialLength = params.analyseUpper;
expectedReturn = NaN(numD,trialLength*params.sampleRate);
expectedCost = NaN(numD,trialLength*params.sampleRate);
rT = NaN(numD,trialLength*params.sampleRate);
rStar = NaN(numD,1);
T = NaN(numD,1);
h = WAITBAR(0,'Initializing...');
c = 1;
for d = 1:numD
    x = 1;
    for t = (1/params.sampleRate):(1/params.sampleRate):trialLength;
        [expectedReturn(d,x), expectedCost(d,x), rT(d,x)] = waitPolicy(params,t,params.D{d});
        mes = sprintf('Evaluating policy for distribution %.0f of %.0f.',d,numD);
        WAITBAR(c./(numD*trialLength*params.sampleRate), h, mes);
        x = x + 1;
        c = c + 1;
    end
end
close(h);

for d = 1:numD
    i = expectedReturn(d,:) >= 0.149; % Set threshold for maximum
    expectedReturn(d,i) = NaN;
    expectedCost(d,i) = NaN;
    rT(d,i) = NaN;
    [rStar(d),T(d)] = nanmax(rT(d,:)); % Decompose into reward and stopping time
    %[rStar(d),T(d)] = findpeaks(rT(d,:),'Npeaks',1); % Decompose into reward and stopping time
end
optimTime = T ./ params.sampleRate;

figure;
l = cell(numD,1);
for d = 1:numD
    % Plot expected return
    subplot(2,2,1);
    plot(1:size(expectedReturn,2),expectedReturn(d,:),'Color',params.colours{d}./255);
    title('Expected return per trial');
    ylabel('Dollars');
    hold on;
    % Plot expected cost
    subplot(2,2,2);
    plot(1:size(expectedCost,2),expectedCost(d,:),'Color',params.colours{d}./255);
    title('Expected cost per trial');
    ylabel('Seconds');
    hold on;
    % Plot total reward rate
    subplot(2,2,[3,4]);
    plot(1:size(rT,2),rT(d,:).*params.blockTime,'Color',params.colours{d}./255);
    xlabel('Elapsed time'); ylabel('Expected return ($)');
    title('Expected total monetary return for waitPolicy(t)');
    hold on;
    l{d} = sprintf('%s',params.D{d}.DistributionName);
    subplot(2,2,[3,4]);
    line([T(d) T(d)],get(gca,'YLim'),'LineStyle',':','Color',params.colours{d}./255);
end

end