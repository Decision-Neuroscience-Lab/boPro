function [reproductionData] = durationReproductionStats(sample, reproduction)
    diff = reproduction - sample;
    absDiff = abs(reproduction-sample);
    relDiff = diff ./ sample;
    relReproduction = reproduction ./ sample;
    SR = sample ./ reproduction;
    absError = absDiff./sample;
    % Reproduction
    meanReproduction = nanmean(reproduction);
    stdReproduction = nanstd(reproduction);
    cvReproduction = stdReproduction./meanReproduction;
    % Deviation
    meanDiff = nanmean(diff);
    stdDiff = nanstd(diff);
    cvDiff = stdDiff./meanDiff;
    % Absolute deviation
    meanAbsDiff = nanmean(absDiff);
    stdAbsDiff = nanstd(absDiff);
    cvAbsDiff = stdAbsDiff./meanAbsDiff;
    % Relative reproduction
    meanRelReproduction = nanmean(relReproduction);
    stdRelReproduction = nanstd(relReproduction);
    cvRelReproduction = stdRelReproduction./meanRelReproduction;
    % SR
    meanSR = nanmean(SR);
    stdSR = nanstd(SR);
    cvSR = stdSR./meanSR;
     % Relative deviation
    meanRelDiff = nanmean(relDiff);
    stdRelDiff = nanstd(relDiff);
    cvRelDiff = stdRelDiff./meanRelDiff;
    % absError
    meanAbsError = nanmean(absError);
    stdAbsError = nanstd(absDiff);
    cvAbsError = stdAbsError./meanAbsError;
    
    reproductionData = [meanReproduction,stdReproduction,cvReproduction,...
        meanDiff,stdDiff,cvDiff,meanAbsDiff,stdAbsDiff,cvAbsDiff,...
        meanRelReproduction,stdRelReproduction,cvRelReproduction,...
        meanSR,stdSR,cvSR,meanRelDiff,stdRelDiff,cvRelDiff,...
        meanAbsError,stdAbsError,cvAbsError];
end