%% Make conditions specific charts

IV = 'reward';
t = 3;

factor = amounts;
    temp = trialData(trialData.flag == 0 & trialData.session == 2,:);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
        for a = 1:numel(factor)
            if strcmp(factor,amounts)
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
            elseif factor == delays
            ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
            end
            means(1,a) = nanmean(ME(:,a));
            sems(1,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
        end
        clearvars ME
    
    figure;
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});  
    end
    ylabel('Normalised deviation');
    ylim([-.05 .25]);
    clearvars('-except',initialVars{:});

    
    
    %% Baselines
    
        t = 3;
    
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'normAccuracy'};
    groupVar = {'session','id','type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    

        for s = 1:3
            ME(:,s) = M.nanmean_normAccuracy(M.session == s & M.type == t);
            SD(1,s) = nanstd(ME(:,s)) ./ sqrt(numel(ME(:,s)));
            MEANS(1,s) = nanmean(ME(:,s));
        end
    
        clearvars ME
    
    figure;
    hBar = bar(MEANS');
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',...
        {'First baseline','Main Task','Second baseline'});
    ylabel('Normalised deviation');
    hold on
    for e = 1:size(SD,2)
        h = errorbar(e, MEANS(1,e), SD(1,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    ylim([-0.35, 0.3]);
    
    %
    % % Draw brackets
    % x1 = 1;
    % x2 = 3;
    % y = 0.12;
    % height = 0.01;
    % % Make some x-data and y-data
    % line_y = y  + [0, 0.5, 0.5, 1, 0.5, 0.5, 0] * height;
    % line_x = x1 + [0, 0.02, 0.48, 0.5, 0.52, 0.98, 1]*(x2-x1);
    % % Draw the brace and some text, too, for fun.
    % line(line_x, line_y, 'Color', 'k')
    %
    % text(1-0.04, mean(ME(:,1))-SD(1)-0.03, '*','FontSize',50);
    
    clearvars('-except',initialVars{:});
