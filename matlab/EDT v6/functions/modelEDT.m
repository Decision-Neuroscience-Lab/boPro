function [accuracy, ip, modelParams] = modelEDT(D,A,Y,fit_to_proportions,ploton)
% Takes a column of delays, a column of amounts, and a column of responses
% (1,2). Also takes an argument (prop) that if set to 1 will model based on
% choice proportions instead of choice values (do this if there are few
% amounts and responses can be binned easily). Assumes a fixed LL reward and a
% fixed SS delay. Returns accuracy of model fit and indifference point for
% each delay. Requires logitFit function.

%% Plot choice frequencies, fits and accuracies
delays = unique(D);
for x = 1:numel(delays)
     d = D == delays(x);
        temp = A(d); % All amounts for delay d
        temp2 = Y(d); % All choices for delay d
        amounts = unique(temp);
        for y = 1:numel(amounts)
            a = temp == amounts(y);
            propChoices(y,1) = mean(temp2(a)-1);
        end
        
        switch fit_to_proportions
            case 0
        % Fit to actual choices
        [params ip(x)] = logitFit(temp, temp2 - 1, ploton);
        % Get model accuracy
        prop(x) = sum(temp2 == 1) / (sum(temp2 == 1) + sum(temp2 == 2)); % Get choice proportion to use as criterion for model (to adjust to baseline)
        cutoff(x) = ((-log((1-prop(x))./prop(x))) ./ params(1)) + params(2); % Generate cutoff amount using model params
        corLL(x) = sum(temp(temp2 == 2) <= cutoff(x));
        incLL(x) = sum(temp(temp2 == 2) > cutoff(x));
        corSS(x) = sum(temp(temp2 == 1) >= cutoff(x));
        incSS(x) = sum(temp(temp2 == 1) < cutoff(x));
        accuracy(x) = (corLL(x) + corSS(x)) / ((incLL(x) + incSS(x)) + (corLL(x) + corSS(x)));
            case 1
        % Fit to proportion of choices (binned)
        [params ip(x)] = logitFit(amounts, propChoices, ploton);
        % Get model accuracy
        prop(x) = sum(temp2 == 1) / (sum(temp2 == 1) + sum(temp2 == 2)); % Get choice proportion to use as criterion for model (to adjust to baseline)
        cutoff(x) = ((-log((1-prop(x))./prop(x))) ./ params(1)) + params(2); % Generate cutoff amount using model params
        corLL(x) = sum(temp(temp2 == 2) <= cutoff(x));
        incLL(x) = sum(temp(temp2 == 2) > cutoff(x));
        corSS(x) = sum(temp(temp2 == 1) >= cutoff(x));
        incSS(x) = sum(temp(temp2 == 1) < cutoff(x));
        accuracy(x) = (corLL(x) + corSS(x)) / ((incLL(x) + incSS(x)) + (corLL(x) + corSS(x)));
        end
        
        modelParams{x} = params;
        
       clear temp temp2 propChoices amounts
end
return