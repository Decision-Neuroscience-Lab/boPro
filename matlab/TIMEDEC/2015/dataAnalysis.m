%% TIMEDEC DATA ANALYSIS
% Bowen J Fung, 2015
%% Get data
oldcd = cd('/Users/Bowen/Documents/MATLAB/projects/TIMEDEC/2015');
load('data.mat');
load('intervals.mat');
load('timeSeries.mat');
load('TDmodelFvals.mat');
load('timedecQualtrics.mat');
load('newHRV2.mat');

%writetable(timeSeries,'/Users/Bowen/Documents/R/TIMEDEC/timeSeries.csv');
%writetable(intervals,'/Users/Bowen/Documents/R/TIMEDEC/intervals.csv')

%% Questionnaire data (already in data file)
 for tidiness = 1
%     % ipip = scoreIPIP(timedecQualtrics{:,6:55});
%     % bisbas = scoreBISBAS(timedecQualtrics{:,60:83});
%     % Apparently scores are
%     % already reversed, so the snippets of code below are just the last bit of
%     % the above functions
%     
%     % Compute scores
%     temp = timedecQualtrics{:,6:55};
%     ipip = nan(size(temp,1),5);
%     c = 1;
%     for i = 1:10:50
%         ipip(:,c) = mean(temp(:,i:i+9),2);
%         c = c + 1;
%         
%     end
%     temp = timedecQualtrics{:,60:83};
%     bisbas = nan(size(temp,1),4);
%     bisbas(:,1) = mean(temp(:,1:7),2);
%     bisbas(:,2) = mean(temp(:,8:11),2);
%     bisbas(:,3) = mean(temp(:,12:15),2);
%     bisbas(:,4) = mean(temp(:,16:20),2);
%     
%     % Zauberman (is this finished? Who knows.)
%     imagine = timedecQualtrics{:,96:99};
%     x = [2 4 8 15]; % Delays
%     auc = zeros(length(imagine),1);
%     for i = 1:length(imagine)
%         nImagine(i,:) = imagine(i,:)/imagine(i,1); % Normalise by lowest distance
%         AUC(i) = trapz(x,nImagine(i,:));
%         %     f = figure;
%         %     plot(x,nImagine(i,:));
%         %     title(sprintf('AUC: %.1f',AUC(i)));
%         %     pause(2)
%         %     close(f)
%     end
%     AUC(sum(imagine,2) == 400) = NaN; % Delete those who rated all as '100'
% end

