%% Carry-over effect regression
load('/Users/Bowen/Documents/MATLAB/PIPW/trialData.mat');
o = 0; % Orthogonalization switch

for p = 1:25
    temp = trialData(trialData.id == p & trialData.type == 1 & trialData.flag == 0 & ~isnan(trialData.lagResponse) & ~isnan(trialData.lagDelay),:);
    
    % Collinearity test
    collintest([ones(size(X(~any(isnan(X),2),:),1),1),X(~any(isnan(X),2),:)]);
    
    % Orthogonalize regressors
    if o == 1
        X = [temp.delay,orth([temp.lagResponse,temp.lagDelay])];
    else
        X = [temp.delay, temp.lagResponse,temp.lagDelay];
    end
    
    % Regression
    lm = fitlm(X,temp.response,'linear');
    
    % Tolerance check
    lm2 = fitlm([temp.delay,temp.lagResponse],temp.lagDelay,'linear');
    rsqu2(p,1) = 1- lm2.Rsquared.Ordinary;

    coefs(p,1:4) = table2array(lm.Coefficients(1:4,1));
    sds(p,1:4) = table2array(lm.Coefficients(1:4,2));
    rsqu(p,1) = lm.Rsquared.Ordinary;
end

% T-test
[h p ci stats] = ttest(coefs);

% Plot coefficients
figure;
hBar = bar(coefs(:,3:4)); hold on;
h = errorbar([1:size(sds,1)] - 0.14, coefs(:,3), sds(:,3));
set(h,'linestyle','none','Color', errorColour);
h2 = errorbar([1:size(sds,1)] + 0.14, coefs(:,4), sds(:,4));
set(h2,'linestyle','none','Color', errorColour);
set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
set(hBar(2),'FaceColor',barColour{6},'EdgeColor','none');
legend({'Decisional carry-over estimates','Perceptual carry-over estimates'});

% Plot within individual correlations
figure;
scatter(coefs(:,3),coefs(:,4));
xlabel('Decisional carry-over estimate');
ylabel('Perceptual carry-over estimate');
[r,p] = corr(coefs(:,3),coefs(:,4),'type','pearson');


