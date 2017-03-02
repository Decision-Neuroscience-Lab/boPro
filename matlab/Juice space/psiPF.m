function psiPF(id,numSessions)

figure;
set(0,'DefaultAxesColorOrder', [0 0.447 0.741; 0.85 0.325 0.098;  0.443 0.82 0.6]);

% Load calibration file for participant
dataMatrix = [];
for x = 1:numSessions
    cd('C:\Users\bowenf\Documents\MATLAB\TIMEJUICE\Juice Space\sessions');
    name = sprintf('%.0f_%.0f_*', id,x);
    loadname = dir(name);
    load(loadname.name);
    anchor = [data.trialLog.anchor]';
    tempSample = [data.trialLog.sample]';
    sample = tempSample - anchor;
    correct = [data.trialLog.correct]';
    dataMatrix = cat(1,dataMatrix,[anchor, sample,correct]);
end
A = unique(dataMatrix(:,1));
for a = 1:2
    i = dataMatrix(:,1) == A(a);
    temp = dataMatrix(i,:);
    
    ParOrNonPar = 1;
    
    %Stimulus intensities
    StimLevels = unique(temp(:,2))';
    
    %Number of positive responses (e.g., 'yes' or 'correct' at each of the
    %   entries of 'StimLevels'
    NumPos = [];
    for x = 1:numel(StimLevels)
        NumPos(x) = sum(temp(temp(:,2)==StimLevels(x),3));
    end
    
    %Number of trials at each entry of 'StimLevels'
    OutOfNum = [];
    for x = 1:numel(StimLevels)
        OutOfNum(x) = sum(temp(:,2)==StimLevels(x));
    end
    
    %Parameter grid defining parameter space through which to perform a
    %brute-force search for values to be used as initial guesses in iterative
    %parameter search.
    searchGrid.alpha = 0:.001:.1;
    searchGrid.beta = logspace(1,3,100);
    searchGrid.gamma = .5;  %scalar here (since fixed) but may be vector
    searchGrid.lambda = 0.02;  %ditto
    
    %Threshold and Slope are free parameters, guess and lapse rate are fixed
    paramsFree = [1 1 0 0];  %1: free parameter, 0: fixed parameter
    
    %Fit a Logistic function
    PF = @PAL_Logistic;  %Alternatives: PAL_Gumbel, PAL_Weibull,
    %PAL_CumulativeNormal, PAL_HyperbolicSecant
    
    %Optional:
    options = PAL_minimize('options');   %type PAL_minimize('options','help') for help
    options.TolFun = 1e-09;     %increase required precision on LL
    options.MaxIter = 100;
    options.Display = 'off';    %suppress fminsearch messages
    
    %Perform fit
    disp('Fitting function.....');
    [paramsValues LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos, ...
        OutOfNum,searchGrid,paramsFree,PF,'searchOptions',options);
    
    disp('done:')
    message = sprintf('Threshold estimate: %6.4f',paramsValues(1));
    disp(message);
    message = sprintf('Slope estimate: %6.4f\r',paramsValues(2));
    disp(message);
    
    
    %Number of simulations to perform to determine standard error
    B=400;
    
    disp('Determining standard errors.....');
    
    if ParOrNonPar == 1
        [SD paramsSim LLSim converged] = PAL_PFML_BootstrapParametric(...
            StimLevels, OutOfNum, paramsValues, paramsFree, B, PF, ...
            'searchOptions',options,'searchGrid', searchGrid);
    else
        [SD paramsSim LLSim converged] = PAL_PFML_BootstrapNonParametric(...
            StimLevels, NumPos, OutOfNum, [], paramsFree, B, PF,...
            'searchOptions',options,'searchGrid',searchGrid);
    end
    
    %Number of simulations to perform to determine Goodness-of-Fit
    B=400;
    
    disp('Determining Goodness-of-fit.....');
    
    [Dev pDev] = PAL_PFML_GoodnessOfFit(StimLevels, NumPos, OutOfNum, ...
        paramsValues, paramsFree, B, PF,'searchOptions',options, ...
        'searchGrid', searchGrid);
    
    %Create simple plot
    ProportionCorrectObserved=NumPos./OutOfNum;
    StimLevelsFineGrain=[min(StimLevels):max(StimLevels)./1000:max(StimLevels)];
    ProportionCorrectModel = PF(paramsValues,StimLevelsFineGrain);
    
    subplot(2,1,a);
    plot(StimLevels,ProportionCorrectObserved,'o');
    ylabel('Proportion Correct');
    xlabel('Volume Difference');
    title(sprintf('Participant %.0f',x));
    axis([min(StimLevels) max(StimLevels) .4 1]);
    hold on
    plot(StimLevelsFineGrain,ProportionCorrectModel);
    title(sprintf('Participant %.0f, Anchor %.1fmL',id,A(a)));

    message = sprintf('Threshold estimate: %6.4f',paramsValues(1));
    disp(message);
    message = sprintf('Slope estimate: %6.4f\r',paramsValues(2));
    disp(message);
        %Put summary of results on screen
    message = sprintf('Deviance: %6.4f',Dev);
    disp(message);
    message = sprintf('p-value: %6.4f',pDev);
    disp(message);
        disp('done:');
    message = sprintf('Standard error of Threshold: %6.4f',SD(1));
    disp(message);
    message = sprintf('Standard error of Slope: %6.4f\r',SD(2));
    disp(message);
    
end
return