% data = [data, array2table(ipip,'VariableNames',{'ipipN','ipipE','ipipO','ipipA','ipipC'})...
%     array2table(bisbas,'VariableNames',{'BIS','BASdrive','BASfun','BASreward'})...
%     array2table(AUC','VariableNames',{'zaubAUC'}), newHRV(:,2:end)];
 end
 
%% Check distributions
for tidiness = 1
    figure;
    subplot(2,1,1);
    histfit(data.k)
    subplot(2,1,2);
    histfit(log(data.k));
    suptitle('k1');
    
    figure;
    subplot(2,1,1);
    histfit(data.k2)
    subplot(2,1,2);
    histfit(log(data.k2));
    suptitle('k2');
    
    figure;
    subplot(2,1,1);
    histfit(data.hyperbolic)
    subplot(2,1,2);
    histfit(log(data.hyperbolic));
    suptitle('hyperbolic');
    
    figure;
    subplot(2,1,1);
    histfit(data.HRV)
    subplot(2,1,2);
    histfit(log(data.HRV));
    suptitle('HRV');
end

%% Temporal discounting
for tidiness = 1
    % Model comparison
    figure;
    fvals(fvals == 0) = NaN;
    hBar = bar(nanmean(fvals(:,1:3)));
    set(hBar, 'FaceColor', [.5 .5 .5], 'EdgeColor', 'none'); hold on;
    set(gca,'XTickLabel',{'Hyperbolic','Exponential','Quasi-hyperbolic'});
    eBar = errorbar(1:3,nanmean(fvals(:,1:3)),nanstd(fvals(:,1:3)));
    set(eBar,'LineStyle','none','Color',[0 0 0]);
    [h,p,ci,stats] = ttest2(fvals(:,1),fvals(:,2));
    
    
    % Histogram
    figure;
    nhist({data.bayesLogK(data.filter == 1)},'smooth',...
        'pdf','decimalplaces',0,'xlabel','log k','ylabel','PDF','color','colormap','fsize',19);
    
    temp = data;
    % Summary stats
    fprintf('Median logK:%.3f\nSTD k:%.2f\n',nanmedian(temp.logK(data.filter == 1)),nanstd(temp.logK(data.filter == 1)));
    fprintf('Median k:%.3f\nSTD k:%.2f\n',nanmedian(temp.k(data.filter == 1)),nanstd(temp.k(data.filter == 1)));
    fprintf('Median k2:%.3f\nSTD k2:%.2f\n',nanmedian(temp.k2(data.filter == 1)),nanstd(temp.k2(data.filter == 1)));
    fprintf('Median k2:%.3f\nSTD k3:%.2f\n',nanmedian(temp.k3(data.filter == 1)),nanstd(temp.k2(data.filter == 1)));

    % Group level estimate from hierarchical model is -0.53692
    
    
    % Test whether there are changes in between blocks
    [p,h,stats] = ranksum(temp.k(data.filter == 1),temp.k2(data.filter == 1));
end

%% Duration reproduction
for tidiness = 1
    figure;
    i = find(~data.cleanDR); % Flag outliers
    delays = unique(timeSeries.sample)';
    
    temp = timeSeries(ismember(timeSeries.id,i) & timeSeries.id < 121,:);
    for d = 1:numel(delays)
        D{d} = temp.reproduction(temp.sample == delays(d));
        delayStrings{d} = num2str(round(delays(d),1));
        M(d) = mean(D{d});
        SEM(d) = std(D{d});
    end
    subplot(2,2,1);
    hBar = plot(delays,M);
    set(hBar(1),'Color',[0 0 0],...
        'LineStyle','none',...
        'Marker','o');
    xlabel('Sample (s)');
    ylabel('Reproduction (s)');
    hold on
    h = errorbar(delays,M,SEM);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', [0 0 0]);
    
    % Psychophysical function
    stevens =  'k*(x^b)'; % 3 parameter power function
    [xData, yData] = prepareCurveData(temp.sample, temp.reproduction);
    ft = fittype(stevens);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    hold on;
    xx = 0:0.001:20;
    hBar = plot(xx,FO(xx), 'Color', [245 186 106]./255, 'LineWidth', 2);
    % legend(hBar,{'Psychophysical function'});
    
    %    % Histogram as third dimension
    %     figure;
    %     g = scatter(temp.sample,temp.reproduction);
    %     hold on
    %     %colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.494 0.184 0.556];
    %     xx = 0:0.001:15;
    %     plot(xx,FO(xx), 'Color', [0.929 0.694 0.1250], 'LineStyle', '--', 'LineWidth',1);
    %
    %     hist3(gca,[temp.sample,temp.reproduction], 'FaceAlpha', 0.2,...
    %         'EdgeAlpha',0.2, 'FaceColor',[0.9 0.9 0.9]);
    %     %set(gca,'CameraPosition', [-0.6831 -22.3766 255.8894]);
    %
    %     xlabel('Sample (s)');
    %     ylabel('Reproduction (s)');
    %     zlabel('Frequency');
    %     set(gcf, 'Color', [1 1 1]);
    %
    %     % Marginal histograms
    %     figure;
    %     scatterhist(temp.sample,temp.reproduction,'Group',temp.sample);
    
    % Plot histogram split by delay
    subplot(2,2,2);
    nhist(D,'smooth','pdf','legend',delayStrings,'decimalplaces',1,'xlabel','Reproduction (s)','ylabel','PDF','color','colormap','fsize',19);
    clearvars D M SEM
    
    % Add log(reproduction/sample) - symmetrical measurement of accuracy
    % (around 0)
    for p = 1:145
        temp = timeSeries(timeSeries.id == p,:);
        sym(p) = mean(log(temp.reproduction./temp.sample));
    end
    
    % SD
    i = find(data.filter); % Flag outliers
    temp = intervals(ismember(intervals.id, i),:);
    for d = 1:numel(delays)
        SD(:,d) = temp.stdReproduction(temp.sampleInterval == delays(d));
        repANOVA(:,d) = temp.meanReproduction(temp.sampleInterval == delays(d));
        repDiffANOVA(:,d) = temp.meanDiff(temp.sampleInterval == delays(d));
    end
    M = mean(SD);
    SEM = std(SD);
    [p,table,stats] = anova1(SD,[],'off');
    fprintf('ANOVA of standard deviation: F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    [p,table,stats] = anova1(repANOVA,[],'off');
    fprintf('ANOVA of reproduction: F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    [p,table,stats] = anova1(repDiffANOVA,[],'off');
    fprintf('ANOVA of difference: F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    subplot(2,2,3);
    hBar = plot(delays,M);
    set(hBar(1),'Color',[0 0 0],...
        'LineStyle',':',...
        'Marker','o');
    xlabel('Sample (s)');
    ylabel('SD');
    hold on
    h = errorbar(delays,M,SEM);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', [0 0 0]);
    clearvars M SD
    
    % Regress to find effect of increasing sample
    lm = fitlm([temp.sampleInterval],temp.meanDiff,'linear');
    
    % CV
    temp = intervals(ismember(intervals.id, i) & intervals.id < 121,:);
    for d = 1:numel(delays)
        CV(:,d) = temp.cvReproduction(temp.sampleInterval == delays(d));
    end
    M = mean(CV);
    SEM = std(CV);
    [p,table,stats] = anova1(CV,[],'off');
    fprintf('ANOVA of CV: F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    subplot(2,2,4);
    hBar = semilogx(delays,M);
    set(hBar(1),'Color',[0 0 0],...
        'LineStyle',':',...
        'Marker','o');
    xlabel('Sample (s)');
    ylabel('CV');
    hold on
    h = errorbar(delays,M,SEM);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', [0 0 0]);
    % Logarithmic regression
    lm = fitlm(log(delays),M,'linear');
    
    clearvars M SEM
    
    figure;
    subplot(2,1,2);
    % Exponents (psychophysics)
    nhist({data.stevens2(data.cleanDR == 0)},'smooth',...
        'pdf','decimalplaces',0,'xlabel','Exponent','ylabel','PDF','color','colormap','fsize',19);
    mean(data.stevens2(data.cleanDR == 0));
    std(data.stevens2(data.cleanDR == 0));
    
    % Intercepts (psychophysics)
    subplot(2,1,1);
    nhist({data.stevens1(data.cleanDR == 0)},'smooth',...
        'pdf','decimalplaces',0,'xlabel','Intercept','ylabel','PDF','color','colormap','fsize',19);
    mean(data.stevens1(data.filter == 1))
    std(data.stevens1(data.filter == 1))
    
end

%% Heart rate
for tidiness = 1
    % Censor data outside physiological range
    data.meanHR(data.meanHR == 0) = NaN;
    data.sdnn(data.sdnn == 0) = NaN;
    data.sdnni(data.sdnni == 0) = NaN;
    
    data.meanHR(data.meanHR > 140) = NaN;
    data.sdnn(data.sdnn < 20) = NaN;
    data.sdnni(data.sdnni < 20) = NaN;
    
    data.hfpowfft(data.hfpowfft > 4000) = NaN;
    data.lfpowfft(data.lfpowfft > 4000) = NaN;
    
    % Histograms
    figure;
    subplot(3,1,1);
    nhist({data.meanHR(data.cleanHR == 0)},'smooth',...
        'pdf','decimalplaces',0,'color','colormap','fsize',19);
    ylabel('PDF','FontName','CMU Serif');
    xlabel('Heart rate (bpm)','FontName','CMU Serif');
    subplot(3,1,2);
    nhist({data.sdnn(data.cleanHR == 0)},'smooth',...
        'pdf','decimalplaces',0,'color','colormap','fsize',19);
    ylabel('PDF','FontName','CMU Serif');
    xlabel('SDNN (ms)','FontName','CMU Serif');
    subplot(3,1,3);
    nhist({data.sdnni(data.cleanHR == 0)},'smooth',...
        'pdf','decimalplaces',0,'color','colormap','fsize',19);
    ylabel('PDF','FontName','CMU Serif');
    xlabel('SDNNI (ms)','FontName','CMU Serif');
    
    
    figure;
    subplot(2,1,1)
    ms2 = sprintf('$$^2$$');
    nhist({data.lfpowfft(data.cleanHR == 0)},'smooth',...
        'pdf','decimalplaces',0,'color','colormap','fsize',19);
    ylabel('PDF','FontName','CMU Serif');
    xlabel('LF power (ms$$^2$$)','Interpreter','latex');
    subplot(2,1,2);
    nhist({data.hfpowfft(data.cleanHR == 0)},'smooth',...
        'pdf','decimalplaces',0,'color','colormap','fsize',19);
    ylabel('PDF','FontName','CMU Serif');
    xlabel('HF power (ms$$^2$$)','Interpreter','latex');
    
    % Summary stats
    fprintf('Mean HR: %.3fbpm\nSTD HR: %.3f\n',nanmean(data.meanHR(data.cleanHR == 0)),nanstd(data.meanHR(data.cleanHR == 0)));
    fprintf('Mean sdnn: %.3fms\nSTD sdnn: %.3f\n',nanmean(data.sdnn(data.cleanHR == 0)),nanstd(data.sdnn(data.cleanHR == 0)));
    fprintf('Mean sdnni: %.3fms\nSTD sdnni: %.3f\n',nanmean(data.sdnni(data.cleanHR == 0)),nanstd(data.sdnni(data.cleanHR == 0)));
    
    fprintf('Mean hf: %.3fms\nSTD hf: %.3f\n',nanmean(data.hfpowfft(data.cleanHR == 0)),nanstd(data.hfpowfft(data.cleanHR == 0)));
    fprintf('Mean lf: %.3fms\nSTD lf: %.3f\n',nanmean(data.lfpowfft(data.cleanHR == 0)),nanstd(data.lfpowfft(data.cleanHR == 0)));

end

%% ANOVA for feedback manipulation
for tidiness = 1
    temp = data(data.filter == 1 & ~isnan(data.k2),{'id','condition','k','k2'});
    temp.condition = categorical(temp.condition);
    
    % Parametric ANOVA
    %     temp.k = log(temp.k); % Log transform K values
    %     temp.k2 = log(temp.k2);
    %
    %     Time = [1:2]';
    %     rm = fitrm(temp,'k-k2 ~ condition','WithinDesign',Time,'WithinModel','orthogonalcontrasts');
    %     ranova(rm)
    %     [p,tab,stats] = anova1(temp.k - temp.k2,temp.condition);
    
    % Non-parametric test
    [p,tbl,stats] = kruskalwallis(temp.k2 - temp.k, temp.condition);
    c = multcompare(stats,'Ctype','hsd');
    
    [p,h,stats] = ranksum(temp.k2(temp.condition == '2')-temp.k(temp.condition == '2'),...
        temp.k2(temp.condition == '3')-temp.k(temp.condition == '3'))
    
    %     % Export for R
    writetable(temp,'/Users/Bowen/Documents/R/TIMEDEC/feedbackMan.csv');
end

%% Correlations
temp = [data, array2table(ipip,'VariableNames',{'ipipN','ipipE','ipipO','ipipA','ipipC'})...
    array2table(bisbas,'VariableNames',{'BIS','BASdrive','BASfun','BASreward'})...
    array2table(AUC','VariableNames',{'zaubAUC'}), newHRV(:,2:end)];
temp = temp(temp.filter == 1,:);

%Temporal discounting and heart rate
vars = {'meanHR','sdann','sdnni','HRV'};
var = 'k3';
for v = 1:numel(vars)
    [r,p(v,1)] = corr(temp{:,vars(v)},temp{:,var},'type','spearman','rows','complete');
    fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v},var,r,p(v,1));
end
FDR1 = mafdr(p,'BHFDR',1);
clearvars p

% Time perception and heart rate
vars = {'stevens1','stevens2','meanReproduction','stdReproduction','cvReproduction','meanDiff',...
    'meanHR','sdann','HRV','sdnn','hfpeakfft','lfpowfft','ratio'};
var = 'stevens1';
for v = 1:numel(vars)
    [r,p(v,1)] = corr(temp{:,vars(v)},temp{:,var},'type','spearman','rows','complete');
    fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v},var,r,p(v,1));
end
FDR2 = mafdr(p,'BHFDR',1);
clearvars p

% Questionnaire measures and heart rate
vars = {'sdnn','ptHR','ratio','HRV','hfpeakfft','lfpowfft',...
    'ipipN','ipipE','ipipO','ipipA','ipipC','BIS','BASfun','BASreward','zaubAUC'};
var = 'zaubAUC';
for v = 1:numel(vars)
    [r,p(v,1)] = corr(temp{:,vars(v)},temp{:,var},'type','spearman','rows','complete');
    fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v},var,r,p(v,1));
end
FDR3 = mafdr(p,'BHFDR',1);
clearvars p

% Everything
%temp.filter(temp.cleanHR == 1 | temp.cleanTD == 1 | temp.cleanOther == 1) = 0;
temp = temp(temp.filter == 1,:);
vars = fieldnames(temp);
vars = vars(2:end-1);
var2 = 'k3';
for v1 = 1:numel(vars)
    [r,p(v1,1)] = corr(temp{:,vars(v1)},temp{:,var2},'type','spearman','rows','complete');
    if p(v1,1) < 0.05
        fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v1},var2,r,p(v1,1));
    end
