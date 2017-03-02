function TIME = getTimeData(samples, responses)
% Calculate various time perception measures and output a table

    diff = responses - samples;
    absDiff = abs(responses-samples);
    relDiff = diff ./ samples;
    relReproduction = responses ./ samples;
    SR = samples ./ responses;
    absError = absDiff./samples;
    % Reproduction
    meanReproduction = mean(responses);
    stdReproduction = std(responses);
    cvReproduction = stdReproduction./meanReproduction;
    % Deviation
    meanDiff = mean(diff);
    stdDiff = std(diff);
    cvDiff = stdDiff./meanDiff;
    % Absolute deviation
    meanAbsDiff = mean(absDiff);
    stdAbsDiff = std(absDiff);
    cvAbsDiff = stdAbsDiff./meanAbsDiff;
    % Relative reproduction
    meanRelReproduction = mean(relReproduction);
    stdRelReproduction = std(relReproduction);
    cvRelReproduction = stdRelReproduction./meanRelReproduction;
    % SR
    meanSR = mean(SR);
    stdSR = std(SR);
    cvSR = stdSR./meanSR;
    % Relative deviation
    meanRelDiff = mean(relDiff);
    stdRelDiff = std(relDiff);
    cvRelDiff = stdRelDiff./meanRelDiff;
    % absError
    meanAbsError = mean(absError);
    stdAbsError = std(absDiff);
    cvAbsError = stdAbsError./meanAbsError;
    
    TIME = table(meanReproduction,stdReproduction,cvReproduction,meanDiff,...
        stdDiff,cvDiff,meanAbsDiff,stdAbsDiff,cvAbsDiff,meanRelReproduction,...
        stdRelReproduction,cvRelReproduction,meanSR,stdSR,cvSR,meanRelDiff,...
        stdRelDiff,cvRelDiff,meanAbsError,stdAbsError,cvAbsError);