end

%% Scatter plots
figure;
scatter(temp.stevens2, temp.k3)
[h,p] = corr(temp.stevens1, temp.k, 'rows','complete','type','spearman')

%% New Correlations (September 2015)
temp = [data, array2table(ipip,'VariableNames',{'ipipN','ipipE','ipipO','ipipA','ipipC'})...
    array2table(bisbas,'VariableNames',{'BIS','BASdrive','BASfun','BASreward'})...
    array2table(AUC','VariableNames',{'zaubAUC'}), newHRV(:,2:18)];
temp = temp(temp.filter == 1,:);

%Temporal discounting and heart rate
clearvars p FDR1
vars = {'meanHR','sdnn','sdann','hfpeakfft','lfpeakfft'};
var = 'k3';
for v = 1:numel(vars)
    [r,p(v,1)] = corr(temp{:,vars(v)},temp{:,var},'type','spearman','rows','complete');
    fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v},var,r,p(v,1));
end
FDR1 = mafdr(p,'BHFDR',1);


% Time perception and heart rate
clearvars p FDR2
vars = {'stevens1','stevens2','meanReproduction','stdReproduction','cvReproduction','meanDiff',...
    'meanHR','sdann','HRV','sdnn','hfpeakfft','lfpowfft','ratio'};
var = 'stevens1';
for v = 1:numel(vars)
    [r,p(v,1)] = corr(temp{:,vars(v)},temp{:,var},'type','spearman','rows','complete');
    fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v},var,r,p(v,1));
end
FDR2 = mafdr(p,'BHFDR',1);


%% Questionnaire correlations
vars = {'ipipN','ipipE','ipipO','ipipA','ipipC','BIS','BASdrive','BASfun','BASreward','zaubAUC'};
vars2 = fieldnames(temp);
vars2 = vars2(2:end-1);
P = cell(length(vars2),length(vars));
for v1 = 1:numel(vars)
    for v2 = 1:numel(vars2)
        [r,p] = corr(temp{:,vars(v1)},temp{:,vars2(v2)},'type','spearman','rows','complete');
        if p < 0.1
            P{v2,v1} = sprintf('%.3f (%.3f)',r,p);
        end
    end
end

persCorr = array2table(P,'VariableNames',vars,'RowNames',vars2);
persCorr({'cleanTD','cleanDR','cleanHR','cleanOther','filter'},:) = [];

%% New HRV correlations (Kubios)
temp = [data, array2table(ipip,'VariableNames',{'ipipN','ipipE','ipipO','ipipA','ipipC'})...
    array2table(bisbas,'VariableNames',{'BIS','BASdrive','BASfun','BASreward'})...
    array2table(AUC','VariableNames',{'zaubAUC'}), newHRV(:,2:18)];
%temp.filter(temp.cleanHR == 1 | temp.cleanTD == 1 | temp.cleanOther == 1) = 0;
temp = temp(temp.filter == 1,:);

vars = fieldnames(temp);
vars = vars(2:end-1);
var2 = 'zaubAUC';
for v1 = 1:numel(vars)
    [r,p] = corr(temp{:,vars(v1)},temp{:,var2},'type','spearman','rows','complete');
    if p < 0.05
        fprintf('%s and %s\nr = %.3f\np = %.3f\n',vars{v1},var2,r,p);
    end
end

%% Temporal carry-over effects
i = find(data.filter == 1);
temp = timeSeries(ismember(timeSeries.id, i),:);
temp.lagSample = nan(height(temp),1);
temp.lagReproduction = nan(height(temp),1);
delays = unique(temp.sample);
par = unique(temp.id);
for p = 1:numel(par)
    i = temp.id == par(p);
    temp.lagSample(i) = lagmatrix(temp.sample(i),1);
    temp.lagReproduction(i) = lagmatrix(temp.reproduction(i),1);
end

collintest([temp.lagSample(~isnan(temp.lagSample)),temp.lagReproduction(~isnan(temp.lagSample))]);


% Previous sample
c = 1;
for p = unique(temp.id)'
    temp2 = temp(temp.id == p,:);
    lm = fitlm([temp2.sample, temp2.lagSample],temp2.reproduction,'linear');
    coefs(c,1) = table2array(lm.Coefficients(3,1));
    sds(c,1) = table2array(lm.Coefficients(3,2));
     c = c + 1;
end
% Remove participants
% notClean = data.id(data.cleanDR == 1);
% notClean = notClean(~isnan(notClean));
% coefs(notClean) = NaN;
[h p ci stats] = ttest(coefs);

figure;
bar(sort(coefs)); hold on;
% errorbar(coefs,sds,'linestyle','none');

% Previous response
c = 1;
for p = unique(temp.id)'
    temp3 = temp(temp.id == p,:);
    lm = fitlm([temp3.sample, temp3.lagReproduction],temp3.reproduction,'linear');
    coefs(c,1) = table2array(lm.Coefficients(3,1));
    sds(c,1) = table2array(lm.Coefficients(3,2));
    c = c + 1;
end
% Remove participants
% notClean = data.id(data.cleanDR == 1);
% notClean = notClean(~isnan(notClean));
% coefs(notClean) = NaN;
[h p ci stats] = ttest(coefs);
figure;
bar(sort(coefs)); hold on;
% errorbar(coefs,sds,'linestyle','none');


clearvars coefs sds
% Previous sample and previous response
c = 1;
for p = unique(temp.id)'
    temp4 = temp(temp.id == p,:);
    lm = fitlm([temp4.sample, temp4.lagReproduction, temp4.lagSample],temp4.reproduction,'linear');
    coefs(c,1:4) = table2array(lm.Coefficients(1:4,1));
    sds(c,1:4) = table2array(lm.Coefficients(1:4,2));
    % subplot(5,5,p);
    % plot(lm);
    % legend('off');
    c =  c + 1;
end
% Remove participants
% notClean = data.id(data.cleanDR == 1);
% notClean = notClean(~isnan(notClean));
% coefs(notClean) = NaN;
[h p ci stats] = ttest(coefs);

figure;
bar(sort(coefs)); hold on;
% errorbar(coefs,sds,'linestyle','none');

%% Correlation scatterplots

    temp = data(data.filter == 1,:);
 % Censor data outside physiological range
    temp.meanHR(temp.meanHR == 0) = NaN;
    temp.sdnn(temp.sdnn == 0) = NaN;
    temp.sdnni(temp.sdnni == 0) = NaN;
    
    temp.meanHR(temp.meanHR > 140) = NaN;
    temp.sdnn(temp.sdnn < 20) = NaN;
    temp.sdnni(temp.sdnni < 20) = NaN;
    
    temp.hfpowfft(temp.hfpowfft > 4000) = NaN;
    temp.lfpowfft(temp.lfpowfft > 4000) = NaN;
    
    temp.hfpowfft(temp.hfpowfft == 0) = NaN;

 % HR and DR
corrPlot([temp.hfpowfft temp.lfpowfft temp.stevens1 temp.stevens2],...
    'varNames',{'HF','LF','Intercept','Exponent'},'type','spearman','rows','pairwise','testR','on');

% HR and TD
corrPlot([temp.k3 temp.meanHR],...
    'varNames',{'log(K)','HR'},'type','spearman','rows','pairwise','testR','on');

% HR and AUC
corrPlot([temp.zaubAUC temp.ptHR],...
    'varNames',{'AUC','HR'},'type','spearman','rows','pairwise','testR','on');

% TD and DR
corrPlot([temp.bayesLogK temp.stevens1 temp.stevens2],...
    'varNames',{'K','intercept','exponent'},'type','spearman','rows','pairwise','testR','on');

% Take median split of LF power and look at psychophysical function
figure;
a1 = nanmean(temp.stevens1(temp.lfpowfft < nanmedian(temp.lfpowfft)));
a1sd = nanstd(temp.stevens1(temp.lfpowfft < nanmedian(temp.lfpowfft)));
b1 = nanmean(temp.stevens2(temp.lfpowfft < nanmedian(temp.lfpowfft)));
b1sd = nanstd(temp.stevens2(temp.lfpowfft < nanmedian(temp.lfpowfft)));

a2 = nanmean(temp.stevens1(temp.lfpowfft >= nanmedian(temp.lfpowfft)));
a2sd = nanstd(temp.stevens1(temp.lfpowfft >= nanmedian(temp.lfpowfft)));
b2 = nanmean(temp.stevens2(temp.lfpowfft >= nanmedian(temp.lfpowfft)));
b2sd = nanstd(temp.stevens2(temp.lfpowfft >= nanmedian(temp.lfpowfft)));

stevens = @(k,b,x) k*(x.^b); % 3 parameter power function
xx = 0:0.001:20;
hBar = plot(xx,stevens(a1,b1,xx), 'Color', [0 113 189]./255, 'LineWidth', 3, 'LineStyle', ':'); hold on;
hBar2 = plot(xx,stevens(a2,b2,xx), 'Color',[217 83 25]./255, 'LineWidth', 3, 'LineStyle', ':'); hold on;
hBar3 = plot(xx,xx, 'Color',[0 0 0], 'LineWidth', 1); hold on; % Veridical
legend({'Low LF power','High LF power'})
xlabel('Sample (s)')
ylabel('Reproduction (s)')

% hBar3 = plot(xx,stevens(a1+a1sd,b1+b1sd,xx), xx, stevens(a1-a1sd,b1-b1sd,xx),...
%     'Color', [0 0 0], 'LineWidth', 1, 'LineStyle', ':'); hold on;
% hBar4 = plot(xx,stevens(a2+a2sd,b2+b2sd,xx), xx,stevens(a2-a2sd,b2-b2sd,xx),...
%     'Color', [0 0 0], 'LineWidth', 1, 'LineStyle', ':'); hold on;

% Take median split of heart rate power and look at discount function
figure;
k1 = nanmean(temp.k3(temp.meanHR < nanmedian(temp.meanHR)));
k2 = nanmean(temp.k3(temp.meanHR >= nanmedian(temp.meanHR)));

hyp = @(k,D) 30 .* (1 ./ (1 + (k.*D) )); % hyperbolic function with set reward
xx = 0:1:12;
hBar = plot(xx,hyp(k1,xx), 'Color', [0 113 189]./255, 'LineWidth', 3, 'LineStyle', ':'); hold on;
hBar2 = plot(xx,hyp(k2,xx), 'Color',[217 83 25]./255, 'LineWidth', 3, 'LineStyle', ':'); hold on;
legend({'Low heart rate','High heart rate'})
xlabel('Time (months)')
ylabel('Value (dollars)')

%% Carry-over effects
 % Plot settings
    set(0,'DefaultAxesColorOrder',...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
    colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
    set(0,'DefaultFigureColor',[1 1 1]);
    set(0,'DefaultAxesFontSize',20);
    %barColour = {[0.15 0.15 0.15],[.3 .3 .3],[.45 .45 .45],[.6 .6 .6],[0.75 0.75 0.75],[0.9 0.9 0.9]};
    barColour = {[0.6824 0.1961 0.3255],[0.8431 0.3412 0.2980],[0.9686 0.7294 0.4157],...
        [0.9490 0.8039 0.5686],[0.7647 0.6941 0.5961],[0.3255 0.5255 0.5647]};
    errorColour = [0.4 0.4 0.4];
    
for tidiness = 1
    c = 1;
    for p = unique(timeSeries.id)'
        temp = timeSeries(timeSeries.id == p,:);
        X = [temp.sample];%, lagmatrix([temp.reproduction],1)];
        lm = fitlm(X,temp.reproduction,'linear');
        numCoefs = numel(lm.Coefficients(:,1));
        coefs(c,1:numCoefs) = table2array(lm.Coefficients(1:numCoefs,1));
        sds(c,1:numCoefs) = table2array(lm.Coefficients(1:numCoefs,2));
        rsqu(c,1) = lm.Rsquared.Ordinary;
 c = c + 1;
        %collintest([ones(size(X(~any(isnan(X),2),:),1),1),X(~any(isnan(X),2),:)]);
    end
    [h p ci stats] = ttest(coefs);
    figure;
    hBar = bar(coefs(:,3:4)); hold on;
    h = errorbar([1:size(sds,1)] - 0.14, coefs(:,3), sds(:,3));
    set(h,'linestyle','none','Color', errorColour);
    h2 = errorbar([1:size(sds,1)] + 0.14, coefs(:,4), sds(:,4));
    set(h2,'linestyle','none','Color', errorColour);
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{6},'EdgeColor','none');
    xlim([0 145])
    legend({'Perceptual carry-over estimates','Response carry-over estimates'});
    [r,p] = corr(coefs(:,3),coefs(:,4),'type','pearson')
    figure;
    scatter(coefs(:,3),coefs(:,4));
    
    xlabel('Decisional carry-over estimate');
    ylabel('Perceptual carry-over estimate');
    
    coefs = [unique(timeSeries.id) coefs];
    coefs = array2table(coefs, 'VariableNames', {'id','intercept','sample'});%,'lagReproduction'});
    writetable(coefs,'/Users/Bowen/Documents/R/TIMEDEC/COcoefs.csv');
    
end

